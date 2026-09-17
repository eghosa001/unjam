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
	save.data.coins = 125
	save.save()

	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(5)
	if main.has_method("build_game_selector"):
		main.call("build_game_selector")
	elif main.has_method("build_live"):
		main.call("build_live")
	else:
		main.set("current_surface", "live")
	await _frames(5)

	var live := main.get_node_or_null("PremiumLive")
	expect_true(live != null and live.visible, "Choose Game live surface did not open")
	var wallet: Button = null
	if live != null:
		wallet = live.find_child("LiveCoinShopButton", true, false) as Button
	expect_true(wallet != null and wallet.visible, "Choose Game has no visible coin Shop action")
	if wallet != null:
		expect_true("125" in wallet.text, "Choose Game wallet does not show current balance")
		economy.grant(50, "qa_live_wallet")
		await _frames(2)
		expect_true("175" in wallet.text, "Choose Game wallet did not update live after coin grant")
		wallet.emit_signal("pressed")
		await _frames(2)
		var hub := main.get_node_or_null("MonetizationHub")
		var overlay = hub.get("overlay") if hub != null else null
		expect_true(overlay is Control and overlay.visible, "Choose Game coin action did not open Shop")

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
		print("LIVE_WALLET_SHOP_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
