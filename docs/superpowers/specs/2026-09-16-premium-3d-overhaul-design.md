# UNJAM Premium 3D Overhaul Design

## Goal
Transform UNJAM from predominantly procedural/flat Godot visuals into a premium, bright, casual 3D presentation while preserving fast mobile performance and existing gameplay logic.

## Approved Direction
- Visual style: bright casual premium.
- Rendering approach: hybrid true 3D gameplay presentation plus lightweight 2D/SVG for icons and HUD where 3D adds no value.
- Performance target: balanced; premium appearance on mid-range Android devices without desktop-class rendering cost.
- Camera: fixed premium camera. Gameplay remains readable and stable; no continuous cinematic camera movement.
- Renderer compatibility: preserve Godot GL Compatibility/mobile reach unless profiling proves a targeted renderer change is necessary.

## Architecture
Introduce a shared 3D presentation layer that is independent of game rules. Existing logic remains authoritative for state, moves, scoring, progression, monetization, and persistence. Each game receives a presentation adapter that maps existing logical objects to optimized 3D nodes and animations.

The system will use low-poly/beveled meshes, reusable materials, controlled lighting, pooled particles, limited real-time shadows, and lightweight shaders. Expensive screen-space effects, multiple dynamic lights, real-time reflections, and unnecessary physics simulation are excluded.

## Shared 3D Presentation System
Create a reusable visual stack for all three games:
- Fixed orthographic/perspective camera presets with per-game framing.
- One dominant key light and low-cost ambient/fill lighting.
- Shared material palette for glossy plastic, glass, liquid, road/board surfaces, metallic accents, and UI depth.
- Quality tiers controlling shadows, particles, shader complexity, and anti-aliasing.
- Object pooling for transient effects.
- Motion helpers for lift, snap, squash, bounce, tilt, settle, exit, and celebration sequences.
- 3D-to-2D input mapping so current touch behavior remains responsive.

## Water Sort
### Visuals
- Replace flat/procedural bottle drawings with true 3D bottle meshes.
- Bottles use lightweight translucent glass materials with visible wall thickness/highlights.
- Liquid is represented as stacked volume segments or efficient clipped meshes with a lightweight shader, not a full fluid simulation.
- Use subtle contact shadows beneath bottles.

### Motion
- Selected bottle lifts slightly toward the camera/world-up direction.
- Pouring bottle rotates around a pivot near the bottle neck.
- Liquid stream originates from the bottle mouth and terminates inside the target opening.
- Pour timing is synchronized to logical transfer completion.
- Bottle return uses eased settle motion without blocking selection of unrelated valid actions where current rules permit multitasking.

### Performance
- No ray-marched fluid.
- No real-time reflection probes per bottle.
- Shared bottle mesh and materials.
- Liquid geometry updates only when state changes.

## Rescue Rush
### Visuals
- Replace flat arrows/vehicles/obstacles with optimized beveled 3D models.
- Fixed elevated/isometric-like camera for clear board readability.
- Road/board receives subtle depth, edge bevels, and contact shadows.
- Strong color separation remains for gameplay readability.

### Motion
- Movement uses acceleration/deceleration curves rather than linear sliding.
- Small suspension/body settle gives objects weight without physics cost.
- Exit objects fully clear the play area before completion overlays or celebrations appear.
- Collision/blocked feedback uses short positional recoil and controlled particles rather than screen flashes.

## Block Puzzle
### Visuals
- Replace flat blocks with beveled 3D block pieces.
- Board becomes a recessed 3D surface with visible cell depth.
- Dragged pieces lift above the board and cast a controlled contact shadow.
- Materials use subtle highlight variation while keeping shape/color readability.

### Motion
- Finger tracking uses smoothed interpolation with low latency.
- Placement preview is stable and readable.
- Valid placement uses snap + short compression/settle animation.
- Line/region clears use staged depth/pop/dissolve effects and pooled particles.
- Invalid placement returns smoothly without harsh flashes.

## UI and Menus
- Keep HUD controls primarily 2D for clarity and performance.
- Use dimensional cards/buttons via layered materials, subtle shadows, gradients, and occasional 3D decorative elements.
- Typography remains large and readable.
- Avoid excessive rounded-card stacking or high-contrast dark presentation.
- Maintain bright premium casual identity across home, selection, settings, win/lose overlays, and game screens.

## Performance Budget
- Target smooth gameplay on mid-range Android devices.
- Prefer 60 FPS where device capability permits; avoid frame-time spikes during clears, pours, and celebrations.
- Limit dynamic shadow-casting lights to the minimum practical count.
- Reuse meshes/materials and batch repeated objects where possible.
- Pool particles/effects.
- Disable or reduce expensive effects under lower quality tiers.
- Keep GL Compatibility support unless measured profiling demonstrates a safe alternative.

## Compatibility and Gameplay Safety
- Existing game rules, level data, saves, monetization, analytics, privacy, and progression behavior must not change unless required to wire presentation events.
- Presentation code must not become the source of truth for game state.
- Touch targets and back navigation must remain functional during animations.
- Animations must be interruptible or non-blocking where gameplay requires rapid input.

## Testing
- Add automated tests for presentation-state synchronization and regression-sensitive timing rules.
- Add scene smoke tests for all three games.
- Validate that completion overlays do not appear before exit animations complete.
- Validate Water Sort stream origin at the bottle mouth and transfer synchronization.
- Validate Block Puzzle drag/snap responsiveness.
- Profile representative low-, mid-, and high-complexity levels.
- Run Godot headless tests plus Android export/build checks before merging.

## Out of Scope
- Photorealistic rendering.
- Full fluid dynamics.
- Heavy post-processing stacks.
- Continuous dynamic camera movement.
- Rewriting game logic that does not need to change for presentation integration.
