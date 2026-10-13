# UNJAM offline cloud conflict rules

When a phone plays while offline and another device updates the same recovery-code account, the Supabase cloud revision can advance. Previously, a `409` or higher-revision initial pull replaced this device's entire progress without reconciling unsynced levels.

The updated conflict handler merges **monotonic puzzle progress only**: level-star maps (maximum stars per level), highest unlocked level, owned milestone/achievement badges, daily-completed dates, previously paid-weekly claim markers and non-overlapping saved Water/Block puzzle checkpoints. It then retries the combined progression with the new cloud revision. Explicit recovery-code restoration still **replaces** gameplay progress by design, subject to the existing confirmation UI.

**Important financial limitation:** currencies, purchases, daily streak counters and independently edited active runs cannot be safely combined by selecting maximum or adding two amounts. The newer cloud wallet/other fields remain authoritative during a conflict. This may omit legitimate coins earned locally while offline, so conflict-safe wallet reconciliation remains a known limitation until there is a transactional server currency ledger or an explicit, user-confirmed conflict resolution UI. Do not claim currency-safe multi-device syncing from the puzzle-progress merge.

Do not sync Play ownership, purchase tokens, pending reward receipt secrets, analytics opt-in or per-device UMP consent through cloud backups. The backup's 64-character recovery code is a bearer secret; keep it private.

Targeted tests: `validate_complete_cloud_progression`, `validate_cloud_conflict_merge`, `validate_cloud_schema_alignment`. Do not run unrelated campaign suites.
