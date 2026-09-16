# UNJAM Premium Visual System Overhaul

Date: 2026-09-16
Branch: `feature/premium-visual-overhaul`

## Objective

Raise UNJAM's presentation from a polished functional Godot UI to a premium casual-puzzle visual standard comparable in depth, clarity, cohesion, motion quality, and screen composition to the approved reference direction, while preserving fast Android performance and existing gameplay behavior.

The approved visual direction is a bright, dimensional 2.5D casual-game style with strong depth cues, large readable typography, distinct identity for each game mode, richer environments, tactile controls, layered materials, and smooth responsive motion.

## Current Architecture Observations

UNJAM already has a useful foundation for this work. The project has separate scenes for Rescue Rush, Water Sort, Block Puzzle and the main launcher, plus a reusable UI layer under `scripts/ui`. Existing systems include `PremiumDesignSystem`, `PremiumBackdrop`, `GameSelectTile`, `GameShowcaseArt`, `MotionSystem`, `MotionDirector`, block-specific UI components, and a premium home implementation.

The current premium system is still dominated by flat `StyleBoxFlat` surfaces, modest shadows, card-style layout composition, and procedural presentation. The home screen is built around a large hero panel and game cards rather than a visually integrated game-world composition. This explains why the current build can look polished but still fall short of the approved reference's tactile 2.5D quality.

## Design Strategy

### 1. Shared premium visual language

Extend the existing design system instead of replacing it wholesale. Preserve the current accent-per-game structure and accessibility behavior, but add reusable premium primitives for:

- multi-layer panels with highlight, bevel, body and drop-shadow layers
- raised and recessed surfaces
- glossy primary buttons
- compact icon buttons
- pill counters and status chips
- premium HUD strips
- stone, glass, toy-plastic and metallic material presets
- soft ambient shadows and controlled rim highlights
- consistent type hierarchy with larger minimum sizes

This keeps visual quality coherent across Home, Game Selection, Rescue Rush, Water Sort and Block Puzzle.

### 2. Home screen composition

Rebuild the launcher around a single strong visual hierarchy:

1. top progression/status row
2. large UNJAM identity treatment
3. mascot / puzzle-world hero scene
4. oversized primary PLAY action
5. compact three-game selector
6. bottom navigation

The existing hero-card look should be reduced. The screen should feel like a game world with UI layered over it, not a dashboard made of cards.

The backdrop should include depth-separated scenery layers and restrained ambient motion. Decorative elements must remain lightweight and stop under Reduced Motion.

### 3. Game Selection screen

Upgrade `GameSelectTile` from flat card components to thick, tactile, illustrated game panels. Each tile should communicate game identity at a glance:

- Rescue Rush: lush green/stone environment, directional arrow pieces, rescue mascot
- Water Sort: translucent glass vessels, colorful liquid, splash/light highlights
- Block Puzzle: chunky toy-like pieces on a warm recessed play surface

Cards should have stronger depth, oversized titles, concise descriptions, progress/star information and a clear directional action affordance.

### 4. Rescue Rush gameplay

Keep the puzzle rules intact. Rebuild only presentation and interaction feedback.

The board becomes a recessed playfield framed by dimensional stone/foliage treatment. Arrow blocks gain bevel layers, surface highlights, deeper contact shadows and stronger color separation. Obstacles use metallic/stone material treatment. The rescue character gets clearer prominence and small idle feedback.

The HUD becomes a compact premium top strip with clearly separated Moves, Rescue and Chain sections. Undo, Hint and Restart become large tactile bottom controls.

The completion sequence must not trigger until the last moving arrow has fully cleared the playfield and its exit animation has finished.

### 5. Water Sort gameplay

Preserve current concurrent interaction goals. Upgrade bottle rendering to a layered 2.5D glass treatment with:

- outer glass rim
- inner shadow/refraction cue
- liquid body
- liquid top surface
- specular highlight
- contact shadow

Pour animation must originate from the bottle mouth rather than the center. The liquid stream should visually connect source mouth to destination opening. Users should still be able to initiate other valid interactions during active pours where the game rules permit it.

