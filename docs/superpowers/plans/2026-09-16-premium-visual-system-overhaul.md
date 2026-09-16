# UNJAM Premium Visual System Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved bright 2.5D premium visual language consistently across every user-facing UNJAM screen while preserving gameplay rules, responsiveness, Reduced Motion, and Android performance.

**Architecture:** Extend the existing `PremiumDesignSystem`, `PremiumBackdrop`, `MotionSystem`, and existing per-screen scripts instead of replacing the Godot architecture. Shared tactile visual primitives are introduced first, then Home/Game Selection/gameplay screens consume them so all screens share the same depth, typography, motion, and material language.

**Tech Stack:** Godot 4.x, GDScript, Control/CanvasItem drawing, existing MotionSystem/MotionDirector, existing DeviceFit responsive sizing.

**Spec:** `docs/superpowers/specs/2026-09-16-premium-visual-system-overhaul-design.md`

## Global Constraints

- Keep the project hybrid 2D/2.5D; do not convert the UI to full real-time 3D.
- Preserve existing gameplay rules and save/progression behavior.
- No full-screen flashes for ordinary navigation; eliminate edge flashes and abrupt white transitions.
- Preserve Reduced Motion and stop decorative processing when it is enabled.
- Typography targets: screen/logo title 40–64 px equivalent; game title 30–46 px; major CTA 24–32 px; HUD values 20–28 px; body 17–22 px; navigation 15–18 px minimum.
- Motion targets: card entry 180–260 ms; major page transition 220–320 ms; drag elevation under 100 ms; placement snap 120–180 ms; reward/completion emphasis under 800 ms.
- Avoid large transparent overdraw stacks, per-frame allocations, and uncapped particles.
- Water Sort pours must visually originate at the bottle mouth and preserve valid concurrent interaction.
- Rescue Rush completion must wait until the final moving arrow has completely exited.
- Block Puzzle drag/drop must remain responsive with no added input latency.
- All production-readiness tests must remain green.

---

### Task 1: Shared 2.5D visual primitives

**Files:**
- Modify: `scripts/ui/premium_design_system.gd`
- Modify: `scripts/ui/premium_backdrop.gd`
- Modify: `scripts/ui/motion_system.gd`
- Test: `tests/test_premium_visual_system.gd`

**Interfaces:**
- Produces: `PremiumDesignSystem.raised_box(...)`, `recessed_box(...)`, `gloss_button(...)`, `hud_box(...)`, `status_chip(...)`, and consistent material helpers for stone/glass/toy/metal.
- Produces: shared motion helpers for tactile press/release and page entry that honor Reduced Motion.

- [ ] **Step 1:** Add failing tests asserting tactile style helpers exist, have non-zero depth/shadow, respect theme contrast, and keep minimum touch height >= 78 px.
- [ ] **Step 2:** Run the premium visual-system test and confirm it fails before implementation.
- [ ] **Step 3:** Add raised/recessed/gloss/HUD/status/material helpers using layered StyleBoxFlat-compatible resources and bounded shadow/highlight values.
- [ ] **Step 4:** Add reusable press/release/page-entry helpers to `MotionSystem`, with Reduced Motion returning immediate final states.
- [ ] **Step 5:** Run the test and existing UI/motion tests; commit `feat: add shared premium 2.5d visual primitives`.

### Task 2: Apply the visual language to Home and persistent navigation

**Files:**
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify: `scripts/ui/premium_home_overhaul.gd`
- Modify: `scripts/ui/game_showcase_art.gd`
- Modify: `scripts/ui/main.gd`
- Test: `tests/test_home_premium_layout.gd`

**Interfaces:**
- Consumes: shared raised/recessed/gloss/HUD primitives from Task 1.
- Produces: visually integrated Home screen with large identity, hero world, oversized PLAY action, three-game selector, and premium bottom navigation.

- [ ] **Step 1:** Add a failing layout test for tall mobile viewport ensuring no overlap, dominant title/PLAY sizing, nav labels >= 15 px, and no card-heavy empty lower region.
- [ ] **Step 2:** Run the test and verify failure on the current dashboard-like composition.
- [ ] **Step 3:** Recompose Home into layered world background + UNJAM identity + mascot/showcase art + large PLAY + compact game selector + persistent bottom nav.
- [ ] **Step 4:** Apply tactile press feedback and remove any transition path that clears to white or exposes an edge flash.
- [ ] **Step 5:** Run Home/layout/navigation tests at representative tall and medium aspect ratios; commit `feat: rebuild premium home and navigation`.

