extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	ProjectSettings.set_setting("monetization/test_mode", true)
	var save_manager = root.get_node_or_null("SaveManager")
	var hint_manager = root.get_node_or_null("HintManager")
	var ad_manager = root.get_node_or_null("AdManager")
	var store_manager = root.get_node_or_null("StoreManager")
	var multi_game = root.get_node_or_null("MultiGameManager")
	expect_true(save_manager != null, "SaveManager autoload missing")
	expect_true(hint_manager != null, "HintManager autoload missing")
	expect_true(ad_manager != null, "AdManager autoload missing")
	expect_true(store_manager != null, "StoreManager autoload missing")
	expect_true(multi_game != null, "MultiGameManager autoload missing")
	if save_manager == null or hint_manager == null or ad_manager == null or store_manager == null or multi_game == null:
		quit(1)
		return

	var original_coins := int(save_manager.data.get("coins", 0))
	var original_remove := bool(save_manager.data.get("remove_ads", false))
	var original_rewarded := int(save_manager.data.get("rewarded_ads_watched", 0))
	var original_hints := int(save_manager.data.get("hints_used", 0))
	var original_starter := bool(save_manager.data.get("starter_pack_purchased", false))
	var original_lifetime_purchased := int(save_manager.data.get("lifetime_purchased_coins", 0))
	var original_purchased: Array = (save_manager.data.get("purchased_products", []) as Array).duplicate(true)
	var original_tokens: Array = (save_manager.data.get("processed_purchase_tokens", []) as Array).duplicate(true)
	var original_claims: Dictionary = (save_manager.data.get("purchase_claim_ids", {}) as Dictionary).duplicate(true)
	var original_install_id := String(save_manager.data.get("purchase_install_id", ""))
	var original_revocations: Array = (save_manager.data.get("processed_purchase_revocations", []) as Array).duplicate(true)
	var original_purchase_debt := int(save_manager.data.get("purchase_coin_debt", 0))
	var original_decorations: Array = (save_manager.data.get("decorations", []) as Array).duplicate(true)
	var original_sound := bool(save_manager.data.get("sound", true))
	var original_vibration := bool(save_manager.data.get("vibration", true))
	var original_music := bool(save_manager.data.get("music", true))
	var original_reduce_motion := bool(save_manager.data.get("reduce_motion", false))
	var original_fast_animation := bool(save_manager.data.get("fast_animation", false))
	var original_privacy_status := String(save_manager.data.get("privacy_consent_status", "unknown"))

	expect_true(store_manager.PRODUCTS.has(store_manager.PRODUCT_REMOVE_ADS), "remove ads product missing")
	expect_true(store_manager.PRODUCTS.has(store_manager.PRODUCT_STARTER_PACK), "starter pack missing")
	expect_true(store_manager.PRODUCTS.size() >= 5, "coin catalog incomplete")
	store_manager.confirm_purchase(store_manager.PRODUCT_COINS_SMALL, "desktop-test")
	await process_frame
	expect_true(int(save_manager.data.get("coins", 0)) == original_coins + 500, "coin purchase grant incorrect")
	store_manager.confirm_purchase(store_manager.PRODUCT_REMOVE_ADS, "desktop-test")
	await process_frame
	expect_true(bool(save_manager.data.get("remove_ads", false)), "remove ads not persisted")
	expect_true(not ad_manager.ads_enabled, "ads should be disabled after remove ads")

	# Hint economy: paid path consumes exactly the configured cost.
	save_manager.data.coins = int(hint_manager.HINT_COST)
	var paid_state := {"granted": false}
	var paid_ok := bool(hint_manager.request_hint("qa_paid", func() -> void: paid_state.granted = true))
	expect_true(paid_ok and bool(paid_state.granted), "paid hint was not granted")
	expect_true(int(save_manager.data.get("coins", -1)) == 0, "paid hint did not spend exactly the hint cost")

	# Rewarded fallback: with no coins, desktop test mode simulates a completed ad.
	var rewarded_before := int(save_manager.data.get("rewarded_ads_watched", 0))
	var ad_state := {"granted": false}
	var ad_ok := bool(hint_manager.request_hint("qa_rewarded", func() -> void: ad_state.granted = true))
	expect_true(ad_ok and bool(ad_state.granted), "rewarded-ad hint fallback did not grant after completion")
	expect_true(int(save_manager.data.get("rewarded_ads_watched", 0)) == rewarded_before + 1, "rewarded-ad completion was not recorded")

	# Verify the real gameplay HINT control is routed through HintManager, not the
	# old free show_hint callback, and that a busy pour can never consume coins.
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(4)
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(6)
	var game = main.get("active_game")
	expect_true(game != null and is_instance_valid(game), "Water Sort could not launch for hint UI validation")
	if game != null and is_instance_valid(game):
		var hint_button := _find_hint_button(game)
		expect_true(hint_button != null, "Gameplay hint button missing")
		if hint_button != null:
			expect_true("25" in hint_button.tooltip_text, "Hint control does not disclose its coin cost")

			# Simulate the exact invalid state that previously lost 25 coins.
			save_manager.data.coins = int(hint_manager.HINT_COST)
			var busy_hints_before := int(save_manager.data.get("hints_used", 0))
			game.active_source_tubes[0] = true
			hint_button.emit_signal("pressed")
			await _frames(2)
			expect_true(int(save_manager.data.get("coins", -1)) == int(hint_manager.HINT_COST), "Busy Water Sort hint incorrectly consumed coins")
			expect_true(int(save_manager.data.get("hints_used", 0)) == busy_hints_before, "Busy Water Sort hint incorrectly recorded/revealed a hint")
			game.active_source_tubes.clear()

			# Normal ready-state hint must still charge and reveal exactly once.
			var hints_before := int(save_manager.data.get("hints_used", 0))
			hint_button.emit_signal("pressed")
			await _frames(2)
			expect_true(int(save_manager.data.get("coins", -1)) == 0, "Real hint button bypassed the coin charge")
			expect_true(int(save_manager.data.get("hints_used", 0)) == hints_before + 1, "Real hint button did not reveal/record a hint")
	main.queue_free()
	await _frames(2)

	# Refunded consumables must never create a negative wallet. Any uncovered
	# amount becomes debt and is automatically settled before future coin grants.
	save_manager.data.coins = 100
	save_manager.data.purchase_coin_debt = 0
	economy.revoke_purchase_credit(150, {"product": store_manager.PRODUCT_COINS_SMALL, "qa": true})
	expect_true(int(save_manager.data.get("coins", -1)) == 0, "Refund clawback drove the wallet below zero")
	expect_true(int(save_manager.data.get("purchase_coin_debt", -1)) == 50, "Refund remainder was not recorded as debt")
	economy.grant(30, "qa_refund_debt_settlement")
	expect_true(int(save_manager.data.get("coins", -1)) == 0 and int(save_manager.data.get("purchase_coin_debt", -1)) == 20, "Future reward did not settle refund debt first")
	economy.grant(40, "qa_refund_debt_settlement")
	expect_true(int(save_manager.data.get("coins", -1)) == 20 and int(save_manager.data.get("purchase_coin_debt", -1)) == 0, "Refund debt did not settle cleanly")

	# Difficulty must stay varied but have a genuinely higher late-game baseline.
	expect_true(String(multi_game.difficulty_for_level(1)) == "easy", "Level 1 should remain easy onboarding")
	expect_true(String(multi_game.difficulty_for_level(25)) == "milestone", "Level 25 milestone cadence regressed")
	expect_true(String(multi_game.difficulty_for_level(100)) == "boss", "Level 100 boss cadence regressed")
	var early_hard := 0
	var late_hard := 0
	for n in range(1, 25):
		if String(multi_game.difficulty_for_level(n)) == "hard": early_hard += 1
	for n in range(7501, 7525):
		if String(multi_game.difficulty_for_level(n)) == "hard": late_hard += 1
	expect_true(late_hard > early_hard, "Late-game baseline difficulty is not higher than early-game baseline")

	# "Reset Progress" must reset gameplay only. Because purchased and earned
	# coins share one wallet, destroying the wallet can destroy paid value. Keep
	# wallet value, permanent decorations, user preferences, consent state, ad
	# history and Play-owned purchase records while level progression resets.
	var qa_token_fingerprint := "qa-reset-purchase-token".sha256_text()
	save_manager.data.coins = 777
	save_manager.data.decorations = ["qa_permanent_decoration"]
	save_manager.data.sound = false
	save_manager.data.vibration = false
	save_manager.data.music = false
	save_manager.data.reduce_motion = true
	save_manager.data.fast_animation = true
	save_manager.data.privacy_consent_status = "not_required"
	save_manager.data.rewarded_ads_watched = 12
	save_manager.data.remove_ads = true
	save_manager.data.starter_pack_purchased = true
	save_manager.data.purchased_products = [store_manager.PRODUCT_REMOVE_ADS, store_manager.PRODUCT_STARTER_PACK]
	save_manager.data.processed_purchase_tokens = [qa_token_fingerprint]
	save_manager.data.purchase_claim_ids = {}
	save_manager.data.purchase_claim_ids[qa_token_fingerprint] = "qa-reset-claim-id"
	save_manager.data.purchase_install_id = "qa-install-1234567890abcdef"
	save_manager.data.processed_purchase_revocations = ["b".repeat(64)]
	save_manager.data.purchase_coin_debt = 321
	save_manager.data.lifetime_purchased_coins = 4321
	save_manager.call("reset_progress")
	expect_true(int(save_manager.data.get("coins", -1)) == 777, "Reset Progress erased the wallet, which can contain paid coins")
	expect_true("qa_permanent_decoration" in (save_manager.data.get("decorations", []) as Array), "Reset Progress erased permanent decorations")
	expect_true(not bool(save_manager.data.get("sound", true)), "Reset Progress erased the sound preference")
	expect_true(not bool(save_manager.data.get("vibration", true)), "Reset Progress erased the vibration preference")
	expect_true(not bool(save_manager.data.get("music", true)), "Reset Progress erased the music preference")
	expect_true(bool(save_manager.data.get("reduce_motion", false)), "Reset Progress erased the reduced-motion preference")
	expect_true(bool(save_manager.data.get("fast_animation", false)), "Reset Progress erased the fast-animation preference")
	expect_true(String(save_manager.data.get("privacy_consent_status", "unknown")) == "not_required", "Reset Progress erased the privacy consent state")
	expect_true(int(save_manager.data.get("rewarded_ads_watched", 0)) == 12, "Reset Progress erased rewarded-ad accounting")
	expect_true(bool(save_manager.data.get("remove_ads", false)), "Reset Progress erased the Remove Ads entitlement")
	expect_true(bool(save_manager.data.get("starter_pack_purchased", false)), "Reset Progress erased the Starter Pack entitlement")
	expect_true(store_manager.PRODUCT_REMOVE_ADS in (save_manager.data.get("purchased_products", []) as Array), "Reset Progress erased the purchased Remove Ads record")
	expect_true(store_manager.PRODUCT_STARTER_PACK in (save_manager.data.get("purchased_products", []) as Array), "Reset Progress erased the purchased Starter Pack record")
	expect_true(qa_token_fingerprint in (save_manager.data.get("processed_purchase_tokens", []) as Array), "Reset Progress erased processed purchase-token fingerprints")
	expect_true(String((save_manager.data.get("purchase_claim_ids", {}) as Dictionary).get(qa_token_fingerprint, "")) == "qa-reset-claim-id", "Reset Progress erased the purchase claim retry ledger")
	expect_true(String(save_manager.data.get("purchase_install_id", "")) == "qa-install-1234567890abcdef", "Reset Progress erased the purchase installation id")
	expect_true("b".repeat(64) in (save_manager.data.get("processed_purchase_revocations", []) as Array), "Reset Progress erased processed refund fingerprints")
	expect_true(int(save_manager.data.get("purchase_coin_debt", 0)) == 321, "Reset Progress erased refund debt")
	expect_true(int(save_manager.data.get("lifetime_purchased_coins", 0)) == 4321, "Reset Progress erased lifetime purchased-coin accounting")

	# Restore persistent QA state.
	save_manager.data.coins = original_coins
	save_manager.data.remove_ads = original_remove
	save_manager.data.rewarded_ads_watched = original_rewarded
	save_manager.data.hints_used = original_hints
	save_manager.data.starter_pack_purchased = original_starter
	save_manager.data.lifetime_purchased_coins = original_lifetime_purchased
	save_manager.data.purchased_products = original_purchased
	save_manager.data.processed_purchase_tokens = original_tokens
	save_manager.data.purchase_claim_ids = original_claims
	save_manager.data.purchase_install_id = original_install_id
	save_manager.data.processed_purchase_revocations = original_revocations
	save_manager.data.purchase_coin_debt = original_purchase_debt
	save_manager.data.decorations = original_decorations
	save_manager.data.sound = original_sound
	save_manager.data.vibration = original_vibration
	save_manager.data.music = original_music
	save_manager.data.reduce_motion = original_reduce_motion
	save_manager.data.fast_animation = original_fast_animation
	save_manager.data.privacy_consent_status = original_privacy_status
	ad_manager.ads_enabled = not original_remove
	save_manager.save()

	if failures.is_empty():
		print("MONETIZATION + HINT ECONOMY + DIFFICULTY VALIDATION PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _find_hint_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and "HINT" in child.text.to_upper():
			return child
		var nested := _find_hint_button(child)
		if nested != null:
			return nested
	return null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
