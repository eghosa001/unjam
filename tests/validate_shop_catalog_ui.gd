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

func _all_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += (node as Label).text + "\n"
	elif node is Button:
		result += (node as Button).text + "\n"
	for child in node.get_children():
		result += _all_text(child)
	return result

func run() -> void:
	await process_frame
	var save_manager = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	var original_coins := int(save_manager.data.get("coins", 0)) if save_manager != null else 0
	if save_manager != null:
		save_manager.data.coins = 200
		save_manager.save()
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(5)
	var hub := main.get_node_or_null("MonetizationHub")
	expect_true(hub != null, "MonetizationHub missing")
	if hub != null:
		hub.call("open_shop")
		await _frames(2)
		var overlay = hub.get("overlay") as Control
		expect_true(overlay != null and overlay.visible, "Shop overlay did not open")
		if overlay != null:
			var text := _all_text(overlay)
			for expected in [
				"REMOVE ADS", "STARTER PACK", "SMALL COINS", "MEDIUM COINS", "LARGE COINS",
				"WATCH & EARN", "RESTORE PURCHASES", "PRIVACY OPTIONS"
			]:
				expect_true(expected in text, "Figma Shop content missing: %s" % expected)
		var balance_label = hub.get("balance_label") as Label
		expect_true(balance_label != null and "200" in balance_label.text, "Shop wallet balance missing")
		for control_name in ["ShopRewardedCoinsButton","ShopRestorePurchases","ShopPrivacyOptions"]:
			var control := overlay.find_child(control_name,true,false) as Button
			expect_true(control != null and control.get_theme_font_size("font_size") >= 14, "Shop action text below premium readability floor: %s" % control_name)
		for buy_node in overlay.find_children("Buy_*","Button",true,false):
			var buy_button := buy_node as Button
			expect_true(buy_button != null and buy_button.get_theme_font_size("font_size") >= 14, "Shop purchase button text below premium readability floor")
		var shop_status = hub.get("status_label") as Label
		expect_true(shop_status != null and shop_status.get_theme_font_size("font_size") >= 14, "Shop status text below premium readability floor")
		if economy != null:
			economy.grant(50, "qa_shop_refresh")
			await _frames(2)
			expect_true(balance_label != null and "250" in balance_label.text, "Shop wallet did not refresh live")
	main.queue_free()
	await _frames(2)
	if save_manager != null:
		save_manager.data.coins = original_coins
		save_manager.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("SHOP_CATALOG_UI_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
