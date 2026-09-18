extends SceneTree

const MAX_CAMPAIGN_LEVEL := 10000
const VIEWPORTS := [
	Vector2i(540, 960),
	Vector2i(720, 1280),
	Vector2i(720, 1600),
	Vector2i(1080, 1920),
	Vector2i(1080, 2160),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400)
]
# Keep the expensive level-10,000 sweep short: the two smallest supported
# portrait classes are the layouts most likely to expose width/height overflow.
const STRESS_VIEWPORTS := [
	Vector2i(540, 960),
	Vector2i(720, 1280)
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project_text := _read("res://project.godot")
	var shell_text := _read("res://scripts/ui/ux_shell_casual.gd")
	var water_scene := _read("res://scenes/WaterSort.tscn")
	var water_10000 := _read("res://scripts/game/water_sort_10000.gd")
	var water_assisted := _read("res://scripts/game/water_sort_assisted.gd")
	var water_motion := _read("res://scripts/game/water_sort_reference_motion.gd")
	var water_fit := _read("res://scripts/game/water_sort_ultra_motion.gd")
	var rescue_motion := _read("res://scripts/game/rescue_rush_polished.gd")
	var block_scene := _read("res://scenes/BlockPuzzle.tscn")
	var block_polish := _read("res://scripts/game/block_puzzle_final_polish.gd")

	if not project_text.contains('window/stretch/aspect="expand"'):
		return _fail("Project stretch aspect must be explicitly set to expand for tall/short portrait screens")
	if shell_text.contains('Vector2(24, -92)') or not shell_text.contains('get_visible_rect().size'):
		return _fail("Gameplay help control is not positioned from the actual visible viewport")

	# Lock the active Water Sort path to lip-based pouring and completion-after-
	# visuals. The assisted leaf must remain layered over the active casual/motion
	# stack so hints/extra-tube support cannot reconnect an obsolete renderer.
	if not water_scene.contains("water_sort_10000.gd") or not water_10000.contains('extends "res://scripts/game/water_sort_assisted.gd"') or not water_assisted.contains('extends "res://scripts/game/water_sort_casual.gd"'):
		return _fail("Water Sort scene no longer uses the 10K leaf over the assisted casual/motion stack")
	if not water_motion.contains("visual_pour_rim_local") or not water_motion.contains("visual_receive_rim_local"):
		return _fail("Water Sort pour animation must resolve source and receiver at the visible bottle rims")
	if not water_motion.contains("pending_completion") or not water_motion.contains("_complete_if_visuals_settled"):
		return _fail("Water Sort result must wait for every active pour visual to settle")
	if not water_fit.contains("_visual_mouth_local") or not water_fit.contains("max_width_from_screen"):
		return _fail("Water Sort must keep lip geometry and viewport-derived tube sizing")

	# Rescue Rush must not show a result while an escaping arrow/token ghost is
	# still on screen.
	if not rescue_motion.contains("_offscreen_target") or not rescue_motion.contains("_wait_for_escape_visuals"):
		return _fail("Rescue Rush completion must wait for the final escape visual to fully leave the viewport")

	# Ensure the live Block Puzzle scene keeps the final competitive polish layer.
	if not block_scene.contains("block_puzzle_final_polish.gd"):
		return _fail("Block Puzzle scene is not using the final polish layer")
	for required in ["CLEAR STREAK", "TIGHT BOARD", "TENSION_THRESHOLD", "PremiumVisuals.burst"]:
		if not block_polish.contains(required):
			return _fail("Block Puzzle final polish regression: missing %s" % required)

	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	for viewport_size in STRESS_VIEWPORTS:
		if not await _validate_late_game_viewport(viewport_size):
			return
	print("Viewport-fit validation passed: baseline surfaces fit 7 portrait sizes, and level 10,000 for all three games fits the two narrow stress viewports without help/back overlap.")
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
	if not _assert_help_clear_of_navigation(main, "Rescue Rush"):
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
	if not _assert_help_clear_of_navigation(main, "Water Sort"):
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
	if not _assert_help_clear_of_navigation(main, "Block Puzzle"):
		return false

	main.queue_free()
	await process_frame
	return true

func _validate_late_game_viewport(viewport_size: Vector2) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn for level-10,000 stress test")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(6)
	var logical_size := root.get_visible_rect().size

	main.call("start_level", MAX_CAMPAIGN_LEVEL)
	await _frames(12)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Rescue Rush level 10,000"):
		return false
	if not _assert_help_button(main, logical_size) or not _assert_help_clear_of_navigation(main, "Rescue Rush level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level", "water_sort", MAX_CAMPAIGN_LEVEL, false)
	await _frames(12)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Water Sort level 10,000"):
		return false
	if not _assert_help_button(main, logical_size) or not _assert_help_clear_of_navigation(main, "Water Sort level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level", "block_puzzle", MAX_CAMPAIGN_LEVEL, false)
	await _frames(12)
	_hide_tutorial(main)
	await _frames(2)
	if not _assert_active_game(main, logical_size, "Block Puzzle level 10,000"):
		return false
	if not _assert_help_button(main, logical_size) or not _assert_help_clear_of_navigation(main, "Block Puzzle level 10,000"):
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

func _assert_help_clear_of_navigation(main: Control, label: String) -> bool:
	var shell := main.get_node_or_null("UXShell")
	var game := main.get_node_or_null("ActiveGame") as Control
	if shell == null or game == null:
		return _fail("%s cannot validate help/navigation separation" % label)
	var help = shell.get("help_button")
	if help == null or not is_instance_valid(help):
		return _fail("%s help button missing while checking navigation overlap" % label)
	var help_rect: Rect2 = help.get_global_rect()
	for node in _controls(game):
		if not node is Button or not node.visible or not node.is_visible_in_tree():
			continue
		var button := node as Button
		var text := button.text.strip_edges().to_upper()
		if text != "←" and text != "‹" and not text.contains("BACK"):
			continue
		if help_rect.intersects(button.get_global_rect()):
			return _fail("%s help control overlaps navigation button %s" % [label, str(button.get_path())])
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

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
