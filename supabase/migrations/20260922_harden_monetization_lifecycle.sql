alter table public.play_purchase_claims
  add column if not exists voided_at timestamptz,
  add column if not exists voided_reason integer,
  add column if not exists voided_source integer,
  add column if not exists voided_quantity integer;

create table if not exists public.play_purchase_installations (
  token_hash text not null references public.play_purchase_claims(token_hash) on delete cascade,
  install_id text not null check (char_length(install_id) between 16 and 128),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (token_hash, install_id)
);

create table if not exists public.play_request_limits (
  key_hash text primary key check (key_hash ~ '^[0-9a-f]{64}$'),
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0)
);

create table if not exists public.play_voided_sync_state (
  singleton boolean primary key default true check (singleton),
  last_started_at timestamptz,
  last_success_at timestamptz
);

insert into public.play_voided_sync_state(singleton)
values (true)
on conflict (singleton) do nothing;

alter table public.play_purchase_installations enable row level security;
alter table public.play_request_limits enable row level security;
alter table public.play_voided_sync_state enable row level security;

revoke all on table public.play_purchase_installations from public, anon, authenticated;
revoke all on table public.play_request_limits from public, anon, authenticated;
revoke all on table public.play_voided_sync_state from public, anon, authenticated;

grant select, insert, update, delete on table public.play_purchase_installations to service_role;
grant select, insert, update, delete on table public.play_request_limits to service_role;
grant select, insert, update on table public.play_voided_sync_state to service_role;

drop function if exists public.issue_play_purchase_claim(text, text, text, text, text, text);

create or replace function public.issue_play_purchase_claim(
  p_token_hash text,
  p_package_name text,
  p_product_id text,
  p_claim_id text,
  p_order_id text default null,
  p_purchase_completion_time text default null,
  p_install_id text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer := 0;
  existing public.play_purchase_claims%rowtype;
  can_grant boolean := false;
begin
  if p_token_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid token fingerprint'; end if;
  if char_length(p_claim_id) < 8 or char_length(p_claim_id) > 128 then raise exception 'invalid claim id'; end if;
  if p_install_id is null or char_length(p_install_id) < 16 or char_length(p_install_id) > 128 then
    raise exception 'invalid install id';
  end if;

  insert into public.play_purchase_claims (
    token_hash, package_name, product_id, order_id, purchase_completion_time, claim_id, state
  ) values (
    p_token_hash, p_package_name, p_product_id, nullif(p_order_id, ''),
    nullif(p_purchase_completion_time, ''), p_claim_id, 'issued'
  ) on conflict (token_hash) do nothing;

  get diagnostics inserted_count = row_count;

  select * into existing
  from public.play_purchase_claims
  where token_hash = p_token_hash
  for update;

  if existing.package_name <> p_package_name or existing.product_id <> p_product_id then
    return jsonb_build_object('grant', false, 'state', existing.state, 'conflict', true);
  end if;

  insert into public.play_purchase_installations(token_hash, install_id)
  values (p_token_hash, p_install_id)
  on conflict (token_hash, install_id)
  do update set last_seen_at = now();

  update public.play_purchase_claims
  set last_seen_at = now()
  where token_hash = p_token_hash;

  can_grant := inserted_count = 1 or (existing.state = 'issued' and existing.claim_id = p_claim_id);

  return jsonb_build_object(
    'grant', can_grant,
    'state', existing.state,
    'conflict', false
  );
end;
$$;

create or replace function public.mark_play_purchase_voided(
  p_token_hash text,
  p_voided_time timestamptz,
  p_voided_reason integer,
  p_voided_source integer,
  p_voided_quantity integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.play_purchase_claims
  set voided_at = coalesce(p_voided_time, now()),
      voided_reason = p_voided_reason,
      voided_source = p_voided_source,
      voided_quantity = greatest(1, coalesce(p_voided_quantity, 1)),
      last_seen_at = now()
  where token_hash = p_token_hash;
  return found;
end;
$$;

create or replace function public.get_play_install_revocations(
  p_install_id text
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'token_hash', c.token_hash,
        'product_id', c.product_id,
        'voided_at', c.voided_at,
        'voided_reason', c.voided_reason,
        'voided_source', c.voided_source,
        'voided_quantity', coalesce(c.voided_quantity, 1)
      )
      order by c.voided_at asc
    ),
    '[]'::jsonb
  )
  from public.play_purchase_claims c
  join public.play_purchase_installations i on i.token_hash = c.token_hash
  where i.install_id = p_install_id
    and c.voided_at is not null;