### Task 3: Premium Game Selection across all three game cards

**Files:**
- Modify: `scripts/ui/game_select_tile.gd`
- Modify: `scripts/ui/game_showcase_art.gd`
- Modify: `scripts/ui/main.gd`
- Test: `tests/test_game_selection_premium.gd`

**Interfaces:**
- Produces: tactile illustrated card variants for `rescue_rush`, `water_sort`, `block_puzzle`.

- [ ] **Step 1:** Add failing tests checking distinct material/accent identity, title hierarchy, progress display, and >= 78 px action target.
- [ ] **Step 2:** Run tests and confirm failure.
- [ ] **Step 3:** Upgrade Rescue Rush card to lush stone/foliage + arrow-piece identity; Water Sort card to glass/liquid identity; Block Puzzle card to chunky toy-piece/recessed-board identity.
- [ ] **Step 4:** Add entry/selection motion using shared motion helpers and Reduced Motion gate.
- [ ] **Step 5:** Run Game Selection tests and commit `feat: upgrade game selection cards`.

### Task 4: Rescue Rush gameplay, HUD, board depth, and completion ordering

**Files:**
- Modify: `scripts/game/rescue_rush_premium.gd`
- Modify: `scripts/game/rescue_rush_polished.gd`
- Modify: `scripts/game/rescue_rush_casual.gd`
- Modify: `scripts/game/rescue_rush_motion_final.gd`
- Modify: `scripts/game/game.gd`
- Test: `tests/test_rescue_rush_premium.gd`
- Test: `tests/test_rescue_completion_order.gd`

**Interfaces:**
- Produces: recessed board, stone/foliage frame, tactile arrow/obstacle rendering, premium Moves/Rescue/Chain HUD, large Undo/Hint/Restart controls.
- Produces: completion gate that fires only after active exit motion is finished and the last arrow is no longer on the playfield.

- [ ] **Step 1:** Add failing completion-order test that simulates final arrow motion and asserts completion UI remains hidden until exit animation completion.
- [ ] **Step 2:** Add failing visual-structure test for HUD sections, button sizes, and board frame depth.
- [ ] **Step 3:** Implement the completion gate using existing motion state rather than a blind timer.
- [ ] **Step 4:** Apply shared materials to board frame, arrows, obstacles, HUD, and controls; keep game rules unchanged.
- [ ] **Step 5:** Run Rescue Rush tests and commit `feat: deliver premium rescue rush presentation`.

### Task 5: Water Sort glass rendering and bottle-mouth pouring

**Files:**
- Modify: `scripts/game/water_sort.gd`
- Modify: `scripts/game/water_sort_casual.gd`
- Modify: `scripts/game/water_sort_polished.gd`
- Modify: `scripts/game/water_sort_reference.gd`
- Modify: `scripts/game/water_sort_reference_motion.gd`
- Test: `tests/test_water_sort_premium.gd`
- Test: `tests/test_water_sort_pour_origin.gd`

**Interfaces:**
- Produces: bottle mouth anchor calculation used by pour stream rendering.
- Produces: layered glass rendering and concurrent-interaction-safe pour animation.

- [ ] **Step 1:** Add failing tests asserting stream start position is at source bottle mouth, end position is destination opening, and a valid second interaction can be queued/started while another pour animates.
- [ ] **Step 2:** Run tests and verify failure.
- [ ] **Step 3:** Implement explicit bottle-mouth anchors and use them for stream start/end geometry.
- [ ] **Step 4:** Add layered rim, inner shadow, liquid body/top surface, specular highlight, and contact shadow without per-frame allocations.
- [ ] **Step 5:** Run Water Sort tests and commit `feat: upgrade water sort glass and pouring`.

### Task 6: Block Puzzle tactile rendering and smoother drag/drop

**Files:**
- Modify: `scripts/ui/block_cell_button.gd`
- Modify: `scripts/ui/block_piece_button.gd`
- Modify: `scripts/ui/polished_block_piece_button.gd`
- Modify: `scripts/ui/block_drag_preview.gd`
- Modify: `scripts/game/block_puzzle.gd`
- Modify: `scripts/game/block_puzzle_polished.gd`
- Modify: `scripts/game/block_puzzle_premium_layout.gd`
- Modify: `scripts/game/block_puzzle_ultra_motion.gd`
- Test: `tests/test_block_puzzle_premium.gd`

