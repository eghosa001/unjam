# UNJAM Production Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current UNJAM release candidate trustworthy for Google Play internal/closed testing by fixing verified CI, billing, progression, UI-ownership, accessibility, and release-readiness defects.

**Architecture:** Keep the existing Godot 4.7.2 architecture and PR branch, but consolidate ownership: CI validators test semantics, billing events are normalized centrally, screen builders own final geometry, and periodic UI patch loops are replaced with event-driven refreshes. Use focused regression tests before each behavior change and keep the branch releasable after each task.

**Tech Stack:** Godot 4.7.2 / GDScript, Android API 36, Google Play Billing plugin 3.3.0, Poing Godot AdMob 5.1.0, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-15-production-stabilization-design.md`

## Global Constraints

- Work on `fix/ui-ux-four-regressions`, never directly on `main`.
- Android target SDK remains API 36 and min SDK 24.
- Production purchases remain fail-closed until HTTPS verification is configured.
- Existing save files must remain readable.
- No new gameplay modes/features during stabilization.
- Every behavior fix adds/updates a focused regression test first.
- Final completion requires a green GitHub Actions run through APK and AAB export.

---

### Task 1: Repair AdMob production validator

**Files:**
- Modify: `tests/validate_admob_production.gd`
- Verify: `tools/install_monetization_plugins.sh`

**Produces:** A validator that checks pinned version variables/install destinations without requiring expanded URL literals.

- [ ] Use the existing failing CI run as RED evidence.
- [ ] Replace literal expanded-URL assertions with semantic checks for `ADMOB_VERSION="5.1.0"`, `GODOT_ADMOB_TEMPLATE_VERSION="4.7.2"`, expected GitHub release path fragments, and `addons/admob/android/bin` destination.
- [ ] Push only the test change.
- [ ] Verify the new PR CI progresses beyond `validate_admob_production`.

### Task 2: Normalize Billing purchase payloads and restore

**Files:**
- Test: `tests/validate_billing_production.gd`
- Modify: `scripts/systems/android_monetization_bridge.gd`
- Modify: `scripts/systems/store_manager.gd`

**Interfaces:**
- Produces: normalized purchase dictionaries with canonical `product_ids`, `purchase_token`, and `purchase_state` handling.

- [ ] Add a failing regression assertion requiring restore code to consume `product_ids` rather than `products`.
- [ ] Verify RED in CI.
- [ ] Update restore parsing to use canonical product IDs and tolerate legacy `products` only as compatibility fallback.
- [ ] Verify billing/monetization suites pass.

### Task 3: Make Billing purchase state recoverable

**Files:**
- Test: `tests/validate_billing_production.gd`
- Modify: `scripts/systems/android_monetization_bridge.gd`
- Modify: `scripts/systems/store_manager.gd`

**Produces:** Lifetime purchase-update subscription and explicit pending/cancel/fail handling without permanent `purchase_in_progress` lock.

- [ ] Add failing checks that the bridge handles pending state and does not connect purchase updates with `CONNECT_ONE_SHOT`.
- [ ] Keep a single billing purchase-update handler connected for the client lifetime.
- [ ] Track pending purchases without granting entitlement.
- [ ] Ensure non-success terminal responses clear StoreManager lock.
- [ ] Verify billing suites and import.

### Task 4: Add Billing reconnection and operation timeouts

**Files:**
- Test: `tests/validate_billing_production.gd`
- Modify: `scripts/systems/android_monetization_bridge.gd`
- Modify: `scripts/systems/purchase_verifier.gd`
- Modify: `scripts/systems/store_manager.gd`

- [ ] Add failing source/behavior checks for reconnect scheduling and verification timeout.
- [ ] Add bounded deferred reconnect after billing disconnect/connect error.
- [ ] Add HTTP verification timeout and guarantee callback cleanup.
- [ ] Add StoreManager purchase timeout fallback.
- [ ] Verify monetization and billing suites.

### Task 5: Restore Shop reachability

**Files:**
- Test: `tests/validate_uiux_regressions.gd`
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify: `scripts/ui/ux_shell_premium.gd`
- Modify: `scripts/ui/monetization_hub.gd`

- [ ] Add failing regression asserting Home exposes a Shop path and UXShell does not force-hide it.
- [ ] Add Shop to Home navigation/header using MonetizationHub's public open method.
- [ ] Stop the shell from overriding shop visibility every frame.
- [ ] Verify UI regression and viewport suites.

### Task 6: Correct daily streaks, achievements, and bounded history

**Files:**
- Test: `tests/validate_retention.gd`
- Modify: `scripts/core/multi_game_manager.gd`
- Modify: `scripts/core/robust_save_manager.gd` if migration is required.

- [ ] Add failing tests for missed-day streak reset and canonical Rescue achievement lookup.
- [ ] Implement shared previous-calendar-day check for Water Sort and Block Puzzle.
- [ ] Read canonical `achievements`, with compatibility fallback for legacy `rescue_achievements`.
- [ ] Prune old multi-game daily task/completion history to a fixed recent window while retaining aggregates.
- [ ] Verify retention/robustness suites.

### Task 7: Consolidate Home geometry ownership

**Files:**
- Test: `tests/validate_uiux_regressions.gd`
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify or remove: `scripts/ui/home_cinematic_polish.gd`
- Modify: `scenes/Main.tscn`

- [ ] Add failing check that Home final geometry is defined by the Home renderer and not periodically rewritten.
- [ ] Move final hero/art/title/button dimensions into `premium_home_casual.gd`.
- [ ] Remove the continuously polling Home patch node from Main.
- [ ] Verify viewport and visual audit suites.

### Task 8: Replace gameplay layout polling with resize-driven refresh

**Files:**
- Modify: `scripts/ui/rescue_layout_polish.gd`
- Modify: `scripts/ui/water_stage_polish.gd`
- Modify: `scripts/ui/puzzle_casual_polish.gd`
- Test: `tests/validate_viewport_fit.gd`
- Test: `tests/validate_uiux_regressions.gd`

- [ ] Add failing assertions that these helpers do not use short interval `_process` loops.
- [ ] Apply once at ready/content build and on viewport-size changes using cached size checks or resize notification.
- [ ] Preserve current calculated dimensions at all tested portrait viewports.
- [ ] Verify viewport-fit and gameplay interaction suites.

### Task 9: Replace global UI polling where practical

**Files:**
- Modify: `scripts/ui/ui_touch_enhancer.gd`
- Modify: `scripts/ui/premium_surface_manager.gd`
- Modify: `scripts/ui/ux_shell_casual.gd`
- Test: `tests/validate_uiux_regressions.gd`

- [ ] Add regression checks preventing 0.18/0.20-second tree rescans for stable screens.
- [ ] Convert touch sizing to node-added plus deferred initial pass.
- [ ] Convert secondary-surface restyling to signature-triggered/deferred refresh rather than interval polling.
- [ ] Keep back/tutorial handling intact.
- [ ] Verify UI, premium UX, and viewport suites.

### Task 10: Make Reduced Motion system-wide

**Files:**
- Test: `tests/validate_motion_quality.gd`
- Modify: `scripts/systems/premium_visuals.gd`
- Modify: `scripts/systems/robust_premium_visuals.gd`
- Modify affected game motion wrappers only where essential.

- [ ] Add failing checks that ambient sparkles, screen flashes, invalid shakes, reward motion, and transition movement respect `reduced_motion`.
- [ ] Suppress nonessential movement/flashing while keeping immediate/fade-only feedback.
- [ ] Verify motion-quality and gameplay interaction suites.

### Task 11: Clean stale production configuration and dead-code candidates

**Files:**
- Modify: `project.godot` if Stagehand plugin entry is stale.
- Remove only after reference verification: `scripts/ui/global_finish_polish.gd`, `scripts/ui/home_ux_patch.gd`, `scripts/ui/secondary_surface_fill.gd`.
- Test: import and all source-reference validations.

- [ ] Verify each candidate has no active scene/autoload/inheritance/reference use on this branch.
- [ ] Remove only confirmed orphans.
- [ ] Remove/repair stale Stagehand plugin configuration so import has no missing-plugin warning.
- [ ] Verify project import remains clean.

### Task 12: Google Play release asset/config readiness

**Files:**
- Modify: `RELEASE_CHECKLIST.md`
- Modify/create text/config only where repository-owned; do not fabricate final screenshots.

- [ ] Update checklist with fixed billing pending/restore requirements.
- [ ] Confirm API 36, versioning, ads declaration, Data Safety, target audience/IARC, root-host `app-ads.txt`, and privacy-policy deployment requirements remain documented.
- [ ] Record that the current rounded SVG is launcher artwork, not the final Play Console full-square listing icon.
- [ ] Record required final 512×512 Play icon, 1024×500 feature graphic, and real portrait screenshots.

### Task 13: Final verification

**Files:** none unless failures expose defects.

- [ ] Inspect latest PR CI for project import and every validator.
- [ ] Confirm visual audit artifact generation succeeds.
- [ ] Confirm Android API 36 debug APK export succeeds.
- [ ] Confirm Android API 36 AAB export succeeds.
- [ ] Review changed files for accidental debug/test-mode regressions.
- [ ] Only then mark the stabilization pass complete.