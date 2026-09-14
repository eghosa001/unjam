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
	# old free show_hint callback.
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
			expect_true("25" in hint_button.text, "Hint button does not disclose its coin cost")
			save_manager.data.coins = int(hint_manager.HINT_COST)
			var hints_before := int(save_manager.data.get("hints_used", 0))
			hint_button.emit_signal("pressed")
			await _frames(2)
			expect_true(int(save_manager.data.get("coins", -1)) == 0, "Real hint button bypassed the coin charge")
			expect_true(int(save_manager.data.get("hints_used", 0)) == hints_before + 1, "Real hint button did not reveal/record a hint")
	main.queue_free()
	await _frames(2)

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

	# Restore persistent QA state.
	save_manager.data.coins = original_coins
	save_manager.data.remove_ads = original_remove
	save_manager.data.rewarded_ads_watched = original_rewarded
	save_manager.data.hints_used = original_hints
	save_manager.data.purchased_products = []
	save_manager.data.processed_purchase_tokens = []
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
