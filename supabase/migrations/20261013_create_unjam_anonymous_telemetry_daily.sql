-- Optional opt-in aggregate analytics. No player IDs, device IDs, IPs,
-- or event payloads are stored. Tables are inaccessible to mobile clients.
create table if not exists public.unjam_telemetry_daily (
  day date not null default (now() at time zone 'UTC')::date,
  event_name text not null check (event_name in
    ('session_start','level_start','level_complete','level_restart','hint_used','undo_used','level_fail')),
  game_id text not null check (game_id in ('all','rescue_rush','water_sort','block_puzzle')),
  level_band integer not null check (level_band in (0,1,10,50,100,500,1000,5000,10000)),
  event_count bigint not null default 0 check (event_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (day, event_name, game_id, level_band)
);
alter table public.unjam_telemetry_daily enable row level security;
revoke all on table public.unjam_telemetry_daily from public, anon, authenticated;
grant select, insert, update on public.unjam_telemetry_daily to service_role;

-- SECURITY INVOKER keeps privilege checks bound to the service-role caller.
create or replace function public.unjam_increment_telemetry(
  p_event_name text, p_game_id text, p_level_band integer, p_n integer
) returns void language plpgsql security invoker
set search_path = public
as $$
begin
  if p_n not between 1 and 24
    or p_event_name not in ('session_start','level_start','level_complete','level_restart','hint_used','undo_used','level_fail')
    or p_game_id not in ('all','rescue_rush','water_sort','block_puzzle')
    or p_level_band not in (0,1,10,50,100,500,1000,5000,10000)
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
revoke all on function public.unjam_increment_telemetry(text,text,integer,integer) from public, anon, authenticated;
grant execute on function public.unjam_increment_telemetry(text,text,integer,integer) to service_role;
