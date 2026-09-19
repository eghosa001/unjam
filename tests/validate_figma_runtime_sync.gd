extends SceneTree

const TEST_VIEWPORT := Vector2i(540, 960)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = TEST_VIEWPORT
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await _frames(12)

	if not await _test_home_and_daily(main):
		return
	if not await _test_selector_card_tap_and_level_launch(main):
		return
	if not await _test_water_controls(main):
		return
	if not await _test_rescue_controls(main):
		return
	if not await _test_block_controls(main):
		return
	if not await _test_settings_toggle(main):
		return

	main.queue_free()
	await _frames(2)
	print("Figma/runtime sync validated: primary nav, card-level selector taps, unlocked-level launch, gameplay controls, paid hint ownership, boosters and settings preferences all respond at 540x960.")
	quit(0)

func _test_home_and_daily(main: Control) -> bool:
	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("PremiumHome is missing")
	if home.find_child("HomeMottoStone", true, false) != null:
		return _fail("Home still renders the retired motto plaque")
	if home.find_child("HomeShopNavButton", true, false) != null:
		return _fail("Home persistent nav still exposes Shop instead of Daily")
	var coin_shop := home.find_child("HomeCoinShopButton", true, false) as Button
	if not _bound(coin_shop):
		return _fail("Home coin wallet does not open Shop")
	var expected := ["HomeNavButton", "HomeLevelsNavButton", "HomeDailyNavButton", "HomeCollectionNavButton", "HomeSettingsNavButton"]
	for name in expected:
		var button := home.find_child(name, true, false) as Button
		if button == null:
			return _fail("Home nav button missing: %s" % name)
		if name != "HomeNavButton" and not _bound(button):
			return _fail("Home nav button is not responsive: %s" % name)
	var daily := home.find_child("HomeDailyNavButton", true, false) as Button
	daily.pressed.emit()
	await _frames(6)
	if String(main.get("current_surface")) != "daily":
		return _fail("Home Daily nav did not open Daily Games")
	if not _all_enabled_buttons_bound(main.get("content") as Control, [""]):
		return false
	return true

func _test_selector_card_tap_and_level_launch(main: Control) -> bool:
	main.call("build_home")
	await _frames(4)
	var home := main.get_node_or_null("PremiumHome") as Control
	var games := home.find_child("HomeLevelsNavButton", true, false) as Button
	games.pressed.emit()
	await _frames(6)
	if String(main.get("current_surface")) != "live":
		return _fail("Home Games nav did not open the game selector")
	var live := main.get_node_or_null("PremiumLive") as Control
	if live == null or not live.visible:
		return _fail("PremiumLive selector is not visible")
	for button in _buttons(live):
		if button.visible and not button.disabled and button.text.strip_edges().begins_with("PLAY"):
			return _fail("Selector still contains a redundant visible PLAY button: %s" % button.text)
	var water_card := live.find_child("GameCard3D_water_sort", true, false) as PanelContainer
	if water_card == null:
		return _fail("Water selector card is missing")
	if water_card.gui_input.get_connections().is_empty():
		return _fail("Water selector card is not itself tappable")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(24, 24)
	live.call("_on_game_card_gui_input", press, "water_sort")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(24, 24)
	live.call("_on_game_card_gui_input", release, "water_sort")
	await _frames(7)
	if String(main.get("current_surface")) != "levels":
		return _fail("Whole-card Water tap did not open the Water level browser")
	if String(main.get("selected_game_id")) != "water_sort":
		return _fail("Whole-card Water tap did not select Water Sort")

	var content := main.get("content") as Control
	var level_button: Button = null
	for button in _buttons(content):
		var first_line := button.text.get_slice("\n", 0).strip_edges()
		if not button.disabled and first_line.is_valid_int():
			level_button = button
			break
	if level_button == null:
		return _fail("Water level browser has no unlocked tappable level")
	if not _bound(level_button):
		return _fail("Unlocked Water level button has no response")
	level_button.pressed.emit()
	await _frames(12)
	if String(main.get("current_surface")) != "game":
		return _fail("Unlocked Water level tap did not enter gameplay")
	var active = main.get("active_game")
	if active == null or not is_instance_valid(active):
		return _fail("Water gameplay did not create an active game")
	return true

