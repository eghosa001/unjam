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
- Supabase Edge Function + Postgres purchase-verification backend; no Cloud Run or Firestore
- Automated campaign, gameplay, economy, monetization, robustness, motion, 3D/idle-cost and viewport validation
- GitHub Actions import, test, rendered visual-audit, boot and Android export gates

## Run locally

Use **Godot 4.7.2 stable**. Open `project.godot` and run `scenes/Main.tscn`.

The compatibility renderer is intentionally used for broader Android device support.

## Validation

CI is defined in `.github/workflows/godot-ci.yml`. Representative local checks are:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/validate_motion_quality.gd
godot --headless --path . --script res://tests/validate_transition_ownership.gd
godot --headless --path . --script res://tests/validate_difficulty_curves.gd
godot --headless --path . --script res://tests/validate_monetization.gd
godot --headless --path . --script res://tests/validate_robustness.gd
godot --headless --path . --script res://tests/validate_campaign.gd
godot --headless --path . --script res://tests/validate_gameplay_interactions.gd
godot --headless --path . --script res://tests/validate_restore_purchase_flow.gd
godot --headless --path . --script res://tests/validate_viewport_fit.gd
godot --headless --path . --quit-after 5
```

The workflow also runs the complete grouped validator set, captures rendered UI screenshots, and performs Android API 36 APK and AAB export smoke tests.

## Android / Google Play

This repository is reset for a **fresh Google Play app listing**. `export_presets.cfg` currently uses:

- package id: `com.eghosa.unjamgam`
- package name: `UNJAM`
- version: `1.0.0` / version code `1`
- minimum SDK: 24
- target SDK: 36
- ARM64 (`arm64-v8a`)
- immersive portrait presentation
- AAB as the production export format

The package ID is intentionally unchanged while the deleted Play app is checked for package-name reuse. If Google Play refuses `com.eghosa.unjamgam`, change the package ID in the repository before creating production billing products or linking AdMob to the replacement listing.

A **debug APK is for installation/testing only**. Google Play deployment must use a release AAB signed with the owner's private upload key. For the new listing, use a newly generated upload key and store its SHA-1 in the GitHub Actions secret `UNJAM_ANDROID_UPLOAD_SHA1`. Store the keystore itself and its credentials only in protected secrets; never commit them.

Before public rollout, complete `RELEASE_CHECKLIST.md`, including Play App Signing, the new upload-key secrets, real AdMob/Play Billing configuration, Supabase purchase verification, privacy/data-safety declarations, store listing assets and testing requirements.

## Project structure

- `scripts/core/` — progression, campaign generation, level management and saves
- `scripts/game/` — Rescue Rush, Water Sort and Block Puzzle gameplay
- `scripts/ui/` — premium launcher, game UI and touch components
- `scripts/systems/` — ads, purchases, privacy, retention, feedback and analytics
- `data/levels/` — handcrafted Rescue Rush overrides
- `tests/` — automated validators and progression checks
- `tools/` — development-only utilities
- `supabase/` — Postgres purchase ledger migration and Edge Function verifier
- `.github/workflows/` — CI and Android export validation

## Release status

The game code and Android export configuration are prepared for testing and Play Internal Testing. Public monetized release still requires owner-controlled external credentials/services listed in `RELEASE_CHECKLIST.md`; those are intentionally not hard-coded or committed.
