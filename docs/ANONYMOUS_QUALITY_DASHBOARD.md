# UNJAM opt-in quality dashboard (Supabase)

Status 13 October 2026: production app opt-in aggregate ingestion is deployed, but the database has **zero real telemetry rows** so far. This is **not** proof of zero players: analytics is OFF by default and previous builds never sent it.

## Data contract and privacy

The only retained records are summed daily event counters by game and broad level band. Players explicitly opt in under **Settings → Privacy → Anonymous Analytics**, independently of advertising consent. No cloud-save ID, player name, device ID, purchase history, IP or arbitrary event properties are sent by the game. Hosting infrastructure can still process ordinary connection metadata. Unchecking this option clears locally queued data.

The telemetry endpoint and database summary are for operational insights, not authenticated players; public app keys are not spam protection and the totals must not be described as independently verified human counts. Session-start events are *session events*, not unique players (DAU). The funnel ratio is completed-level events divided by started-level events in that day. It may be greater than 100% due to continued sessions or level replay; it is **not** a real win rate, retention or D1/D7 cohort metric. A real retention report requires a separate appropriately consented identity/cohort methodology.

Batch ingestion calls one bounded transactional SQL RPC rather than multiple independent writes. New clients add one fresh random receipt per batch (not per device or account). The service stores only that short-lived receipt and the aggregate counters, and replays of the same batch no longer increase totals a second time. Old clients remain supported without receipt de-duplication. Receipts are retained for no more than approximately seven days, with opportunistic pruning; they are not a player/session ID. Revoking analytics consent cancels pending requests and clears unsent batches, although an earlier request already accepted by the server cannot be withdrawn from anonymous daily aggregates.

## Read the dashboard

Inside the project's Supabase SQL Editor, run:

```sql
select day, game_id, sessions_started, level_starts, level_completions,
       restarts, hints, undos, failures, completion_per_start_pct
from public.unjam_telemetry_daily_funnel
where day >= current_date - interval '14 days'
order by day desc, game_id;
```

The `game_id = 'all'` row contains opted-in session-start events (one per app start/first opt-in) and does **not** indicate per-game unique sessions. The game rows provide event totals per game only. Blank rows mean no events were collected, not proof of zero traffic.

For a specific 10,000-level content band (e.g. long-session difficulty):

```sql
select day, game_id, level_band, event_name, event_count
from public.unjam_telemetry_daily
where day >= current_date - interval '7 days'
  and game_id in ('rescue_rush','water_sort','block_puzzle')
order by day desc, game_id, level_band, event_name;
```

Keep all queries within privileged Supabase console access. Both the underlying table and `security_invoker` dashboard view are inaccessible to `anon` and `authenticated` clients.

## Evidence still needed for 8.7+/10

Gather signed/installed Android device measurements for sustained frame pacing, scene memory, input latency, error-free navigation and TalkBack. The current analytics aggregate alone cannot measure production crash-free users, cohorts, D1/D7, or authenticated cheating attempts. Use Google Play / Android diagnostics and an explicitly reviewed crash backend for those missing dimensions. Follow the repo's change-scoped CI rule.


## Optional unexpected-foreground-exit signal (v1.0.11+)

When the player explicitly opts into anonymous game analytics, the app keeps **one local Boolean** recording whether the foreground session was active. Normal Android backgrounding and closing clear it; resuming foreground play restores it. On a subsequent cold start, a Boolean left active contributes **one** anonymous `session_interrupted` aggregate event (game=`all`, level band=`0`). Disabling analytics clears both the unsent events and the local Boolean.

The `unclean_foreground_starts` column in the service-only daily funnel is **not a crash count, crash-free-user rate, Android ANR statistic or user-retention measure**. A force-stop, OS process termination or missed lifecycle callback could trigger the same indicator. There are **no exception traces, player identifiers, installation IDs, individual event logs, IP addresses or purchase details** in this aggregate. A proper platform crash reporting service and real player consented retention insights are still required for full release verification.
