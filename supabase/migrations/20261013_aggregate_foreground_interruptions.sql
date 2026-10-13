-- Anonymous, opt-in foreground interruption *signal*, not a crash report.
-- No user/install identifiers, timestamps per player, stack traces, or device
-- metadata. Only aggregate day/game/level-band counters are persisted.
alter table public.unjam_telemetry_daily
  drop constraint if exists unjam_telemetry_daily_event_name_check;
alter table public.unjam_telemetry_daily
  add constraint unjam_telemetry_daily_event_name_check
  check (event_name in (
    'session_start','session_interrupted','level_start','level_complete',
    'level_restart','hint_used','undo_used','level_fail'
  ));

create or replace function public.unjam_increment_telemetry(
  p_event_name text, p_game_id text, p_level_band integer, p_n integer
) returns void language plpgsql security invoker
set search_path = public
as $$
begin
  if p_n not between 1 and 24
    or p_event_name not in (
      'session_start','session_interrupted','level_start','level_complete',
      'level_restart','hint_used','undo_used','level_fail'
    )
    or p_game_id not in ('all','rescue_rush','water_sort','block_puzzle')
    or p_level_band not in (0,1,10,50,100,500,10000,1000,5000)
    or (p_event_name='session_interrupted' and (p_game_id <> 'all' or p_level_band <> 0))
  then
    raise exception 'Invalid aggregate telemetry input';
  end if;

  insert into public.unjam_telemetry_daily(day,event_name,game_id,level_band,event_count)
    values ((now() at time zone 'UTC')::date,p_event_name,p_game_id,p_level_band,p_n)
  on conflict (day,event_name,game_id,level_band)
    do update set event_count = public.unjam_telemetry_daily.event_count + excluded.event_count,
                  updated_at = now();
end;
$$;
revoke all on function public.unjam_increment_telemetry(text,text,integer,integer)
  from public,anon,authenticated;
grant execute on function public.unjam_increment_telemetry(text,text,integer,integer)
  to service_role;

-- Separate from true crash-free session / D1 metrics: do not claim those
-- are measured from this anonymous heuristic.
create or replace view public.unjam_telemetry_daily_funnel
with (security_invoker = true) as
select
  day, game_id,
  coalesce(sum(event_count) filter (where event_name='session_start'),0)::bigint as sessions_started,
  coalesce(sum(event_count) filter (where event_name='session_interrupted'),0)::bigint as unclean_foreground_starts,
  coalesce(sum(event_count) filter (where event_name='level_start'),0)::bigint as level_starts,
  coalesce(sum(event_count) filter (where event_name='level_complete'),0)::bigint as level_completions,
  coalesce(sum(event_count) filter (where event_name='level_restart'),0)::bigint as restarts,
  coalesce(sum(event_count) filter (where event_name='hint_used'),0)::bigint as hints,
  coalesce(sum(event_count) filter (where event_name='undo_used'),0)::bigint as undos,
  coalesce(sum(event_count) filter (where event_name='level_fail'),0)::bigint as failures,
  round(
    100.0 * coalesce(sum(event_count) filter (where event_name='level_complete'),0)::numeric /
      nullif(sum(event_count) filter (where event_name='level_start'),0), 1
  ) as completion_per_start_pct
from public.unjam_telemetry_daily
group by day, game_id;
revoke all on public.unjam_telemetry_daily_funnel from public,anon,authenticated;
grant select on public.unjam_telemetry_daily_funnel to service_role;
