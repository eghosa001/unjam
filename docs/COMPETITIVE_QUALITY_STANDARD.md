# UNJAM — Competitive Premium Quality Standard (9+/10)

**Owner-approved benchmark, established 2026-10-09.** Applies to every release and every meaningful new feature. This is the *product comparison standard*; [QUALITY_GATE.md](../QUALITY_GATE.md) remains the release gate and [RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md) remains the account/Play readiness checklist.

## Goal and non-negotiable rules

UNJAM must feel comparable to excellent shipping mobile puzzle games, not merely contain a large number of levels or pass scripts. The reference set is **Unblock Me / leading arrow-jam games** (Rescue Rush), **SortPuz / leading Water Sort apps** (Water Sort), **Block Blast!** (Block Puzzle), and the strongest cohesive, accessible casual puzzle collections (launcher and shared experience). Competitors are qualitative yardsticks, not permission to copy proprietary artwork, UI layouts, sounds or level data. Preserve the approved UNJAM brand, its three games, the Figma-authored identity, and simple glossy-flat visual language.

**Every category must individually earn at least 9.0/10 before a 9+ product claim.** Never inflate a score, average an excellent backend over a poor gameplay experience, confuse completed source code with shipped behaviour, or invent retention/performance figures. Maintain the four evidence labels: **CODE**, **CI**, **DEVICE**, **LIVE**. "Not tested" is **UNVERIFIED**, never 9/10. For release-blocking requirements, an **UNVERIFIED** or **FAIL** prevents an overall 9+ claim.

### Score anchors (applied identically to every row)

| Score | Meaning |
|---|---|
| 0–5.9 | Missing, broken, unusable or no meaningful proof of the experience |
| 6.0–6.9 | Works inconsistently; obvious rough edges; below good casual-game quality |
| 7.0–7.9 | Functional/good but lacks at least one major premium characteristic |
| 8.0–8.9 | Strong, polished baseline; remaining noticeable defects or missing evidence |
| 9.0–9.4 | Excellent compared with the reference set, verified on real devices and all category gates passed |
| 9.5–10 | Exceptional consistency and delight, independently validated; rarely awarded |

Scores are based on *observed outcomes*, not lines of code, number of effects, or green workflow badges. Do not turn UNVERIFIED into a numerical 9 by assumption. A baseline score from code review is an **estimate**, not verified.

## Category-by-category comparison contract

The following provisional baseline scores reproduce the 2026-10-09 code-review assessment. They **do not** certify Android visuals, latency, telemetry, or commercial release. For each row, meet its acceptance criteria and attach the indicated evidence before raising its status to VERIFIED >=9.

