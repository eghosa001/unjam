# UNJAM Premium 3D Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the active flat/procedural gameplay presentation with a true lightweight 3D presentation for Water Sort, Rescue Rush, and Block Puzzle while preserving existing game state, input, progression, saves, monetization, and Android performance.

**Architecture:** Keep the existing Control-based game scripts as authoritative state and input. Add a shared `SubViewportContainer` + `SubViewport` + `Node3D` renderer that mirrors logical state into optimized meshes; the existing 2D gameplay controls remain as transparent hit/drop targets so no game-rule rewrite is required. Per-game 3D stages own only rendering and animation.

**Tech Stack:** Godot 4.7.2, GDScript, GL Compatibility renderer, StandardMaterial3D, primitive meshes, SubViewport, Tween.

**Spec:** `docs/superpowers/specs/2026-09-16-premium-3d-overhaul-design.md`

## Global Constraints

- Preserve `gl_compatibility` for desktop and mobile.
- Fixed camera only; no continuous camera motion.
- Existing game scripts remain authoritative for rules/state.
- HUD remains 2D; gameplay objects/boards render in true 3D.
- Mid-range Android performance target; reusable primitive meshes/materials and one directional light.
- No full fluid simulation, reflection probes, heavy post-processing, or physics-driven gameplay.
- Existing 2D controls may remain as near-transparent hit/drop targets until 3D picking is proven equivalent.

---

### Task 1: Add the premium 3D contract test

**Files:**
- Create: `tests/validate_premium_3d.gd`
- Modify: `.github/workflows/godot-ci.yml`

**Interfaces:**
- Consumes: active Water Sort, Rescue Rush, and Block Puzzle scripts/scenes.
- Produces: a CI contract requiring `Premium3DMaterials`, `Premium3DStage`, and all three game-specific stages.

- [ ] Write a failing Godot headless test that loads the shared and game-specific 3D scripts, checks fixed-camera stage APIs, checks material APIs, and checks that the three active game scripts reference their 3D stage adapters.
- [ ] Add `validate_premium_3d` to the fast CI contract list.
- [ ] Open a draft PR and verify CI fails because the new production scripts do not exist yet.

### Task 2: Shared GL-compatible 3D foundation

**Files:**
- Create: `scripts/ui/premium_3d_materials.gd`
- Create: `scripts/ui/premium_3d_stage.gd`

**Interfaces:**
- `Premium3DMaterials.glossy(color: Color) -> StandardMaterial3D`
- `Premium3DMaterials.matte(color: Color) -> StandardMaterial3D`
- `Premium3DMaterials.glass(tint: Color) -> StandardMaterial3D`
- `Premium3DMaterials.liquid(color: Color) -> StandardMaterial3D`
- `Premium3DStage.configure_stage(clear_color: Color, camera_position: Vector3, camera_target: Vector3, ortho_size: float) -> void`
- `Premium3DStage.content_root() -> Node3D`
- `Premium3DStage.clear_content() -> void`
- `Premium3DStage.make_box(size: Vector3, color: Color, glossy := true) -> MeshInstance3D`
- `Premium3DStage.make_cylinder(radius: float, height: float, color: Color, glossy := true) -> MeshInstance3D`

- [ ] Implement a transparent/bright SubViewportContainer, own World3D, fixed orthographic Camera3D, one DirectionalLight3D, WorldEnvironment ambient fill, and content root.
- [ ] Implement reusable StandardMaterial3D helpers with conservative metallic/specular/roughness/transparency settings compatible with GL Compatibility.
- [ ] Keep shadows limited to the single key light and disable expensive effects.

### Task 3: Water Sort 3D presentation

**Files:**
- Create: `scripts/ui/water_sort_3d_stage.gd`
- Modify: `scripts/game/water_sort_ultra_motion.gd`

**Interfaces:**
- `WaterSort3DStage.sync_state(tubes: Array, selected: int) -> void`
- `WaterSort3DStage.animate_pour(source_index: int, target_index: int, source_values: Array, target_values: Array, color_index: int, amount: int, final_tubes: Array) -> void`
- signal `pour_finished(source_index: int, target_index: int)`

- [ ] Build each bottle from lightweight cylinder/rim/glass meshes and four liquid-segment meshes; no fluid simulation.
- [ ] Arrange bottles in the same logical grid as the Control board and use a fixed frontal/elevated camera.
- [ ] Animate source lift, travel, neck-pivot tilt, a narrow 3D liquid stream from the mouth, receiver fill, upright, and return.
- [ ] Override the active Water Sort visual-pour function to use the 3D stage while preserving existing logical transfer, multitasking dictionaries, queued actions, and completion timing.
- [ ] Make 2D tube controls near-transparent rather than removing them, preserving exact touch targets.

### Task 4: Rescue Rush 3D presentation

**Files:**
- Create: `scripts/ui/rescue_rush_3d_stage.gd`
- Modify: `scripts/game/rescue_rush_motion_final.gd`

**Interfaces:**
- `RescueRush3DStage.sync_state(width: int, height: int, pieces: Array, rescue_pos: Vector2i, rescued: bool, accent: Color) -> void`
- `RescueRush3DStage.animate_escape(piece: Dictionary, width: int, height: int) -> void`
- signal `escape_finished`

- [ ] Build a raised board slab, recessed cells, beveled-looking vehicle/arrow pieces, blockers/gates/bombs/keys, and a rescue token from cheap primitive meshes.
- [ ] Use strong color separation and a fixed elevated camera.
- [ ] Override the active escape visual with 3D acceleration/deceleration and settle motion.
- [ ] Preserve `_escape_visual_deadline_msec` so completion cannot cover the final exiting object.
- [ ] Keep 2D board buttons as near-transparent input hit targets.

### Task 5: Block Puzzle 3D presentation

**Files:**
- Create: `scripts/ui/block_puzzle_3d_stage.gd`
- Modify: `scripts/game/block_puzzle_ultra_motion.gd`

**Interfaces:**
- `BlockPuzzle3DStage.sync_state(cells: Array, colors: Array) -> void`
- `BlockPuzzle3DStage.preview_shape(shape: Array, origin: Vector2i, color: Color, valid: bool) -> void`
- `BlockPuzzle3DStage.clear_preview() -> void`

- [ ] Build an 8x8 recessed 3D board and render occupied cells as raised beveled blocks.
- [ ] Add a subtle top highlight layer and contact depth rather than expensive per-block shadows.
- [ ] Mirror state after every existing `render()` call and make only the board-cell drawing transparent; preserve drop targets.
- [ ] Keep the existing high-response drag input path and add 3D placement preview hooks without increasing touch latency.

### Task 6: Bright premium integration and verification

**Files:**
- Modify: `scripts/game/water_sort_casual.gd`
- Modify: `scripts/game/rescue_rush_casual.gd`
- Modify: `scripts/game/block_puzzle_premium_layout.gd` only where needed for bright stage framing
- Modify: `tests/validate_visual_quality_contract.gd` if necessary to include the 3D foundation contract

**Interfaces:** Existing public game interfaces unchanged.

- [ ] Make gameplay stage surrounds bright/soft enough to match the approved casual-premium direction without reducing object contrast.
- [ ] Ensure HUD typography and buttons remain readable and do not overlap the 3D viewport.
- [ ] Run the draft PR CI: import, headless contracts, gameplay contracts, boot smoke, visual screenshot audit, APK export, and AAB export.
- [ ] Inspect visual-audit artifacts and CI logs; fix any script errors, visual regressions, or export failures before marking the PR ready.
