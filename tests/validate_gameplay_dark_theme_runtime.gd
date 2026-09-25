extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(8)

	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return _fail("UX shell is missing")
	shell.set("theme_mode", "light")
	shell.call("_apply_theme")
	main.call("build_settings")
	await _frames(4)
	var theme_toggle := main.find_child("SettingsThemeToggle", true, false) as Button
	if theme_toggle == null:
		return _fail("Settings theme button is missing")
	theme_toggle.emit_signal("pressed")
	await _frames(6)
	if String(shell.get("theme_mode")) != "dark":
		return _fail("Pressing the Settings theme button did not enter dark mode")

	var settings_bg := main.find_child("FigmaSurfaceViewportBackground", true, false) as ColorRect
	if settings_bg == null or settings_bg.color.get_luminance() > 0.38:
		return _fail("Settings did not rebuild on the dark palette")

	main.call("start_level", 1)
	await _frames(10)
	var rescue := main.get("active_game") as Control
	if rescue == null:
		return _fail("Rescue Rush did not launch")
	if not _assert_dark_game(rescue, "RescueFigmaViewportBackground", "Rescue Rush"):
		return
	main.call("_remove_active_game")
	await _frames(3)

	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(10)
	var water := main.get("active_game") as Control
	if water == null:
		return _fail("Water Sort did not launch")
	if not _assert_dark_game(water, "WaterFigmaViewportBackground", "Water Sort"):
		return
	main.call("_remove_active_game")
	await _frames(3)

	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(10)
	var block := main.get("active_game") as Control
	if block == null:
		return _fail("Block Puzzle did not launch")
	if not _assert_dark_game(block, "BlockFigmaViewportBackground", "Block Puzzle"):
		return

	var dark_block_bg := block.find_child("BlockFigmaViewportBackground", true, false) as ColorRect
	var dark_luma := dark_block_bg.color.get_luminance()
	shell.call("_toggle_theme")
	await _frames(5)
	if String(shell.get("theme_mode")) != "light":
		return _fail("Theme toggle did not return to light mode")
	var light_block_bg := block.find_child("BlockFigmaViewportBackground", true, false) as ColorRect
	if light_block_bg == null or light_block_bg.color.get_luminance() <= dark_luma + 0.03:
		return _fail("Active Block Puzzle did not restyle when returning to light mode")

	print("GAMEPLAY_DARK_THEME_RUNTIME_OK")
	quit(0)

func _assert_dark_game(game: Control, node_name: String, label: String) -> bool:
	var bg := game.find_child(node_name, true, false) as ColorRect
	if bg == null:
		return _fail("%s dark background is missing" % label)
	if bg.color.get_luminance() > 0.18:
		return _fail("%s stayed on the light gameplay palette (luma %.3f)" % [label, bg.color.get_luminance()])
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
