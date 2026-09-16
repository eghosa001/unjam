# UNJAM Production Quality Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate UNJAM's motion/presentation systems, raise the three games' procedural visual and interaction quality, improve accessibility/performance, and harden monetization/release behavior without breaking existing campaign logic.

**Architecture:** Add one shared motion vocabulary and expand the existing feedback manager into semantic/cached feedback. Migrate only active game paths first, reduce presentation overlap incrementally, and keep external monetization credentials/provider setup as explicit release gates rather than inventing values.

**Tech Stack:** Godot 4.x, GDScript, GitHub Actions, Android export/Play Billing bridge.

**Spec:** `docs/superpowers/specs/2026-09-16-production-quality-overhaul-design.md`

## Global Constraints
- Preserve existing campaign generation and gameplay semantics.
- Never animate whole-screen roots for gameplay impact.
- Keep GL Compatibility rendering and portrait-first layout.
- Paid entitlements remain fail-closed until verification succeeds.
- Do not invent AdMob IDs, Play credentials, signing material, secrets, or verification endpoints.
- Reduced Motion preserves gameplay meaning; Fast Animation reduces latency without skipping state transitions.
- Prefer migration/consolidation over another parallel `premium/polished/ultra` layer.

---

### Task 1: Shared Motion Vocabulary and Preferences

**Files:**
- Create: `scripts/ui/motion_system.gd`
- Modify: `scripts/ui/motion_director.gd`
- Modify: `scripts/core/robust_save_manager.gd`
- Test: `tests/test_motion_system.gd`

**Interfaces:**
- Produces: `MotionSystem.duration(kind: StringName) -> float`, `MotionSystem.reduced() -> bool`, `MotionSystem.fast() -> bool`, `MotionSystem.fade_in(control: CanvasItem)`, `MotionSystem.pop(control: Control, strength := 1.0)`, `MotionSystem.local_punch(control: Control, strength := 1.0)`.
- Consumes: `SaveManager.data` settings.

- [ ] **Step 1: Write failing tests** asserting default/fast/reduced duration ordering, no root geometry mutation for `fade_in`, and save defaults for `reduce_motion`/`fast_animation`.
- [ ] **Step 2: Run the motion test** and confirm it fails before the implementation exists.
- [ ] **Step 3: Implement `motion_system.gd`** with named timings (`micro`, `press`, `travel`, `settle`, `celebrate`, `screen`) and a strict easing vocabulary: cubic-out for entrances/travel, sine-in-out for continuous liquid movement, back-out only for pop confirmation.
- [ ] **Step 4: Add settings defaults/migration** in `robust_save_manager.gd` for `reduce_motion=false`, `fast_animation=false`.
- [ ] **Step 5: Update `motion_director.gd`** to use the shared `screen` duration and fade helper; preserve geometry-fixed screen roots.
- [ ] **Step 6: Run the motion test plus existing premium UX/motion tests** and confirm green.
- [ ] **Step 7: Commit** `feat: centralize motion timing and accessibility preferences`.

### Task 2: Semantic Cached Feedback

**Files:**
- Modify: `scripts/systems/feedback_manager.gd`
- Test: `tests/test_feedback_manager.gd`

**Interfaces:**
- Produces: `nav()`, `lift()`, `drop()`, `pour_start()`, `pour_land()`, `invalid()`, `line_clear(lines := 1)`, `combo(chain := 1)`, `complete(kind := "level")` while preserving existing `tap/blocked/escape/effect/rescue` compatibility.

- [ ] **Step 1: Write failing API tests** for the semantic methods and a cache-size invariant after repeated identical effects.
- [ ] **Step 2: Run the feedback test** and confirm failure.
- [ ] **Step 3: Add a tone cache** keyed by frequency/duration/volume profile so repeated effects reuse `AudioStreamWAV` objects.
- [ ] **Step 4: Implement semantic methods** with restrained vibration: invalid/error, multi-line clear, rescue/level completion; ordinary lift/drop/pour remain sound-only.
- [ ] **Step 5: Make music/sound/vibration settings remain backward compatible.**
- [ ] **Step 6: Run feedback and existing headless tests**.
- [ ] **Step 7: Commit** `feat: add cached semantic game feedback`.

### Task 3: Adaptive Procedural Backdrop and Material Helpers

**Files:**
- Modify: `scripts/ui/premium_backdrop.gd`
- Modify: `scripts/systems/robust_premium_visuals.gd`
- Create: `scripts/ui/procedural_materials.gd`
- Test: `tests/test_visual_quality_contract.gd`

**Interfaces:**
- Produces material helpers for `shade(base, vertical_t)`, contact-shadow colors, liquid/glass highlight colors, and quality-scaled particle counts.

