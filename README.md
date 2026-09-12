# Unjam: Rescue Rush

A mobile-first chain-reaction rescue puzzle built in Godot. Tap directional pieces to clear a path for a trapped character; keys, gates, bombs, rotators and linked pieces can transform the board and create satisfying chain reactions.

## Launch scope now implemented

- Android-oriented portrait layout and compatibility renderer
- Premium procedural UI presentation with six world themes
- 60-level campaign split into six worlds
- 10 handcrafted onboarding levels plus deterministic campaign generation
- Daily challenge with deterministic daily seed, 100-coin reward and streak tracking
- Persistent progress, stars, rescued characters, coins and settings
- Rescue Garden with collectible characters and purchasable decorations
- Directional path/block checks and rescue-path win detection
- Undo, hints, restart and star scoring
- Normal, rotate, key, gate, bomb, linked and blocker mechanics
- Chain reaction feedback, board shake, reveal/rescue tweens
- Procedural sound effects and Android haptic feedback without external audio dependencies
- Rewarded-ad and interstitial placement boundaries isolated in `AdManager`
- Analytics event boundary isolated in `AnalyticsManager`
- Internal visual level editor
- Handcrafted-level validator and full 60-level campaign validator
- GitHub Actions import/validation/boot smoke tests
- Android export preset targeting ARM64

## Gameplay

Tap a directional piece. If every tile in its direction is clear, it escapes the board. Clearing a route from the rescue character to any board edge completes the level.

Special pieces:

- **Rotate** — rotates adjacent movable pieces clockwise.
- **Key** — opens gates with the same `key_id`.
- **Gate** — blocks movement until the matching key is released.
- **Bomb** — removes nearby non-gate pieces.
- **Linked** — activates another linked piece with the same `link_id`; blocked partners rotate instead.
- **Blocker** — permanent obstacle unless removed by a bomb.

## Campaign worlds

1. **Garden Escape** — core directional rules
2. **Locks & Keys** — keys and gates
3. **Chain Reaction** — rotators and changing board states
4. **Blast Lab** — bombs and destructible blockers
5. **Linked Zone** — paired pieces and multi-object reactions
6. **Chaos Rescue** — mixed-mechanic mastery

## Run

Use Godot 4.5.x. Open `project.godot` and run the project.

The project uses the compatibility renderer for lower-end Android support.

## Validation

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/validate_levels.gd
godot --headless --path . --script res://tests/validate_campaign.gd
godot --headless --path . --quit-after 5
```

GitHub Actions runs the same checks on pushes and pull requests.

## Level editor

Open `scenes/LevelEditor.tscn` directly in Godot and run the scene. The editor can:

- place/remove pieces on a 5×5 grid
- select piece type and direction
- move the rescue target
- clear the board
- export the level as JSON into `data/levels/`

Hand-authored JSON levels override generated campaign levels with the same number, so polished levels can gradually replace generated ones without changing game code.

## Android

`export_presets.cfg` contains an ARM64 Android preset with package id `com.eghosa.unjam`.

Before a Play Store release you still need to configure your own Android SDK/JDK environment, upload/signing keystore and store credentials. Never commit keystore passwords or service credentials.

## Monetization integration

Gameplay never talks directly to an ad SDK. Replace the development fallback inside `scripts/systems/ad_manager.gd` with your selected provider implementation.

Current placements are deliberately conservative:

- rewarded double-reward on the result screen
- interstitial pacing after multiple completed levels
- no mid-puzzle interruption

`remove_ads` is already represented in save data for a future purchase adapter.

## Analytics integration

`scripts/systems/analytics_manager.gd` currently logs events locally. Replace the `track()` implementation with Firebase Analytics, GameAnalytics or another provider. Gameplay already reports starts and completions, while the architecture supports restart/hint/undo instrumentation.

## Project structure

- `scripts/core/` — saves, level loading and campaign generation
- `scripts/game/` — puzzle rules and game presentation
- `scripts/ui/` — home, worlds, settings and Rescue Garden
- `scripts/systems/` — ads, analytics, daily challenge and feedback
- `tools/` — internal level editor
- `data/levels/` — handcrafted JSON level overrides
- `tests/` — validators
- `.github/workflows/` — CI quality gate

## External release blockers

The codebase is feature-complete for the planned first commercial version. The remaining release-specific work requires owner-controlled external resources rather than more game architecture:

1. choose and configure the real ad SDK/application IDs
2. optionally connect production analytics
3. create the Play Console listing, privacy policy and store graphics
4. provide the Android signing/upload key
5. replace or extend procedural visuals with commissioned/custom artwork if desired
6. playtest and tune individual level difficulty using real-player data

The project deliberately keeps those external dependencies isolated so the game remains fully playable during development.
