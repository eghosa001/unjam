extends SceneTree

const OUT_DIR := "res://build/visual-audit"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Main.tscn for visual audit")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _settle(8)

	main.call("build_home")
	await _capture("01-home-dark")

	main.set("current_surface", "live")
	await _capture("02-live-dark")

	main.call("build_level_select")
	await _capture("03-levels-rescue-dark")

	main.set("selected_game_id", "water_sort")
	main.set("selected_multi_world", 1)
	main.call("build_multi_level_select")
	await _capture("04-levels-water-dark")

	main.call("build_collection")
	await _capture("05-collection-dark")

	main.call("build_settings")
	await _capture("06-settings-dark")

	var shell := main.get_node_or_null("UXShell")
	if shell != null:
		shell.set("theme_mode", "light")
		if shell.has_method("_apply_theme"):
			shell.call("_apply_theme")
	main.call("build_home")
	await _capture("07-home-light")
	main.call("build_settings")
	await _capture("08-settings-light")

	if shell != null:
		shell.set("theme_mode", "dark")
		if shell.has_method("_apply_theme"):
			shell.call("_apply_theme")

	main.call("start_level", 1)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("09-game-rescue")

	main.call("start_multi_level", "water_sort", 1, false)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("10-game-water")

	main.call("start_multi_level", "block_puzzle", 1, false)
	await _settle(8)
	_hide_tutorial(shell)
	await _capture("11-game-block")

	main.call("force_back_from_game")
	main.set("selected_game_id", "block_puzzle")
	main.set("selected_multi_world", 1)
	main.call("build_multi_level_select")
	await _capture("12-levels-block-dark")

	if shell != null:
		shell.set("theme_mode", "light")
		if shell.has_method("_apply_theme"):
			shell.call("_apply_theme")
	main.call("build_collection")
	await _capture("13-collection-light")
	main.set("current_surface", "live")
	await _capture("14-live-light")

	if shell != null:
		shell.set("theme_mode", "dark")
		if shell.has_method("_apply_theme"):
			shell.call("_apply_theme")
	main.call("start_level", 1)
	await _settle(8)
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", "rescue_rush")
	await _capture("15-tutorial-rescue-dark")
	_hide_tutorial(shell)

	var result := PremiumResultOverlay.new()
	result.configure(
		"LEVEL COMPLETE",
		"Clean play. Strong route. Keep the streak moving.",
		"7 MOVES   •   PERFECT ≤ 8\n1 RESCUE SECURED",
		3,
		Color("2dd4b6"),
		"NEXT PUZZLE"
	)
	main.add_child(result)
	await _capture("16-result-overlay-dark")
	result.queue_free()
	await _settle(3)

	print("Visual audit captures written to %s" % OUT_DIR)
	quit(0)

func _hide_tutorial(shell: Node) -> void:
	if shell == null:
		return
	var panel = shell.get("tutorial_panel")
	if panel != null and is_instance_valid(panel) and panel.visible and shell.has_method("hide_tutorial"):
		shell.call("hide_tutorial")

func _settle(frames: int = 5) -> void:
	for _i in range(frames):
		await process_frame

func _capture(name: String) -> void:
	await _settle(7)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Visual audit capture failed for %s" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save visual audit capture %s: %s" % [name, error_string(err)])
	else:
		print("Captured %s" % path)
