create table if not exists public.play_purchase_claims (
  token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
  package_name text not null,
  product_id text not null,
  order_id text,
  purchase_completion_time text,
  claim_id text not null check (char_length(claim_id) between 8 and 128),
  state text not null default 'issued' check (state in ('issued', 'committed')),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  committed_at timestamptz
);

alter table public.play_purchase_claims enable row level security;
revoke all on table public.play_purchase_claims from public, anon, authenticated;
grant select, insert, update on table public.play_purchase_claims to service_role;

create or replace function public.issue_play_purchase_claim(
  p_token_hash text, p_package_name text, p_product_id text, p_claim_id text,
  p_order_id text default null, p_purchase_completion_time text default null
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  inserted_count integer := 0;
  existing public.play_purchase_claims%rowtype;
begin
  if p_token_hash !~ '^[0-9a-f]{64}$' then raise exception 'invalid token fingerprint'; end if;
  if char_length(p_claim_id) < 8 or char_length(p_claim_id) > 128 then raise exception 'invalid claim id'; end if;

  insert into public.play_purchase_claims (
    token_hash, package_name, product_id, order_id, purchase_completion_time, claim_id, state
  ) values (
    p_token_hash, p_package_name, p_product_id, nullif(p_order_id, ''),
    nullif(p_purchase_completion_time, ''), p_claim_id, 'issued'
  ) on conflict (token_hash) do nothing;

  get diagnostics inserted_count = row_count;
  if inserted_count = 1 then
    return jsonb_build_object('grant', true, 'state', 'issued', 'conflict', false);
  end if;

  select * into existing from public.play_purchase_claims where token_hash = p_token_hash for update;
  if existing.package_name <> p_package_name or existing.product_id <> p_product_id then
    return jsonb_build_object('grant', false, 'state', existing.state, 'conflict', true);
  end if;

  update public.play_purchase_claims set last_seen_at = now() where token_hash = p_token_hash;
  return jsonb_build_object(
    'grant', existing.state = 'issued' and existing.claim_id = p_claim_id,
    'state', existing.state, 'conflict', false
  );
end;
$$;

create or replace function public.commit_play_purchase_claim(
  p_token_hash text, p_package_name text, p_product_id text, p_claim_id text
) returns boolean
language plpgsql security definer set search_path = public
as $$
declare current_state text;
begin
  select state into current_state
  from public.play_purchase_claims
  where token_hash = p_token_hash and package_name = p_package_name
    and product_id = p_product_id and claim_id = p_claim_id
  for update;

  if current_state is null then return false; end if;
  if current_state = 'committed' then
    update public.play_purchase_claims set last_seen_at = now() where token_hash = p_token_hash;
    return true;
  end if;
  if current_state <> 'issued' then return false; end if;

  update public.play_purchase_claims
  set state = 'committed', committed_at = now(), last_seen_at = now()
  where token_hash = p_token_hash;
  return true;
end;
$$;

revoke all on function public.issue_play_purchase_claim(text, text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.commit_play_purchase_claim(text, text, text, text) from public, anon, authenticated;
grant execute on function public.issue_play_purchase_claim(text, text, text, text, text, text) to service_role;
grant execute on function public.commit_play_purchase_claim(text, text, text, text) to service_role;
