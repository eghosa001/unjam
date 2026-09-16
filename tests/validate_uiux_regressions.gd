extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue := FileAccess.open("res://scripts/ui/rescue_layout_polish.gd", FileAccess.READ).get_as_text()
	var rescue_ui := FileAccess.open("res://scripts/game/rescue_rush_casual.gd", FileAccess.READ).get_as_text()
	var water_motion := FileAccess.open("res://scripts/game/water_sort_ultra_motion.gd", FileAccess.READ).get_as_text()
	var water_reference := FileAccess.open("res://scripts/game/water_sort_reference_motion.gd", FileAccess.READ).get_as_text()
	var water_stage := FileAccess.open("res://scripts/ui/water_stage_polish.gd", FileAccess.READ).get_as_text()
	var water_ui := FileAccess.open("res://scripts/game/water_sort_casual.gd", FileAccess.READ).get_as_text()
	var block_drag := FileAccess.open("res://scripts/ui/smooth_block_piece_button.gd", FileAccess.READ).get_as_text()
	var block_ui := FileAccess.open("res://scripts/ui/puzzle_casual_polish.gd", FileAccess.READ).get_as_text()
	var home := FileAccess.open("res://scripts/ui/premium_home_casual.gd", FileAccess.READ).get_as_text()
	var settings := FileAccess.open("res://scripts/ui/premium_main_casual.gd", FileAccess.READ).get_as_text()
	var motion := FileAccess.open("res://scripts/ui/motion_director.gd", FileAccess.READ).get_as_text()
	var touch := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ).get_as_text()
	var ux_shell := FileAccess.open("res://scripts/ui/ux_shell_casual.gd", FileAccess.READ).get_as_text()
	var ux_shell_base := FileAccess.open("res://scripts/ui/ux_shell_premium.gd", FileAccess.READ).get_as_text()
	var monetization := FileAccess.open("res://scripts/ui/monetization_hub.gd", FileAccess.READ).get_as_text()
	var main_controller := FileAccess.open("res://scripts/ui/robust_main.gd", FileAccess.READ).get_as_text()
	var main_scene := FileAccess.open("res://scenes/Main.tscn", FileAccess.READ).get_as_text()
	var water_scene := FileAccess.open("res://scenes/WaterSort.tscn", FileAccess.READ).get_as_text()
	var block_scene := FileAccess.open("res://scenes/BlockPuzzle.tscn", FileAccess.READ).get_as_text()
	var rescue_scene := FileAccess.open("res://scenes/Game.tscn", FileAccess.READ).get_as_text()
	var surface := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ).get_as_text()
	var surface_base := FileAccess.open("res://scripts/ui/premium_surface_manager.gd", FileAccess.READ).get_as_text()
	var visuals := FileAccess.open("res://scripts/systems/premium_visuals.gd", FileAccess.READ).get_as_text()
	var robust_visuals := FileAccess.open("res://scripts/systems/robust_premium_visuals.gd", FileAccess.READ).get_as_text()
	var backdrop := FileAccess.open("res://scripts/ui/premium_backdrop.gd", FileAccess.READ).get_as_text()
	var showcase := FileAccess.open("res://scripts/ui/game_showcase_art.gd", FileAccess.READ).get_as_text()
	var project_text := FileAccess.open("res://project.godot", FileAccess.READ).get_as_text()

	if not rescue.contains("viewport_height") or not rescue.contains("max_board_height"):
		return _fail("Rescue height-aware sizing missing")
	if rescue.contains("func _process") or not rescue.contains("size_changed.connect") or not rescue.contains("node_added.connect"):
		return _fail("Rescue layout is still timer-polled instead of event-driven")
	if not water_motion.contains("func _balanced_columns") or not water_motion.contains("tube_count <= 6") or not water_motion.contains("return 3"):
		return _fail("Water Sort adaptive phone layout missing")
	if not water_reference.contains("visual_pour_rim_local") or not water_reference.contains("visual_receive_rim_local") or not water_reference.contains("source_mouth, exit_point, receiver_mouth"):
		return _fail("Water Sort bottle-rim pour geometry missing")
	if water_stage.contains("func _process") or not water_stage.contains("size_changed.connect") or not water_stage.contains("node_added.connect"):
		return _fail("Water Sort stage layout is still timer-polled instead of event-driven")
	if not block_drag.contains("_shape_centroid_grid") or not block_drag.contains("_candidate_origin_for_probe") or not block_drag.contains("game.call(\"can_place\", shape, candidate)"):
		return _fail("Block centroid magnetism missing")
	if block_ui.contains("func _process") or not block_ui.contains("size_changed.connect") or not block_ui.contains("node_added.connect"):
		return _fail("Block Puzzle layout is still timer-polled instead of event-driven")
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
	if not main_scene.contains("premium_surface_manager_static.gd") or not main_scene.contains("premium_home_casual.gd") or not main_scene.contains("premium_main_casual.gd"):
		return _fail("Active main scene is not using the casual-polish surfaces")
	if main_scene.contains("home_ux_patch.gd") or main_scene.contains("secondary_surface_fill.gd") or main_scene.contains("global_finish_polish.gd"):
		return _fail("Legacy dashboard/flash polish layers are still active")
	if main_scene.contains("home_cinematic_polish.gd"):
		return _fail("Home still depends on a periodic geometry override")
	if surface.contains("content.position =") or surface.contains("tween_property(content, \"position\""):
		return _fail("Active surface manager still moves content root")
	if not motion.contains("reduced_motion"):
		return _fail("Reduced Motion preference is not wired into navigation motion")
	var visuals_has_gate := visuals.contains("func _reduced_motion") or visuals.contains("func reduced_motion_enabled")
	var visuals_uses_gate := visuals.contains("if _reduced_motion()") or visuals.contains("if reduced_motion_enabled()")
	if not visuals_has_gate or not visuals_uses_gate:
		return _fail("Shared premium effects do not expose and use a Reduced Motion gate")
	if not robust_visuals.contains("_reduced_motion()") and not robust_visuals.contains("reduced_motion_enabled()"):
		return _fail("Adaptive premium visuals still ignore Reduced Motion")
	if not backdrop.contains("reduced_motion") or not backdrop.contains("set_process(not reduced)") or not showcase.contains("reduced_motion") or not showcase.contains("set_process(not reduced)"):
		return _fail("Continuous decorative animation ignores Reduced Motion")
	if not home.contains("reduced_motion") or not surface.contains("reduced_motion"):
		return _fail("Home or secondary-surface entrance animation ignores Reduced Motion")
	if not settings.contains("PremiumVisuals.apply_motion_preference()"):
		return _fail("Reduced Motion setting is not applied immediately")

	var retired_paths := [
		"res://scripts/ui/home_cinematic_polish.gd",
		"res://scripts/ui/home_ux_patch.gd",
		"res://scripts/ui/secondary_surface_fill.gd",
		"res://scripts/ui/global_finish_polish.gd"
	]
	for path in retired_paths:
		if FileAccess.file_exists(path):
			return _fail("Retired UI patch script still exists: %s" % path)
	if project_text.contains("res://addons/stagehand/plugin.cfg"):
		return _fail("Project still enables the missing Stagehand editor plugin")

	if not home.contains("HomeSecondaryActions") or home.contains("LIVE\nPLAY HUB"):
		return _fail("Home still uses dashboard-like equally weighted secondary actions")
	if not home.contains("hero.custom_minimum_size = Vector2(0, 520)") or not home.contains("hero_art.custom_minimum_size = Vector2(390, 480)") or not home.contains('hero_title.add_theme_font_size_override("font_size", 46)') or not home.contains('hero_subtitle.add_theme_font_size_override("font_size", 21)') or not home.contains("Vector2(0, 92)"):
		return _fail("Home script does not own the final cinematic geometry")
	if not home.contains("SHOP") or not home.contains("open_shop"):
		return _fail("Home does not expose a Shop path")
	if not monetization.contains("func open_shop"):
		return _fail("MonetizationHub does not expose a public Shop opener")
	if ux_shell.contains("shop.visible = false") or ux_shell_base.contains("shop.visible = false"):
		return _fail("UXShell still force-hides the Shop")
	if not settings.contains("REDUCED MOTION") or settings.contains("PLAY HISTORY"):
		return _fail("Settings is not yet a compact preferences surface")
	if not water_ui.contains("GameplayStage") or water_ui.contains("Vector2(0, 1040)") or not water_scene.contains("water_sort_casual.gd"):
		return _fail("Water Sort is not using the gameplay-first stage")
	if not block_ui.contains("CompactProgressStrip") or not block_ui.contains("available_height") or not block_scene.contains("puzzle_casual_polish.gd"):
		return _fail("Block Puzzle is not using the board-first responsive polish")
	if not rescue_ui.contains("GameplayBoardHolder") or rescue_ui.contains("EVERY RESCUE COUNTS") or rescue_ui.contains("Tip: clear blockers") or not rescue_scene.contains("rescue_rush_casual.gd"):
		return _fail("Rescue Rush still contains duplicate gameplay chrome")

	print("UI/UX regression checks passed")
	quit(0)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
