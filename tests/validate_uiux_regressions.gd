extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue_layout := _read("res://scripts/game/rescue_rush_motion_final.gd")
	var rescue_ui := _read("res://scripts/game/rescue_rush_casual.gd")
	var rescue_motion := _read("res://scripts/game/rescue_rush_polished.gd")
	var water_layout := _read("res://scripts/game/water_sort_ultra_motion.gd")
	var water_reference := _read("res://scripts/game/water_sort_reference_motion.gd")
	var water_ui := _read("res://scripts/game/water_sort_casual.gd")
	var block_drag := _read("res://scripts/ui/smooth_block_piece_button.gd")
	var block_ui := _read("res://scripts/game/block_puzzle_3d.gd")
	var block_preview := _read("res://scripts/ui/smooth_block_drag_preview.gd")
	var home := _read("res://scripts/ui/premium_home_casual.gd")
	var settings := _read("res://scripts/ui/premium_main_casual.gd")
	var motion := _read("res://scripts/ui/motion_director.gd")
	var touch := _read("res://scripts/ui/ui_touch_enhancer.gd")
	var ux_shell := _read("res://scripts/ui/ux_shell_casual.gd")
	var ux_shell_base := _read("res://scripts/ui/ux_shell_premium.gd")
	var monetization := _read("res://scripts/ui/monetization_hub_3d.gd")
	var main_controller := _read("res://scripts/ui/robust_main.gd")
	var main_scene := _read("res://scenes/Main.tscn")
	var water_scene := _read("res://scenes/WaterSort.tscn")
	var block_scene := _read("res://scenes/BlockPuzzle.tscn")
	var rescue_scene := _read("res://scenes/Game.tscn")
	var surface := _read("res://scripts/ui/premium_surface_manager_static.gd")
	var surface_base := _read("res://scripts/ui/premium_surface_manager.gd")
	var visuals := _read("res://scripts/systems/premium_visuals.gd")
	var project_text := _read("res://project.godot")

	if rescue_layout.is_empty() or water_layout.is_empty() or block_ui.is_empty():
		return _fail("Active gameplay layout sources are missing")
	if not rescue_layout.contains("size_changed.connect(_queue_board_fit)") or not rescue_layout.contains("_fit_board_to_viewport") or rescue_layout.contains("node_added.connect"):
		return _fail("Rescue Rush must have one event-driven layout owner")
	if not water_layout.contains("size_changed.connect(_queue_tube_layout)") or not water_layout.contains("_apply_tube_layout") or water_layout.contains("node_added.connect"):
		return _fail("Water Sort must have one event-driven layout owner")
	if not block_ui.contains("size_changed.connect(_queue_board_fit)") or not block_ui.contains("_fit_3d_board_layout") or block_ui.contains("node_added.connect"):
		return _fail("Block Puzzle must have one event-driven layout owner")
	for retired_layout in [
		"res://scripts/ui/rescue_layout_polish.gd",
		"res://scripts/ui/water_stage_polish.gd",
		"res://scripts/ui/puzzle_casual_polish.gd"
	]:
		if FileAccess.file_exists(retired_layout):
			return _fail("Duplicate gameplay layout helper still exists: %s" % retired_layout)
	if rescue_scene.contains("rescue_layout_polish.gd") or water_scene.contains("water_stage_polish.gd") or block_scene.contains("puzzle_casual_polish.gd"):
		return _fail("A gameplay scene still attaches a duplicate layout watcher")

	if not rescue_motion.contains("_escape_route_cells") or not rescue_motion.contains("await _wait_for_escape_visuals()") or not rescue_motion.contains("_speed_line_pool"):
		return _fail("Rescue route/completion tracking or effect pooling is missing")
	if not water_layout.contains("func _balanced_columns") or not water_reference.contains("_build_transfer_plan") or not water_reference.contains("visual_pour_rim_local") or not water_reference.contains("visual_receive_rim_local"):
		return _fail("Water Sort adaptive layout, pure transfer plan or mouth-to-mouth pour geometry is missing")
	if not block_drag.contains("_shape_centroid_grid") or not block_drag.contains("_candidate_origin_for_probe") or not block_preview.contains("exp(-delta * 86.0)"):
		return _fail("Block Puzzle magnetic smooth drag contract is missing")

	if not main_controller.contains("signal surface_changed"):
		return _fail("Main controller does not publish surface changes")
	if touch.contains("func _process") or not touch.contains("node_added.connect"):
		return _fail("Touch/readability enhancement still rescans the full UI on a timer")
	if surface_base.contains("func _process") or not surface_base.contains("surface_changed.connect"):
		return _fail("Secondary-surface styling still polls state instead of following surface events")
	if ux_shell.contains("func _process") or ux_shell_base.contains("func _process") or not ux_shell_base.contains("surface_changed.connect") or not ux_shell_base.contains("size_changed.connect"):
		return _fail("UX shell still maintains visibility/geometry every frame")
	if motion.contains("func _process") or not motion.contains("surface_changed.connect"):
		return _fail("Navigation motion still polls surface state every frame")
	if surface.contains("content.position =") or surface.contains("tween_property(content, \"position\""):
		return _fail("Active surface manager still moves content root")

	if not main_scene.contains("premium_surface_manager_static.gd") or not main_scene.contains("premium_home_casual.gd") or not main_scene.contains("premium_main_casual.gd") or not main_scene.contains("MotionDirector"):
		return _fail("Main scene is not using the final reboot surface stack")
	if not home.contains("Unjam3DBackdrop") or not home.contains("Unjam3DMascot") or not home.contains("_open_game_selector"):
		return _fail("Home is not using the reference-style 3D launcher")
	if not settings.contains("Settings3DDiorama") or not settings.contains("Collection3DDiorama") or not settings.contains("Levels3DDiorama") or not settings.contains("Unjam3DGameArt.new()"):
		return _fail("Secondary pages are missing one-shot 3D depth")
	if not monetization.contains("UNJAM SHOP") or not monetization.contains("Unjam3DBackdrop"):
		return _fail("Shop is not using the bright 3D surface")
	if not ux_shell_base.contains("theme_mode := \"light\""):
		return _fail("New installs still default to the old dark visual direction")

	if not motion.contains("MotionSystem.reduced()"):
		return _fail("Reduced Motion preference is not wired through MotionSystem")
	var visuals_has_gate := visuals.contains("func _reduced_motion") or visuals.contains("func reduced_motion_enabled")
	var visuals_uses_gate := visuals.contains("if _reduced_motion()") or visuals.contains("if reduced_motion_enabled()")
	if not visuals_has_gate or not visuals_uses_gate:
		return _fail("Shared premium effects do not expose and use a Reduced Motion gate")
	if not settings.contains("PremiumVisuals.apply_motion_preference()"):
		return _fail("Reduced Motion setting is not applied immediately")

	for retired_path in [
		"res://scripts/ui/home_cinematic_polish.gd",
		"res://scripts/ui/home_ux_patch.gd",
		"res://scripts/ui/secondary_surface_fill.gd",
		"res://scripts/ui/global_finish_polish.gd",
		"res://scripts/ui/game_showcase_art.gd",
		"res://scripts/ui/game_select_tile.gd",
		"res://scripts/ui/unjam_logo.gd",
		"res://scripts/ui/polished_block_piece_button.gd",
		"res://scripts/ui/level_browser_polish.gd"
	]:
		if FileAccess.file_exists(retired_path):
			return _fail("Retired UI source still exists: %s" % retired_path)
	if project_text.contains("res://addons/stagehand/plugin.cfg"):
		return _fail("Project still enables the missing Stagehand editor plugin")

	if not water_ui.contains("GameplayStage") or not water_scene.contains("water_sort_casual.gd"):
		return _fail("Water Sort is not using the gameplay-first stage")
	if not block_scene.contains("block_puzzle_3d.gd"):
		return _fail("Block Puzzle is not using the 3D gameplay presentation")
	if not rescue_ui.contains("GameplayBoardHolder") or not rescue_scene.contains("rescue_rush_casual.gd"):
		return _fail("Rescue Rush is not using the gameplay-first presentation")

	print("UI/UX regression contract validated")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
