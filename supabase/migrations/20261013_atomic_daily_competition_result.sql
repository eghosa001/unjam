-- Make a single Daily result write + daily/weekly totals atomic.
-- Existing entries remain intact and old local retry queues remain compatible.
create index if not exists competition_entries_player_week_idx
  on public.competition_entries (player_hash, week_start);

create or replace function public.unjam_record_daily_result(
  p_player_hash text,
  p_display_name text,
  p_game_id text,
  p_day date,
  p_week date,
  p_score integer,
  p_metrics jsonb
) returns jsonb language plpgsql security invoker set search_path = public
as $$
declare
  v_best integer;
  v_daily_score integer;
  v_daily_count integer;
  v_weekly_score integer;
  v_weekly_count integer;
begin
  if p_player_hash is null or p_player_hash !~ '^[0-9a-f]{64}$'
    or p_display_name is null or length(p_display_name) not between 1 and 20
    or p_game_id not in ('rescue_rush','water_sort','block_puzzle')
    or p_score not between 1 and 1200
    or p_day is null
    or p_day < (now() at time zone 'utc')::date - 1
    or p_day > (now() at time zone 'utc')::date + 1
    or p_week is null
    or p_week <> p_day - (extract(isodow from p_day)::integer - 1)
    or jsonb_typeof(p_metrics) is distinct from 'object'
  then
    return jsonb_build_object('ok',false,'status',400,'reason','Invalid Daily score');
  end if;
  -- Serialize ALL days/games for the same player. Per-day locks would
  -- race when rebuilding the weekly total on different concurrent dates.
  perform pg_advisory_xact_lock(hashtextextended('unjam-daily:' || p_player_hash, 0));

  insert into public.competition_entries(
    player_hash, display_name, competition_day, week_start, game_id,
    score, metrics, updated_at
  ) values (
    p_player_hash, p_display_name, p_day, p_week, p_game_id,
    p_score, p_metrics, now()
  )
  on conflict (player_hash, competition_day, game_id) do update set
    score=greatest(public.competition_entries.score, excluded.score),
    metrics=case when excluded.score > public.competition_entries.score
                 then excluded.metrics else public.competition_entries.metrics end,
    display_name=excluded.display_name,
    updated_at=case when excluded.score > public.competition_entries.score
                    then now() else public.competition_entries.updated_at end
  returning score into v_best;

  select count(*)::integer,coalesce(sum(score),0)::integer
    into v_daily_count,v_daily_score
  from public.competition_entries
  where player_hash=p_player_hash and competition_day=p_day;
  insert into public.competition_totals(
    period_type,period_key,player_hash,display_name,score,games_count,updated_at
  ) values (
    'daily',p_day,p_player_hash,p_display_name,v_daily_score,v_daily_count,now()
  )
  on conflict (period_type,period_key,player_hash) do update set
    display_name=excluded.display_name,score=excluded.score,
    games_count=excluded.games_count,updated_at=now();

  select count(*)::integer,coalesce(sum(score),0)::integer
    into v_weekly_count,v_weekly_score
  from public.competition_entries
  where player_hash=p_player_hash and week_start=p_week;
  insert into public.competition_totals(
    period_type,period_key,player_hash,display_name,score,games_count,updated_at
  ) values (
    'weekly',p_week,p_player_hash,p_display_name,v_weekly_score,v_weekly_count,now()
  )
  on conflict (period_type,period_key,player_hash) do update set
    display_name=excluded.display_name,score=excluded.score,
    games_count=excluded.games_count,updated_at=now();

  return jsonb_build_object(
    'ok',true,'score',v_best,
    'day_score',v_daily_score,'weekly_score',v_weekly_score,
    'daily_games',v_daily_count,'weekly_games',v_weekly_count
  );
end;
$$;
revoke all on function public.unjam_record_daily_result(text,text,text,date,date,integer,jsonb)
  from public,anon,authenticated;
grant execute on function public.unjam_record_daily_result(text,text,text,date,date,integer,jsonb)
  to service_role;
