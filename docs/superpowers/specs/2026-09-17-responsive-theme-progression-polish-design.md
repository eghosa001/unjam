# Responsive Theme and Progression Polish Design

## Goal

Keep the current bright premium 3D UNJAM direction while fixing the user-observed density, fit, progression, Block Puzzle drag duplication, early Rescue Rush difficulty, Collection depth, level navigation, and dark-mode behavior.

## Design

### Responsive composition

Home, Settings, Levels, Collection, Rescue Rush, Water Sort and Block Puzzle must consume the available safe viewport instead of relying on conservative fixed caps. Primary actions become taller, flexible gameplay holders stop creating large empty gaps, and level grids choose 2/3/4 columns from safe width. Decorative 3D art must remain inside the safe content rectangle and top-level custom surfaces clip accidental decorative overflow.

### Gameplay sizing

Rescue Rush increases its board budget and removes the oversized flexible gap around the board. Water Sort derives tube width and height from both safe width and available stage height, keeping tall tube proportions while making small tube counts materially larger. Block Puzzle keeps its enlarged board but uses one authoritative touch preview so the same brick shape is never rendered twice during one drag.

### Rescue Rush opening rhythm

Levels 1-10 use: easy, easy, medium, easy, medium, medium, easy, medium, medium, hard. Levels 5-9 add more meaningful blockers/fillers without introducing the later gate/bomb mechanics. Level 10 remains the first hard milestone. Existing campaign solvability validation remains authoritative.

### Levels and progression

Every Levels screen gets a three-game switcher. Switching moves directly to the selected game's current world. The Choose Game surface rebuilds whenever it becomes visible so its level, stars, and progress bar always reflect the latest completed level while staying event-driven.

### Collection

Collection becomes an UNJAM-wide journey screen. It shows combined progress plus per-game level/stars/perfect/world data, unlocked achievements, and the existing Rescue Garden/friends/decorations. The screen uses a scrollable body so added depth never causes narrow-screen overflow.

### Dark mode

Dark mode must affect custom 3D surfaces, not only legacy controls. The 3D backdrop gains a dark presentation, secondary surface polishing respects the dark flag, Home and Choose Game rebuild with dark-aware styling, and active gameplay receives an immediate dark environment shade without restarting the level. Game identity accents stay vivid.

### Verification

Add a fast regression contract for the reported issues, then keep existing viewport, navigation, campaign solvability, and visual audit checks. The regression contract must fail on the pre-fix implementation and pass after the changes.
