extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func run() -> void:
	await process_frame
	var save_manager = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	var original_coins := int(save_manager.data.get("coins", 0)) if save_manager != null else 0
	if save_manager != null:
		save_manager.data.coins = 123
		save_manager.save()

	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(6)
	var home := main.get_node_or_null("PremiumHome")
	var hub := main.get_node_or_null("MonetizationHub")
	expect_true(home != null, "Premium Home missing")
	expect_true(hub != null, "MonetizationHub missing")
	if home != null and home.has_method("build_home_launcher"):
		home.call("build_home_launcher")
		await _frames(2)

	var retired_shop_nav: Button = null
	var daily_nav: Button = null
	var coin_shop: Button = null
	if home != null:
		retired_shop_nav = home.find_child("HomeShopNavButton", true, false) as Button
		daily_nav = home.find_child("HomeDailyNavButton", true, false) as Button
		coin_shop = home.find_child("HomeCoinShopButton", true, false) as Button
	expect_true(retired_shop_nav == null, "Retired Shop tab is still present in Home persistent navigation")
	expect_true(daily_nav != null and daily_nav.visible, "Home persistent navigation has no visible Daily entry")
	expect_true(coin_shop != null and coin_shop.visible, "Home coin balance is not the Shop action")
	if coin_shop != null:
		expect_true("123" in coin_shop.text, "Home coin Shop action does not show wallet balance")

	if coin_shop != null and hub != null:
		coin_shop.emit_signal("pressed")
		await _frames(2)
		var overlay: Variant = hub.get("overlay")
		var shop_open: bool = overlay is Control and (overlay as Control).visible
		expect_true(shop_open, "Coin balance action did not open Shop overlay")
		if hub.has_method("_close_shop"):
			hub.call("_close_shop")

	if economy != null and coin_shop != null:
		economy.grant(50, "qa_wallet_refresh")
		await _frames(2)
		expect_true("173" in coin_shop.text, "Home wallet did not refresh after EconomyManager balance signal")

	if daily_nav != null:
		daily_nav.emit_signal("pressed")
		await _frames(3)
		expect_true(String(main.get("current_surface")) == "daily", "Home Daily navigation did not open Daily Games")

	main.call("build_settings")
	await _frames(2)
	var settings_purchases := main.find_child("SettingsPurchases", true, false) as Button
	expect_true(settings_purchases != null and settings_purchases.visible, "Settings has no visible Purchases entry")
	if settings_purchases != null and hub != null:
		settings_purchases.emit_signal("pressed")
		await _frames(2)
		var settings_overlay: Variant = hub.get("overlay")
		expect_true(settings_overlay is Control and (settings_overlay as Control).visible, "Settings Purchases entry did not open Shop")
		if hub.has_method("_close_shop"):
			hub.call("_close_shop")

	main.queue_free()
	await _frames(2)
	if save_manager != null:
		save_manager.data.coins = original_coins
		save_manager.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("SHOP_NAVIGATION_RUNTIME_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)