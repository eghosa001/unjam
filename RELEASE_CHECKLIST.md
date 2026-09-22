# UNJAM production release checklist

The repository is hardened to fail closed until production services are configured.

## Fresh Google Play app reset

This repository is now prepared to start the replacement Play listing at **versionName 1.0.0 / versionCode 1** with a **new upload key**.

- [ ] Create the replacement app in Play Console.
- [ ] Use the production package `com.eghosa.unjamgam` consistently in Google Play, AdMob, billing verification, and release builds.
- [ ] Enable Play App Signing for the replacement app and let Google manage the app-signing key unless there is a specific reason to supply your own.
- [ ] Generate a new RSA upload keystore and keep at least two secure backups outside the repository.
- [ ] Add the new keystore and credentials to GitHub Actions secrets: `UNJAM_ANDROID_KEYSTORE_BASE64`, `UNJAM_ANDROID_KEY_ALIAS`, and `UNJAM_ANDROID_KEY_PASSWORD`.
- [ ] Add the new upload certificate SHA-1 to GitHub Actions secret `UNJAM_ANDROID_UPLOAD_SHA1`.
- [x] Bind the selected Supabase project URL and publishable key in `project.godot` (public client configuration).
- [ ] Add GitHub Actions repository variable `UNJAM_DEVELOPER_WEBSITE_URL` using the exact developer website URL entered in Play Console. Production release now checks the crawler hostname root for `app-ads.txt`.
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
- [x] GodotGooglePlayBilling 3.3.0 is pinned in the CI installer; this plugin line uses Google Play Billing Library 9.1.0.
- [x] Play Billing connection, localized product-price query, purchase, pending, restore, and authoritative ownership reconciliation paths are implemented.
- [x] Google Play acknowledgement/consumption is finalized server-side after the purchase claim is committed.
- [x] Voided Purchases refund/chargeback synchronization is implemented with install-bound revocation delivery.
- [x] Refunded consumable coin grants are clawed back without allowing a negative wallet; any remainder becomes purchase-refund debt settled by future grants.
- [x] Purchase-verifier requests are protected by a database-backed rate limiter.
- [x] Local purchase-token history stores SHA-256 fingerprints rather than reusable raw Play purchase tokens.
- [x] Resetting gameplay progress preserves Play-owned non-consumable entitlements and local duplicate-grant history.
- [x] `app-ads.txt` at repository root and `docs/app-ads.txt` contain the AdMob publisher record.
- [x] Privacy policy source exists at `docs/privacy.html`.

Still account-side / external:

- [ ] Publish `app-ads.txt` at the **hostname root** of the developer website used in the Play listing (for example `https://example.com/app-ads.txt`). A GitHub Pages project URL such as `https://eghosa001.github.io/unjam/` is not sufficient by itself because AdMob checks `https://eghosa001.github.io/app-ads.txt`, not the project subpath.
- [ ] Confirm the configured privacy policy URL is publicly reachable without login.
- [x] Purchase-verification backend is implemented for Google Play Developer API verification and production purchases fail closed until the live HTTPS endpoint is injected at release time.
- [x] Supabase Edge Function exposes a readiness action that verifies Postgres, Google Play purchase verification, Voided Purchases authorization, and hardened monetization capabilities; production release fails if any dependency is unavailable.
- [x] Purchase verification is idempotent by SHA-256 purchase-token fingerprint in Supabase Postgres. `unjam_starter_pack` and other non-consumable entitlements cannot be granted twice from duplicate callbacks when the backend is live.
- [x] Apply `supabase/migrations/20260922_create_purchase_ledger.sql` and `supabase/migrations/20260922_harden_monetization_lifecycle.sql` to the selected Supabase project.
- [x] Deploy `supabase/functions/unjam-purchase` to that project.
- [x] Store `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL` and `GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY` only as Supabase Edge Function secrets. Live readiness reaches the Google Play API, confirming the credentials are present and OAuth succeeds; Cloud Run and Firestore are not used.
- [ ] In Play Console, grant that service-account identity access to `com.eghosa.unjamgam` with **View financial data** (or the account-level equivalent **View financial data, orders and cancellation survey responses**). The live Purchases API probe currently returns HTTP 403 until this permission is granted.
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
- CI must pass project import, all validation suites, boot smoke, rendered visual audit, Android API 36 APK/AAB export, packaged AdMob/Play Billing manifest checks, and live monetization readiness including Supabase Postgres + Play Purchases API authorization on the exact release commit.

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
