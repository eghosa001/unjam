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