### 6. Block Puzzle gameplay

Keep existing drag/drop and magnetic placement logic. Increase tactile feedback through:

- raised piece rendering
- contact shadows
- drag elevation
- mild scale/tilt feedback
- stronger valid placement preview
- soft snap compression on drop
- line-clear particles and brief board response

Motion must stay responsive and must not introduce extra input latency.

## Rendering Approach

The implementation should use a hybrid 2D/2.5D approach rather than converting the whole app to real-time 3D.

Use Godot Controls and CanvasItem drawing for most UI, with layered 2D primitives, gradients, highlights and textures where appropriate. Small selective 3D or shader-backed effects may be used only when they provide clear visual gain without harming Android performance.

The goal is the look of 3D casual-game UI without the memory, fill-rate and scene complexity cost of making every interface element a 3D mesh.

## Motion System

Motion should use the current Reduced Motion gate and existing motion infrastructure. Standardize around a small motion vocabulary:

- press: fast downscale + shadow compression
- release: short spring return
- card entry: 180–260 ms fade/translate
- major page transition: 220–320 ms
- drag elevation: immediate, under 100 ms
- placement snap: 120–180 ms
- reward/completion emphasis: short staged sequence under 800 ms

No full-screen flashes should be used for ordinary navigation. Edge flashes and abrupt white transitions should be eliminated.

## Typography and Scale

Typography should be enlarged globally for mobile readability. Primary headings and CTAs should be visually dominant. Small helper text should be minimized.

Target hierarchy:

- screen/logo title: 40–64 px equivalent
- game title: 30–46 px
- major CTA: 24–32 px
- HUD values: 20–28 px
- body/secondary text: 17–22 px
- navigation labels: 15–18 px minimum

Exact values remain adaptive through `DeviceFit` and viewport scaling.

## Performance Constraints

The visual upgrade must not regress input responsiveness or mobile frame stability.

Rules:

- decorative layers must be batched or inexpensive
- avoid large transparent overdraw stacks
- cap active particles
- reuse draw components and style resources where practical
- avoid per-frame allocations in drawing or motion loops
- stop decorative processing when Reduced Motion is enabled
- preserve existing gameplay update cadence
- benchmark representative Android viewport sizes

## Accessibility

Preserve Reduced Motion behavior and existing theme/accessibility settings. Maintain strong contrast for text and controls. Do not encode gameplay state by color alone where an icon, shape or label can also communicate it.

## Testing

The implementation should add or update automated checks for:

- scene boot/load without script errors
- home layout at common mobile aspect ratios
- navigation without edge flashes or stuck transitions
- Rescue Rush completion ordering
- Water Sort stream origin and interaction concurrency
- Block Puzzle drag/drop responsiveness
- Reduced Motion disabling decorative loops
- touch target minimum sizes
- no UI overlap at target phone resolutions
- frame-time and FPS regression gates where practical

Manual visual QA should capture Home, Game Selection, Rescue Rush, Water Sort and Block Puzzle on at least one tall Android viewport and compare them against the approved premium direction.

## Implementation Order

1. Extend shared premium design primitives.
2. Rebuild Home visual hierarchy.
3. Upgrade Game Selection tiles.
4. Upgrade Rescue Rush board/HUD and fix completion timing.
5. Upgrade Water Sort bottle/pour rendering.
6. Upgrade Block Puzzle rendering and drag feedback.
7. Unify transitions and remove flashes.
8. Run automated and visual QA, then tune performance.

## Success Criteria

The pass is complete when:

- Home no longer reads as a developer-style or dashboard-style screen.
- Game Selection has three distinct, premium illustrated cards.
- All three game modes share one cohesive visual language while retaining individual identities.
- Core controls appear tactile and dimensional rather than flat.
- Motion is smoother without reducing input responsiveness.
- Water Sort pours from bottle mouths.
- Rescue Rush never shows a remaining moving arrow behind the completion state.
- Block Puzzle drag/drop feels materially smoother and more tactile.
- Navigation no longer produces unnecessary edge flashes.
- The app remains performant on Android and all production-readiness tests remain green.
