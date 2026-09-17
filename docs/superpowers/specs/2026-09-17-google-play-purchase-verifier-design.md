# UNJAM Google Play Purchase Verifier Design

## Goal
Provide UNJAM with a small production backend for Google Play one-time-product verification without Supabase or player accounts.

## Architecture
UNJAM calls a public HTTPS Cloud Run service. The service validates the purchase token against the Google Play Developer API using the Cloud Run service account, then uses Firestore only as an idempotency ledger. The ledger never stores a raw Play purchase token; its document key is a SHA-256 fingerprint.

The protocol has two endpoints: `POST /verify` and `POST /commit`. `/verify` validates Google Play ownership and creates or reuses a claim. A first claim returns `grant=true`; a retry with the same claim ID also returns `grant=true`; a different/new installation or a committed claim returns `grant=false`. `/commit` marks that claim committed only after the game has persisted the reward locally. This narrows the crash/retry window and prevents clearing app data or using a second device from repeatedly granting the Starter Pack or consumable coins.

## Product contract
Package: `com.eghosa.unjam`.

Allowed products:
- `unjam_remove_ads` — non-consumable entitlement.
- `unjam_starter_pack` — non-consumable Remove Ads entitlement plus a one-time 1,000-coin reward.
- `unjam_coins_500` — consumable.
- `unjam_coins_1500` — consumable.
- `unjam_coins_4000` — consumable.

A duplicate non-consumable remains a valid entitlement. Therefore the server can return `valid=true`, `grant=false`, `entitlement=true`. The client restores Remove Ads but does not regrant Starter Pack coins. Duplicate consumables return `valid=true`, `grant=false`, `entitlement=false`.

## Google Play verification
Use Google Play Developer API v3 `purchases.productsv2.getproductpurchasev2`, which validates the token using package name and token. Accept only `PURCHASED` purchases and require the requested product ID to occur in `productLineItem`. Authentication uses Application Default Credentials with the `https://www.googleapis.com/auth/androidpublisher` scope. The Cloud Run runtime service account must be granted access to the new app in Play Console.

## Firestore ledger
Collection: `play_purchase_claims`.

Document ID: `sha256(purchase_token)`.

Stored fields: package name, product ID, order ID when returned by Play, purchase completion time, state (`issued` or `committed`), claim ID, first/last seen timestamps, and committed timestamp. Never persist or log the raw purchase token.

## Client changes
The Godot save gains `purchase_claim_ids`, a dictionary keyed by token fingerprint. The value is a random per-install claim ID created before first verification and persisted before the network request. Gameplay reset preserves this dictionary. Robust save sanitization only permits SHA-256 keys and bounded claim-ID strings.

`PurchaseVerifier` sends the claim ID and parses `valid`, `grant`, `entitlement`, `claim_id`, and `reason`. After StoreManager persists a new reward locally, it calls `/commit`. Google Play consume/acknowledge finalization occurs after a successful commit. If a commit fails, the purchase remains unfinalized so reconciliation retries it; the local token fingerprint prevents another local reward grant.

## Security and privacy
The endpoint is public because the game has no account system. Security comes from Google Play token verification, exact package/product allowlists, strict body limits, no redirects from the game verifier, no raw-token logging, and a Firestore transaction for claims. No Google service-account JSON key is committed: Cloud Run uses its attached runtime identity.

## Testing
Node tests cover input validation, Play state/product matching, first claim, same-claim retry, different-claim duplicate, committed duplicate, and commit authorization. Godot validators cover server `grant=false` behavior, claim-ID persistence, and reset preservation. Full repository CI remains the merge gate.
