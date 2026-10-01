create table if not exists public.player_cloud_saves (
  save_key_hash text primary key,
  revision bigint not null default 0 check (revision >= 0),
  payload jsonb not null default '{}'::jsonb,
  payload_sha256 text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.player_cloud_saves enable row level security;
revoke all on table public.player_cloud_saves from anon, authenticated;

create index if not exists player_cloud_saves_updated_at_idx
  on public.player_cloud_saves (updated_at desc);
