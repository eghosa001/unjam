# UNJAM production release checklist

The repository is hardened to fail closed until production services are configured.

## Fresh Google Play app reset

This repository is now prepared to start the replacement Play listing at **versionName 1.0.0 / versionCode 1** with a **new upload key**.

- [ ] Create the replacement app in Play Console.
- [ ] Keep `com.eghosa.unjam` only if Google Play accepts that package for the replacement app. A deleted app with zero lifetime installs can have its package name reused; a deleted app with any lifetime install cannot.
- [ ] Enable Play App Signing for the replacement app and let Google manage the app-signing key unless there is a specific reason to supply your own.
- [ ] Generate a new RSA upload keystore and keep at least two secure backups outside the repository.
- [ ] Add the new keystore and credentials to GitHub Actions secrets: `UNJAM_ANDROID_KEYSTORE_BASE64`, `UNJAM_ANDROID_KEY_ALIAS`, and `UNJAM_ANDROID_KEY_PASSWORD`.
- [ ] Add the new upload certificate SHA-1 to GitHub Actions secret `UNJAM_ANDROID_UPLOAD_SHA1`.
- [ ] Add the production HTTPS purchase-verification endpoint to GitHub Actions secret `UNJAM_PURCHASE_VERIFICATION_URL`.
- [ ] Run the `Android Production Release` workflow with `version_name=1.0.0` and `version_code=1`; download the verified release AAB and upload that AAB to the new Play listing.
- [ ] After the first accepted Play upload, every subsequent upload must use a higher `versionCode`.

Do not reuse the deleted app's old private upload key merely because it still exists. The replacement release workflow validates the new certificate fingerprint supplied through `UNJAM_ANDROID_UPLOAD_SHA1` and will reject a keystore whose SHA-1 does not match that secret.

## Monetization status

Configured in code/CI:

- [x] Production AdMob App ID configured.
- [x] Production Rewarded Ad Unit ID configured.
- [x] Production Interstitial Ad Unit ID configured.
- [x] Debug builds automatically use Google's official Android test ad unit IDs.
- [x] Rewarded rewards are granted only from the earned-reward callback.
- [x] Interstitials use natural-break frequency controls, a 180-second cooldown, and a per-session cap.
- [x] Google UMP consent and Privacy Options hooks are implemented and ads fail closed until consent is usable.
- [x] Poing Godot AdMob 5.1.0 and its Godot 4.7.2 Android native package are pinned in the CI installer.
- [x] GodotGooglePlayBilling 3.3.0 is pinned in the CI installer.
- [x] Play Billing connection, localized product-price query, purchase, restore, consume, and acknowledge paths are implemented.
- [x] Local purchase-token history stores SHA-256 fingerprints rather than reusable raw Play purchase tokens.
- [x] Resetting gameplay progress preserves Play-owned non-consumable entitlements and local duplicate-grant history.
- [x] `docs/app-ads.txt` contains the AdMob publisher record.
- [x] Privacy policy source exists at `docs/privacy.html`.

Still account-side / external:

- [ ] Publish `app-ads.txt` at the **root hostname** of the developer website used in the Play listing (for example `https://example.com/app-ads.txt`). Keeping it only inside this repository is not enough for AdMob crawling.
- [ ] Publish the privacy policy at the configured public URL and confirm it is reachable without login.
- [ ] Set an HTTPS `purchase_verification_url` backed by Google Play Developer API verification. Production purchases intentionally fail closed until this exists.
- [ ] Make the purchase-verification backend idempotent by Google Play transaction/purchase token. In particular, `unjam_starter_pack` must not grant its 1,000 coins again after reinstall, app-data clear, restore on another device, retry, or duplicate callback; the server must be the durable source of truth for whether a non-consumable grant was already applied.
- [ ] Create `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000` as one-time products in the **new** Play Console app.
- [ ] Configure the matching product prices in the new Play Console app.
- [ ] Complete Play Console Data Safety based on the exact production SDK set.
- [ ] Set **Contains ads = Yes**.
- [ ] Complete Target audience and IARC accurately.
- [ ] Add the developer website URL to the Play store listing so AdMob can discover app-ads.txt.
- [ ] Link the replacement Google Play listing to the AdMob app and wait for AdMob app-readiness/app-ads verification.
- [ ] Keep release keystore path, alias and passwords only in CI/Play secrets; never commit them.
- [ ] Upload the AAB to Play Internal Testing and test purchase success, cancel, pending, restore, refund, repeat consumable purchase, offline behavior, rewarded-ad success/failure, and consent flows with license testers.
- [ ] Explicitly test reinstall/app-data-clear and second-device restore so the backend proves that non-consumable entitlements restore without duplicating one-time coin grants.
- [ ] If this developer account is subject to Google's new-personal-account production-access rule, complete the required closed test before applying for production.

## Code-side release gates

- HINT buttons disclose a 25-coin cost. When the player has enough coins the hint is charged immediately; when the balance is too low a hint is granted only after a rewarded ad completes.
- Rewarded ads and Play purchases fail closed when their provider/configuration is unavailable; gameplay remains usable without monetization services.
- Difficulty stays intentionally variable within each 25-level chapter, while later worlds raise the baseline difficulty. Every 25th level is a milestone and every 100th is a boss.
- Save data is sanitized, backed up and written through a temporary file before replacement.
- Release builds do not emit the development analytics event stream.
- CI must pass project import, all validation suites, boot smoke, rendered visual audit, Android API 36 APK export and Android API 36 AAB export on the exact release commit.

## Google Play store listing assets

Current asset pack requirements verified against Google Play guidance:

- App icon: 512 × 512, 32-bit PNG with alpha, maximum 1 MB.
- Feature graphic: 1024 × 500, JPEG or 24-bit PNG without alpha.
- Phone screenshots: use real in-app experiences and keep promotional text truthful and minimal.
- Keep icon, feature graphic and screenshots visually consistent.
- Do not use ranking, award, price, discount or misleading claims in listing graphics.

## Play Console organization-only rejection check

Before the replacement submission, review every Play Console declaration that could classify the app as requiring an organization account. UNJAM is a casual puzzle collection, so declarations for regulated financial services, health services, government affiliation or other organization-only categories must only be selected if the shipped app actually provides those features.

Do not change a truthful declaration merely to bypass review. If a genuinely used feature requires an organization account, the correct fix is to publish from an eligible organization developer account.

## Production decision

Do not submit to Production until the exact release commit is green in CI, the final AAB passes Internal Testing, the organization-only declaration issue is resolved accurately, the privacy/Data Safety/ads declarations match the shipped build, the purchase-verification backend is live and idempotent across reinstall/device restore, and app-ads.txt is reachable at the root hostname of the developer website.