| Category | Provisional baseline /10 | Competitive 9+ acceptance | Required evidence |
|---|---:|---|---|
| Visual design direction | 7.7 | Distinctive UNJAM identity on every surface; original art; depth subordinate to the puzzle; no generic template feel | DEVICE screenshots, side-by-side competitive review |
| UI consistency | 7.8 | Shared typographic scale, colour semantics, spacing, button states, icons, result treatment; no screen-specific visual regressions | DEVICE visual matrix in light/dark |
| UX simplicity | 7.4 | A new player understands each puzzle in <=30 seconds; no unexplained mode, currency, or booster blocks first play | DEVICE moderated first-session playtest |
| Home | 7.5 | One dominant Choose Game CTA; attractive functional 3-game previews; ranking and Daily are readable without scrolling/overlap | DEVICE compact/tall/tablet |
| Game selector | 8.1 | Games are unmistakable; game card provides discoverable levels; explicit PLAY resumes; every action works on release | CI navigation contract + DEVICE touch |
| Navigation | 8.3 | Zero accidental launches or double-tap routes; consistent Android Back; loading/cancel/retry recovery; correct surface in one interaction | CI regression + DEVICE rapid navigation |
| Typography/readability | 6.8 | Main actions ~16+ authored px where layout allows; secondary content preferably >=14 authored px; no important text clipped/ellipsized, no tiny scaled-up text, contrast >=4.5:1 for normal text | DEVICE 100%-scale screenshots and contrast audit |
| Touch and gesture response | 7.8 | >=44×44 authored hit zones on core controls; accurate drag/pour/tap; feedback begins on first interaction; no touch-through | CI touch test + DEVICE finger/stylus |
| Rescue Rush gameplay | 8.0 | Piece arrows and escape lanes readable; movement legal and deterministic; blocked attempts explained; late-level complexity remains fair | CI solver + DEVICE levels 1, 100, 500, 5000, 10000 |
| Water Sort gameplay | 7.9 | Bottles and colour layers legible; valid pours feel fluid and cancellable safely; colour-blind-friendly identification; undo/retry understandable | CI pour/solver + DEVICE play |
| Block Puzzle gameplay | 7.6 | Drag preview follows finger, snap is precise; basic mechanics precede modes/boosters; clear goals; no artificial dead-end during proven campaign play | CI block interactions + DEVICE play |
| Motion/animation | 7.8 | 1:1 input-to-response feedback; short functional transitions; visual spectacle only for meaningful wins/combos; reduced motion respected | DEVICE 60fps recording and reduced-motion review |
| Audio/haptics | 7.0 | Distinct satisfying cues; no distortion, overlap, crackling, muted cue leakage or abrupt loudness; vibration optional | DEVICE speakers, wired/Bluetooth, headphones |
| Tutorials/onboarding | 7.5 | First-time instruction teaches by interacting, can skip/revisit, does not obscure play; no misleading explanation of game rules | DEVICE new-save study |
| Difficulty/fairness | 7.8 | Proven achievable setups; early levels teach, late levels challenge without repetition traps; no pay-for-win wall | CI solver/samples + DEVICE player feedback |
| Content diversity | 7.3 | Opening, middle and late campaigns display genuinely varied objectives, shapes and board rhythms, not merely random visual permutations | Curated DEVICE blind sample at milestone levels |
| Daily challenges | 8.0 | Deterministic date-local journeys; clear availability, scores, completion, reset boundaries, and genuine replay value | CI progression + DEVICE day rollover |
| Leaderboards | 8.1 | Full-screen, legible Today/Weekly/All-time views; accurate timestamps and player/game rankings; honest loading/empty/error states | CI navigation + LIVE ranked players |
| Rewards/retention | 7.7 | Goals, collection, achievements and season rewards provide clear non-coercive value without cluttering first play | DEVICE + LIVE D1/D7 metrics |
| Accessibility | 7.0 | Labelled all major controls, >=44px targets, >=4.5:1 text contrast, noncolour-only states, TalkBack and reduced motion validated | DEVICE Android TalkBack and accessibility audit |
| Localization | 7.1 | Key journeys professionally readable in all supported locales; no untranslated fragments, broken layouts, clipped controls, or lost preferred locale | CI locale + DEVICE screenshots for all languages |
| Performance | 8.0 | Reference target: sustained 60fps on supported midrange devices, p95 frame <16.7ms where hardware permits; no visible interaction freeze; no memory climb after 100 navigations | DEVICE p50/p95/p99, Android GPU + memory trace |
| Stability/CI | 8.4 | Relevant change-scoped regression checks pass; zero reproducible crash, dead navigation or stuck scene on tested devices; no test suite gaming | CI focused logs + DEVICE long session |
| Save/recovery | 8.5 | Resumes exact level reliably offline and after kill/relaunch, repairs partial writes, preserves purchases/preferences, handles cloud conflicts | CI recovery + DEVICE crash/reinstall |
| Monetization design | 7.8 | Ads only at natural breaks, rewards only after callbacks, no deceptive buttons; real catalog pricing; cancel/retry/refund work without loss | CI contracts + LIVE licence testing |
| Privacy/consent | Unverified | Correct consent on *each* device/session, truthful Data Safety, no tracking before permission, account-bound purchase checks | CI + LIVE Play/UMP |
| Analytics/crash insight | 4.5 | Production opt-in/consent-aware first-play funnel, level attempts/fail reasons, D1/D7, FPS/crash signals; not fabricated from local QA counters | LIVE dashboard and crash-free session measurement |
| Store release readiness | 5.5 | Correct signed AAB, Play Internal Testing acceptance, live billing product catalog, UMP/AdMob, correct store claims/assets | LIVE Play Console evidence |

