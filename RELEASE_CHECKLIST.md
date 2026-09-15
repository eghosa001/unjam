# UNJAM production release checklist

This branch is hardened to fail closed until production services are configured. Complete every unchecked account-side item before public rollout.

## Verified code/UI gates

- [x] Godot 4.7.2 project imports without script or parse errors in the local Linux test environment.
- [x] UI/UX regression validation passes.
- [x] Premium UX contract validation passes.
- [x] Rescue Rush, Water Sort and Block Puzzle Level 1 scenes launch and render interactive gameplay.
- [x] Gameplay interaction validation passes for move/place, hint, undo, retry and checkpoint restore.
- [x] Motion-quality validation passes, including stationary screen roots during navigation.
- [x] Fresh 1080x1920 visual-audit screenshots were captured with a real X/OpenGL session.
- [x] Rescue Rush board fitting accounts for viewport width and height.
- [x] Water Sort six-tube levels use a balanced 3x2 arrangement and rim-to-rim curved pour motion.
- [x] Block Puzzle uses centroid-based magnetic placement and viewport-aware board fitting.
- [x] Home, Settings and gameplay surfaces use the shared premium teal/blue/violet colour system.

## Release-build gates

- [ ] Confirm the full GitHub Actions workflow passes on the exact release commit, including the long campaign validation and Android API 36 APK/AAB export gates.
- [ ] Increment `version/code` for every Play release.
- [ ] Export a release AAB signed with the owner's private Play upload key.
- [ ] Keep release keystore path, alias and passwords only in CI/Play secrets; never commit them.
- [ ] Upload the AAB to Play Internal Testing before production rollout.
- [ ] Install the Play-delivered build on physical Android hardware and test back navigation, rapid taps, pause/resume, background/foreground, offline play, save/restore and low-memory relaunch.

## Google Play Console declarations

- [ ] Keep the app type/category accurate: UNJAM is a puzzle game.
- [ ] Complete the Content Rating / IARC questionnaire accurately.
- [ ] Complete Target Audience and Content accurately.
- [ ] Complete Data Safety from the behaviour of the exact production SDK set.
- [ ] Set Contains Ads to match the production build.
- [ ] Publish `docs/privacy.html` at the configured privacy-policy URL and add that URL to Play Console.
- [ ] Verify developer identity/contact information and account-type requirements.
- [ ] Do not declare finance, lending, health, VPN, government, gambling or other restricted categories/features that UNJAM does not provide.

## Monetisation configuration

- [ ] Set real AdMob app, rewarded and interstitial IDs in production configuration; never click live ads during testing.
- [ ] Configure Google UMP/privacy messaging and verify Privacy Options on a real Android build.
- [ ] Install Poing Studios Godot AdMob 5.1.0 and the required Godot 4.7.2 Android template/dependencies.
- [ ] Install GodotGooglePlayBilling 3.3.0 and enable its plugin.
- [ ] Set an HTTPS `purchase_verification_url` backed by Google Play Developer API verification. Production purchases fail closed until this exists.
- [ ] Create `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000` in Play Console.
- [ ] Configure `app-ads.txt` from the developer website used by the Play listing before monetised rollout.
- [ ] Test purchase success, cancel, pending, restore, refund, repeat consumable purchase, offline behaviour, rewarded-ad failure/success and consent flows with license testers.

## Store listing assets

- [x] App name prepared within the 30-character limit: `UNJAM`.
- [x] Short description prepared within the 80-character limit.
- [x] Full description prepared within the 4,000-character limit.
- [x] Google Play icon prepared as a 512x512 32-bit PNG.
- [x] Feature graphic prepared as a 1024x500 24-bit PNG.
- [x] Five current-version portrait screenshots prepared at 1080x1920; the first three show actual gameplay.
- [x] Screenshot alt text prepared.
- [ ] Upload listing assets and alt text to Play Console and review the final listing preview on phone and web.
- [ ] Ensure every screenshot and description claim still matches the exact release build submitted for review.

## Existing gameplay/monetisation contracts

- HINT buttons disclose a 25-coin cost. When the player has enough coins the hint is charged immediately; when the balance is too low a hint is granted only after a rewarded ad completes.
- Rewarded ads and Play purchases fail closed when their provider/configuration is unavailable; gameplay remains usable without monetisation services.
- Difficulty stays intentionally variable within each 25-level chapter, while later worlds raise the baseline difficulty. Every 25th level is a milestone and every 100th is a boss.
- Save data is sanitised, backed up and written through a temporary file before replacement.
- Release builds do not emit the development analytics event stream.

## External launch blockers

A public monetised release is **not launch-ready** until the unchecked provider, Play Console, signing and verification items above are complete. These values are intentionally not invented or committed. Until they are supplied, monetisation features fail closed rather than granting rewards or purchases incorrectly.
