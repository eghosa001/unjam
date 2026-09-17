# UNJAM Store and Coin Economy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose the existing UNJAM store and make coins a consistent shared currency for hints, Water Sort extra tubes, ads, rewards, purchases, and live wallet displays.

**Architecture:** Introduce `EconomyManager` as the gameplay-facing wallet API while keeping `SaveManager` as persistence, `StoreManager` as Google Play purchase authority, and `AdManager` as ad lifecycle authority. UI listens to one balance signal so Home, secondary surfaces, gameplay, and Shop stay synchronized without reloads.

**Tech Stack:** Godot 4.7.2, GDScript, existing Google Play Billing bridge, existing AdMob integration, existing SaveManager/StoreManager/AdManager architecture.

**Spec:** `docs/superpowers/specs/2026-09-17-store-coin-economy-design.md`

## Global Constraints

- Work only on branch `visual-reboot-3d-build-final2`; do not merge PR #17.
- Preserve current premium 3D visual direction and current gameplay logic.
- Hint cost: 25 coins across all three games.
- Water Sort Extra Tube cost: 75 coins, maximum one paid extra tube per attempt.
- Rewarded Shop ad: 50 coins.
- No negative balances and no duplicate grants/charges.
- Keep purchase verification, pending-purchase, consent, restore, and Remove Ads behavior intact.
- No subscriptions or second currency.

---

### Task 1: Wallet/Economy API

**Files:**
- Create: `scripts/systems/economy_manager.gd`
- Modify: `project.godot`
- Test: `tests/validate_coin_economy.gd`

**Interfaces:**
- Produces: `EconomyManager.balance() -> int`
- Produces: `EconomyManager.can_afford(amount: int) -> bool`
- Produces: `EconomyManager.spend(amount: int, reason: String, metadata: Dictionary = {}) -> bool`
- Produces: `EconomyManager.grant(amount: int, reason: String, metadata: Dictionary = {}) -> int`
- Produces signals: `balance_changed(new_balance: int, delta: int, reason: String)` and `transaction_recorded(transaction: Dictionary)`

- [ ] **Step 1: Write the failing wallet test**

Create `tests/validate_coin_economy.gd` that asserts missing `EconomyManager` behavior: starting from 100 coins, spend 25 succeeds and emits balance 75; spend 100 then fails and leaves 75; grant 50 produces 125; zero/negative transaction requests are rejected/no-op.

- [ ] **Step 2: Run RED**

Run: `timeout 45s godot --headless --path . --script res://tests/validate_coin_economy.gd`
Expected: FAIL because `EconomyManager` is not registered/implemented.

- [ ] **Step 3: Implement minimal EconomyManager**

Create the autoload node using SaveManager persistence, clamp inputs, mutate via SaveManager `add_coins`/`spend_coins`, emit balance/transaction signals after successful mutations, and add it to `[autoload]` in `project.godot`.

- [ ] **Step 4: Run GREEN**

Run the same Godot test; expected `COIN_ECONOMY_OK` and exit code 0.

- [ ] **Step 5: Commit**

Commit message: `feat: centralize coin economy`

### Task 2: Charge All Gameplay Assists Consistently

**Files:**
- Modify: `scripts/systems/hint_manager.gd`
- Modify: `scripts/game/water_sort_assisted.gd`
- Test: `tests/validate_assist_economy_runtime.gd`

**Interfaces:**
- Consumes: `EconomyManager.spend(...)`, `EconomyManager.balance()`
- Keeps: HintManager rewarded-ad fallback behavior
- Produces: `WaterSort.EXTRA_TUBE_COST := 75`

- [ ] **Step 1: Write failing assist-economy test**

Test the three HintManager placements at exactly 25 coins and Water Sort extra tube at exactly 75 coins. Verify insufficient balance does not invoke hint/tube behavior. Verify a second Extra Tube tap cannot charge again.

- [ ] **Step 2: Run RED**

Run: `timeout 60s godot --headless --path . --script res://tests/validate_assist_economy_runtime.gd`
Expected: FAIL because HintManager still spends directly and Water Sort tube is free.

