# Responsive Theme and Progression Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix UNJAM's vertical under-use, level navigation/progression refresh, Block Puzzle duplicate drag visuals, early Rescue Rush difficulty, Collection depth, viewport containment, and app-wide dark mode without replacing the current 3D redesign.

**Architecture:** Keep the active scene/script inheritance chains and patch the final presentation layers. Add one fast regression contract first, then make responsive sizing/theme/progression changes in the active UI/game scripts while preserving authoritative save/gameplay systems.

**Tech Stack:** Godot 4.7.2, GDScript, GitHub Actions, Android API 36.

**Spec:** `docs/superpowers/specs/2026-09-17-responsive-theme-progression-polish-design.md`

## Global Constraints

- Work only on `visual-reboot-3d-build-final2`.
- Preserve current gameplay logic and 3D visual direction.
- Keep changes event-driven; do not add always-running UI polling.
- Preserve 10,000-level campaigns.
- Preserve existing campaign solvability and viewport contracts.
- Dark mode must not restart the active level.

---

### Task 1: Add regression contract

**Files:**
- Create: `tests/validate_reported_polish_regressions.gd`
- Modify: `.github/workflows/godot-ci.yml`

**Interfaces:**
- Consumes: active source files and `CampaignGenerator.generate(level_number)`.
- Produces: a 45-second fast CI contract that fails until all requested fixes exist.

- [ ] **Step 1: Write the failing test**

The test must verify the exact opening difficulty rhythm and require source-level ownership for: one touch preview, level game tabs, live progress refresh, dark-theme propagation, responsive Rescue/Water sizing, and cross-game Collection.

- [ ] **Step 2: Run test to verify it fails**

Run in CI: `godot --headless --path . --script res://tests/validate_reported_polish_regressions.gd`
Expected: FAIL on the current branch because the requested contracts are not yet implemented.

- [ ] **Step 3: Add the contract to Fast quality contracts**

Insert `validate_reported_polish_regressions` into the existing fast test loop so every PR commit checks it.

### Task 2: Fix Block Puzzle single-preview ownership

**Files:**
- Modify: `scripts/ui/smooth_block_piece_button.gd`

**Interfaces:**
- Consumes: inherited `touch_preview`, `touch_drag_started`, `_get_drag_data`, `_show_touch_preview`, `_hide_touch_preview`.
- Produces: exactly one floating brick preview for a touch drag and a fully hidden tray source during the drag.

- [ ] **Step 1: Make manual touch preview singleton-owned**

Before creating a touch preview, free any stale preview instance. Override `_get_drag_data()` so a touch-owned drag cannot also create Godot's native drag preview.

- [ ] **Step 2: Hide and restore the tray source cleanly**

Use zero alpha while dragging instead of leaving the source faintly visible; restore it through the existing end-drag path.

### Task 3: Rebalance Rescue Rush opening and gameplay density

**Files:**
- Modify: `scripts/core/campaign_generator.gd`
- Modify: `scripts/game/rescue_rush_motion_final.gd`
- Modify: `scripts/game/rescue_rush_casual.gd`

**Interfaces:**
- Produces: opening rhythm `[easy,easy,medium,easy,medium,medium,easy,medium,medium,hard]`, larger early boards, denser early layouts, larger action controls, and no oversized flexible gap around the board.

- [ ] **Step 1: Change onboarding difficulty mapping**

Levels 3, 5, 6, 8 and 9 become medium; 10 stays hard milestone. Increase required lane blockers and safe filler count only for the medium opening levels.

- [ ] **Step 2: Increase board budget**

Raise the responsive board height ratio and cell cap while remaining width-limited.

- [ ] **Step 3: Remove empty gameplay gap**

Make the board holder shrink to its board rather than consuming all remaining height, and increase action-button height.

### Task 4: Fill Water Sort vertically without overflow

**Files:**
- Modify: `scripts/game/water_sort_ultra_motion.gd`
- Modify: `scripts/game/water_sort_casual.gd`

