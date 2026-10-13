-- Idempotent anonymous telemetry receipt. A fresh random token is generated
-- for each 24-event batch; it is not an installation or player identifier.
-- Keep short-lived receipts only to suppress duplicate HTTP retries.
create table if not exists public.unjam_telemetry_batch_receipts (
  batch_id text primary key check (batch_id ~ '^[0-9a-f]{32}$'),
  received_at timestamptz not null default now()
);
create index if not exists unjam_telemetry_batch_receipts_received_idx
  on public.unjam_telemetry_batch_receipts(received_at);
alter table public.unjam_telemetry_batch_receipts enable row level security;
revoke all on public.unjam_telemetry_batch_receipts from public, anon, authenticated;
grant select, insert, delete on public.unjam_telemetry_batch_receipts to service_role;

-- Preserve the old one-parameter batch function for already-shipped builds.
-- The new RPC serializes each receipt with its aggregate counter increments
-- inside one transaction: a replay is a no-op, even after a lost HTTP reply.
create or replace function public.unjam_increment_telemetry_batch_v2(
  p_batch_id text, p_events jsonb
) returns boolean
language plpgsql security invoker set search_path = public
as $$
declare
  v_inserted integer := 0;
begin
  if p_batch_id is null or p_batch_id !~ '^[0-9a-f]{32}$'
     or jsonb_typeof(p_events) is distinct from 'array'
     or jsonb_array_length(p_events) not between 1 and 24 then
    raise exception 'Invalid anonymous telemetry receipt or batch';
  end if;

  insert into public.unjam_telemetry_batch_receipts(batch_id)
  values (p_batch_id) on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false; -- duplicate receipt; no counters are modified
  end if;

  -- The existing function validates all events and writes a single transaction.
  -- Any exception rolls back the receipt and every counter in this call.
  perform public.unjam_increment_telemetry_batch(p_events);
  -- Bounded retention, without a scheduled background job. Receipts older
  -- than seven days can be removed by occasional service-role requests.
  if random() < 0.02 then
    delete from public.unjam_telemetry_batch_receipts
    where received_at < now() - interval '7 days';
  end if;
  return true;
end;
$$;
revoke all on function public.unjam_increment_telemetry_batch_v2(text,jsonb)
  from public, anon, authenticated;
grant execute on function public.unjam_increment_telemetry_batch_v2(text,jsonb)
  to service_role;
