extends SceneTree

const TEST_VIEWPORT := Vector2i(540,960)

func _initialize() -> void:
	call_deferred("_run")

func _save() -> Node:
	return root.get_node("SaveManager")

func _run() -> void:
	root.size = TEST_VIEWPORT
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await _frames(12)

	if not await _test_home_and_surfaces(main):
		return
	if not await _test_selector_and_level_launch(main):
		return
	if not await _test_water_controls(main):
		return
	if not await _test_rescue_controls(main):
		return
	if not await _test_block_controls(main):
		return
	if not await _test_settings_toggle(main):
		return
	if not await _test_shop(main):
		return

	main.queue_free()
	await _frames(2)
	print("Figma/runtime sync validated: navigation, level launch, gameplay actions, settings, Shop and reference-canvas surfaces are responsive.")
	quit(0)

func _test_home_and_surfaces(main: Control) -> bool:
	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("PremiumHome is missing")
	var canvas := home.find_child("FigmaHome390x844",true,false) as Control
	if canvas == null:
		return _fail("Figma Home canvas is missing")
	for name in ["HomeCoinShopButton","HomeLevelsNavButton","HomeDailyNavButton","HomeCollectionNavButton","HomeSettingsNavButton"]:
		var button := home.find_child(name,true,false) as Button
		if not _bound(button):
			return _fail("Figma Home control is missing or unbound: %s" % name)

	if home.find_child("HomeNavSelectedDot",true,false) == null or home.find_child("HomeNavSelectedUnderline",true,false) == null:
		return _fail("Home nav selection still lacks the fixed dot/underline treatment")
	var water_switch := home.find_child("HomeDirect_water_sort",true,false) as Button
	var block_switch := home.find_child("HomeDirect_block_puzzle",true,false) as Button
	var rescue_switch := home.find_child("HomeDirect_rescue_rush",true,false) as Button
	if not _bound(water_switch) or not _bound(block_switch) or not _bound(rescue_switch):
		return _fail("Home quick-switch controls are missing or unbound")
	water_switch.pressed.emit()
	await _frames(2)
	var hero_title := home.find_child("HomeHeroGameTitle",true,false) as Label
	if String(main.get("current_surface")) != "home" or String(main.get("selected_game_id")) != "water_sort" or hero_title == null or hero_title.text != "WATER SORT":
		return _fail("Home quick switch did not update the hero to Water Sort in place")
	block_switch.pressed.emit()
	await _frames(2)
	if String(main.get("selected_game_id")) != "block_puzzle" or hero_title.text != "BLOCK PUZZLE":
		return _fail("Home quick switch did not update the hero to Block Puzzle")
	rescue_switch.pressed.emit()
	await _frames(2)
	if String(main.get("selected_game_id")) != "rescue_rush" or hero_title.text != "RESCUE RUSH":
		return _fail("Home quick switch did not restore Rescue Rush")

	var daily := home.find_child("HomeDailyNavButton",true,false) as Button
	daily.pressed.emit()
	await _frames(6)
	if String(main.get("current_surface")) != "daily":
		return _fail("Home Daily nav did not open Daily Games")
	if not _has_figma_surface(main):
		return _fail("Daily Games is not using the Figma surface canvas")
	var daily_canvas := (main.get("content") as Control).find_child("FigmaSurface390x844",true,false) as Control
	if daily_canvas == null or daily_canvas.find_child("StdNav/SelectedDot/daily",true,false) == null or daily_canvas.find_child("StdNav/SelectedLine/daily",true,false) == null:
		return _fail("Daily nav does not use the fixed dot/underline selected state")
	if daily_canvas.find_child("StdNav/Active",true,false) != null:
		return _fail("Legacy moving nav color slab is still present")
	if not _all_enabled_buttons_bound(main.get("content") as Control):
		return false

	main.call("build_collection")
	await _frames(5)
	if not _has_figma_surface(main):
		return _fail("Collection is not using the Figma surface canvas")
	if main.find_child("Journey",true,false) == null or main.find_child("Garden",true,false) == null:
		return _fail("Figma Collection hierarchy is incomplete")

	main.call("build_settings")
	await _frames(5)
	if not _has_figma_surface(main):
		return _fail("Settings is not using the Figma surface canvas")
	if main.find_child("SettingsCard/Sound",true,false) == null and main.find_child("SettingsCard_Sound",true,false) == null:
		# Node-name sanitisation is engine-version dependent; geometry test below
		# remains the authoritative Settings check.
		var sound_toggle := _button_at(main.get("content") as Control,Vector2(279,130),Vector2(72,38))
		if sound_toggle == null:
			return _fail("Figma Settings sound section is missing")
	return true

