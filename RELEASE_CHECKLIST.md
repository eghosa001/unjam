# UNJAM production release checklist

The repository is hardened to fail closed until production services are configured.

## Existing Play app and owner-confirmed upload key

The owner confirmed on 14 November 2026 that the **D8:B5 alternate-key AAB** worked in Google Play for `com.eghosa.unjamgam`. Preserve this upload-key identity for subsequent updates, subject to confirming the currently registered Play Console upload certificate. See [the upload-key record](docs/PLAY_UPLOAD_KEY.md). **Do not generate a new keystore for a routine update**, and never store keystore bytes or passwords in the repository.

## Fresh Google Play app reset

Current Android export and release workflow defaults are **versionName 1.0.16 / versionCode 16**. The fresh Google Play listing and new upload-key configuration remain account-side release prerequisites; do not interpret a successful QA APK as a signed, Play-accepted build.

- [ ] Confirm the existing Play Console listing for `com.eghosa.unjamgam` and its registered upload certificate; do not create a replacement listing for an update.
- [ ] Use the production package `com.eghosa.unjamgam` consistently in Google Play, AdMob, billing verification, and release builds.
- [ ] Confirm Play App Signing and the **upload certificate** for the existing app; Google Play app-signing keys and developer upload keys are distinct.
- [ ] Recover and securely back up the **existing owner-confirmed D8:B5 upload keystore**; do not generate a new key or reset the registered upload key unless Play Console requires it.
- [ ] Add the new keystore and credentials to GitHub Actions secrets: `UNJAM_ANDROID_KEYSTORE_BASE64`, `UNJAM_ANDROID_KEY_ALIAS`, and `UNJAM_ANDROID_KEY_PASSWORD`.
- [ ] Add the new upload certificate SHA-1 to GitHub Actions secret `UNJAM_ANDROID_UPLOAD_SHA1`.
- [x] Bind the selected Supabase project URL and publishable key in `project.godot` (public client configuration).
- [x] Bind the production developer website in `project.godot` to `https://unjam-eghosa.onrender.com`; `UNJAM_DEVELOPER_WEBSITE_URL` remains an optional CI override. Production release checks the crawler hostname root for `app-ads.txt`.
- [ ] Confirm the highest Google Play version code, then run `Android Production Release` with a higher code. For automatic Internal Testing draft upload, set `upload_to_internal_testing=true` and provide `UNJAM_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` as a GitHub Actions secret with release access to this app. Otherwise download the signed AAB artifact and upload manually. Review the draft in Play Console before making it available to testers.
- [ ] Confirm the highest version code previously accepted by Play Console before uploading; use a higher `versionCode` if 16 has already been used. Every subsequent upload must increase it.

Do not rotate the registered upload key during an update without following Google Play's upload-key reset process. The release workflow rejects a keystore whose SHA-1 does not match `UNJAM_ANDROID_UPLOAD_SHA1`.

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

- [ ] Confirm the **currently deployed** production Render developer website serves `app-ads.txt` at the hostname root with HTTP 200 and the expected seller record. A past successful check is not proof of present availability.
- [ ] Confirm the **currently deployed** Render privacy policy URL serves the full policy with HTTP 200 and no login. Recheck on each release.
- [x] Purchase-verification backend is implemented for Google Play Developer API verification and production purchases fail closed until the live HTTPS endpoint is injected at release time.
- [x] Supabase Edge Function exposes a readiness action that verifies Postgres, Google Play purchase verification, Voided Purchases authorization, and hardened monetization capabilities; production release fails if any dependency is unavailable.
- [x] Purchase verification is idempotent by SHA-256 purchase-token fingerprint in Supabase Postgres. `unjam_starter_pack` and other non-consumable entitlements cannot be granted twice from duplicate callbacks when the backend is live.
- [x] Apply `supabase/migrations/20260922_create_purchase_ledger.sql` and `supabase/migrations/20260922_harden_monetization_lifecycle.sql` to the selected Supabase project.
- [x] Deploy `supabase/functions/unjam-purchase` to that project.
- [x] Store `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL` and `GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY` only as Supabase Edge Function secrets. Live readiness reaches the Google Play API, confirming the credentials are present and OAuth succeeds; Cloud Run and Firestore are not used.
- [x] Grant the purchase-verifier service account Google Play API access for `com.eghosa.unjamgam`; live readiness now passes both purchase verification and Voided Purchases authorization. The earlier HTTP 403 is resolved.
- [ ] Create/activate `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000` as one-time products in Google Play.
- [ ] Configure real prices and at least one active, region-available buy option for each product. Release readiness queries every required product ID individually and stays red until all five are sellable.
- [ ] Complete Play Console Data Safety based on the exact production SDK set.
- [ ] Set **Contains ads = Yes**.
- [ ] Complete Target audience and IARC accurately.
- [ ] Add the developer website URL to the Play store listing so AdMob can discover app-ads.txt.
- [ ] Verify that the existing Google Play listing is correctly linked to the AdMob app and wait for AdMob app-readiness/app-ads verification.
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

Before the next submission, review every Play Console declaration that could classify the app as requiring an organization account. UNJAM is a casual puzzle collection, so declarations for regulated financial services, health services, government affiliation or other organization-only categories must only be selected if the shipped app actually provides those features.

Do not change a truthful declaration merely to bypass review. If a genuinely used feature requires an organization account, the correct fix is to publish from an eligible organization developer account.

## Production decision

Do not submit to Production until the exact release commit is green in CI, the final AAB passes Internal Testing, the organization-only declaration issue is resolved accurately, the privacy/Data Safety/ads declarations match the shipped build, the purchase-verification backend is live and idempotent across reinstall/device restore, and app-ads.txt is reachable at the root hostname of the developer website.

## Production website validation

The production site is deployed separately from the Android application. Render's free static site must run `python3 tools/build_public_site.py` and publish `public/`, serving `/`, `/privacy.html`, `/support.html`, `/assets/site.css`, `/assets/icon.svg`, `/robots.txt`, `/sitemap.xml`, and `/app-ads.txt`. CI tests these routes via a running Nginx container. The release verifier checks the live developer hostname, not just files in Git.

Do not mark Google Play production ready from a successful QA APK: it uses temporary QA signing and test advertising. The Android Production Release workflow must pass for the exact release commit with the correct upload key, live monetization and Google Play product catalog; a signed AAB must then be accepted by Play Console and installed through internal testing before production submission.


## Render static hosting (no fixed free-trial expiration)

- Hosting provider: Render Static Site (free tier subject to monthly bandwidth and build-minute quotas).
- Repository: `eghosa001/unjam`, branch `main`.
- Build command: `python3 tools/build_public_site.py`.
- Publish directory: `public`.
- Developer website: `https://unjam-eghosa.onrender.com`.
- Privacy policy: `https://unjam-eghosa.onrender.com/privacy.html`.
- AdMob seller record: `https://unjam-eghosa.onrender.com/app-ads.txt`.
- Deploy automatically on main, validate live status through the monetization CI gate.
- After verification, update the developer website field in the Google Play listing and let AdMob recrawl (can take at least 24 hours).
- Do not claim a no-cost tier is guaranteed forever; excessive usage or provider policy changes may affect availability.
