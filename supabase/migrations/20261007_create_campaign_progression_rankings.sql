create table if not exists public.progression_level_events (
  player_hash text not null check (char_length(player_hash) = 64),
  game_id text not null check (game_id in ('rescue_rush','water_sort','block_puzzle')),
  level_number integer not null check (level_number between 1 and 10000),
  best_stars integer not null check (best_stars between 1 and 3),
  first_clear_week date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (player_hash, game_id, level_number)
);

create table if not exists public.progression_rankings (
  scope_type text not null check (scope_type in ('all_time','weekly')),
  period_key date not null,
  game_id text not null check (game_id in ('rescue_rush','water_sort','block_puzzle')),
  player_hash text not null check (char_length(player_hash) = 64),
  display_name varchar(20) not null,
  levels_completed integer not null default 0 check (levels_completed between 0 and 10000),
  highest_level integer not null default 0 check (highest_level between 0 and 10000),
  stars integer not null default 0 check (stars between 0 and 30000),
  rank_score bigint not null default 0 check (rank_score >= 0),
  updated_at timestamptz not null default now(),
  primary key (scope_type, period_key, game_id, player_hash)
);

create table if not exists public.progression_reward_claims (
  player_hash text not null check (char_length(player_hash) = 64),
  period_key date not null,
  game_id text not null check (game_id in ('rescue_rush','water_sort','block_puzzle')),
  rank integer not null check (rank > 0),
  levels_completed integer not null check (levels_completed >= 0),
  coins integer not null check (coins >= 0),
  crowns integer not null check (crowns >= 0),
  claimed_at timestamptz not null default now(),
  primary key (player_hash, period_key, game_id)
);

create index if not exists progression_events_week_game_idx
  on public.progression_level_events (first_clear_week, game_id, player_hash);

create index if not exists progression_rankings_score_idx
  on public.progression_rankings (scope_type, period_key, game_id, rank_score desc, updated_at asc);

alter table public.progression_level_events enable row level security;
alter table public.progression_rankings enable row level security;
alter table public.progression_reward_claims enable row level security;

revoke all on table public.progression_level_events from anon, authenticated;
revoke all on table public.progression_rankings from anon, authenticated;
revoke all on table public.progression_reward_claims from anon, authenticated;

grant select, insert, update, delete on table public.progression_level_events to service_role;
grant select, insert, update, delete on table public.progression_rankings to service_role;
grant select, insert, update, delete on table public.progression_reward_claims to service_role;
