# UNJAM Monetization Release Notes

## AdMob

Production Android App ID:
`ca-app-pub-7517898921176341~1892369383`

Production rewarded unit:
`ca-app-pub-7517898921176341/2926249456`

Production interstitial unit:
`ca-app-pub-7517898921176341/9108514429`

Debug builds must use Google's official Android test ad-unit IDs. Release builds use the production IDs above through `scripts/systems/admob_config.gd`.

Rewarded ads are opt-in and are used for the hint fallback. A hint is granted only from the earned-reward callback. Closing or failing an ad does not grant the reward.

Interstitials are limited to natural breaks. Current guardrails include a minimum level history, a multi-level interval, a time cooldown, and a per-session cap. Remove Ads disables interstitials.

## Consent and privacy

Android ad requests are blocked until the UMP consent state is `obtained` or `not_required`. The Settings screen exposes Privacy Options. If the consent/plugin path is unavailable, ads fail closed.

The privacy policy source is `docs/privacy.html`.

The publisher record is `docs/app-ads.txt`:

`google.com, pub-7517898921176341, DIRECT, f08c47fec0942fa0`

For AdMob app verification, this file must be publicly reachable at the root of the developer website domain used by the Google Play listing, e.g. `https://<developer-domain>/app-ads.txt`.

## Google Play Billing

Product IDs currently expected by the app:

- `unjam_remove_ads`
- `unjam_starter_pack`
- `unjam_coins_500`
- `unjam_coins_1500`
- `unjam_coins_4000`

The Android bridge uses Google Play Billing 3.3.0 integration and supports connection, localized product detail queries, purchase callbacks, restore, consumption and acknowledgement.

Purchases intentionally fail closed on Android until `monetization/purchase_verification_url` is a real HTTPS endpoint that verifies Google Play purchase tokens server-side.

## Plugin versions

CI installs:

- Poing Godot AdMob v5.1.0
- Poing Android native template for Godot 4.7.2
- Godot Google Play Billing 3.3.0

The install entrypoint is `tools/install_monetization_plugins.sh`.

## Before public monetized release

1. Publish/link the Google Play listing in AdMob.
2. Make `app-ads.txt` publicly reachable from the Play listing developer website domain.
3. Complete AdMob/UMP privacy messaging configuration.
4. Set Play Console `Contains ads` accurately.
5. Complete Data Safety and target-audience declarations based on the actual shipped SDKs and audience.
6. Create the five product IDs above in Play Console if in-app purchases will ship.
7. Configure and test the HTTPS purchase-verification backend before enabling purchases.
8. Use Play license testers and Google test ads during development; do not click live ads during testing.
9. Require a green exact-commit CI run plus Internal testing before Production.
