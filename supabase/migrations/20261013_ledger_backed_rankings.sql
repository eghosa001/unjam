-- Preserve the old public scores for audit, but do not present them as
-- ledger-backed competitive results. The old snapshot API once promoted
-- client-reported thousands of levels without completion receipts.
-- A new account can start ranking from its current campaign level, but that
-- first submission counts as just ONE ranked completion.
alter table public.progression_rankings
  add column if not exists ledger_backed boolean not null default false;

-- Backfill only the contiguous, individually recorded chain (it may begin
-- at a late campaign level for upgraded installations). Gaps cannot
-- silently become credited milestones when old clients made jumps.
with numbered as (
  select e.player_hash,e.game_id,e.level_number,e.best_stars,e.first_clear_week,
         min(e.level_number) over (partition by e.player_hash,e.game_id) as first_level,
         row_number() over (partition by e.player_hash,e.game_id order by e.level_number) as seq
  from public.progression_level_events e
), eligible as (
  select * from numbered where level_number = first_level + seq - 1
), rollups as (
  select 'all_time'::text as scope_type,date '1970-01-01' as period_key,
    game_id,player_hash,count(*)::integer as completed,
    max(level_number)::integer as highest,coalesce(sum(best_stars),0)::integer as stars
  from eligible group by game_id,player_hash
  union all
  select 'weekly'::text,first_clear_week,game_id,player_hash,
    count(*)::integer,max(level_number)::integer,
    coalesce(sum(best_stars),0)::integer
  from eligible group by first_clear_week,game_id,player_hash
)
update public.progression_rankings r set
  levels_completed = x.completed,highest_level = x.highest,stars = x.stars,
  rank_score = x.completed::bigint * 100000 + x.stars,
  ledger_backed = true
from rollups x
where r.scope_type=x.scope_type and r.period_key=x.period_key
  and r.game_id=x.game_id and r.player_hash=x.player_hash;

create index if not exists progression_rankings_ledger_score_idx
  on public.progression_rankings(scope_type,period_key,game_id,rank_score desc,updated_at asc)
  where ledger_backed=true;

-- Transactional, service-only league updates. No client-side score snapshot
-- can modify these rankings. One player/game advisory lock serializes simultaneous
-- distinct level clears; row uniqueness keeps repeated submissions idempotent.
create or replace function public.unjam_record_progress(
  p_player_hash text, p_display_name text, p_game_id text,
  p_level_number integer, p_stars integer, p_first_clear boolean,
  p_week date
) returns jsonb language plpgsql security invoker
set search_path = public
as $$
declare
  v_levels integer := 0;
  v_highest integer := 0;
  v_stars integer := 0;
  v_prior_best integer;
  v_inserted_level integer;
  v_recent bigint := 0;
  v_count integer := 0;
  v_week_stars integer := 0;
  v_week_highest integer := 0;
  v_new_clear boolean := false;
  v_upgraded boolean := false;
  v_repaired boolean := false;
