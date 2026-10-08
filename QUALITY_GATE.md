# UNJAM: release quality bar (9+/10 in every category)

An automated PASS is not itself a 9+/10 visual or product rating. Each dimension must
be verified with its own evidence. Do not claim 9+ without a device/screenshot review.

## Mandatory release gates

| Area | Acceptance criterion | Evidence |
| --- | --- | --- |
| Home / selector / nav | Every visible button opens the intended destination on first press; never resumes a game from CHOOSE GAME | Navigation runtime test and device replay |
| All secondary screens | No clipped text, overlapping controls or unreachable content in light/dark mode | Viewport-fit and screenshots on compact phone, tall phone, tablet |
| Text readability | Minimum practical secondary text ~14 physical px at 1x reference and ideally >=16 for actions; never shrink below legibility just to fit | Screenshot inspection at 100% display scale |
| Rescue Rush | Exits, grid, hit zones, win timing, dense 10K boards legible | Campaign + Rescue runtime and Android playtest |
| Water Sort | Visible bottle mouth, no crooked pours, valid animated transfers and no stuck idle redraw | Water motion/solver tests + Android playtest |
| Block Puzzle | Preview follows finger, precisely snaps, 8x8 board and objectives remain readable | Block runtime/solvers + touch-device replay |
| Audio and haptics | No crackle, clipping, unexpected volume spikes or feedback during muted/reduced-motion modes | Real Android speaker/headphone test |
| Performance | 60fps target on supported representative Android phones; p95 gameplay frame <=16.7ms where hardware supports 60Hz; no sustained node growth after 100 navigations | On-device profiler capture |
| Monetization | Play catalog live in enabled regions; all purchases, pending/cancel/restore/refund/repeat consumables; rewarded callbacks award once | License tester and Play console evidence |
| Privacy | Test denied/accepted/required consent flows, fail-closed ads, and policy/Data Safety matching shipped SDKs | On-device consent test and listing audit |
| Save and progression | Resume, offline saves, reinstall/second-device recovery, daily rollover, and 10,000-level targets | Tests plus multi-device checklist |
| Localization | All supported language locales have readable controls and translated key journeys; no accidental substring replacements; switching a saved language restores English correctly and keeps assistive labels in sync | Localization integrity + Settings language-switch runtime contract + locale screenshots |
| Playmate Sidekick | Advice must use actual local campaign progress and remain within the game-specific safe strategy set; never claim to know an uninspected live puzzle solution | Sidekick progress-coaching runtime test plus human gameplay evaluation |
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
rerun deterministic advice tests. Changes to the shared Settings/Sidekick surface
must manually run the targeted language/Sidekick checks alongside the existing
change-scoped secondary-screen viewport, touch-zone and visual-fit checks;
keep the fast CI policy's six-test per-area budget. A button added to the Figma
reference canvas must not obscure
an adjacent label at any tested viewport, even if every function still responds.

Test success only verifies the selected locales and sample states. Before a
release, independently inspect every supported language's phone/tablet layout,
check native screen-reader output, and verify that Sidekick suggestions are
useful in real late-campaign play.