### Per-game premium quality details

**Rescue Rush — Unblock Me / arrow puzzle reference:** A player instantly knows each piece's arrow, can trace escape lanes even on crowded boards, receives precise feedback after invalid taps, learns gates and chain reactions before they dominate the board, and never mistakes decorative motion for state changes.

**Water Sort — SortPuz / Water Sort reference:** The currently selected bottle is obvious without relying solely on colour. Layers can be distinguished, liquid flow begins promptly and finishes without jitter, correct pour targets are obvious, and a stuck state provides recovery without charging a penalty for misunderstanding.

**Block Puzzle — Block Blast! reference:** The player starts by placing blocks and clearing lines, not parsing a menu of premium modes or four boosters. During drag, placement prediction aligns with the actual release location. Objectives never cover the board. Campaign, Endless, Zen and Extreme are disclosed only when useful.

**Whole-app premium reference:** The Home does not duplicate the Games screen. A Home illustration opens *that game's levels*. Choose Game opens the selector. From selector, the main card opens *levels*; the explicit PLAY control deliberately launches/resumes. Daily/leaderboard/share/Shop never hijack basic play. Completed purchases, ad consent, accessibility and save recovery are essential quality, not optional polish.

## 9+ acceptance runbook

1. **Maintain a single canonical scorecard.** Every change records category, baseline, objective defect, before/after evidence, score and verification status. Treat existing numerical scores as provisional. Do not claim 9+ based on a PR title.
2. **Respect the fast-production rule.** Small navigation/copy edits use their *single focused* contract. Broader visual, device, performance, purchase or release checks run only when directly required by the change or when preparing an actual release. Never restore blanket CI.
3. **First-session test (no prior saved data):** On compact phone, open app, choose each puzzle, understand the aim, do five moves, access undo/hint, complete/retry, go home. Track confusion, taps, time and crashes. Repeat with accessibility enabled.
4. **Device matrix for final release:** Compact Android phone, mainstream 60Hz Android phone, high-refresh Android phone, and tablet; light/dark and supported languages; levels 1/100/500/5000/10000 (sample where level progression allows) plus campaign/daily/endless.
5. **Interaction proof:** In at least 100 rapid screen changes, observe no erroneous destination, double-trigger, clipped button, frozen input or permanently growing scene tree. Every visible control performs its stated action on the first intentional interaction.
6. **Readability proof:** View screens at native display scale; avoid reducing essential wording below legibility to force fixed Figma bounds. Critical actionable information must not be clipped or ellipsized.
7. **Audio/visual proof:** Compare a real capture of each game side-by-side with genre references on puzzle comprehension, moment-to-moment feedback, animation rhythm and texture discipline. Verify reduced-motion and muted options.
8. **Reliability proof:** Save/restore, calendar rollover, offline mode, phone background/foreground, interruption during completion, and ads/purchases each have documented expected outcomes.
9. **Evidence status:** Mark categories VERIFIED only with directly relevant evidence and reproducible checks. A passing script is evidence for logic, not for delight, 60fps, TalkBack, hearing comfort, D1/D7 retention or Play acceptance.
10. **Ship gate:** No production 9+ claim while any mandatory area is FAIL or UNVERIFIED; unresolved Play/Billing/consent/analytics requirements are displayed explicitly.

## Progress record — initial change batch (2026-10-09)

- Baseline: the category scores above are **provisional code-review estimates**.
- Completed targeted improvements are recorded in the PR describing this standard, not reflected in the baseline scores until tests and real-device review are complete.
- Mandatory remaining evidence: physical-device screenshots and interaction capture; speaker/headset sound; accurate production retention/crashes; real Play purchasing, ads and UMP; signed Play-accepted build.
- Do not rewrite this section to falsely declare an all-green 9+ completion. Improve the product, gather the evidence, then update each category individually.
