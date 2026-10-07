create table if not exists public.social_profiles (
  player_hash text primary key check (char_length(player_hash) = 64),
  friend_code varchar(8) not null unique check (friend_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$'),
  display_name varchar(20) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.social_friends (
  player_hash_a text not null references public.social_profiles(player_hash) on delete cascade,
  player_hash_b text not null references public.social_profiles(player_hash) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (player_hash_a, player_hash_b),
  check (player_hash_a < player_hash_b)
);

create index if not exists social_friends_b_idx on public.social_friends (player_hash_b, player_hash_a);

alter table public.social_profiles enable row level security;
alter table public.social_friends enable row level security;

revoke all on table public.social_profiles from anon, authenticated;
revoke all on table public.social_friends from anon, authenticated;

grant select, insert, update, delete on table public.social_profiles to service_role;
grant select, insert, update, delete on table public.social_friends to service_role;
