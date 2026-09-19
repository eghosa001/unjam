# UNJAM Completion Status

Updated: 2026-09-19  
Repository: `eghosa001/unjam`  
Branch: `ui/unified-world-backdrop`  
Latest implementation commit reviewed: `4d3761c601d4ff1c8a46928b74a4da8f83ad2b36`

## Current gate

The implementation candidate passed the full Godot CI release-quality gate in run 1036. Merge remains gated on the exact PR head being green after this completion-status update, followed by post-merge verification on `main`.

## Issue inventory

- **P0:** none known.
- **P1 — AdMob Android native packaging:** fixed and verified. The installer now preserves the Poing AdMob Android template's required `bin/<library>/...` hierarchy, asserts the ads bridge/AARs exist, and CI rejects missing AdMob libraries or any packaged `_CONFIGURATION_ERROR` marker.
- **P1 — compact selector lifecycle:** fixed and verified. Compact layouts no longer allocate unattached `WorldProgress` controls/style resources, eliminating the Godot ObjectDB/RID shutdown leak while keeping all three game cards and Play actions visible at 540x960.
- **P1 — gameplay / progression / viewport:** no known open defects from the final automated gameplay, campaign, viewport, robustness, monetization and UX contracts.
- **P2 — launcher visual continuity:** fixed. Home, game selector, secondary launcher surfaces and Shop reuse one persistent UNJAM world backdrop.
- **P2/P3:** no additional release-blocking code issues known.

## Verified implementation candidate

Godot CI run 1036 on `4d3761c601d4ff1c8a46928b74a4da8f83ad2b36` passed:
- Godot 4.7.2 import/script validation
- purchase-verifier backend tests
- fast quality, monetization, viewport, robustness and premium UX contracts
- flat-board 3D-effects architecture and idle-cost contracts
- focused gameplay and 10,000-level campaign/progression contracts
- boot smoke
- rendered visual audit
- Android API 36 debug APK export
- packaged AdMob/Google Play Billing manifest verification with no configuration-error marker
- Android API 36 debug AAB export

## Visual states reviewed

The final rendered audit covers dark/light Home, game selector, Rescue Rush/Water Sort/Block Puzzle level selectors, Collection, Settings, Shop, all three gameplay screens, tutorial and result states, including compact 540x960 captures. The compact Choose a Game screen now shows Rescue Rush, Water Sort and Block Puzzle together with their Play actions before scrolling. No obvious clipping, overlap, duplicate Block pieces, off-screen primary controls or undersized primary actions were found in the inspected audit.

## Security / monetization / release

- Production purchase verification remains fail-closed and the production workflow requires the live verification URL.
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
- Complete required internal/closed testing and real-device touch/performance/ad checks.

## Release sequence

Require a green exact-head PR CI check, review the final diff, merge PR #44 to `main`, then require the post-merge workflows to pass on the resulting `main` commit before treating repository completion as finished.
