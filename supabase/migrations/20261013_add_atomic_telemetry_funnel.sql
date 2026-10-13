-- Atomic backend aggregation: all counters from a batch commit together.
-- This cannot deduplicate retries after a network timeout; it prevents
-- partially written batches being replayed after one counter fails.
create or replace function public.unjam_increment_telemetry_batch(p_events jsonb)
returns void language plpgsql security invoker set search_path = public
as $$
declare
  row jsonb;
  event_name text;
  game_id text;
  level_band integer;
  amount integer;
begin
  if jsonb_typeof(p_events) is distinct from 'array'
     or jsonb_array_length(p_events) not between 1 and 24 then
    raise exception 'Invalid anonymous analytics batch';
  end if;
  for row in select value from jsonb_array_elements(p_events) loop
    if jsonb_typeof(row) is distinct from 'object'
       or not (row ?& array['event_name','game_id','level_band','n'])
       or coalesce(row->>'level_band','') !~ '^[0-9]{1,5}$'
       or coalesce(row->>'n','') !~ '^[0-9]{1,2}$' then
      raise exception 'Malformed anonymous analytics event';
    end if;
    event_name := row->>'event_name';
    game_id := row->>'game_id';
    level_band := (row->>'level_band')::integer;
    amount := (row->>'n')::integer;
    perform public.unjam_increment_telemetry(event_name, game_id, level_band, amount);
  end loop;
end;
$$;
revoke all on function public.unjam_increment_telemetry_batch(jsonb)
  from public, anon, authenticated;
grant execute on function public.unjam_increment_telemetry_batch(jsonb)
  to service_role;

-- Read-only anonymous daily operational insight. These ratios are event
-- ratios, not user-level win rates, retention, DAU or validated player data.
create or replace view public.unjam_telemetry_daily_funnel
with (security_invoker = true) as
select
  day, game_id,
  coalesce(sum(event_count) filter (where event_name='session_start'), 0)::bigint as sessions_started,
  coalesce(sum(event_count) filter (where event_name='level_start'), 0)::bigint as level_starts,
  coalesce(sum(event_count) filter (where event_name='level_complete'), 0)::bigint as level_completions,
  coalesce(sum(event_count) filter (where event_name='level_restart'), 0)::bigint as restarts,
  coalesce(sum(event_count) filter (where event_name='hint_used'), 0)::bigint as hints,
  coalesce(sum(event_count) filter (where event_name='undo_used'), 0)::bigint as undos,
  coalesce(sum(event_count) filter (where event_name='level_fail'), 0)::bigint as failures,
  round(
    100.0 * coalesce(sum(event_count) filter (where event_name='level_complete'),0)::numeric /
      nullif(sum(event_count) filter (where event_name='level_start'), 0), 1
  ) as completion_per_start_pct
from public.unjam_telemetry_daily
group by day, game_id;
revoke all on public.unjam_telemetry_daily_funnel from public, anon, authenticated;
grant select on public.unjam_telemetry_daily_funnel to service_role;
