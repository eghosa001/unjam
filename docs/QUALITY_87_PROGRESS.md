# UNJAM — 8.7+ competitive quality verification ledger

**Updated:** 2026-10-13 · **Target:** Every quality category at least **8.7/10**.  
**Policy:** A passing source test is not a verified gameplay score. Do not change an observed rating or claim 8.7+ without the required evidence. **Existing numeric scores below remain the 2026-10-09 provisional code-review baselines**, not post-change device results.

## Categories and next objective evidence

| Category | Old provisional /10 | Code improvement / current check | Required 8.7+ proof |
| --- | ---: | --- | --- |
| Visual design direction | 7.7 | Brand/source art retained; no style reset | Screenshot comparisons on physical phones |
| UI consistency | 7.8 | Shared Figma hierarchy, explicit Collection level badge | Dark/light render matrix, manual clip review |
| UX simplicity | 7.4 | One primary Choose Game action | First-session observation: puzzle understood in 30 s |
| Home | 7.5 | One-touch illustrated levels | Compact/tall/tablet review |
| Game selector | 8.1 | Explicit PLAY versus browse levels | Real touch and Back replay |
| Navigation | 8.3 | Existing scene ownership, release-safe taps | 100 rapid transitions, zero misroutes |
| Typography/readability | 6.8 | Collection titles/levels split to avoid 8–9px squashing | Native-resolution contrast/text matrix |
| Touch response | 7.8 | Existing touch ownership and release actions | Touch latency video/capture |
| Rescue Rush | 8.0 | Two-chapter authored data LRU | Levels 1, 100, 500, 5k, 10k physical play |
| Water Sort | 7.9 | Existing guided pour and selection behavior | Long-session liquid/jitter test |
| Block Puzzle | 7.6 | Two-chapter authored data LRU | Real drag placement and snap accuracy |
| Motion | 7.8 | Existing Gentle Effects/Reduce Motion | 60fps record and slow-motion review |
| Audio/haptics | 7.0 | Existing bounded voices, fades and optional haptics | Physical speaker, headset, Bluetooth listening |
| Tutorial | 7.5 | Existing three-game tutorials | Five-player cold-start test |
| Difficulty/fairness | 7.8 | Solver-checked catalogs; bounded caches | Samples across campaigns and skill levels |
| Content diversity | 7.3 | Curated 20-chapter catalogs retained | Blind early/mid/late board diversity review |
| Daily challenge | 8.0 | Persisted result retry preserved | Date-rollover and network outage device test |
| Leaderboards | 8.1 | Read-only leaderboard, capped verified completion increments, offline FIFO | Real ranked players, historical-data transition & abuse test |
| Rewards/retention | 7.7 | Existing permanent Collection boosts; analytics event counters | Opted-in event counts and real D1/D7 evidence |
| Accessibility | 7.0 | Screen-reader Collection labels and accessible Privacy sheet | Android TalkBack and contrast audit |
| Localization | 7.1 | Existing 9 locale tables; Privacy controls must be translated/reviewed | Native-language review in all supported locales |
| Performance | 8.0 | Rescue/Block parsed chapter caches bounded at 2 each | Midrange Android p50/p95/p99 GPU + memory |
| Stability / CI | 8.4 | Scoped sync/privacy/cache regressions | Clean focused CI, device long session |
| Save / recovery | 8.5 | Durable bounded offline ranked-result queue | Force-stop/relaunch and offline/resume test |
| Monetization | 7.8 | Consent separated from opt-in analytics; no ad behavior change | Live Play Billing, UMP, rewarded callbacks |
| Privacy / consent | Unverified | Default-off anonymous aggregate telemetry, explicit switch, data minimization, RLS | Live consent, policy and Play Data Safety review |
| Analytics / crash insight | 4.5 | Aggregate event pipeline and Supabase Edge Function added | Production opt-in funnel, external crash monitoring, real dashboards |
| Store readiness | 5.5 | Correct stale logo-release validator | Signed AAB accepted by Play Internal Test; active SKUs |

## October 13 second audit: targeted high-risk hardening

- Legacy all-time/weekly progression snapshots lacked per-level receipts. A live read-only audit found 1,482 stored all-time ranking rows but only 54 recorded completion receipts; these are not interchangeable with genuine player counts. The new `ledger_backed` rank filter leaves legacy rows intact for audit, removes their unsupported scores from public standings, and reconstructs credited completions from contiguous receipt chains. A first ranked completion at an advanced local level is worth **one** level, not a retroactively claimed backlog.
- The transaction rejects later gaps and applies receipt-backed counts to both weekly/all-time standings. The backend filters public, personal, reward and friend progression reads. **This is anti-abuse hardening, not cryptographic proof of human gameplay**: a modified client can still forge sequential completions or fabricated daily results. Authenticated attestation/authoritative puzzle verification remains a required release safeguard for high-stakes ranked rewards.
- Small text-fitting paths now stop shrinking standard 12px+ authored labels under 12px and retain full accessibility/tooltip text when an ellipsis is needed. Native-phone rendering and translation length checks remain prerequisites for a verified typography score.
- Release workflow defaults have been advanced to version 1.0.11/code 11, consistent with Android export presets. This does not complete Play Console or signed-build requirements.
- Focused regression checks are `validate_ledger_backed_rankings` and `validate_readable_meta_text`. The backend migration and Edge Function must be deployed together; only their live verification can qualify the feature as operational.

## Implemented security / telemetry changes

- Existing score snapshots **no longer advance public rankings on read**. New completion reports advance ranked totals **at most once per newly recorded level**, irrespective of local save jumps. There is an additional **180 new submissions per hour/game** guard, but this is *not proof against all client forgery*.
- Campaign completion events are queued offline, serialized, de-duplicated, bounded to 240, and retried after a network failure. Events older than the accepted competition-day window do not rewrite past weekly results.
- A separate analytics preference is **OFF by default**. It sends at most 24 whitelisted events per batch, with only event type, game and a broad level band, and stores **only aggregate daily counters**. Opting out clears queued events. It is intentionally **not** a D1/D7 user cohort service and does not include production crash collection.
- Rescue and Block authored 10k-level campaigns now retain **at most two parsed 500-level chapters** per game. Re-reading an evicted chapter trades some disk work for bounded RAM.

## Release blockers — do not substitute CI for player evidence

1. Physical Android visual + performance + interaction capture for all three games; audio and TalkBack.
2. Linguistic audit of new Privacy UI and supported translations, especially Yoruba, Hausa and Igbo.
3. Verify live Supabase competition deployment against old and new clients. Add Play Integrity / authenticated competition proof for high-trust league rewards.
4. Verify telemetry opt-in/off behavior and disclosure on the **signed** release build; avoid treating public publishable keys as anti-spam security.
5. Establish crash-reporting and real retention analysis without violating privacy choices.
6. Play Console activation of the five products, accurate Data Safety/advertising declarations, production ad mode, live license testers and a signed, Play-accepted AAB.

### Check discipline

Run only tests affected by each change. Relevant new focused contracts: `validate_campaign_sync_queue`, `validate_campaign_cache_bounds`, `validate_opt_in_telemetry`. Use the existing visual-scoped runner for Collection/Settings. Do **not** run full campaign enumeration or broad E2E tests by default.

**Current verdict:** Concrete improvements are implemented, but no observed per-category rating is automatically elevated to 8.7. Record new scores only alongside actual reproducible evidence.