- [ ] **Step 1: Write failing visual-contract tests** that reduced motion freezes decorative drift and low quality uses fewer decorative particles than high quality.
- [ ] **Step 2: Run and confirm failure.**
- [ ] **Step 3: Implement procedural material helpers** without GPU-only shaders so GL Compatibility remains supported.
- [ ] **Step 4: Update backdrop** to respect reduced motion and quality tiers, keep slow depth fields, and avoid redrawing decorative motion unnecessarily when reduced motion is enabled.
- [ ] **Step 5: Run visual and screenshot smoke tests.**
- [ ] **Step 6: Commit** `feat: improve adaptive procedural materials and backdrop`.

### Task 4: Water Sort Motion and Visual Pass

**Files:**
- Modify: `scripts/game/water_sort_reference_motion.gd`
- Modify: `scripts/game/water_sort_ultra_motion.gd`
- Modify: `scripts/ui/tube_button.gd` or the active tube-control script discovered by reference tracing
- Test: existing water-sort motion tests plus `tests/test_water_sort_premium_motion.gd`

**Interfaces:**
- Consumes: `MotionSystem`, `FeedbackManager`, `ProceduralMaterials`.

- [ ] **Step 1: Add failing tests** for stream origin near the lip, fast-animation duration reduction, reduced-motion suppression of nonessential lift/bounce, and legal concurrent selection while another bottle is returning when game state permits it.
- [ ] **Step 2: Run and confirm targeted failures.**
- [ ] **Step 3: Route phase timings** (lift/travel/tip/pour/return) through `MotionSystem` and preserve state ordering.
- [ ] **Step 4: Improve tube/liquid drawing** with top-light/bottom-depth and restrained moving specular cues.
- [ ] **Step 5: Add semantic feedback** at lift, pour start, pour landing, invalid selection and completion.
- [ ] **Step 6: Ensure interaction locks are per-source/per-target rather than global where safe.**
- [ ] **Step 7: Run water-sort gameplay/motion tests and campaign level tests.**
- [ ] **Step 8: Commit** `feat: polish water sort motion materials and input flow`.

### Task 5: Block Puzzle Drag, Placement and Clear Pass

**Files:**
- Modify: `scripts/game/block_puzzle_polished.gd`
- Modify: `scripts/game/block_puzzle_premium_layout.gd`
- Modify: `scripts/game/block_puzzle_ultra_motion.gd`
- Modify: `scripts/ui/block_drag_preview.gd`
- Modify: `scripts/ui/block_piece_button.gd`
- Test: existing block motion tests plus `tests/test_block_puzzle_premium_motion.gd`

**Interfaces:**
- Consumes: `MotionSystem`, `FeedbackManager`, `ProceduralMaterials`.

- [ ] **Step 1: Add failing tests** for stable root geometry during drag/clear, smoothed preview tracking, local landing punch, combo feedback scaling, and animated tray replacement without blocking the next legal drag longer than the fast-mode bound.
- [ ] **Step 2: Run and confirm failures.**
- [ ] **Step 3: Upgrade drag preview** with bounded smoothing and contact shadow while preserving accurate placement coordinates.
- [ ] **Step 4: Add placement anticipation/settle** and board-local punch only.
- [ ] **Step 5: Add traveling line-clear highlight and lightweight procedural debris** scaled by quality tier.
- [ ] **Step 6: Animate tray reflow/replacement** with short stagger and semantic audio.
- [ ] **Step 7: Scale combo presentation by chain count without global screen shake.**
- [ ] **Step 8: Run block puzzle gameplay, motion and 200-level interaction tests.**
- [ ] **Step 9: Commit** `feat: raise block puzzle drag clear and combo quality`.

### Task 6: Rescue Rush Motion and Completion Pass

**Files:**
- Modify: `scripts/game/rescue_rush_motion_final.gd`
- Modify: `scripts/game/rescue_rush_premium.gd`
- Modify: `scripts/ui/rescue_result_guard.gd`
- Test: existing Rescue Rush completion/motion tests plus `tests/test_rescue_rush_premium_motion.gd`

**Interfaces:**
- Consumes: `MotionSystem`, `FeedbackManager`.

- [ ] **Step 1: Add failing tests** for final-piece clearance before result overlay, reduced-motion correctness, fast-mode completion bound, blocked feedback, and no full-screen root transform mutation.
- [ ] **Step 2: Run and confirm failures.**
- [ ] **Step 3: Route move/exit timings through MotionSystem** and add small local anticipation/follow-through.
- [ ] **Step 4: Strengthen result guard** so completion is emitted only after final visual exit/settle resolves.
- [ ] **Step 5: Add board-local rescue/combo celebration** and semantic feedback.
- [ ] **Step 6: Run Rescue Rush tests plus early-level campaign playability tests.**
- [ ] **Step 7: Commit** `feat: polish rescue rush motion and completion sequencing`.