**Interfaces:**
- Produces: tube dimensions derived from viewport width, row count, and available gameplay height; larger controls; no oversized empty stage below the tubes.

- [ ] **Step 1: Derive tube height from available stage budget**

Calculate rows from tube count, determine per-row height from approximately 58% of viewport height, and clamp width to the smaller of width and height constraints while preserving tube aspect ratio.

- [ ] **Step 2: Compact the stage around content**

Use a shrink-centered stage holder and larger action buttons so free space does not sit between tubes and controls.

### Task 5: Fix level switching, progression refresh, Collection and responsive grids

**Files:**
- Modify: `scripts/ui/premium_live_hub.gd`
- Modify: `scripts/ui/premium_main_casual.gd`
- Modify: `scripts/ui/premium_home_casual.gd`

**Interfaces:**
- Produces: fresh Choose Game progress on every entry, game tabs on all level browsers, 2/3/4-column responsive level grids, scrollable cross-game Collection, and fuller Home/Settings composition.

- [ ] **Step 1: Refresh Choose Game on entry**

Call `_build()` whenever `surface == "live"`; no polling loop.

- [ ] **Step 2: Inject game tabs into both level browsers**

Add Rescue Rush, Water Sort and Block Puzzle buttons. Each calls `open_game_campaign(game_id)` and visually marks the current game.

- [ ] **Step 3: Make level grids width-driven**

Use 4 columns on wide layouts, 3 on medium layouts and 2 on narrow layouts, calculating each button width from the safe usable width.

- [ ] **Step 4: Replace Collection body with a scrollable UNJAM journey view**

Show combined progress, three per-game cards, achievements, Rescue Garden roster/decorations, and the decoration shop.

- [ ] **Step 5: Use spare Home/Settings height intentionally**

Allow the Home hero to expand, enlarge the main PLAY control, and make Settings control rows taller on normal portrait phones.

### Task 6: Make dark mode affect custom 3D surfaces immediately

**Files:**
- Modify: `scripts/ui/unjam_3d_theme.gd`
- Modify: `scripts/ui/unjam_3d_backdrop.gd`
- Modify: `scripts/ui/premium_surface_manager_static.gd`
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify: `scripts/ui/premium_live_hub_3d.gd`
- Modify: `scripts/ui/ux_shell_casual.gd`
- Modify: `scripts/game/rescue_rush_casual.gd`
- Modify: `scripts/game/water_sort_casual.gd`
- Modify: `scripts/game/block_puzzle_3d.gd`

**Interfaces:**
- Produces: `Unjam3DBackdrop.configure(accent, dark_mode=false)`, dark-aware `Unjam3DTheme.gloss_button(..., dark_mode=false)`, and `apply_theme_mode(dark: bool)` on active game surfaces.

- [ ] **Step 1: Add dark-aware shared 3D helpers**

Secondary buttons/panels get dark surfaces with white text, while game accent colors remain saturated.

- [ ] **Step 2: Propagate theme to active surfaces**

Home and Choose Game build their backdrop/styling from current theme. Secondary surface manager respects the supplied dark flag instead of hard-coding bright mode.

- [ ] **Step 3: Update active gameplay without restart**

On theme toggle, call `active_game.apply_theme_mode(theme_mode == "dark")`; each game owns a behind-UI environment shade.

### Task 7: Verify and build

**Files:**
- Test: `tests/validate_reported_polish_regressions.gd`
- Test: existing viewport/navigation/campaign/visual audit suites

- [ ] **Step 1: Run fast contracts**

Expected: new regression contract and existing fast tests pass with no script errors.

- [ ] **Step 2: Run focused gameplay/campaign tests**

Expected: campaign remains structurally valid and solver-verified; gameplay interaction tests pass.

- [ ] **Step 3: Render screenshots**

Inspect Home, Settings, Levels, Collection, Rescue Rush, Water Sort and Block Puzzle for density, containment and dark-mode effect.

- [ ] **Step 4: Export debug APK**

Expected: Android API 36 debug APK export succeeds and artifact is uploaded.
