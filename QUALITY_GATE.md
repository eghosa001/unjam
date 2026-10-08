# UNJAM: release quality bar (9+/10 in every category)

An automated PASS is not itself a 9+/10 visual or product rating. Each dimension must
be verified with its own evidence. Do not claim 9+ without a device/screenshot review.

## Mandatory release gates

| Area | Acceptance criterion | Evidence |
| --- | --- | --- |
| Home / selector / nav | Every visible button opens the intended destination on first press; never resumes a game from CHOOSE GAME | Navigation runtime test and device replay |
| All secondary screens | No clipped text, overlapping controls or unreachable content in light/dark mode | Viewport-fit and screenshots on compact phone, tall phone, tablet |
| Text readability | Minimum practical secondary text ~14 physical px at 1x reference and ideally >=16 for actions; never shrink below legibility just to fit | Screenshot inspection at 100% display scale |
| Late-game objective readability | Rescue HUD keeps lives/moves distinct from combo; Water tubes expose order and selection without relying on colour; Block shows current goal progress; mission reward labels do not shrink below 12px reference | Active gameplay accessibility runtime test and late-game screenshot review |
| Rescue Rush | Exits, grid, hit zones, win timing, dense 10K boards legible | Campaign + Rescue runtime and Android playtest |
| Water Sort | Visible bottle mouth, no crooked pours, valid animated transfers and no stuck idle redraw | Water motion/solver tests + Android playtest |
| Block Puzzle | Preview follows finger, precisely snaps, 8x8 board and objectives remain readable | Block runtime/solvers + touch-device replay |
| Audio and haptics | No crackle, clipping, unexpected volume spikes or feedback during muted/reduced-motion modes | Real Android speaker/headphone test |
| Performance | Sample actual frame intervals on compact/mid/high-end Android phones, inspect p50/p95/p99 and >16.7ms/>33.3ms rates; profile rendering and memory separately; no sustained node growth after 100 navigations | Numeric debug QA frame snapshot, on-device profiler and long-session capture |
| Monetization | Play catalog live in enabled regions; all purchases, pending/cancel/restore/refund/repeat consumables; rewarded callbacks award once | License tester and Play console evidence |
| Privacy | Require a current-device UMP/provider result before production ads, reject cached and cloud-imported consent; test required/obtained/not-required flows and listing/Data Safety compliance | Device-local consent CI contract, on-device UMP replay and listing audit |
| Save and progression | No destructive remove-before-rename; recover valid main, pending or backup after crashes; preserve purchases and selected locale through resets; verify resume, offline saves and 10,000-level targets | Atomic save/failed-write and reset-language CI, progression tests, device recovery checklist |
| Localization | All supported language locales have readable controls and translated key journeys; no accidental substring replacements; switching a saved language restores English correctly and keeps assistive labels in sync | Localization integrity + Settings language-switch runtime contract + locale screenshots |
| Playmate Sidekick | For matching campaign checkpoints, validate Water transfers and Block tray fit before declaring no moves; show retry/undo recovery rather than irrelevant strategy, never guess a winning move | Sidekick progress and no-move checkpoint contracts, locale integrity, viewport and human gameplay review |
| Accessibility | Contrast >=4.5:1 for normal text, usable touch targets, keyboard/screen-reader checks where supported, reduced motion | Accessibility audit |
| Analytics / stability | Opt-in/privacy-compliant production telemetry and crash monitoring validated; no developer-only log counts used as retention proof | Dashboard and crash-free-session evidence |
| Shipping | Signed, Play-accepted release AAB and listing compliance complete; no debug/test ads in production | CI + Google Play Internal Testing |

## Score reporting

For each screen and game, report **verified**, **not verified**, or **fails** for:
- Information hierarchy, readability, contrast, typography, original art and motion
- Buttons/navigation/back paths, empty/error/loading states, ads and purchase recovery
- Touch feedback, clipping, overlap, safe-area, rotation/foldable handling
- Frame pacing, memory, battery, audio and haptics
- First-time onboarding, mastery, late-game difficulty and retention