func _test_selector_and_level_launch(main: Control) -> bool:
	main.call("build_home")
	await _frames(4)
	var home := main.get_node_or_null("PremiumHome") as Control
	var games := home.find_child("HomeLevelsNavButton",true,false) as Button
	games.pressed.emit()
	await _frames(6)
	if String(main.get("current_surface")) != "live":
		return _fail("Home Games nav did not open the selector")
	var live := main.get_node_or_null("PremiumLive") as Control
	if live == null or not live.visible:
		return _fail("PremiumLive selector is not visible")
	if live.find_child("FigmaSelector390x844",true,false) == null:
		return _fail("Selector is not using the Figma reference canvas")
	for button in _buttons(live):
		if button.visible and not button.disabled and button.text.strip_edges().begins_with("PLAY"):
			return _fail("Selector still contains a redundant PLAY button")

	var water_hit := live.find_child("SelectorCardHit_water_sort",true,false) as Button
	if not _bound(water_hit):
		return _fail("Water selector card hit target is missing or unbound")
	water_hit.pressed.emit()
	await _frames(7)
	if String(main.get("current_surface")) != "levels" or String(main.get("selected_game_id")) != "water_sort":
		return _fail("Water selector card did not open Water levels")

	var content := main.get("content") as Control
	var level_button: Button = null
	for button in _buttons(content):
		if not button.disabled and button.text.strip_edges().is_valid_int():
			level_button = button
			break
	if level_button == null or not _bound(level_button):
		return _fail("Water Figma level browser has no unlocked bound level")
	level_button.pressed.emit()
	await _frames(12)
	if String(main.get("current_surface")) != "game":
		return _fail("Unlocked Water level did not launch gameplay")
	var active = main.get("active_game")
	if active == null or not is_instance_valid(active):
		return _fail("Water gameplay did not create an active game")
	if (active as Node).find_child("FigmaWater390x844",true,false) == null:
		return _fail("Water gameplay is not using the Figma canvas")
	return true

func _test_water_controls(main: Control) -> bool:
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Water game missing before control audit")
	await _frames(5)
	var actions := (game as Node).find_child("CompactGameActions",true,false) as HBoxContainer
	if actions == null:
		return _fail("Water action row is missing")
	var buttons: Array[Button] = []
	for child in actions.get_children():
		if child is Button:
			buttons.append(child as Button)
	if buttons.size() != 3:
		return _fail("Water must expose exactly three bottom actions; found %d" % buttons.size())
	for required in ["WaterUndoAction","WaterHintAction","AddTubeAction","WaterRetryAction"]:
		var button := (game as Node).find_child(required,true,false) as Button
		if not _bound(button):
			return _fail("Water control is missing or unbound: %s" % required)
	if not _all_enabled_buttons_bound(game as Control):
		return false
	main.call("force_back_from_game")
	await _frames(5)
	return true

func _test_rescue_controls(main: Control) -> bool:
	main.call("start_level",1)
	await _frames(12)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Rescue gameplay did not launch")
	if (game as Node).find_child("FigmaRescue390x844",true,false) == null:
		return _fail("Rescue gameplay is not using the Figma canvas")
	for required in ["RescueBackAction","RescueRetryAction","RescueUndoAction","RescueHintAction","RescueRestartAction"]:
		var button := (game as Node).find_child(required,true,false) as Button
		if not _bound(button):
			return _fail("Rescue control is missing or unbound: %s" % required)
	if not _all_enabled_buttons_bound(game as Control):
		return false
	var active_before := _active_piece_count(game as Node)
	var moves_before := int((game as Node).get("moves"))
	(game as Node).call("show_hint")
	await _frames(18)
	var active_after := _active_piece_count(game as Node)
	if active_after >= active_before:
		return _fail("Rescue Hint did not remove an arrow")
	if int((game as Node).get("moves")) != moves_before:
		return _fail("Rescue Hint incorrectly counted its automatic arrow removal as a player move")
	var restart := (game as Node).find_child("RescueRestartAction",true,false) as Button
	restart.pressed.emit()
	await _frames(10)
	game = main.get("active_game")
	if game == null or not is_instance_valid(game) or (game as Node).find_child("FigmaRescue390x844",true,false) == null:
		return _fail("Rescue Restart did not rebuild the Figma gameplay surface")
	main.call("force_back_from_game")
	await _frames(5)
	return true

