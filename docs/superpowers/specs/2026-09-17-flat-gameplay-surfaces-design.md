# Flat Gameplay Surfaces with 3D Effects — Design

## Goal

All three UNJAM games must present their playable puzzle area as a flat, front-facing surface. Depth should come from materials, highlights, shadows, bevels, particles, motion, and non-interactive scenery rather than perspective-rendered gameplay geometry.

## Shared visual invariant

- The authoritative puzzle board/stage remains a 2D `Control` hierarchy (`PanelContainer`, `GridContainer`, etc.).
- Gameplay coordinates must read directly from the screen: no tilted board, no perspective camera changing cell alignment, and no perspective transform used for input or puzzle state.
- Decorative 3D scenery may remain behind the gameplay layer, must ignore input, and must never determine gameplay coordinates.
- 3D effects are encouraged for bevels, gloss, rim light, shadows, squash/stretch, particles, trails, liquid motion, and celebratory effects.
- Reduced Motion continues to suppress nonessential entrance/pulse animation.

## Rescue Rush

Rescue Rush should read like a premium flat board puzzle, not like miniature 3D objects placed in a rendered scene.

- Keep the current front-facing grid and responsive board sizing.
- Replace per-piece `SubViewport`/mesh rendering with `PremiumPieceButton` top-down pieces.
- Preserve chunky depth using bevels, edge highlights, shadows, glossy caps, directional arrows, press/pop motion, trails, and completion particles.
- Escape ghosts use the same flat piece renderer so the final piece visually leaves the board before completion.
- The chick/rescue character may remain dimensional as a character/effect, but stays anchored to the flat board and does not turn the board into a perspective scene.
- Remove Rescue-specific 3D piece code once no production path references it.

## Water Sort

- Keep the playable bottle layout on the existing flat `GridContainer` stage.
- Bottles may retain dimensional glass/liquid rendering because their positions remain front-facing and screen-aligned.
- Pouring must originate at the bottle rim and land at the target rim.
- Decorative 3D environment remains background-only and input-transparent.

## Block Puzzle

- Keep the existing flat orthographic grid and drag tray.
- Cubes may retain bevel/extrusion/shadow effects, but placement remains on the flat 2D cell grid.
- Drag previews must map directly to 2D target cells without perspective distortion.
- Decorative 3D environment remains background-only and input-transparent.

## Performance and lifecycle

- No always-rendering 3D viewport is permitted for normal Rescue Rush pieces.
- Existing one-shot/sleeping 3D rendering rules remain for non-interactive scenery and Water Sort bottle effects.
- Navigation and completion coroutines remain cancellation-safe when the game leaves the scene tree.

## Regression protection

Add a production contract that checks:

1. Rescue Rush production board pieces use `PremiumPieceButton` and do not reference `rescue_piece_3d_button.gd`.
2. Rescue, Water Sort, and Block Puzzle authoritative playfields are 2D grid/control surfaces.
3. `Unjam3DGameplayStage` remains decorative and `MOUSE_FILTER_IGNORE`.
4. The deleted Rescue 3D piece renderer is not referenced by active code or CI.
5. Existing gameplay, motion, viewport-fit, visual-audit, APK, and AAB checks remain green.
