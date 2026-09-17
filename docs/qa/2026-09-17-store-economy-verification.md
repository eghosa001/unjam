# UNJAM Store / Coin Economy Verification Note

This file records the exact verification target for the current Store and coin-economy pass on `visual-reboot-3d-build-final2`.

Current behavior under test:

- Home exposes Shop from the bottom navigation and the live coin balance control.
- Choose Game exposes a live coin Shop control rather than a passive snapshot.
- Hint costs 25 coins across Rescue Rush, Water Sort, and Block Puzzle.
- Water Sort Extra Tube costs 75 coins and can be purchased once per attempt.
- Shop sections are Remove Ads, Starter Pack, Coin Packs, and Free Coins.
- Rewarded coin grant is +50 coins.
- Insufficient-coins recovery offers Shop and rewarded coins.
- Restore Purchases must wait for verification and count only verified restored entitlements.
- Purchase-token de-duplication and secure verification remain mandatory.

Verification must be performed by the repository's Godot 4.7.2 CI at the exact branch head. This note intentionally changes documentation only so the open draft PR receives a fresh `synchronize` event without altering runtime behavior.
