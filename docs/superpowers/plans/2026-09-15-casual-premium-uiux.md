# Casual Premium UI/UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework UNJAM's shared home/settings surfaces and all three gameplay surfaces so the board/tubes and primary action dominate, secondary chrome is compact, and the motion/touch behavior matches modern casual puzzle-game expectations.

**Architecture:** Keep all game rules, persistence and level systems unchanged. Implement presentation changes in the existing premium UI scripts and small focused polish scripts, preserving the current inheritance chain. Add regression tests that assert the new hierarchy and motion rules before changing production UI, then verify with Godot and Stagehand.

**Tech Stack:** Godot 4.7.2, GDScript, existing PremiumDesignSystem/PremiumVisuals/MotionDirector, GitHub Actions, Stagehand Linux.

**Spec:** `docs/superpowers/specs/2026-09-15-casual-premium-uiux.md`

## Global Constraints

- Do not change puzzle rules, level generation, save/checkpoint behavior, scoring semantics or monetization semantics.
- Screen roots must remain stationary during transitions.
- Existing fixes for Water Sort curved pour/3x2 layout, Rescue Rush height-aware sizing and Block Puzzle centroid magnetism must remain active.
- Keep touch targets practical while reducing their visual dominance.
- No duplicated instructional copy.

---

### Task 1: Regression contract for premium hierarchy

**Files:**
- Modify: `tests/validate_uiux_regressions.gd`

**Interfaces:**
- Consumes: existing source scripts.
- Produces: source-contract checks for compact home/settings/gameplay hierarchy.

- [ ] **Step 1:** Add checks requiring compact home secondary actions, compact settings rows, no Block Puzzle run deck, compact Rescue Rush layout, and Water Sort stage/action sizing markers.
- [ ] **Step 2:** Run `godot --headless --path . --script res://tests/validate_uiux_regressions.gd`; verify RED against the current branch.
- [ ] **Step 3:** Commit the failing contract.

### Task 2: Home and settings hierarchy

**Files:**
- Modify: `scripts/ui/premium_home_overhaul.gd`
- Modify: `scripts/ui/premium_main.gd`

**Interfaces:**
- Produces: `HomeSecondaryActions` compact row and compact settings sections with `REDUCED MOTION`, `HOW TO PLAY`, and `PRIVACY` affordances.

- [ ] **Step 1:** Reduce hero/header chrome and remove the four equally weighted dashboard actions from the main hierarchy.
- [ ] **Step 2:** Replace them with a compact secondary action strip under the three game selectors.
- [ ] **Step 3:** Rebuild Settings as compact toggles plus secondary links; remove PLAY HISTORY from this surface.
- [ ] **Step 4:** Run UI regression test and import check; verify GREEN for home/settings requirements.
- [ ] **Step 5:** Commit.

### Task 3: Water Sort gameplay-first layout

**Files:**
- Modify: `scripts/game/water_sort_reference.gd`
- Modify: `scripts/game/water_sort_ultra_motion.gd`

**Interfaces:**
- Produces: compact header/info/actions, expanded tube stage, selected/invalid feedback; preserves `_quadratic_bezier_points` and 3x2 six-tube rule.

- [ ] **Step 1:** Reduce header and action sizes and collapse metadata/move state into one compact strip.
- [ ] **Step 2:** Increase the stage's share of available height while reducing empty panel padding.
- [ ] **Step 3:** Strengthen selected bottle lift/glow and invalid feedback without blocking concurrent pours.
- [ ] **Step 4:** Run motion/UI regression and gameplay interaction tests.
- [ ] **Step 5:** Commit.

### Task 4: Block Puzzle gameplay-first layout

**Files:**
- Modify: `scripts/game/block_puzzle_premium_layout.gd`
- Modify: `scripts/game/block_puzzle_ultra_motion.gd`

**Interfaces:**
- Produces: larger board, compact score/goal, tray immediately beneath board, compact progress indicator; preserves `SmoothPieceButton` centroid magnetism.

- [ ] **Step 1:** Remove `_add_run_progress_deck` from the build path and replace it with a compact progress strip integrated near score/tray.
- [ ] **Step 2:** Use both viewport width and height to maximize safe board cell size.
- [ ] **Step 3:** Reduce decorative chrome and place the piece tray directly beneath the board.
- [ ] **Step 4:** Run UI regression, motion quality and gameplay interaction tests.
- [ ] **Step 5:** Commit.

### Task 5: Rescue Rush gameplay-first layout

**Files:**
- Modify: `scripts/game/rescue_rush_premium.gd`
- Modify: `scripts/ui/rescue_layout_polish.gd`

**Interfaces:**
- Produces: compact top bar/status and board-dominant layout while retaining `_fit_board_to_viewport`.

- [ ] **Step 1:** Remove duplicate brand/world/footer/tip chrome from normal gameplay.
- [ ] **Step 2:** Keep one compact level title and one compact status row around the board.
- [ ] **Step 3:** Remove the large Rescue Route deck; keep route information visually encoded in board cells and a small live label only if needed.
- [ ] **Step 4:** Re-run responsive sizing and completion-buffer tests.
- [ ] **Step 5:** Commit.

### Task 6: Full runtime verification and visual iteration

**Files:**
- Modify as needed only when a fresh runtime screenshot exposes a concrete issue.

**Interfaces:**
- Produces: validated screenshots and Stagehand interaction run.

- [ ] **Step 1:** Run Godot editor import with script-error rejection.
- [ ] **Step 2:** Run `validate_level_launch`, `validate_gameplay_interactions`, `validate_motion_quality`, `validate_uiux_regressions`, `validate_premium_ux`.
- [ ] **Step 3:** Capture fresh home/settings/Rescue/Water/Block screenshots at tall-phone layout.
- [ ] **Step 4:** Repeat visual audit at a narrower viewport and fix clipping or wasted-space issues found.
- [ ] **Step 5:** Run Stagehand navigation/interaction smoke and performance sampling.
- [ ] **Step 6:** Review the PR diff and only then mark ready for review.
