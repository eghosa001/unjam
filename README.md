# UNJAM

UNJAM is a portrait-first Android puzzle collection built in Godot 4.7.2 with three equal game modes:

- **Rescue Rush** — directional escape and chain-reaction rescue puzzles.
- **Water Sort** — colour-sorting tube puzzles with animated pours.
- **Block Puzzle** — 8×8 placement and line-clearing puzzles.

Each game has its own progression, stars and a deterministic 10,000-level campaign. The launcher includes premium Home and Live surfaces, daily challenges, level selection, collection/reward systems, settings, persistence, monetization boundaries and Android-oriented touch input.

## Current production scope

- Godot 4.7.2 compatibility renderer
- 1080×1920 portrait design viewport with 540×960 test override
- Premium dark/light launcher UI
- Rescue Rush, Water Sort and Block Puzzle integrated into one app
- 10,000 deterministic campaign levels per game
- Per-game progress, stars, worlds and checkpoints
- Daily challenges and retention systems
- Save recovery/sanitization
- Hints, undo/restart where appropriate and result overlays
- Ad, purchase, privacy and analytics abstraction layers
- Automated level, gameplay, monetization, robustness and first-100 progression validation
- GitHub Actions import, test, boot and Android export gates

## Run locally

Use **Godot 4.7.2 stable**. Open `project.godot` and run `scenes/Main.tscn`.

The compatibility renderer is intentionally used for broader Android device support.

## Validation

CI currently runs:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/validate_levels.gd
godot --headless --path . --script res://tests/validate_campaign.gd
godot --headless --path . --script res://tests/validate_retention.gd
godot --headless --path . --script res://tests/validate_robustness.gd
godot --headless --path . --script res://tests/validate_level_launch.gd
godot --headless --path . --script res://tests/validate_gameplay_interactions.gd
godot --headless --path . --script res://tests/validate_first_100_progression.gd
godot --headless --path . --script res://tests/validate_campaign_1000.gd
godot --headless --path . --script res://tests/validate_monetization.gd
godot --headless --path . --quit-after 5
```

The workflow also performs Android API 36 APK and AAB export smoke tests.

## Android / Google Play

`export_presets.cfg` currently uses:

- package id: `com.eghosa.unjam`
- package name: `UNJAM`
- version: `1.0.0` / version code `1`
- minimum SDK: 24
- target SDK: 36
- ARM64 (`arm64-v8a`)
- immersive portrait presentation
- AAB as the production export format

A **debug APK is for installation/testing only**. Google Play deployment must use a release AAB signed with the owner's private upload key. Do not commit the keystore, alias password or store password to this repository.

Before public rollout, complete `RELEASE_CHECKLIST.md`, including real AdMob/Play Billing configuration, privacy/data-safety declarations, store listing assets and upload-key signing.

## Project structure

- `scripts/core/` — progression, campaign generation, level management and saves
- `scripts/game/` — Rescue Rush, Water Sort and Block Puzzle gameplay
- `scripts/ui/` — premium launcher, game UI and touch components
- `scripts/systems/` — ads, purchases, privacy, retention, feedback and analytics
- `data/levels/` — handcrafted Rescue Rush overrides
- `tests/` — automated validators and progression checks
- `tools/` — development-only utilities
- `.github/workflows/` — CI and Android export validation

## Release status

The game code and Android export configuration are prepared for testing and Play Internal Testing. Public monetized release still requires owner-controlled external credentials/services listed in `RELEASE_CHECKLIST.md`; those are intentionally not hard-coded or committed.
