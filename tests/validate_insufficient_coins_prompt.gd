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
	ProjectSettings.set_setting("monetization/test_mode", true)
	var save_manager = root.get_node_or_null("SaveManager")
	var original_coins := int(save_manager.data.get("coins", 0)) if save_manager != null else 0
	if save_manager != null:
		save_manager.data.coins = 0
		save_manager.save()
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(5)
	var prompt := main.get_node_or_null("InsufficientCoinsPrompt")
	var hub := main.get_node_or_null("MonetizationHub")
	expect_true(prompt != null and prompt.has_method("show_for"), "Insufficient coin recovery prompt missing")
	if prompt != null:
		var retry_state := {"count": 0}
		prompt.call("show_for", "HINT", 25, func() -> bool:
			retry_state.count += 1
			return true
		)
		await _frames(2)
		var overlay = prompt.get("overlay") as Control
		expect_true(overlay != null and overlay.visible, "Insufficient coin prompt did not become visible")
		var shop_button := prompt.find_child("*Shop", true, false) as Button
		var reward_button := prompt.find_child("*Rewarded", true, false) as Button
		expect_true(shop_button != null, "Figma coin prompt has no Open Shop action")
		expect_true(reward_button != null and "+50" in reward_button.text, "Figma coin prompt has no +50 rewarded coin action")
		if shop_button != null and hub != null:
			shop_button.emit_signal("pressed")
			await _frames(2)
			var shop_overlay = hub.get("overlay") as Control
			expect_true(shop_overlay != null and shop_overlay.visible, "Prompt Open Shop action did not open Store")
			if hub.has_method("_close_shop"):
				hub.call("_close_shop")
			prompt.call("show_for", "HINT", 25, func() -> bool:
				retry_state.count += 1
				return true
			)
		if reward_button != null:
			reward_button = prompt.find_child("*Rewarded", true, false) as Button
			reward_button.emit_signal("pressed")
			await _frames(3)
			expect_true(int(save_manager.data.get("coins", -1)) == 50, "Reward recovery did not grant exactly 50 coins")
			expect_true(int(retry_state.count) == 1, "Recovery retry did not execute exactly once")
	main.queue_free()
	await _frames(2)
	if save_manager != null:
		save_manager.data.coins = original_coins
		save_manager.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("INSUFFICIENT_COINS_PROMPT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