- [ ] **Step 3: Route HintManager through EconomyManager**

Use reason `hint_%s` for game id, keep 25 coin cost, and only call the hint after successful spend or rewarded completion.

- [ ] **Step 4: Charge Extra Tube before mutation**

Add `EXTRA_TUBE_COST = 75`; reject while completed/busy/already-used; spend `75` with reason `extra_tube` immediately before appending the tube; if spend fails, do not modify history, tubes, checkpoint, or `extra_tube_used`.

- [ ] **Step 5: Run GREEN**

Run the test and existing assist runtime tests:
`validate_assist_economy_runtime`, `validate_rescue_hint_exec`, `validate_water_assist_runtime`, `validate_block_hint_exec_runtime`.

- [ ] **Step 6: Commit**

Commit message: `feat: charge hints and extra tube consistently`

### Task 3: Route Coin Grants Through EconomyManager

**Files:**
- Modify: `scripts/systems/ad_manager.gd`
- Modify: `scripts/systems/store_manager.gd`
- Modify: `scripts/core/robust_save_manager.gd` only where needed to expose semantic reward hooks without changing progression math
- Test: `tests/validate_coin_grants.gd`

**Interfaces:**
- Consumes: `EconomyManager.grant(...)`
- Keep StoreManager purchase token de-duplication exactly once.

- [ ] **Step 1: Write failing grant test**

Verify rewarded ad grants 50 through the economy signal, Starter Pack grants 1,000 once, consumable coin packs grant configured amounts, and replaying a processed purchase token does not grant again.

- [ ] **Step 2: Run RED**

Run: `timeout 60s godot --headless --path . --script res://tests/validate_coin_grants.gd`
Expected: FAIL because grants bypass the new economy signal/reason path.

- [ ] **Step 3: Implement grant routing**

Use reason codes `rewarded_ad`, `purchase`, `level_reward`, `daily_reward` where the matching code path is touched. Preserve existing progression reward amounts.

- [ ] **Step 4: Run GREEN**

Run the new test plus `validate_monetization`, `validate_billing_production`, `validate_admob_production`, and `validate_retention`.

- [ ] **Step 5: Commit**

Commit message: `refactor: route coin grants through economy`

### Task 4: Make Shop Discoverable from Home

**Files:**
- Modify: `scripts/ui/premium_home_casual.gd`
- Modify: `scripts/ui/monetization_hub_3d.gd`
- Test: `tests/validate_shop_navigation_runtime.gd`

**Interfaces:**
- Home calls `Main/MonetizationHub.open_shop()`.
- Coin badge becomes interactive and opens the same Shop overlay.

- [ ] **Step 1: Write failing navigation test**

Instantiate Main, build Home, assert a visible `SHOP` control exists, press it, and assert MonetizationHub overlay is visible. Also press the Home coin balance action and assert the same Shop opens.

- [ ] **Step 2: Run RED**

Run: `timeout 45s godot --headless --path . --script res://tests/validate_shop_navigation_runtime.gd`
Expected: FAIL because active Home has no Shop entry and the coin badge is non-interactive.

- [ ] **Step 3: Add Home Shop routes**

Add `SHOP` to bottom navigation while keeping touch targets large enough for narrow phones. Replace the coin status badge with an equivalent premium button/badge whose `+` action opens Shop.

- [ ] **Step 4: Run GREEN and viewport regression**

Run the Shop test plus `validate_viewport_fit` and `validate_navigation_surface_coverage`.

- [ ] **Step 5: Commit**

Commit message: `feat: expose shop from home`

### Task 5: Reorganize Shop and Live Wallet UI

**Files:**
- Modify: `scripts/ui/monetization_hub_3d.gd`
- Modify: `scripts/ui/premium_main_casual.gd`
- Modify active gameplay scripts only as needed for wallet labels
- Test: `tests/validate_live_wallet_ui.gd`

**Interfaces:**
- UI listens to `EconomyManager.balance_changed`.
- Shop groups products into Remove Ads, Starter Pack, Coin Packs, Free Coins.

