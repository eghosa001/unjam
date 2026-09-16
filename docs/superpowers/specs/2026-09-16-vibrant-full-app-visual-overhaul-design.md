# Vibrant Full-App Visual Overhaul Design

## Goal
Bring every major UNJAM screen as close as practical to the approved vibrant reference image in perceived quality, density, readability, polish, and color while preserving gameplay rules, low/mid-range Android performance, reduced-motion support, and GL Compatibility.

## Visual standard
The approved target is a bright premium mobile-puzzle presentation: saturated cyan/teal/blue/purple/pink/orange/yellow accents, illustrated scenery, large readable typography, glossy 2.5D controls, beveled cards, stronger shadows, very limited dead space, large primary actions, game-specific identity, and playful decorative detail. The app should feel visually full without becoming cluttered.

## Shared architecture
Keep the existing pseudo-3D/procedural rendering approach and make it the single visual language across the app. Extend `PremiumDesignSystem`, `ProceduralMaterials`, and `PremiumBackdrop` so all shell screens and gameplay scenes consume the same palette, surface, gradient, bevel, shadow, and backdrop helpers. Do not convert gameplay to heavy true-3D or introduce shader-only effects that would break GL Compatibility.

## Screen coverage
The rollout covers:
- Home launcher and game chooser
- Level browser for Rescue Rush, Water Sort, and Block Puzzle
- Settings
- Collection / Rescue Garden
- Live and Daily surfaces
- Monetization/shop hub where present
- Tutorials for all three games
- Result / completion overlays
- Rescue Rush gameplay
- Water Sort gameplay
- Block Puzzle gameplay
- Shared navigation, headers, status strips, buttons, cards, empty states, and modal surfaces

## Layout requirements
- Reduce side gutters on phone layouts and avoid centered fixed-size islands that leave large unused regions.
- Prefer edge-to-edge or near-edge-to-edge panels with safe-area margins.
- Use large feature areas, stacked or grid cards, and bottom navigation to consume the available vertical space intentionally.
- Maintain touch target sizes of at least 48dp equivalent; primary actions should visually dominate secondary controls.
- Preserve responsiveness for the current 1080x1920 reference viewport and existing device-fit logic.

## Color and material requirements
- Dark appearance may remain supported, but it must still be colorful rather than navy/black-dominant.
- Light appearance should be bright and vivid, not flat white/gray.
- Each game gets a recognizable palette: Rescue Rush green/teal/yellow, Water Sort blue/cyan/magenta, Block Puzzle purple/pink/orange.
- Shared controls use glossy bevels, multi-layer extrusion, contact shadows, top highlights, and controlled glow.
- Backgrounds may use clouds, bubbles, foliage-like arcs, sparkles, water/sky bands, or other lightweight procedural decoration.

## Motion requirements
- Keep MotionSystem durations and reduced-motion behavior.
- Use entrance, hover, press, bounce, liquid, piece-land, and completion motion to increase perceived quality.
- Never block input unnecessarily during decorative motion.

## Performance constraints
- Keep GL Compatibility.
- Keep procedural draw calls quality-scaled through existing quality controls.
- Decorative particles and glow passes must scale down on low quality and reduced motion.
- Avoid large new raster art dependencies in the core implementation; use procedural art and existing assets unless a later art pass deliberately adds optimized textures.

## Verification
- Add or extend automated contracts that fail when the app regresses to sparse/dark presentation.
- Godot 4.7.2 import must be free of parse/script errors.
- Existing fast quality contracts and gameplay smoke contracts must remain green.
- The visual audit must capture all major screens in dark/light modes where applicable plus all three gameplay scenes and overlays.
- Final acceptance is based on the rendered screenshots, not only source-code inspection.