func _test_block_controls(main: Control) -> bool:
	main.call("start_multi_level","block_puzzle",1,false)
	await _frames(12)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("Block gameplay did not launch")
	if (game as Node).find_child("FigmaBlock390x844",true,false) == null:
		return _fail("Block gameplay is not using the Figma canvas")
	for required in ["BackAction","RetryAction","HintAction","Booster_Undo","Booster_Hammer","Booster_Shuffle","Booster_Rotate"]:
		var button := (game as Node).find_child(required,true,false) as Button
		if not _bound(button):
			return _fail("Block control is missing or unbound: %s" % required)
	if not _all_enabled_buttons_bound(game as Control):
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
	var sound := content.find_child("SettingToggle*Sound",true,false) as Button
	if sound == null:
		return _fail("Sound Effects Figma toggle is missing")
	if not _rect_eq(Rect2(sound.position,sound.size),Rect2(279,130,72,38)):
		return _fail("Sound Effects toggle drifted from Figma geometry: %s | custom=%s | minimum=%s | font=%d | exact=%s" % [str(Rect2(sound.position,sound.size)), str(sound.custom_minimum_size), str(sound.get_combined_minimum_size()), sound.get_theme_font_size("font_size"), str(sound.has_meta("unjam_figma_exact_geometry"))])
	if not _bound(sound):
		return _fail("Sound Effects Figma toggle is unbound")
	var save := _save()
	var data: Dictionary = save.get("data")
	var before := bool(data.get("sound",true))
	sound.pressed.emit()
	await _frames(5)
	data = save.get("data")
	var after := bool(data.get("sound",true))
	if after == before:
		return _fail("Sound Effects toggle did not change state")
	data["sound"] = before
	save.set("data",data)
	save.call("save")
	return true

func _test_shop(main: Control) -> bool:
	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	var wallet := home.find_child("HomeCoinShopButton",true,false) as Button
	if not _bound(wallet):
		return _fail("Home wallet action is missing before Shop audit")
	wallet.pressed.emit()
	await _frames(6)
	var hub := main.get_node_or_null("MonetizationHub")
	if hub == null:
		return _fail("MonetizationHub is missing")
	var overlay = hub.get("overlay")
	if overlay == null or not is_instance_valid(overlay) or not overlay.visible:
		return _fail("Shop overlay did not open")
	if (overlay as Node).find_child("FigmaShop390x844",true,false) == null:
		return _fail("Shop is not using the Figma reference canvas")
	var reward := (overlay as Node).find_child("ShopRewardedCoinsButton",true,false) as Button
	if not _bound(reward):
		return _fail("Shop rewarded-coins control is missing or unbound")
	hub.call("_close_shop")
	return true

func _active_piece_count(game: Node) -> int:
	var pieces = game.get("pieces")
	if not pieces is Array:
		return 0
	var count := 0
	for raw in pieces:
		if raw is Dictionary and bool((raw as Dictionary).get("active",true)):
			count += 1
	return count

func _has_figma_surface(main: Control) -> bool:
	var content := main.get("content") as Control
	return content != null and content.find_child("FigmaSurface390x844",true,false) != null

func _button_at(node: Node, expected_pos: Vector2, expected_size: Vector2) -> Button:
	for button in _buttons(node):
		if button.position.distance_to(expected_pos) <= 1.0 and button.size.distance_to(expected_size) <= 1.0:
			return button
	return null

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _all_enabled_buttons_bound(node: Control) -> bool:
	if node == null:
		return _fail("Cannot audit buttons on a null control")
	for button in _buttons(node):
		if not button.visible or not button.is_visible_in_tree() or button.disabled:
			continue
		if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if button.pressed.get_connections().is_empty():
			return _fail("Visible enabled button has no response: %s (%s)" % [str(button.get_path()),button.text.replace("\n"," / ")])
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