- [ ] **Step 1: Write failing live-wallet test**

Open Home, Levels, Collection, Shop, and representative game screens; grant/spend coins through EconomyManager; assert visible wallet labels update without rebuilding the whole scene.

- [ ] **Step 2: Run RED**

Run: `timeout 60s godot --headless --path . --script res://tests/validate_live_wallet_ui.gd`
Expected: FAIL because wallet labels are currently snapshots.

- [ ] **Step 3: Add wallet binding helper and Shop grouping**

Use one helper to bind labels/buttons to `balance_changed`. In Shop, render explicit section headers and keep localized Play price, `OWNED`, and `PENDING` states.

- [ ] **Step 4: Run GREEN and visual contracts**

Run new test, `validate_premium_ux`, `validate_visual_quality_contract`, `validate_uiux_regressions`, and `validate_viewport_fit`.

- [ ] **Step 5: Commit**

Commit message: `feat: add live wallet and organized shop`

### Task 6: Insufficient-Coin Recovery Panel

**Files:**
- Create: `scripts/ui/insufficient_coins_prompt.gd`
- Modify: `scripts/systems/hint_manager.gd`
- Modify: `scripts/game/water_sort_assisted.gd`
- Modify: `scenes/Main.tscn` only if a persistent host is required
- Test: `tests/validate_insufficient_coins_prompt.gd`

**Interfaces:**
- Produces: `show_for(action_name: String, cost: int, retry: Callable = Callable())`
- `OPEN SHOP` invokes MonetizationHub.
- `WATCH AD +50` uses `AdManager.reward_coins(...)` and can optionally retry the requested assist after reward completion if the new balance covers it.

- [ ] **Step 1: Write failing prompt test**

Attempt a hint and Extra Tube with zero coins. Assert action does not execute and prompt exposes Shop + rewarded actions. Simulate rewarded completion and verify exactly 50 coins are granted and the action cannot be double-triggered.

- [ ] **Step 2: Run RED**

Run: `timeout 60s godot --headless --path . --script res://tests/validate_insufficient_coins_prompt.gd`
Expected: FAIL because current failure is text-only.

- [ ] **Step 3: Implement prompt**

Use the existing premium 3D theme, large touch targets, one overlay owner, and a busy guard for the rewarded action.

- [ ] **Step 4: Integrate Hint and Extra Tube failures**

Replace text-only insufficient-funds failure with the prompt while preserving busy/completed errors as ordinary status messages.

- [ ] **Step 5: Run GREEN**

Run new test plus navigation, viewport, monetization, and assist-runtime tests.

- [ ] **Step 6: Commit**

Commit message: `feat: add insufficient coin recovery flow`

### Task 7: Final Regression and PR Update

**Files:**
- Modify: `.github/workflows/godot-ci.yml` only to add new focused tests to the existing fast/focused lists if required
- Modify: PR #17 body after verification

- [ ] **Step 1: Import and parse check**

Run: `godot --headless --path . --editor --quit` and reject SCRIPT ERROR/Parse Error/Invalid access output.

- [ ] **Step 2: Run all new economy tests**

Run all tests created in Tasks 1-6.

- [ ] **Step 3: Run impacted existing contracts**

Run: `validate_monetization`, `validate_admob_production`, `validate_billing_production`, `validate_rescue_hint_exec`, `validate_water_assist_runtime`, `validate_block_hint_exec_runtime`, `validate_home_direct_levels_runtime`, `validate_navigation_surface_coverage`, `validate_uiux_regressions`, `validate_viewport_fit`, `validate_premium_ux`, `validate_visual_quality_contract`.

- [ ] **Step 4: Boot smoke**

Run: `godot --headless --path . --quit-after 5` and reject script/runtime errors.

- [ ] **Step 5: Update CI list and PR body**

Add the new tests to CI and document verified behavior. Keep PR #17 draft/unmerged.

- [ ] **Step 6: Commit**

Commit message: `test: verify store and coin economy pass`
