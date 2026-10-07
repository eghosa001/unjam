create table if not exists public.competition_entries (
  id uuid primary key default gen_random_uuid(),
  player_hash text not null check (char_length(player_hash) = 64),
  display_name varchar(20) not null,
  competition_day date not null,
  week_start date not null,
  game_id text not null check (game_id in ('rescue_rush','water_sort','block_puzzle')),
  score integer not null check (score between 1 and 1200),
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (player_hash, competition_day, game_id)
);

create table if not exists public.competition_totals (
  period_type text not null check (period_type in ('daily','weekly')),
  period_key date not null,
  player_hash text not null check (char_length(player_hash) = 64),
  display_name varchar(20) not null,
  score integer not null default 0 check (score >= 0),
  games_count integer not null default 0 check (games_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (period_type, period_key, player_hash)
);

create table if not exists public.competition_reward_claims (
  player_hash text not null check (char_length(player_hash) = 64),
  period_key date not null,
  rank integer not null check (rank > 0),
  score integer not null check (score >= 0),
  coins integer not null check (coins >= 0),
  crowns integer not null check (crowns >= 0),
  claimed_at timestamptz not null default now(),
  primary key (player_hash, period_key)
);

create index if not exists competition_entries_day_game_score_idx on public.competition_entries (competition_day, game_id, score desc);
create index if not exists competition_totals_rank_idx on public.competition_totals (period_type, period_key, score desc, updated_at asc);

alter table public.competition_entries enable row level security;
alter table public.competition_totals enable row level security;
alter table public.competition_reward_claims enable row level security;

revoke all on table public.competition_entries from anon, authenticated;
revoke all on table public.competition_totals from anon, authenticated;
revoke all on table public.competition_reward_claims from anon, authenticated;

grant select, insert, update, delete on table public.competition_entries to service_role;
grant select, insert, update, delete on table public.competition_totals to service_role;
grant select, insert, update, delete on table public.competition_reward_claims to service_role;
