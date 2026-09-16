extends SceneTree

const VIEWPORTS := [
	Vector2i(540, 960),
	Vector2i(720, 1280),
	Vector2i(720, 1600),
	Vector2i(1080, 1920),
	Vector2i(1080, 2160),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400)
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project_text := FileAccess.open("res://project.godot", FileAccess.READ).get_as_text()
	var shell_text := FileAccess.open("res://scripts/ui/ux_shell_casual.gd", FileAccess.READ).get_as_text()
	if not project_text.contains('window/stretch/aspect="expand"'):
		return _fail("Project stretch aspect must be explicitly set to expand for tall/short portrait screens")
	if shell_text.contains('Vector2(24, -92)') or not shell_text.contains('get_visible_rect().size'):
		return _fail("Gameplay help control is not positioned from the actual visible viewport")

	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	print("Viewport-fit validation passed for 7 portrait sizes: home, settings, Rescue Rush, Water Sort and Block Puzzle stay inside the visible viewport.")
	quit(0)

func _validate_viewport(viewport_size: Vector2) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(6)

	var logical_size := root.get_visible_rect().size

	main.call("build_home")
	await _frames(6)
	logical_size = root.get_visible_rect().size
	if not _assert_named_surface(main, logical_size, ["PremiumHome"]):
		return false

	main.call("build_settings")
	await _frames(6)
	if not _assert_tree_fit(main, logical_size, "Settings", ["TutorialPanel"]):
		return false

	main.call("start_level", 1)
	await _frames(8)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Rescue Rush"):
		return false
	if not _assert_help_button(main, logical_size):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(8)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Water Sort"):
		return false
	if not _assert_help_button(main, logical_size):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(8)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Block Puzzle"):
		return false
	if not _assert_help_button(main, logical_size):
		return false

	main.queue_free()
	await process_frame
	return true

func _assert_named_surface(main: Control, viewport_size: Vector2, names: Array[String]) -> bool:
	for surface_name in names:
		var node := main.get_node_or_null(surface_name) as Control
		if node != null and node.visible:
			if not _rect_inside(node.get_global_rect(), viewport_size):
				return _fail("%s spills outside %s: %s" % [surface_name, str(viewport_size), str(node.get_global_rect())])
	return true

func _assert_active_game(main: Control, viewport_size: Vector2, label: String) -> bool:
	var game := main.get_node_or_null("ActiveGame") as Control
	if game == null:
		return _fail("%s missing ActiveGame at %s" % [label, str(viewport_size)])
	if not _rect_inside(game.get_global_rect(), viewport_size):
		return _fail("%s root spills outside %s: %s" % [label, str(viewport_size), str(game.get_global_rect())])
	return _assert_tree_fit(game, viewport_size, label, [])

func _assert_tree_fit(root_control: Control, viewport_size: Vector2, label: String, skip_names: Array[String]) -> bool:
	for node in _controls(root_control):
		if not node.visible or not node.is_visible_in_tree():
			continue
		if node.name in skip_names:
			continue
		if node is Label:
			continue
		var rect := node.get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			continue
		if not _rect_inside(rect, viewport_size):
			return _fail("%s control %s spills outside %s: %s" % [label, str(node.get_path()), str(viewport_size), str(rect)])
	return true

func _assert_help_button(main: Control, viewport_size: Vector2) -> bool:
	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return _fail("UXShell missing")
	var button = shell.get("help_button")
	if button == null or not is_instance_valid(button):
		return _fail("Help button missing")
	if not button.visible:
		return _fail("Help button is not visible during gameplay at %s" % str(viewport_size))
	var rect: Rect2 = button.get_global_rect()
	if not _rect_inside(rect, viewport_size):
		return _fail("Help button spills outside %s: %s" % [str(viewport_size), str(rect)])
	return true

func _hide_tutorial(main: Control) -> void:
	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return
	var panel = shell.get("tutorial_panel")
	if panel != null and is_instance_valid(panel) and panel.visible and shell.has_method("hide_tutorial"):
		shell.call("hide_tutorial")

func _rect_inside(rect: Rect2, viewport_size: Vector2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= -epsilon \
		and rect.position.y >= -epsilon \
		and rect.end.x <= float(viewport_size.x) + epsilon \
		and rect.end.y <= float(viewport_size.y) + epsilon

func _controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in node.get_children():
		if child is Control:
			result.append(child as Control)
		result.append_array(_controls(child))
	return result

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
