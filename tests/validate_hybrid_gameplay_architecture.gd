extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	_check("res://scripts/game/rescue_rush_polished.gd", [
		"rescue_piece_3d_button.gd",
		"_active_escape_visuals",
		"_escape_route_cells",
		"_wait_for_escape_visuals",
		"await _wait_for_escape_visuals()",
		"_speed_line_pool",
		"_effect_label_pool",
		"_acquire_speed_line"
	], failures)
	_check("res://scripts/game/rescue_rush_premium.gd", [
		"rescue_piece_3d_button.gd",
		"RescuePiece3D.new()"
	], failures)
	_check("res://scripts/ui/rescue_piece_3d_button.gd", [
		"SubViewport",
		"SubViewport.UPDATE_ONCE",
		"BoxMesh",
		"TorusMesh",
		"_build_arrow_symbol"
	], failures)
	_check_absent("res://scripts/game/rescue_rush_motion_final.gd", [
		"_escape_visual_deadline_msec"
	], failures)

	_check("res://scripts/game/water_sort_reference_motion.gd", [
		"water_tube_3d_motion.gd",
		"active_source_tubes",
		"active_target_tubes",
		"_build_transfer_plan",
		"_commit_transfer_plan",
		"pending_completion",
		"visual_pour_rim_local",
		"visual_receive_rim_local"
	], failures)
	_check("res://scripts/ui/water_tube_3d_motion.gd", [
		"SubViewport",
		"CylinderMesh",
		"TorusMesh",
		"SubViewport.UPDATE_ONCE",
		"Vector2i(168, 336)",
		"liquid_materials_3d",
		"_refresh_liquid_3d"
	], failures)

	_check("res://scripts/game/block_puzzle_ultra_motion.gd", [
		"SmoothPieceButton"
	], failures)
	_check("res://scripts/ui/smooth_block_drag_preview.gd", [
		"exp(-delta * 86.0)"
	], failures)
	_check("res://scripts/ui/block_cell_button.gd", [
		"_draw_extruded_cube",
		"draw_colored_polygon"
	], failures)
	_check("res://scripts/ui/block_drag_preview.gd", [
		"_draw_extruded_cube",
		"draw_colored_polygon"
	], failures)

	_check("res://scripts/ui/premium_main_casual.gd", [
		"grid.columns = 4",
		"_highest_level_for_game"
	], failures)
	_check("res://scripts/ui/ux_shell_premium.gd", [
		"theme_mode := \"light\"",
		"get_value(\"appearance\", \"theme\", \"light\")"
	], failures)
	_check_absent("res://scenes/Main.tscn", [
		"level_browser_polish.gd",
		"LevelBrowserPolish"
	], failures)
	if FileAccess.file_exists("res://scripts/ui/level_browser_polish.gd"):
		failures.append("Obsolete level browser polling helper still exists")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Hybrid gameplay architecture contract validated.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _check(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if not text.contains(needle):
			failures.append("Missing hybrid gameplay contract '%s' in %s" % [needle, path])

func _check_absent(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if text.contains(needle):
			failures.append("Obsolete hybrid gameplay path '%s' still present in %s" % [needle, path])