### Task 7: Shell Consolidation, Safe Area, Accessibility and Performance

**Files:**
- Modify: `scenes/Main.tscn`
- Modify: `scripts/ui/premium_main.gd`
- Modify: `scripts/ui/motion_director.gd`
- Modify: presentation patch scripts only where needed to remove duplicate ownership
- Create: `scripts/ui/device_fit.gd`
- Test: `tests/test_shell_contract.gd`, visual audit workflow/scripts

**Interfaces:**
- Produces: `DeviceFit.safe_margins() -> Vector4`, shell transition signal(s), stable Android Back priority.

- [ ] **Step 1: Write shell tests** for safe margins, modal/game/surface Back priority, no duplicate transition mutation, minimum touch targets and multiple portrait viewports.
- [ ] **Step 2: Run and confirm targeted failures.**
- [ ] **Step 3: Add safe-area helper** with zero-safe fallback when platform cutout data is unavailable.
- [ ] **Step 4: Replace high-frequency transition polling** with explicit surface-change notification where the current main controller exposes a single change point; otherwise use low-cost signature polling only as compatibility fallback.
- [ ] **Step 5: Remove duplicate screen transition/background mutation responsibilities** from secondary patch controllers while leaving unrelated layout behavior intact.
- [ ] **Step 6: Preserve focusability for actionable controls** instead of globally suppressing focus.
- [ ] **Step 7: Expand visual audit** to at least 720×1600, 1080×1920 and 1080×2400 portrait captures.
- [ ] **Step 8: Run shell, visual and full gameplay suites.**
- [ ] **Step 9: Commit** `refactor: consolidate shell presentation and device fit`.

### Task 8: Monetization State Machine and Release Hardening

**Files:**
- Modify: `scripts/systems/android_monetization_bridge.gd`
- Modify: `scripts/systems/store_manager.gd`
- Modify: `scripts/systems/purchase_verifier.gd`
- Modify: `.github/workflows/godot-ci.yml`
- Modify: `RELEASE_CHECKLIST.md`
- Test: `tests/test_monetization_state_machine.gd`

**Interfaces:**
- Produces normalized purchase states `idle/requested/pending/verifying/purchased/cancelled/failed`, product metadata callback/signal with localized price fields, restore completion only after all verification work completes.

- [ ] **Step 1: Add failing state-machine tests** for pending purchase, cancellation, verified purchase, failed verification, interrupted restore and localized product metadata propagation.
- [ ] **Step 2: Run and confirm failures.**
- [ ] **Step 3: Normalize bridge callbacks** into explicit states and ensure pending does not leave the UI permanently stuck.
- [ ] **Step 4: Implement product-query propagation** when the installed Play Billing plugin provides product details; keep graceful unavailable behavior when the plugin is absent.
- [ ] **Step 5: Make restore await/reconcile all verification results** before success emission.
- [ ] **Step 6: Keep entitlement grants fail-closed** when verification endpoint/configuration is required but missing.
- [ ] **Step 7: Harden CI** by removing failure-masking SDK installation, upgrading deprecated actions where compatible, and adding explicit production-config checks without embedding secrets.
- [ ] **Step 8: Update release checklist** with Play App Signing, production IDs, Data Safety, target audience, pre-launch report, crash/ANR monitoring and version-code requirements.
- [ ] **Step 9: Run monetization tests and complete Godot CI suite.**
- [ ] **Step 10: Commit** `fix: harden monetization and production release gates`.

### Task 9: Dead-Code/Reference Cleanup and Final Verification

**Files:**
- Delete only files proven unreferenced by scene/autoload/script/reference search.
- Modify documentation with final active architecture map.

- [ ] **Step 1: Generate/reference-search all `.gd` files** against scenes, autoloads, preload/load/extends paths and dynamic class references.
- [ ] **Step 2: Produce a candidate list and exclude anything referenced dynamically or by tests/tools.**
- [ ] **Step 3: Delete only high-confidence unreachable files** such as legacy presentation/game layers that have no active or test references.
- [ ] **Step 4: Run import/parse, all unit/gameplay/motion tests, 10,000-level generation validation, first-200 interaction tests, visual audit and Android debug AAB export.**
- [ ] **Step 5: Inspect logs for parse errors, invalid calls, ObjectDB leak warnings and export warnings.**
- [ ] **Step 6: Compare branch to `main` and document remaining external blockers (real SDK packages/IDs/verification endpoint/signing credentials/device-only QA).**
- [ ] **Step 7: Commit** `chore: remove obsolete code and finalize production audit`.