$$;

create or replace function public.consume_play_request_slot(
  p_key_hash text,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.play_request_limits%rowtype;
begin
  if p_key_hash !~ '^[0-9a-f]{64}$' then return false; end if;
  if p_limit < 1 or p_limit > 1000 then return false; end if;
  if p_window_seconds < 1 or p_window_seconds > 86400 then return false; end if;

  delete from public.play_request_limits
  where window_started_at < now() - interval '2 days';

  insert into public.play_request_limits(key_hash, window_started_at, request_count)
  values (p_key_hash, now(), 0)
  on conflict (key_hash) do nothing;

  select * into current_row
  from public.play_request_limits
  where key_hash = p_key_hash
  for update;

  if current_row.window_started_at <= now() - make_interval(secs => p_window_seconds) then
    update public.play_request_limits
    set window_started_at = now(), request_count = 1
    where key_hash = p_key_hash;
    return true;
  end if;

  if current_row.request_count >= p_limit then
    return false;
  end if;

  update public.play_request_limits
  set request_count = request_count + 1
  where key_hash = p_key_hash;
  return true;
end;
$$;

create or replace function public.claim_play_voided_sync(
  p_min_interval_seconds integer
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.play_voided_sync_state%rowtype;
  start_from timestamptz;
begin
  if p_min_interval_seconds < 60 or p_min_interval_seconds > 86400 then
    raise exception 'invalid sync interval';
  end if;

  insert into public.play_voided_sync_state(singleton)
  values (true)
  on conflict (singleton) do nothing;

  select * into current_row
  from public.play_voided_sync_state
  where singleton = true
  for update;

  if current_row.last_started_at is not null
     and current_row.last_started_at > now() - make_interval(secs => p_min_interval_seconds) then
    return jsonb_build_object('claimed', false, 'start_time_ms', 0);
  end if;

  start_from := coalesce(current_row.last_success_at - interval '5 minutes', now() - interval '29 days');

  update public.play_voided_sync_state
  set last_started_at = now()
  where singleton = true;

  return jsonb_build_object(
    'claimed', true,
    'start_time_ms', floor(extract(epoch from start_from) * 1000)::bigint
  );
end;
$$;

create or replace function public.complete_play_voided_sync()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.play_voided_sync_state
  set last_success_at = now()
  where singleton = true;
end;
$$;

revoke all on function public.issue_play_purchase_claim(text, text, text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.mark_play_purchase_voided(text, timestamptz, integer, integer, integer) from public, anon, authenticated;
revoke all on function public.get_play_install_revocations(text) from public, anon, authenticated;
revoke all on function public.consume_play_request_slot(text, integer, integer) from public, anon, authenticated;
revoke all on function public.claim_play_voided_sync(integer) from public, anon, authenticated;
revoke all on function public.complete_play_voided_sync() from public, anon, authenticated;

grant execute on function public.issue_play_purchase_claim(text, text, text, text, text, text, text) to service_role;
grant execute on function public.mark_play_purchase_voided(text, timestamptz, integer, integer, integer) to service_role;
grant execute on function public.get_play_install_revocations(text) to service_role;
grant execute on function public.consume_play_request_slot(text, integer, integer) to service_role;
grant execute on function public.claim_play_voided_sync(integer) to service_role;
grant execute on function public.complete_play_voided_sync() to service_role;
