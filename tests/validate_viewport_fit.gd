extends SceneTree

const MAX_CAMPAIGN_LEVEL := 10000
const VIEWPORTS := [
	Vector2i(540,960),
	Vector2i(720,1280),
	Vector2i(720,1600),
	Vector2i(1080,1920),
	Vector2i(1080,2160),
	Vector2i(1080,2340),
	Vector2i(1080,2400)
]
const STRESS_VIEWPORTS := [Vector2i(540,960),Vector2i(720,1280)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _source_contracts():
		return
	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	for viewport_size in STRESS_VIEWPORTS:
		if not await _validate_late_game_viewport(viewport_size):
			return
	print("Viewport-fit validation passed: audited 390x844 Figma canvases scale uniformly across 7 portrait sizes and level 10,000 stress cases.")
	quit(0)

func _source_contracts() -> bool:
	var project_text := _read("res://project.godot")
	var ref_text := _read("res://scripts/ui/figma_reference_canvas.gd")
	var water_scene := _read("res://scenes/WaterSort.tscn")
	var water_10000 := _read("res://scripts/game/water_sort_10000.gd")
	var water_assisted := _read("res://scripts/game/water_sort_assisted.gd")
	var water_motion := _read("res://scripts/game/water_sort_reference_motion.gd")
	var water_casual := _read("res://scripts/game/water_sort_casual.gd")
	var water_tube_3d := _read("res://scripts/ui/water_tube_3d_motion.gd")
	var rescue_motion := _read("res://scripts/game/rescue_rush_polished.gd")
	var block_scene := _read("res://scenes/BlockPuzzle.tscn")
	var block_campaign := _read("res://scripts/game/block_puzzle_10000.gd")
	var block_polish := _read("res://scripts/game/block_puzzle_final_polish.gd")
	if not project_text.contains('window/stretch/aspect="expand"'):
		return _fail("Project stretch aspect must remain expand")
	if not ref_text.contains("REFERENCE_SIZE := Vector2(390.0, 844.0)") or not ref_text.contains("_fit_reference_canvas"):
		return _fail("Figma reference canvas contract is missing")
	if not water_scene.contains("water_sort_10000.gd") or not water_10000.contains('extends "res://scripts/game/water_sort_assisted.gd"') or not water_assisted.contains('extends "res://scripts/game/water_sort_casual.gd"'):
		return _fail("Water active scene no longer uses the 10K assisted Figma stack")
	if not water_casual.contains("FigmaWater390x844"):
		return _fail("Water gameplay no longer mounts the Figma canvas")
	if not water_motion.contains("visual_pour_rim_local") or not water_motion.contains("visual_receive_rim_local"):
		return _fail("Water pour motion no longer resolves visible bottle rims")
	if not water_motion.contains("pending_completion") or not water_motion.contains("_complete_if_visuals_settled"):
		return _fail("Water completion no longer waits for pour visuals")
	if not water_tube_3d.contains("_project_rim_point") or not water_tube_3d.contains("camera_3d.unproject_position"):
		return _fail("Water 3D rim projection contract is missing")
	if not rescue_motion.contains("_offscreen_target") or not rescue_motion.contains("_wait_for_escape_visuals"):
		return _fail("Rescue completion no longer waits for escape visuals")
	if not block_scene.contains("block_puzzle_10000.gd") or not block_campaign.contains('extends "res://scripts/game/block_puzzle_final_polish.gd"'):
		return _fail("Block active scene no longer preserves final polish/campaign logic")
	for required in ["TENSION_THRESHOLD","PremiumVisuals.burst"]:
		if not block_polish.contains(required):
			return _fail("Block final-polish contract missing %s" % required)
	return true

func _validate_viewport(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)

	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null or not _assert_canvas(home,"FigmaHome390x844",viewport_size,"Home"):
		return false

	main.call("build_settings")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Settings"):
		return false

	main.call("build_collection")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Collection"):
		return false

	main.call("build_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Rescue levels"):
		return false

	main.set("selected_game_id","water_sort")
	main.call("build_multi_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Water levels"):
		return false

	main.set("selected_game_id","block_puzzle")
	main.call("build_multi_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Block levels"):
		return false

	main.call("start_level",1)
	await _frames(10)
	var shell := main.get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial","rescue_rush")
		await _frames(4)
		if not _assert_canvas(shell as Node,"FigmaTutorial390x844",viewport_size,"Tutorial"):
			return false
		shell.call("hide_tutorial")
		await _frames(2)
	if not _assert_game(main,"FigmaRescue390x844",viewport_size,"Rescue"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","water_sort",1,false)
	await _frames(10)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaWater390x844",viewport_size,"Water"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","block_puzzle",1,false)
	await _frames(10)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaBlock390x844",viewport_size,"Block"):
		return false

	main.queue_free()
	await process_frame
	return true

func _validate_late_game_viewport(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn for level-10,000 stress test")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(7)

	main.call("start_level",MAX_CAMPAIGN_LEVEL)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaRescue390x844",viewport_size,"Rescue level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","water_sort",MAX_CAMPAIGN_LEVEL,false)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaWater390x844",viewport_size,"Water level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","block_puzzle",MAX_CAMPAIGN_LEVEL,false)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaBlock390x844",viewport_size,"Block level 10,000"):
		return false

	main.queue_free()
	await process_frame
	return true

func _assert_game(main: Control, canvas_name: String, viewport_size: Vector2i, label: String) -> bool:
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("%s active game missing" % label)
	var control := game as Control
	if not _rect_inside(control.get_global_rect(),Rect2(Vector2.ZERO,viewport_size)):
		return _fail("%s root spills outside %s" % [label,str(viewport_size)])
	return _assert_canvas(game as Node,canvas_name,viewport_size,label)

func _assert_canvas(owner: Node, canvas_name: String, viewport_size: Vector2i, label: String) -> bool:
	if owner == null:
		return _fail("%s owner is missing" % label)
	var canvas := owner.find_child(canvas_name,true,false) as Control
	if canvas == null:
		return _fail("%s missing %s" % [label,canvas_name])
	if canvas.size.distance_to(Vector2(390,844)) > 1.0:
		return _fail("%s reference canvas local size changed: %s" % [label,str(canvas.size)])
	if absf(canvas.scale.x-canvas.scale.y) > 0.001 or canvas.scale.x <= 0.0:
		return _fail("%s reference canvas scale is not uniform" % label)
	var screen := Rect2(Vector2.ZERO,viewport_size)
	if not _rect_inside(canvas.get_global_rect(),screen):
		return _fail("%s reference canvas spills outside %s: %s" % [label,str(viewport_size),str(canvas.get_global_rect())])
	return true

func _hide_tutorial(main: Control) -> void:
	var shell := main.get_node_or_null("UXShell")
	if shell != null and shell.has_method("hide_tutorial"):
		shell.call("hide_tutorial")

func _rect_inside(rect: Rect2, viewport: Rect2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= viewport.position.x-epsilon and rect.position.y >= viewport.position.y-epsilon and rect.end.x <= viewport.end.x+epsilon and rect.end.y <= viewport.end.y+epsilon

func _read(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
