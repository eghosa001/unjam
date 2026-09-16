# UNJAM production release checklist

The repository is hardened to fail closed until production services are configured.

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
- [x] `docs/app-ads.txt` contains the AdMob publisher record.
- [x] Privacy policy source exists at `docs/privacy.html`.

Still account-side / external:

- [ ] Publish `app-ads.txt` at the **root hostname** of the developer website used in the Play listing (for example `https://example.com/app-ads.txt`). Keeping it only inside this repository is not enough for AdMob crawling.
- [ ] Publish the privacy policy at the configured public URL and confirm it is reachable without login.
- [ ] Set an HTTPS `purchase_verification_url` backed by Google Play Developer API verification. Production purchases intentionally fail closed until this exists.
- [ ] Create `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000` as one-time products in Play Console.
- [ ] Configure the matching product prices in Play Console.
- [ ] Complete Play Console Data Safety based on the exact production SDK set.
- [ ] Set **Contains ads = Yes**.
- [ ] Complete Target audience and IARC accurately.
- [ ] Add the developer website URL to the Play store listing so AdMob can discover app-ads.txt.
- [ ] Link the published Google Play listing back to the AdMob app and wait for AdMob app-readiness/app-ads verification.
- [ ] Keep release keystore path, alias and passwords only in CI/Play secrets; never commit them.
- [ ] Upload the AAB to Play Internal Testing and test purchase success, cancel, pending, restore, refund, repeat consumable purchase, offline behavior, rewarded-ad success/failure, and consent flows with license testers.
- [ ] Increment `version/code` for every Play upload.

## Code-side release gates

- HINT buttons disclose a 25-coin cost. When the player has enough coins the hint is charged immediately; when the balance is too low a hint is granted only after a rewarded ad completes.
- Rewarded ads and Play purchases fail closed when their provider/configuration is unavailable; gameplay remains usable without monetization services.
- Difficulty stays intentionally variable within each 25-level chapter, while later worlds raise the baseline difficulty. Every 25th level is a milestone and every 100th is a boss.
- Save data is sanitized, backed up and written through a temporary file before replacement.
- Release builds do not emit the development analytics event stream.
- CI must pass project import, all validation suites, boot smoke, Android API 36 APK export and Android API 36 AAB export on the exact release commit.

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

Do not submit to Production until the exact release commit is green in CI, the final AAB passes Internal Testing, the previous organization-only declaration issue is resolved accurately, the privacy/Data Safety/ads declarations match the shipped build, the purchase-verification backend is live, and app-ads.txt is reachable at the root hostname of the developer website.
