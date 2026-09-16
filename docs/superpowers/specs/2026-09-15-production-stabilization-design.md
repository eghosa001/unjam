# UNJAM Production Stabilization Design

**Date:** 2026-09-15

## Goal

Move the current `fix/ui-ux-four-regressions` release candidate from a feature-complete but fragile state to a production-ready Android build by fixing verified release blockers, eliminating conflicting UI ownership, hardening monetization state handling, correcting progression data defects, and making release validation trustworthy.

## Scope

This stabilization pass deliberately avoids adding new gameplay modes or cosmetic feature expansion. Work is limited to issues already identified by the production audit and required to make the existing application reliable.

## Release principles

1. The exact release commit must pass project import, validation suites, boot smoke, visual audit, APK export, and AAB export.
2. Google Play purchases fail closed until secure HTTPS verification is configured.
3. Purchase state is explicit and recoverable: cancelled, pending, purchased, failed, verification failure, timeout, disconnect, and restore must all terminate or transition predictably.
4. One UI component owns each screen's final geometry. Polling patch nodes must not fight the renderer that built the screen.
5. Responsive layout work runs on construction or viewport/state changes, not on short fixed intervals when nothing changed.
6. Reduced Motion must apply consistently to nonessential motion and flashing effects.
7. Progression/date logic uses shared rules so all games behave consistently.
8. Existing saves remain compatible; schema corrections must be migrated or read compatibly.
9. Store/listing configuration must truthfully match the shipped SDKs and features.

## Architecture

### CI and release validation

Production validators test outcomes and pinned configuration values rather than brittle source-string formatting. The AdMob validator checks version constants and install destinations semantically. The CI pipeline remains the release gate and must progress through Android APK/AAB export on the final commit.

### Monetization

`AndroidMonetizationBridge` owns Google Play SDK connectivity and raw purchase events. `StoreManager` owns product catalog/entitlement state. The bridge normalizes product IDs and purchase states before handing them to StoreManager. Purchase-update listeners remain connected for the billing-client lifetime instead of using one-shot callbacks for transactions that may become pending.

The store must never remain locked indefinitely. Every started purchase eventually reaches success, failure, cancellation, pending/recovery, or timeout. Non-consumables restore through the same normalized purchase parser. Real-money entitlement remains gated by `PurchaseVerifier` and the configured HTTPS backend.

### UI ownership

The final Home dimensions live in `premium_home_casual.gd`; `home_cinematic_polish.gd` stops continuously mutating them. Rescue, Water Sort, Block Puzzle, touch sizing, and secondary-surface styling move from interval polling toward event-driven refreshes triggered by initial construction, viewport resize, surface change, theme change, or content rebuild.

`current_surface` remains the source of truth for which top-level surface is visible. Full-screen surfaces use deterministic layer/Z ownership. Store navigation is exposed from the actual Home/navigation model rather than being created by one system and hidden every frame by another.

### Progression and persistence

Daily streak calculation is shared in behavior across all games: a streak increments only when the previous completion date is exactly the previous calendar day; otherwise it resets to 1. Old daily-task/completion history is pruned to bounded retention while lifetime counters remain.

Rescue achievements read the canonical `achievements` data with compatibility for any earlier `rescue_achievements` saves.

### Accessibility and motion

Reduced Motion becomes a global semantic choice. Navigation motion, ambient sparkles, screen flashes, invalid shakes, reward banners, and nonessential scale/translation effects check the setting. Essential gameplay state changes remain visible using simple fades or immediate state changes.

## Error handling

- Billing disconnection marks the provider unavailable and schedules bounded reconnect attempts.
- Purchase pending state does not grant entitlement and does not corrupt the transaction state.
- Verification and ad operations have explicit timeouts/failure callbacks.
- Restore ignores malformed purchases safely and never grants unknown products.
- UI refresh functions are idempotent and safe when nodes are freed during transitions.

## Testing strategy

Use existing Godot headless validation scripts and add focused regression tests before behavior changes. Key regressions include:

- AdMob installer/version validation must pass with variable-composed URLs.
- Restore must recognize `product_ids`.
- Pending purchase must not grant entitlement and must not permanently lock purchases.
- Daily streak must reset after a missed day.
- Rescue achievements must expose canonical stored achievements.
- Shop entry must be reachable from normal Home navigation.
- Reduced Motion must suppress nonessential global effects.
- Home/game layouts must no longer depend on repeated 0.18/0.20-second mutation loops.

The final branch is not complete until the latest GitHub Actions run is green through APK and AAB export.