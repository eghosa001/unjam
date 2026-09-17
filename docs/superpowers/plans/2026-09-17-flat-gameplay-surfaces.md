# Flat Gameplay Surfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Rescue Rush, Water Sort, and Block Puzzle use flat front-facing gameplay surfaces while retaining premium 3D depth effects.

**Architecture:** Gameplay state and hit testing remain in 2D `Control`/grid layers. Decorative 3D scenery stays behind the boards and ignores input. Rescue Rush removes per-piece 3D viewport rendering and returns to flat beveled `PremiumPieceButton` visuals; Water Sort and Block Puzzle retain their already-flat gameplay layouts and are protected by a shared regression contract.

**Tech Stack:** Godot 4.7.2, GDScript, GitHub Actions, Android API 36.

**Spec:** `docs/superpowers/specs/2026-09-17-flat-gameplay-surfaces-design.md`

## Global Constraints

- All three playable puzzle surfaces are front-facing 2D Controls.
- 3D scenery is decorative, input-transparent, and cannot define gameplay coordinates.
- Rescue Rush normal pieces must not use a `SubViewport` or 3D mesh renderer.
- Water Sort bottle depth and Block Puzzle bevel/extrusion effects may remain because their gameplay positions stay screen-aligned.
- Preserve Reduced Motion behavior and current gameplay rules.
- Preserve the final Rescue Rush escape-before-completion behavior.
- Android release validation remains API 36.

---

### Task 1: Add the flat-surface regression contract

**Files:**
- Create: `tests/validate_flat_gameplay_surfaces.gd`
- Modify: `.github/workflows/godot-ci.yml`
- Modify: `tests/validate_hybrid_gameplay_architecture.gd`

**Interfaces:**
- Consumes: active Rescue Rush, Water Sort, Block Puzzle source files.
- Produces: CI contract `validate_flat_gameplay_surfaces`.

- [ ] **Step 1: Write the failing contract**

Create a test that requires:

```gdscript
_check_contains("res://scripts/game/rescue_rush_premium.gd", ["PremiumPieceButton.new()"])
_check_absent("res://scripts/game/rescue_rush_premium.gd", ["RescuePiece3D", "rescue_piece_3d_button.gd"])
_check_contains("res://scripts/game/rescue_rush_casual.gd", ["board_grid = GridContainer.new()"])
_check_contains("res://scripts/game/water_sort_casual.gd", ["board = GridContainer.new()", "GameplayStage"])
_check_contains("res://scripts/game/block_puzzle_3d.gd", ["board_grid = GridContainer.new()", "BlockCellButton.new()"])
_check_contains("res://scripts/ui/unjam_3d_gameplay_stage.gd", ["mouse_filter = Control.MOUSE_FILTER_IGNORE"])
```

Also fail if `res://scripts/ui/rescue_piece_3d_button.gd` still exists after the migration.

- [ ] **Step 2: Run the contract and verify RED**

Run:

```bash
godot --headless --path . --script res://tests/validate_flat_gameplay_surfaces.gd
```

Expected: FAIL because Rescue Rush still instantiates `RescuePiece3D` and the old 3D piece file still exists.

- [ ] **Step 3: Update the hybrid architecture contract**

Change Rescue assertions from per-piece 3D rendering to flat beveled pieces while leaving Water Sort and Block Puzzle depth contracts intact.

- [ ] **Step 4: Add the new contract to CI**

Add `validate_flat_gameplay_surfaces` to the fast visual/architecture test loop and remove the obsolete Rescue 3D-piece idle-cost contract after Task 2 deletes that renderer.

### Task 2: Convert Rescue Rush pieces to flat premium pieces

**Files:**
- Modify: `scripts/game/rescue_rush_premium.gd`
- Modify: `scripts/game/rescue_rush_polished.gd`
- Modify: `scripts/ui/ui_touch_enhancer.gd`
- Modify: `scripts/ui/ui_touch_enhancer_casual.gd`
- Delete: `scripts/ui/rescue_piece_3d_button.gd`
- Modify: `tests/validate_3d_rebuild_atomic.gd`
- Modify: `tests/validate_3d_world_isolation.gd`
- Delete: `tests/validate_rescue_piece_idle_cost.gd`

