extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var save = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	expect_true(save != null and economy != null, "Economy autoloads missing")
	if save == null or economy == null:
		_finish()
		return

	var original_coins := int(save.data.get("coins", 0))
	save.data.coins = 210
	save.save()

	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(5)

	main.call("build_collection")
	await _frames(3)
	var collection_wallet := main.find_child("FigmaHeaderPill", true, false) as Button
	expect_true(collection_wallet != null and collection_wallet.visible, "Collection has no Figma coin Shop action")
	if collection_wallet != null:
		expect_true(collection_wallet.text == "◈ +", "Collection coin pill drifted from Figma")
		expect_true("210" in collection_wallet.tooltip_text, "Collection coin pill does not expose current balance")
		economy.grant(15, "qa_collection_wallet")
		await _frames(2)
		expect_true("225" in collection_wallet.tooltip_text, "Collection coin pill did not update live")

	main.call("open_game_campaign", "rescue_rush")
	await _frames(3)
	var rescue_wallet := main.find_child("FigmaHeaderPill", true, false) as Button
	expect_true(rescue_wallet != null and rescue_wallet.visible, "Rescue Levels has no Figma coin Shop action")
	if rescue_wallet != null:
		expect_true(rescue_wallet.text == "◈ +", "Rescue Levels coin pill drifted from Figma")
		expect_true("225" in rescue_wallet.tooltip_text, "Rescue Levels wallet balance is stale")

	main.call("open_game_campaign", "water_sort")
	await _frames(3)
	var water_wallet := main.find_child("FigmaHeaderPill", true, false) as Button
	expect_true(water_wallet != null and water_wallet.visible, "Water Sort Levels has no Figma coin Shop action")
	if water_wallet != null:
		expect_true(water_wallet.text == "◈ +", "Water Levels coin pill drifted from Figma")
		economy.grant(25, "qa_levels_wallet")
		await _frames(2)
		expect_true("250" in water_wallet.tooltip_text, "Levels wallet did not update live")
		water_wallet.emit_signal("pressed")
		await _frames(2)
		var hub := main.get_node_or_null("MonetizationHub")
		var overlay = hub.get("overlay") if hub != null else null
		expect_true(overlay is Control and overlay.visible, "Secondary wallet action did not open Shop")

	main.queue_free()
	await _frames(2)
	save.data.coins = original_coins
	save.save()
	_finish()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("SECONDARY_WALLET_SHOP_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
