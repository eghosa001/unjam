# UNJAM Completion Status

Updated: 2026-09-19  
Repository: `eghosa001/unjam`  
Branch: `ui/unified-world-backdrop`  
Latest implementation commit reviewed: `b58cb7e9745d131b265f2fcf1b444954c93e057f`

## Current gate

Final integration verification before merge to `main`.

## Issue inventory

- **P0:** none known.
- **P1 — AdMob Android native packaging:** fixed on this branch. The installer previously flattened the Poing AdMob Android template, causing `ads_CONFIGURATION_ERROR` to be injected into the APK manifest while export still succeeded. The installer now preserves the required `bin/<library>/...` hierarchy and asserts the core ads bridge/AARs exist. Debug and production CI now fail on missing AdMob libraries or any `_CONFIGURATION_ERROR` manifest marker. **Awaiting CI verification on the final branch head.**
- **P1 — gameplay / progression / viewport:** no known open defects from the latest automated campaign, gameplay, viewport, robustness, and visual contracts.
- **P2 — launcher visual continuity:** fixed. Home, game selector, secondary launcher surfaces, and Shop now reuse one persistent UNJAM world backdrop rather than swapping full-screen environments.
- **P2/P3:** no additional release-blocking code issues known at this checkpoint.

## Verified before the AdMob packaging correction

Godot CI run 1016 on `da0f4a94a22c839fec63de0b7f75503f48a6eeba` passed:
- Godot 4.7.2 import/script validation
- fast quality, monetization, viewport, robustness and premium UX contracts
- focused gameplay and 10,000-level campaign/progression contracts
- boot smoke
- rendered visual audit
- Android API 36 APK and AAB exports
- billing/package/permission manifest checks

That run is **not** counted as proof of working native AdMob packaging because its export log exposed the missing-library error found during manual log review.

## Visual states reviewed

Latest rendered audit includes compact 540x960 and standard portrait coverage across Home, level/game selection, Collection, tutorial/result states, Rescue Rush, Water Sort and Block Puzzle. The inspected Home, Water Sort and Block Puzzle captures showed no obvious clipping, overlap, undersized primary controls, duplicate Block pieces, or off-screen gameplay controls. Full real-device touch/performance/ad behavior remains a device/account verification item.

## Security / monetization / release

- Production purchase verification remains fail-closed and the release workflow requires the live verification URL.
- Release signing material is not committed; the production workflow requires owner-controlled secrets.
- Package identity remains `com.eghosa.unjamgam`.
- Android release gates include API 36 export, billing/ads manifest verification and 16 KB native-page compatibility.
- No secrets should be added to the repository.

## Owner/account actions that remain external to code completion

- Configure/confirm Play Console app, Play App Signing/upload key and release secrets.
- Deploy/authorize the live Google Play purchase-verification backend and Firestore ledger.
- Create/activate Play Billing products and pricing, then run licensed purchase/restore/refund tests.
- Complete truthful Play Data Safety, Contains Ads, advertising ID, target audience and content-rating declarations.
- Publish the privacy policy and root-hosted `app-ads.txt` on the developer website.
- Link/confirm the Play app in AdMob and allow account-side ad readiness to complete.
- Complete required internal/closed testing and real-device checks.

## Next unfinished action

Verify the final branch head in CI, confirm the APK/AAB export logs and packaged manifest contain no AdMob configuration error, review the final diff, then merge to `main` and verify the post-merge workflow.
