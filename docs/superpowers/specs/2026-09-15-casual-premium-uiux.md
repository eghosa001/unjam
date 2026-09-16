# UNJAM Casual Premium UI/UX Spec

## Goal
Raise UNJAM's home, settings, Rescue Rush, Water Sort and Block Puzzle presentation to the interaction discipline of leading casual puzzle games without copying their branding or artwork.

## Global UX principles
- Gameplay is the visual hero: board/tubes occupy most useful screen attention.
- One clear primary action per screen; secondary information is compact.
- Back/retry/undo/hint controls are large enough for touch but visually compact.
- No duplicated instructions, status blocks or decorative panels competing with gameplay.
- Screen roots remain geometrically stationary during navigation; motion is local and short.
- Dark/light themes maintain strong contrast without edge flashes.
- All gameplay surfaces must fit narrow/tall phones without clipping.
- Touch feedback, selected states, invalid states, success states and completion motion must be immediate and readable.

## Home
- Dominant continue/play hero.
- Three game selectors directly beneath/alongside hero.
- Remove the extra four-button dashboard row from the main hierarchy; keep Daily, Levels, Collection and Live as secondary compact actions/navigation.
- Reduce top chrome and statistics; show only the most useful progress summary.
- Bottom navigation remains compact and consistent.

## Settings
- Compact, focused settings surface.
- Rows for Sound, Music, Haptics, Appearance/Theme and Reduced Motion.
- Secondary links for How to Play and Privacy; Restore Purchases can be shown only when a purchase system is available.
- Remove the large play-history dashboard from Settings.

## Water Sort
- Tubes are the primary focal point and use available height efficiently.
- Six-tube levels use 3x2.
- Compact top header and one-line level/move state.
- Undo and Hint are compact utility actions.
- Curved rim-to-rim liquid stream remains visible above the glass.
- Selected bottle lifts/glows; invalid target gives immediate feedback.

## Block Puzzle
- Board is the dominant object and pieces sit directly beneath it.
- Score/goal is compact and close to the board.
- Remove persistent large run-progress deck; use compact progress chips/bars if needed.
- Centroid-based magnetic placement remains active.
- Placement preview is clear; line clears and combos have strong feedback.

## Rescue Rush
- Grid is the dominant object.
- Compact status row for moves/rescue/chain.
- Remove duplicate brand/world/tip/footer/deck information from normal play.
- Escape route must be visually obvious without requiring instructional prose.
- Height-aware responsive sizing remains active.

## Motion
- Navigation/component transitions: roughly 160-250 ms.
- Never move/scale the whole content root for screen transitions.
- No persistent pulsing that distracts from gameplay.
- Avoid edge flashes and overlapping transition owners.

## Verification
- Godot import must show no script/parse/runtime errors.
- Existing gameplay interaction suite must pass.
- Motion quality and UI/UX regression suites must pass.
- Capture fresh home/settings/three-game screenshots.
- Stagehand smoke: home -> settings -> home -> each game -> interact -> back.
- Check at least tall-phone and narrower viewport layouts.