begin
  if p_player_hash is null or p_player_hash !~ '^[a-f0-9]{64}$'
     or p_display_name is null or length(p_display_name) not between 1 and 20
     or p_game_id is null or p_game_id not in ('rescue_rush','water_sort','block_puzzle')
     or p_level_number is null or p_level_number not between 1 and 10000
     or p_stars is null or p_stars not between 1 and 3
     or p_week is null
     or extract(isodow from p_week) <> 1
     or p_week < (now() at time zone 'utc')::date - 7
     or p_week > (now() at time zone 'utc')::date + 7
  then
    return jsonb_build_object('ok',false,'reason','Invalid league input','status',400);
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_player_hash || ':' || p_game_id, 0));
  select levels_completed, highest_level, stars
    into v_levels, v_highest, v_stars
  from public.progression_rankings
  where scope_type='all_time' and period_key=date '1970-01-01'
    and game_id=p_game_id and player_hash=p_player_hash
    and ledger_backed=true;
  v_levels := coalesce(v_levels, 0);
  v_highest := coalesce(v_highest, 0);
  v_stars := coalesce(v_stars, 0);

  if not p_first_clear and p_level_number > v_highest then
    return jsonb_build_object('ok',false,'reason','Only first clears advance rankings','status',409);
  end if;

  -- Existing offline campaigns may begin ranked sync at an advanced level.
  -- Count that first receipt as ONE level, never as thousands of completed
  -- levels. Once a receipt exists, reject any gap in the ranked sequence.
  if p_first_clear and v_levels > 0 and p_level_number > v_highest + 1 then
    return jsonb_build_object('ok',false,'reason','Skipped ranked level','status',409);
  end if;

  if p_first_clear and p_level_number > v_highest then
    select count(*) into v_recent
    from public.progression_level_events
    where player_hash=p_player_hash and game_id=p_game_id
      and created_at >= now() - interval '1 hour';
    if v_recent >= 180 then
      return jsonb_build_object('ok',false,'reason','Hourly ranked-completion limit','status',429);
    end if;
    insert into public.progression_level_events (
      player_hash,game_id,level_number,best_stars,first_clear_week
    ) values (p_player_hash,p_game_id,p_level_number,p_stars,p_week)
    on conflict (player_hash,game_id,level_number) do nothing
    returning level_number into v_inserted_level;
    if v_inserted_level is not null then
      v_new_clear := true;
      v_levels := least(10000, v_levels + 1);
      v_highest := greatest(v_highest,p_level_number);
      v_stars := least(v_levels * 3, v_stars + p_stars);
    else
      -- Self-heal an event/rank mismatch left by an older non-transactional
      -- client: derive total score only from the unique event ledger.
      with ranked as (
        select level_number,best_stars,
               min(level_number) over () as initial_level,
               row_number() over (order by level_number) as sequence_no
        from public.progression_level_events
        where player_hash=p_player_hash and game_id=p_game_id
      )
      select count(*)::integer,coalesce(sum(best_stars),0)::integer,
             coalesce(max(level_number),0)::integer
        into v_levels,v_stars,v_highest
      from ranked
      where level_number = initial_level + sequence_no - 1;
      v_repaired := true;
    end if;
  else
    select best_stars into v_prior_best
    from public.progression_level_events
    where player_hash=p_player_hash and game_id=p_game_id and level_number=p_level_number;
    if v_prior_best is not null and p_stars > v_prior_best then
      update public.progression_level_events
        set best_stars=p_stars,updated_at=now()
      where player_hash=p_player_hash and game_id=p_game_id and level_number=p_level_number;
      v_stars := least(v_levels * 3,v_stars + p_stars - v_prior_best);
      v_upgraded := true;
    end if;
  end if;

  if v_new_clear or v_upgraded or v_repaired then
    insert into public.progression_rankings (
      scope_type,period_key,game_id,player_hash,display_name,
      levels_completed,highest_level,stars,rank_score,updated_at,ledger_backed
    ) values (
      'all_time',date '1970-01-01',p_game_id,p_player_hash,p_display_name,
      v_levels,v_highest,v_stars,v_levels::bigint*100000+v_stars,now(),true
    )
    on conflict (scope_type,period_key,game_id,player_hash)
    do update set display_name=excluded.display_name,
      levels_completed=excluded.levels_completed,
      highest_level=excluded.highest_level,
      stars=excluded.stars,rank_score=excluded.rank_score,updated_at=now(),
      ledger_backed=true;
  end if;

  with ranked as (
    select level_number,best_stars,first_clear_week,
           min(level_number) over () as initial_level,
           row_number() over (order by level_number) as sequence_no
    from public.progression_level_events
    where player_hash=p_player_hash and game_id=p_game_id
  )
  select count(*)::integer,coalesce(sum(best_stars),0)::integer,
         coalesce(max(level_number),0)::integer
  into v_count,v_week_stars,v_week_highest
  from ranked
  where level_number = initial_level + sequence_no - 1
    and first_clear_week=p_week;
  if v_count > 0 then
    insert into public.progression_rankings (
      scope_type,period_key,game_id,player_hash,display_name,
      levels_completed,highest_level,stars,rank_score,updated_at,ledger_backed
    ) values (
      'weekly',p_week,p_game_id,p_player_hash,p_display_name,
      v_count,v_week_highest,v_week_stars,v_count::bigint*100000+v_week_stars,now(),true
    )
    on conflict (scope_type,period_key,game_id,player_hash)
    do update set display_name=excluded.display_name,
      levels_completed=excluded.levels_completed,
      highest_level=excluded.highest_level,
      stars=excluded.stars,rank_score=excluded.rank_score,updated_at=now(),
      ledger_backed=true;
  end if;
  return jsonb_build_object('ok',true,'new_clear',v_new_clear,
    'stars_upgraded',v_upgraded,'levels_completed',v_levels,'stars',v_stars);
end;
$$;
revoke all on function public.unjam_record_progress(text,text,text,integer,integer,boolean,date)
from public,anon,authenticated;
grant execute on function public.unjam_record_progress(text,text,text,integer,integer,boolean,date)
to service_role;
