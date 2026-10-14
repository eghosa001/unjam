extends SceneTree

# Regression from a Samsung S25 FE recording: a single tap on the back
# arrow of WATER levels briefly displayed Choose Game, then fell to HOME.
# Previously its touch-DOWN navigated and the newly exposed selector had a
# back button at the SAME position, permitting a second route on touch-UP.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(390,844)
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null: return _fail("Missing Main scene")
	var main := scene.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await _frames(7)
	var shell := main.get_node_or_null("UXShell")
	if shell == null: return _fail("Android back handler missing")
	for game in ["water_sort","rescue_rush","block_puzzle"]:
		main.call("open_game_campaign",game)
		await _frames(3)
		if String(main.get("current_surface")) != "levels":
			return _fail("Opening %s levels failed" % game)
		var back := main.find_child("FigmaBack",true,false) as Button
		if back == null:
			return _fail("No levels Back control for %s" % game)
		if back.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
			return _fail("%s levels Back fires on TOUCH-DOWN and cascades to Home" % game)
		var selector := main.get_node_or_null("PremiumLive") as Control
		if selector == null: return _fail("Chooser missing")
		if selector.visible: return _fail("Chooser is visible behind level browser")
		back.pressed.emit()
		if String(main.get("current_surface")) != "live":
			return _fail("%s levels Back must open Choose Game, not Home" % game)
		var live_back := selector.find_child("SelectorBackButton",true,false) as Button
		if live_back == null or live_back.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
			return _fail("Selector Back control is missing RELEASE semantics")
		await _frames(4)
		if String(main.get("current_surface")) != "live":
			return _fail("%s levels -> selector unexpectedly navigated again on deferred update" % game)
		# System Back may be delivered twice (WM notification + Escape).
		# One physical action must advance only ONE level in the back stack.
		main.call("open_game_campaign",game)
		await _frames(2)
		shell.call("_handle_back")
		shell.call("_handle_back")
		if String(main.get("current_surface")) != "live":
			return _fail("Double Android back advanced from %s levels to Home" % game)
		# Deliberate next Back, not from the same gesture, should reach Home.
		shell.set("_last_system_back_ms",-1000)
		shell.call("_handle_back")
		if String(main.get("current_surface")) != "home":
			return _fail("Separate Back from chooser did not reach Home")
		await _frames(2)

	# Home shortcuts must not navigate to Levels until the finger is lifted.
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null: return _fail("Home missing")
	var shortcut_found := 0
	for name in ["rescue_rush","water_sort","block_puzzle"]:
		var buttons: Array[Button] = []
		_find_home_shortcuts(home,buttons)
		for button in buttons:
			if button.get_meta("unjam_game", "") == name:
				shortcut_found += 1
				if button.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
					return _fail("Home %s shortcut responds to DOWN; can touch through into level tiles" % name)
	if shortcut_found == 0:
		var source := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
		if not source.contains("tap.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE"):
			return _fail("Home shortcut RELEASE regression")
	main.queue_free()
	await process_frame
	print("SAMSUNG_BACK_GESTURE_OK: 3 browsers, no 2nd route on delayed callbacks, system key dedup and Home")
	quit(0)

func _find_home_shortcuts(node: Node, output: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button and String(child.name).begins_with("HomeQuickSwitch"):
			output.append(child)
		_find_home_shortcuts(child,output)

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