**Interfaces:**
- Produces: raised piece states, drag elevation, valid-placement glow, 120–180 ms snap compression, bounded clear particles.

- [ ] **Step 1:** Add failing responsiveness test asserting drag elevation begins under 100 ms and placement snap duration stays within 120–180 ms.
- [ ] **Step 2:** Run test and verify failure.
- [ ] **Step 3:** Apply layered toy-piece rendering, contact shadows, slight scale/tilt on drag, stronger valid preview, and snap compression.
- [ ] **Step 4:** Add capped line-clear particles and brief board response; disable decorative response under Reduced Motion.
- [ ] **Step 5:** Run Block Puzzle tests and commit `feat: polish block puzzle tactile motion`.

### Task 7: Make remaining user-facing screens match the same premium system

**Files:**
- Modify: `scripts/ui/main.gd`
- Modify: `scripts/ui/level_browser_polish.gd`
- Modify: `scripts/ui/monetization_hub.gd`
- Modify: `scripts/ui/premium_design_system.gd`
- Modify: relevant Settings/Collection/Daily/Live builders discovered in `scripts/ui/main.gd`
- Test: `tests/test_all_screen_visual_consistency.gd`

**Interfaces:**
- Produces: same typography, button depth, card treatment, header/navigation grammar, and transition behavior on Home, Levels, Collection, Settings, Daily, Live, Shop/monetization, and auxiliary screens.

- [ ] **Step 1:** Add a failing screen-consistency test that instantiates each user-facing screen and checks heading/body/nav minimum font sizes, tactile button style assignment, non-white background coverage, and touch target minimums.
- [ ] **Step 2:** Run test and record screens still using legacy flat styling.
- [ ] **Step 3:** Apply the shared premium primitives to every remaining user-facing screen without changing feature behavior.
- [ ] **Step 4:** Ensure game-specific screens retain their individual accent while all utility screens use the shared UNJAM shell.
- [ ] **Step 5:** Run all-screen consistency tests and commit `feat: apply premium visual system to all screens`.

### Task 8: Transition cleanup, edge-flash prevention, accessibility, and performance

**Files:**
- Modify: `scripts/ui/motion_director.gd`
- Modify: `scripts/ui/motion_system.gd`
- Modify: `scripts/ui/premium_backdrop.gd`
- Modify: `scripts/ui/device_fit.gd` only if viewport fixes are required
- Test: `tests/test_transition_quality.gd`
- Test: `tests/test_reduced_motion.gd`
- Test: existing performance/FPS gate tests

**Interfaces:**
- Produces: shared page transition path with continuous background coverage and no flash frame.

- [ ] **Step 1:** Add failing transition test ensuring outgoing/incoming screens overlap background coverage and no white/default clear frame can appear.
- [ ] **Step 2:** Add/extend Reduced Motion test asserting ambient backdrop/particle loops stop.
- [ ] **Step 3:** Implement unified 220–320 ms major page transition and remove ad-hoc flash-producing transitions.
- [ ] **Step 4:** Audit particle counts/transparent layers and remove per-frame allocations introduced by this work.
- [ ] **Step 5:** Run transition, Reduced Motion, FPS/performance, and full automated suites; commit `perf: finalize premium transitions and performance`.

### Task 9: Final visual QA and release-readiness verification

**Files:**
- Modify only files required by defects discovered during verification.
- Test: full `tests/` suite and existing GitHub Actions production pipeline.

**Interfaces:**
- Produces: final release candidate branch ready for PR/merge.

- [ ] **Step 1:** Boot Home, Game Selection, Rescue Rush, Water Sort, Block Puzzle, Levels, Collection, Settings, Daily, Live, and Shop on a tall Android viewport and verify no overlaps/cutoffs.
- [ ] **Step 2:** Verify Rescue Rush last-arrow completion ordering, Water Sort bottle-mouth stream, and Block Puzzle drag smoothness manually and through automated tests.
- [ ] **Step 3:** Verify dark/light/accessibility settings and Reduced Motion.
- [ ] **Step 4:** Run the full Godot test suite and production-readiness checks; fix only demonstrated regressions.
- [ ] **Step 5:** Commit final fixes as `test: verify premium visual overhaul` and open a PR from `feature/premium-visual-overhaul` to `main` with test evidence.
