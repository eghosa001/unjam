# UNJAM Store and Coin Economy Design

## Goal

Make monetization discoverable and make coins a coherent shared gameplay currency across Rescue Rush, Water Sort, Block Puzzle, rewarded ads, level rewards, garden purchases, and Google Play purchases without changing the current premium visual direction.

## Current State

The project already has a production-oriented StoreManager, Google Play billing bridge, purchase verification hooks, rewarded ads, Remove Ads, Starter Pack, and three coin packs. The shop UI also exists as MonetizationHub3D, but its launcher is hidden and the active Home navigation does not expose Shop. HintManager charges 25 coins, while Water Sort's extra tube is currently free. Coin mutations are performed directly through SaveManager, so UI refresh and reason tracking are inconsistent.

## Economy Rules

- One shared wallet is stored in `SaveManager.data.coins`.
- Hint cost is 25 coins in Rescue Rush, Water Sort, and Block Puzzle.
- Water Sort Extra Tube cost is 75 coins and remains limited to one extra tube per attempt.
- Rewarded shop ad grants 50 coins.
- Existing first-clear, star-improvement, milestone, world, daily, achievement, garden, and purchased-coin rewards remain intact unless they conflict with duplicate-grant protection.
- Player balance must never become negative.
- A paid assist may execute only after its charge succeeds.
- Rapid repeated taps must not charge an assist twice while the first action is still being accepted/executed.
- Every wallet mutation records a reason code for analytics/debugging, including `hint_rescue_rush`, `hint_water_sort`, `hint_block_puzzle`, `extra_tube`, `rewarded_ad`, `level_reward`, `purchase`, `daily_reward`, and `garden_purchase` where applicable.

## Architecture

Add a small `EconomyManager` autoload as the single gameplay-facing API for balance reads, grants, and spends. It delegates persistence to SaveManager, emits `balance_changed`, and emits transaction metadata. Existing StoreManager remains the source of truth for Google Play products and verified purchase ownership. Existing AdManager remains the source of truth for rewarded/interstitial ad lifecycle.

HintManager will use EconomyManager rather than directly spending through SaveManager. Water Sort will charge through EconomyManager before adding the one-use extra tube. StoreManager and AdManager coin grants will also route through EconomyManager so purchased and rewarded balances update live everywhere.

## Shop UX

The active Home screen will visibly expose Shop in two ways:

1. A `SHOP` entry in the bottom navigation.
2. The coin balance badge/plus action opens Shop directly.

The current MonetizationHub3D overlay will be reorganized into four clear sections:

- Remove Ads
- Starter Pack
- Coin Packs
- Free Coins (rewarded ad)

Owned non-consumables show `OWNED`; Play pending purchases show `PENDING`; restore purchase and privacy controls remain available. The current Play Billing verification requirement stays unchanged.

## Wallet UX

Home, Levels, Settings/Collection headers where applicable, and all three gameplay screens must show the current live coin balance without requiring a scene reload. EconomyManager's `balance_changed` signal drives refreshes.

If a player cannot afford an assist, the app shows one premium insufficient-coins prompt with two useful routes:

- `OPEN SHOP`
- `WATCH AD +50`

If rewarded ads are unavailable, the UI states that clearly and keeps Shop available. Assist action must not execute until payment or rewarded unlock has succeeded.

## Purchase Safety

- Keep StoreManager purchase-token fingerprinting and verified exactly-once grants.
- Keep Android purchases blocked when secure verification URL is missing.
- Do not fake real-money prices; use localized Play prices when supplied.
- Remove Ads remains non-consumable and disables interstitial ads after verified ownership.
- Starter Pack remains non-consumable and grants Remove Ads + 1,000 coins exactly once.
- Consumable coin packs grant their configured amount only after verification.

## Tests

Add focused Godot contracts that verify:

- Shop is reachable from Home navigation and coin badge.
- Wallet balance signal/UI refresh works after earn/spend.
- Hint costs 25 coins in each game and does not execute when payment fails.
- Water Sort Extra Tube costs 75 coins, charges exactly once, and cannot double-charge on repeat taps.
- Insufficient-funds prompt exposes Shop and rewarded-ad routes.
- Rewarded coin grant is 50 and occurs once per completed reward.
- Remove Ads ownership still disables interstitial eligibility.
- Existing purchase token de-duplication remains intact.

## Non-goals

- Do not redesign the three games again.
- Do not add a second premium currency.
- Do not add subscriptions.
- Do not weaken purchase verification or consent requirements.
- Do not change Google Play product IDs in this pass.