**Interfaces:**
- Consumes: `PremiumPieceButton.configure(type_value, direction_value, base_color)`.
- Produces: flat top-down Rescue Rush board and escape visuals.

- [ ] **Step 1: Switch board pieces**

Remove the Rescue 3D preload and replace:

```gdscript
var button := RescuePiece3D.new()
```

with:

```gdscript
var button := PremiumPieceButton.new()
```

Keep the existing `configure`, disabled-state, press binding, board sizing, and entrance animation.

- [ ] **Step 2: Switch escape ghosts**

Remove the Rescue escape 3D preload and replace the ghost with `PremiumPieceButton.new()`. Preserve `_active_escape_visuals`, off-screen travel, speed lines, completion wait, and final cleanup.

- [ ] **Step 3: Remove obsolete Rescue 3D touch classification**

Delete `_is_rescue_piece_button()` and remove it from `ui_touch_enhancer_casual.gd`. Normal Rescue pieces remain sized by the authoritative board-fit code.

- [ ] **Step 4: Delete the obsolete renderer and its renderer-only tests**

Delete `rescue_piece_3d_button.gd` and `validate_rescue_piece_idle_cost.gd`. Remove Rescue piece checks from 3D rebuild/world-isolation tests while preserving game-card, scenery, mascot, rescue-token, and Water Sort checks.

- [ ] **Step 5: Run focused GREEN checks**

Run:

```bash
godot --headless --path . --script res://tests/validate_flat_gameplay_surfaces.gd
godot --headless --path . --script res://tests/validate_hybrid_gameplay_architecture.gd
godot --headless --path . --script res://tests/validate_motion_quality.gd
godot --headless --path . --script res://tests/validate_viewport_fit.gd
```

Expected: all PASS.

### Task 3: Verify Water Sort and Block Puzzle preserve the flat-board rule

**Files:**
- Modify only if tests reveal a violation: `scripts/game/water_sort_casual.gd`, `scripts/game/block_puzzle_3d.gd`, `scripts/ui/unjam_3d_gameplay_stage.gd`.

**Interfaces:**
- Water Sort authoritative board: `GridContainer board` inside `GameplayStage`.
- Block Puzzle authoritative board: `GridContainer board_grid` containing `BlockCellButton` controls.

- [ ] **Step 1: Verify source and runtime hierarchy**

Run the flat-surface contract and existing viewport-fit/visual hierarchy tests. Confirm scenery viewport is behind gameplay with `z_index = -100` and `MOUSE_FILTER_IGNORE`.

- [ ] **Step 2: Make no cosmetic rewrite if already compliant**

If both games already satisfy the invariant, leave their gameplay rendering unchanged. This avoids unnecessary regression in Water Sort pouring and Block Puzzle drag smoothness.

### Task 4: Full production verification

**Files:**
- No additional product changes unless a failing gate identifies a root cause.

- [ ] **Step 1: Import/parse check**

```bash
godot --headless --path . --editor --quit
```

Reject any `SCRIPT ERROR`, parse failure, invalid call, or invalid access.

- [ ] **Step 2: Run CI quality contracts**

Run the repository’s fast quality, flat-surface, gameplay, boot, and rendered screenshot checks.

- [ ] **Step 3: Inspect rendered game screenshots**

Confirm visually:

```text
Rescue Rush: flat top-down board, flat beveled arrows/pieces, no miniature mesh-platform look.
Water Sort: flat bottle stage, dimensional glass/liquid only.
Block Puzzle: flat grid, beveled/extruded cubes only.
```

- [ ] **Step 4: Export Android artifacts**

Run the existing API-36 APK and AAB smoke exports. Expected: both exit 0 and upload artifacts.

- [ ] **Step 5: Commit final implementation**

Commit with a message describing the visual invariant, for example:

```bash
git commit -m "fix: keep gameplay boards flat with 3d effects"
```
