# UNJAM production release checklist

The repository is hardened to fail closed until production services are configured. Complete these account-side steps before public rollout:

- Set real AdMob app, rewarded and interstitial IDs in the production configuration; never click live ads during testing.
- Configure Google UMP/privacy messaging and verify Privacy Options is reachable on a real Android build.
- Install Poing Studios Godot AdMob 5.1.0 and its Godot 4.7.2 Android template/dependencies.
- Install GodotGooglePlayBilling 3.3.0 and enable its plugin.
- Set an HTTPS `purchase_verification_url` backed by Google Play Developer API verification. Production purchases fail closed until this exists.
- Create `unjam_remove_ads`, `unjam_starter_pack`, `unjam_coins_500`, `unjam_coins_1500`, and `unjam_coins_4000` in Play Console.
- Publish `docs/privacy.html` at the configured privacy-policy URL and complete Play Data Safety, Contains Ads, target audience and IARC declarations accurately.
- Configure app-ads.txt from the developer website used by the Play listing before monetized rollout.
- Keep release keystore path, alias and passwords only in CI/Play secrets; never commit them.
- Upload the AAB to Play Internal Testing and test purchase success, cancel, pending, restore, refund, repeat consumable purchase, offline behavior and consent flows with license testers.
- Increment `version/code` for every Play release.

## Code-side release gates

- HINT buttons disclose a 25-coin cost. When the player has enough coins the hint is charged immediately; when the balance is too low a hint is granted only after a rewarded ad completes.
- Rewarded ads and Play purchases fail closed when their provider/configuration is unavailable; gameplay remains usable without monetization services.
- Difficulty stays intentionally variable within each 25-level chapter, while later worlds raise the baseline difficulty. Every 25th level is a milestone and every 100th is a boss.
- Save data is sanitized, backed up and written through a temporary file before replacement.
- Release builds do not emit the development analytics event stream.
- CI must pass project import, all validation suites, the first-100 lifecycle test, boot smoke, Android API 36 APK export and Android API 36 AAB export on the exact release commit.

## External launch blockers

A public monetized release is **not launch-ready** until the AdMob IDs, provider plugins, Play Billing products and HTTPS purchase-verification service above are configured. These values are intentionally not invented or committed here. Until they are supplied, monetization features fail closed rather than granting rewards or purchases incorrectly.

## Google Play store listing assets

Current asset pack requirements verified against Google Play guidance:

- App icon: 512 × 512, 32-bit PNG with alpha, maximum 1 MB.
- Feature graphic: 1024 × 500, JPEG or 24-bit PNG without alpha.
- Phone screenshots: use real in-app experiences and keep promotional text truthful and minimal.
- Keep icon, feature graphic and screenshots visually consistent.
- Do not use ranking, award, price, discount or misleading claims in listing graphics.

The prepared release pack contains:

- `unjam-app-icon-512.png`
- `unjam-feature-graphic-1024x500.png`
- five 1080 × 1920 real-app screenshots
- optional promotional screenshot variants
- final title, short description and full description
- `PLAY_STORE_RELEASE_CHECKLIST.md`

## Play Console organization-only rejection check

Before the next submission, review every Play Console declaration that could classify the app as requiring an organization account. UNJAM is a casual puzzle collection, so declarations for regulated financial services, health services, government affiliation or other organization-only categories must only be selected if the shipped app actually provides those features.

Do not change a truthful declaration merely to bypass review. If a genuinely used feature requires an organization account, the correct fix is to publish from an eligible organization developer account.

## Listing verification before Production

- Preview every uploaded asset in Play Console.
- Verify the screenshots match the exact submitted build.
- Confirm the short description is at most 80 characters.
- Verify privacy policy, Data safety, Contains ads, target audience and content rating all match the actual build.
- Use Internal testing before Production and clear Play pre-launch report crashes, ANRs and policy warnings.