Averaging strong engineering scores with missing commercial/device evidence is not a
replacement for these gates. Unknown items stay unverified rather than receiving 9+.
Mark production-ready only after the required gates have independently passed.

## Change-scoped CI

Use `tools/select_fast_ci_tests.py` and only tests relevant to the changed files in
normal development. Run the full production/readiness, catalog and Android pack gates
before a release, or when broad shared-system changes warrant them. Never remove a
necessary release check to make CI green.

## Language and coaching regression guard

Changes to `scripts/systems/localization_manager.gd` must rerun the locale integrity
and reversible Settings selector tests. Changes to `scripts/systems/sidekick_coach.gd`
rerun deterministic advice and checkpoint-context tests. Changes to the shared Settings/Sidekick surface
must manually run the targeted language/Sidekick checks alongside the existing
change-scoped secondary-screen viewport, touch-zone and visual-fit checks;
keep the fast CI policy's six-test per-area budget. A button added to the Figma
reference canvas must not obscure
an adjacent label at any tested viewport, even if every function still responds.

Test success only verifies the selected locales and sample states. Before a
release, independently inspect every supported language's phone/tablet layout,
check native screen-reader output, and verify that Sidekick suggestions are
useful in real late-campaign play.

## Atomic save integrity

The save writer must flush a temporary JSON file, protect the previous valid
primary in a separately staged backup, and replace the primary without
pre-deleting it. A failed rename must not truncate the committed primary or
emit a successful save event. Startup restores in precedence order: valid main,
valid pending temp, valid backup. An unreadable or partial JSON file is not a
valid save. Tests must exercise these cases using isolated `user://` fixture
files, including an intentionally obstructed rename.

User-selected locale belongs to preferences: reset progress and cloud backup
must preserve it. Player coins and existing Play purchase ledgers must survive
a gameplay reset, and local/cloud files must not become uploadable logs.

## Consent does not transfer with game progress

Consent state is installation/session-specific; cloud progress must never
serialize, restore, or imply advertising permission from another device.
Previously uploaded backups containing `privacy_consent_status` must be ignored
on restore. Production ad requests remain blocked until a consent provider
confirms `obtained` or `not_required` in the current running session; cached
approval from a prior run cannot open the gate while a new check is pending.
Local closed-test demo ad units remain covered by their separate explicit
project setting and must be disabled in release builds. Verify real UMP flows
on Android before advertising the app as production-compliant.

## Comprehensive quality coverage

The release gate applies equally to Home, selector, gameplay for all three games,
Daily, Collection, Goals, Profile, Friends, competition, Shop, tutorials,
results, Settings and accessibility. No section can be declared 9+/10 based on
other sections passing. Changes to Rescue, Water, Block and Goals status copy
must retain the active-scene gameplay readability contract. The source of truth
is what the player sees in the active scene, not an inherited base-class HUD.

Unverified external work must remain red: physical Android frame-pacing and
memory traces, TalkBack exploration, speaker/headphone listening, production
analytics and crash collection, native UMP consent, Google Play license-tester
purchase cycles, item activation and Play-accepted signed AAB. Screenshots and
headless geometry tests do not certify those conditions.

## Frame-pacing evidence on Android

The in-memory `AnalyticsManager.quality_snapshot()` contains bounded frame
interval p50/p95/p99, sample count and percentages over 16.7/33.3ms. A debug
APK logs the numeric-only snapshot under `[unjam-frame-quality]` on pause or
close; collect it with adb logcat on each representative device, covering
menu navigation and game levels 1, 500, 5000 and 10000 for all three games.
Keep tests change-scoped and reject regressions under
`validate_frame_pacing_probe`. Main-loop intervals are not GPU timestamps:
record Android GPU/frame-render/memory traces too. This facility is LOCAL
QA telemetry, not commercial analytics, crash reporting, or permission to
claim device-verified 60fps without device evidence.