func _test_water_controls(main: Control) -> bool:
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Water game missing before control audit")
	await _frames(5)
	var actions := game.find_child("CompactGameActions", true, false) as HBoxContainer
	if actions == null:
		return _fail("Water action row is missing")
	var action_buttons: Array[Button] = []
	for child in actions.get_children():
		if child is Button:
			action_buttons.append(child as Button)
	if action_buttons.size() != 3:
		return _fail("Water must expose exactly three bottom actions (Undo, Hint, +Tube); found %d" % action_buttons.size())
	for required in ["WaterUndoAction", "WaterHintAction", "AddTubeAction"]:
		var button := game.find_child(required, true, false) as Button
		if not _bound(button):
			return _fail("Water control is missing or unbound: %s" % required)
	if game.find_child("WaterRestartAction", true, false) != null:
		return _fail("Water still duplicates Restart in the bottom action row")
	var retry := game.find_child("WaterRetryAction", true, false) as Button
	if not _bound(retry):
		return _fail("Water header Retry is missing or unbound")
	var hint := game.find_child("WaterHintAction", true, false) as Button
	if hint.pressed.get_connections().size() != 1:
		return _fail("Water Hint must have exactly one runtime owner after HintManager attachment")
	if not _all_enabled_buttons_bound(game as Control, []):
		return false
	main.call("force_back_from_game")
	await _frames(5)
	return true

func _test_rescue_controls(main: Control) -> bool:
	main.call("start_level", 1)
	await _frames(12)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Rescue gameplay did not launch")
	for required in ["RescueBackAction", "RescueRetryAction", "RescueUndoAction", "RescueHintAction", "RescueRestartAction"]:
		var button := game.find_child(required, true, false) as Button
		if not _bound(button):
			return _fail("Rescue control is missing or unbound: %s" % required)
	var hint := game.find_child("RescueHintAction", true, false) as Button
	if hint.pressed.get_connections().size() != 1:
		return _fail("Rescue Hint must have exactly one runtime owner after HintManager attachment")
	if not _all_enabled_buttons_bound(game as Control, []):
		return false
	var restart := game.find_child("RescueRestartAction", true, false) as Button
	restart.pressed.emit()
	await _frames(10)
	game = main.get("active_game")
	if game == null or not is_instance_valid(game) or game.find_child("RescueRestartAction", true, false) == null:
		return _fail("Rescue Restart did not rebuild a responsive gameplay surface")
	main.call("force_back_from_game")
	await _frames(5)
	return true

func _test_block_controls(main: Control) -> bool:
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(12)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Block gameplay did not launch")
	for required in ["BackAction", "RetryAction", "HintAction", "Booster_Undo", "Booster_Hammer", "Booster_Shuffle", "Booster_Rotate"]:
		var button := game.find_child(required, true, false) as Button
		if not _bound(button):
			return _fail("Block control is missing or unbound: %s" % required)
	var hint := game.find_child("HintAction", true, false) as Button
	if hint.pressed.get_connections().size() != 1:
		return _fail("Block Hint must have exactly one runtime owner")
	if not _all_enabled_buttons_bound(game as Control, []):
		return false
	main.call("force_back_from_game")
	await _frames(5)
	return true

func _test_settings_toggle(main: Control) -> bool:
	main.call("build_settings")
	await _frames(6)
	var content := main.get("content") as Control
	if content == null:
		return _fail("Settings content is missing")
	if not _all_enabled_buttons_bound(content, []):
		return false
	var sound: Button = null
	for button in _buttons(content):
		if "SOUND EFFECTS" in button.text.to_upper():
			sound = button
			break
	if sound == null or not _bound(sound):
		return _fail("Sound Effects setting is missing or unbound")
	var before := bool(SaveManager.data.get("sound", true))
	sound.pressed.emit()
	await _frames(5)
	var after := bool(SaveManager.data.get("sound", true))
	if after == before:
		return _fail("Sound Effects toggle did not change state")
	SaveManager.data["sound"] = before
	SaveManager.save()
	return true

func _all_enabled_buttons_bound(node: Control, allowed_unbound_names: Array[String]) -> bool:
	if node == null:
		return _fail("Cannot audit buttons on a null control")
	for button in _buttons(node):
		if not button.visible or not button.is_visible_in_tree() or button.disabled:
			continue
		if button.name in allowed_unbound_names:
			continue
		if button.pressed.get_connections().is_empty():
			return _fail("Visible enabled button has no response: %s (%s)" % [str(button.get_path()), button.text.replace("\n", " / ")])
	return true

func _buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node == null:
		return result
	for child in node.get_children():
		if child is Button:
			result.append(child as Button)
		result.append_array(_buttons(child))
	return result

func _bound(button: Button) -> bool:
	return button != null and not button.pressed.get_connections().is_empty()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
