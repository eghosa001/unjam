# Vibrant Full-App Visual Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved vibrant premium reference quality to every major UNJAM screen while preserving performance, gameplay behavior, reduced-motion support, and GL Compatibility.

**Architecture:** Extend the existing shared visual system (`PremiumDesignSystem`, `ProceduralMaterials`, `PremiumBackdrop`) and then migrate each active screen family to it. Keep gameplay rules unchanged; only presentation, layout density, motion polish, and reusable visual primitives change. Verification is test-first and screenshot-driven.

**Tech Stack:** Godot 4.7.2, GDScript, GL Compatibility renderer, GitHub Actions visual audit, procedural 2.5D UI rendering.

**Spec:** `docs/superpowers/specs/2026-09-16-vibrant-full-app-visual-overhaul-design.md`

## Global Constraints
- Keep GL Compatibility.
- Preserve existing gameplay semantics and save compatibility.
- Respect MotionSystem reduced-motion behavior.
- Maintain quality-scaled decorative work.
- Avoid large new raster-art dependencies in the core pass.
- Target the current 1080x1920 visual-audit viewport and existing device-fit system.

---

### Task 1: Expand the visual regression contract

**Files:**
- Modify: `tests/validate_vibrant_ui_contract.gd`
- Modify: `.github/workflows/godot-ci.yml`

**Interfaces:**
- Consumes: current UI source files and visual design helpers.
- Produces: source-level checks that enforce bright palettes, dense layout markers, shared vibrant surfaces, and expanded visual-audit coverage.

- [ ] **Step 1: Write failing checks** for all major screen families and screenshot outputs.
- [ ] **Step 2: Run the contract and confirm it fails** because the remaining screens have not adopted the new visual system.
- [ ] **Step 3: Add the contract to Fast quality contracts and expand screenshot assertions.**
- [ ] **Step 4: Re-run after later tasks until it passes.**
- [ ] **Step 5: Commit.**

### Task 2: Finish shared vibrant primitives

**Files:**
- Modify: `scripts/ui/premium_design_system.gd`
- Modify: `scripts/ui/procedural_materials.gd`
- Modify: `scripts/ui/premium_backdrop.gd`

**Interfaces:**
- Consumes: game id, theme mode, quality scale, reduced-motion setting.
- Produces: `game_card_gradient(game_id)`, vivid canvas/surface colors, game-specific accent palettes, glossy material helpers, and scalable decorative backdrops.

- [ ] **Step 1: Write failing helper assertions** in the visual contract for palette saturation and distinct game gradients.
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement vivid helpers and lightweight scenery primitives.**
- [ ] **Step 4: Verify helper and visual-quality contracts pass.**
- [ ] **Step 5: Commit.**

### Task 3: Home, launcher, and game chooser

**Files:**
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify: `scripts/ui/game_select_tile.gd`
- Modify: `scripts/ui/game_showcase_art.gd`
- Modify: `scripts/ui/unjam_logo.gd`

**Interfaces:**
- Consumes: shared visual primitives and progress state.
- Produces: near-edge-to-edge home composition, large Play CTA, saturated game cards, fuller hero art, compact navigation.

- [ ] **Step 1: Add/strengthen failing density and palette checks.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement the approved reference composition without changing navigation behavior.**
- [ ] **Step 4: Render home dark/light screenshots and inspect dead space/readability.**
- [ ] **Step 5: Commit.**

### Task 4: Level browser, live, daily, collection, settings, and shop

**Files:**
- Modify: `scripts/ui/premium_home_overhaul.gd`
- Modify: `scripts/ui/main.gd`
- Modify: `scripts/ui/level_browser_polish.gd`
- Modify: `scripts/ui/monetization_hub.gd`

**Interfaces:**
- Consumes: shared visual primitives, current save/progress/monetization state.
- Produces: colorful dense cards, larger typography, brighter headers, vivid selected/locked states, improved empty states, consistent navigation.

