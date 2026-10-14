-- Add a practical first-play and opt-in return funnel without any
-- transmitted player/install/session identifier. Local-only milestone flags
-- count an opted-in device once if it returns EXACTLY on D1 or D7.
-- These are approximate aggregate counters, not authenticated D1/D7 cohorts.
alter table public.unjam_telemetry_daily
  drop constraint if exists unjam_telemetry_daily_event_name_check;
alter table public.unjam_telemetry_daily
  add constraint unjam_telemetry_daily_event_name_check
  check (event_name in (
    'session_start','session_interrupted','level_start','level_complete',
    'level_restart','hint_used','undo_used','level_fail',
    'opt_in_started','return_d1','return_d7',
    'game_selected','daily_opened','garden_opened'
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
      'level_restart','hint_used','undo_used','level_fail',
      'opt_in_started','return_d1','return_d7',
      'game_selected','daily_opened','garden_opened'
    )
    or p_game_id not in ('all','rescue_rush','water_sort','block_puzzle')
    or p_level_band not in (0,1,10,50,100,500,1000,5000,10000)
    or (p_event_name in ('session_start','session_interrupted','opt_in_started',
      'return_d1','return_d7','daily_opened','garden_opened')
      and (p_game_id <> 'all' or p_level_band <> 0))
    or (p_event_name = 'game_selected'
      and (p_game_id = 'all' or p_level_band <> 0))
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

-- Roll up operational events; NULL values mean no valid denominator.
-- The "opt-in return ratio" compares separate days' counters, NOT
-- user-level verified retention. Privileged reporting only.
create or replace view public.unjam_telemetry_daily_activation
with (security_invoker = true) as
select
 day,
 coalesce(sum(event_count) filter(where event_name='opt_in_started'),0)::bigint as new_opt_ins,
 coalesce(sum(event_count) filter(where event_name='return_d1'),0)::bigint as exact_day_1_returns,
 coalesce(sum(event_count) filter(where event_name='return_d7'),0)::bigint as exact_day_7_returns,
 coalesce(sum(event_count) filter(where event_name='game_selected'),0)::bigint as game_selections,
 coalesce(sum(event_count) filter(where event_name='daily_opened'),0)::bigint as daily_screen_opens,
 coalesce(sum(event_count) filter(where event_name='garden_opened'),0)::bigint as garden_screen_opens
from public.unjam_telemetry_daily
group by day;
revoke all on public.unjam_telemetry_daily_activation from public,anon,authenticated;
grant select on public.unjam_telemetry_daily_activation to service_role;
