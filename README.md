# Unjam: Rescue Rush

A mobile-first directional rescue puzzle built in Godot. The core hook is simple: clear directional pieces to open a path for the trapped character, while special pieces transform the board through chain reactions.

## Current playable scope

- Android-oriented portrait layout
- Main menu and level selection
- Persistent progress, stars, rescued characters and coins
- Data-driven JSON levels
- Directional path/block checks
- Rescue path detection
- Undo and hint systems
- Star scoring based on par moves
- Result screen and next-level flow
- Rescue Garden collection screen
- Normal, rotate, key, gate, bomb, linked and blocker pieces
- Chain counter for multi-object effects
- 10 handcrafted starter levels
- Headless level-data validator
- Isolated ad and analytics service interfaces for later SDK integration

## Controls

Tap a directional piece. If every tile in its direction is clear, it escapes the board. Clearing a route from the rescue character to any board edge completes the level.

Special pieces:

- **Rotate**: rotates adjacent movable pieces clockwise when it escapes.
- **Key**: opens gates with the same `key_id`.
- **Gate**: blocks movement until its matching key is released.
- **Bomb**: removes nearby non-gate pieces.
- **Linked**: activates another linked piece with the same `link_id`; if the partner cannot escape, it rotates instead.
- **Blocker**: permanent obstacle unless removed by a bomb.

## Run

Open the repository in Godot 4.x and run `project.godot`.

The project uses the compatibility renderer to remain friendly to lower-end Android hardware.

## Validate level data

From a machine with Godot on PATH:

```bash
godot --headless --path . --script res://tests/validate_levels.gd
```

The validator checks board size, rescue placement, duplicate positions, valid piece types, valid directions and out-of-bounds objects.

## Add a level

Create `data/levels/level_XX.json`:

```json
{
  "width": 5,
  "height": 5,
  "par_moves": 3,
  "rescue_id": "chick",
  "rescue": [2, 2],
  "pieces": [
    {"x": 2, "y": 0, "type": "normal", "direction": "up"},
    {"x": 0, "y": 2, "type": "rotate", "direction": "left"}
  ]
}
```

## Architecture

- `scripts/core/` — save and level loading
- `scripts/game/` — puzzle rules, board state, undo, hints, rescue and results
- `scripts/ui/` — menu, level selection and Rescue Garden
- `scripts/systems/` — ads/analytics adapters
- `data/levels/` — level definitions
- `tests/` — data validation

## Next production passes

The current repository is the playable MVP foundation. The next high-value passes are:

1. Replace Unicode/procedural presentation with finished 2D/2.5D art, character sprites and themed world backgrounds.
2. Add escape tweens, particles, haptics, stronger chain-reaction presentation and rescue celebration animation.
3. Add sound/music assets and route them through an AudioManager.
4. Build an in-game level editor and expand from 10 to 50–80 tuned launch levels.
5. Add worlds and mechanic onboarding instead of exposing every mechanic immediately.
6. Connect `AdManager` to the selected Android ad SDK and use rewarded hints/undo plus conservative interstitials.
7. Connect `AnalyticsManager` to Firebase/GameAnalytics and tune levels using restart/quit/fail data.
8. Add daily challenge and lightweight Rescue Garden decorations only after retention is proven.

The design rule is: **depth from interactions, not from adding hundreds of systems.**
