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
    and game_id=p_game_id and player_hash=p_player_hash;
  v_levels := coalesce(v_levels, 0);
  v_highest := coalesce(v_highest, 0);
  v_stars := coalesce(v_stars, 0);

  if not p_first_clear and p_level_number > v_highest then
    return jsonb_build_object('ok',false,'reason','Only first clears advance rankings','status',409);
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
      select count(*)::integer,coalesce(sum(best_stars),0)::integer,
             coalesce(max(level_number),0)::integer
        into v_levels,v_stars,v_highest
      from public.progression_level_events
      where player_hash=p_player_hash and game_id=p_game_id;
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
      levels_completed,highest_level,stars,rank_score,updated_at
    ) values (
      'all_time',date '1970-01-01',p_game_id,p_player_hash,p_display_name,
      v_levels,v_highest,v_stars,v_levels::bigint*100000+v_stars,now()
    )
    on conflict (scope_type,period_key,game_id,player_hash)
    do update set display_name=excluded.display_name,
      levels_completed=excluded.levels_completed,
      highest_level=excluded.highest_level,
      stars=excluded.stars,rank_score=excluded.rank_score,updated_at=now();
  end if;

  select count(*)::integer,coalesce(sum(best_stars),0)::integer,
         coalesce(max(level_number),0)::integer
  into v_count,v_week_stars,v_week_highest
  from public.progression_level_events
  where player_hash=p_player_hash and game_id=p_game_id and first_clear_week=p_week;
  if v_count > 0 then
    insert into public.progression_rankings (
      scope_type,period_key,game_id,player_hash,display_name,
      levels_completed,highest_level,stars,rank_score,updated_at
    ) values (
      'weekly',p_week,p_game_id,p_player_hash,p_display_name,
      v_count,v_week_highest,v_week_stars,v_count::bigint*100000+v_week_stars,now()
    )
    on conflict (scope_type,period_key,game_id,player_hash)
    do update set display_name=excluded.display_name,
      levels_completed=excluded.levels_completed,
      highest_level=excluded.highest_level,
      stars=excluded.stars,rank_score=excluded.rank_score,updated_at=now();
  end if;
  return jsonb_build_object('ok',true,'new_clear',v_new_clear,
    'stars_upgraded',v_upgraded,'levels_completed',v_levels,'stars',v_stars);
end;
$$;
revoke all on function public.unjam_record_progress(text,text,text,integer,integer,boolean,date)
from public,anon,authenticated;
grant execute on function public.unjam_record_progress(text,text,text,integer,integer,boolean,date)
to service_role;