- [ ] **Step 1: Add failing checks for each shell surface using shared vibrant helpers.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Apply dense responsive layout and game-colored card treatments.**
- [ ] **Step 4: Render level/settings/collection/live screenshots in both themes.**
- [ ] **Step 5: Commit.**

### Task 5: Rescue Rush gameplay presentation

**Files:**
- Modify: active Rescue Rush gameplay scripts under `scripts/` and `scripts/ui/` referenced by `scenes/Game.tscn`.
- Modify: `scripts/ui/premium_piece_button.gd`
- Modify: `scripts/ui/rescue_token.gd`

**Interfaces:**
- Consumes: Rescue Rush game state and shared visual primitives.
- Produces: vivid board frame, larger HUD, colorful objectives, brighter pieces, richer environmental framing, non-blocking motion.

- [ ] **Step 1: Add failing source/visual checks for shared vibrant surfaces.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement presentation-only changes.**
- [ ] **Step 4: Run gameplay interaction/progression tests and capture screenshot.**
- [ ] **Step 5: Commit.**

### Task 6: Water Sort gameplay presentation

**Files:**
- Modify: active Water Sort gameplay and bottle/tube drawing scripts.

**Interfaces:**
- Consumes: water-sort state and shared visual primitives.
- Produces: bright scenic canvas, richer tube glass, stronger liquid saturation, corrected top-pour visual path, fuller HUD and controls.

- [ ] **Step 1: Add failing presentation checks.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement visual changes without serializing user input during decorative pour motion.**
- [ ] **Step 4: Run solvability/gameplay tests and capture screenshot.**
- [ ] **Step 5: Commit.**

### Task 7: Block Puzzle gameplay presentation

**Files:**
- Modify: `scripts/ui/block_cell_button.gd`
- Modify: `scripts/ui/block_piece_button.gd`
- Modify: `scripts/ui/block_drag_preview.gd`
- Modify: active Block Puzzle scene/controller scripts.

**Interfaces:**
- Consumes: block-puzzle state and shared visual primitives.
- Produces: saturated blocks, stronger board depth, smooth drag/land/clear motion, clearer target footprint, fuller HUD.

- [ ] **Step 1: Add failing presentation checks.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Implement visual/motion changes.**
- [ ] **Step 4: Run gameplay interaction tests and capture screenshot.**
- [ ] **Step 5: Commit.**

### Task 8: Tutorials, result overlays, modals, and cross-screen consistency

**Files:**
- Modify: tutorial/result/modal scripts identified by the visual-audit capture harness.
- Modify: `tests/capture_visual_audit.gd`

**Interfaces:**
- Consumes: existing tutorial/result state and shared visual primitives.
- Produces: vivid full-screen onboarding and completion surfaces with large readable copy and consistent CTAs.

- [ ] **Step 1: Expand visual-audit captures for tutorials/results in representative themes.**
- [ ] **Step 2: Confirm missing/inconsistent surfaces fail the contract.**
- [ ] **Step 3: Apply shared vibrant styling.**
- [ ] **Step 4: Capture and inspect all overlays.**
- [ ] **Step 5: Commit.**

### Task 9: Full verification and quality comparison

**Files:**
- No production changes unless failures reveal a regression.

**Interfaces:**
- Consumes: entire branch.
- Produces: passing Godot import, quality contracts, gameplay smoke tests, Android debug export, and complete visual-audit artifact.

- [ ] **Step 1: Run Godot import and reject parse/script errors.**
- [ ] **Step 2: Run fast quality contracts including vibrant UI contract.**
- [ ] **Step 3: Run gameplay smoke contracts.**
- [ ] **Step 4: Render the complete visual-audit screenshot set and compare every major surface against the approved reference standard.**
- [ ] **Step 5: Run Android APK/AAB export smoke tests.**
- [ ] **Step 6: Only after all fresh evidence is green, mark the overhaul ready for review.**
