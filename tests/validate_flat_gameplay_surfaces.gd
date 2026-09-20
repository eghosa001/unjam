extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Rescue Rush keeps its proven gameplay/escape interfaces, but the renderer
	# behind that interface must be a straight-on CanvasItem tile with 3D effects.
	_check("res://scripts/game/rescue_rush_premium.gd", [
		"rescue_piece_3d_button.gd",
		"RescuePiece3D.new()",
		"board_grid = GridContainer.new()"
	], failures)
	_check("res://scripts/game/rescue_rush_polished.gd", [
		"rescue_piece_3d_button.gd",
		"RescueEscapePiece3D.new()",
		"_wait_for_escape_visuals()"
	], failures)
	_check("res://scripts/ui/rescue_piece_3d_button.gd", [
		"premium_piece_button.gd",
		"super._ready()",
		"set_process(false)"
	], failures)
	_check_absent("res://scripts/ui/rescue_piece_3d_button.gd", [
		"Camera3D",
		"SubViewport",
		"Node3D",
		"BoxMesh",
		"TorusMesh",
		"StandardMaterial3D"
	], failures)
	_check("res://scripts/ui/premium_piece_button.gd", [
		"_draw_shell",
		"Lower bevel",
		"gloss_rect",
		"shadow_rect"
	], failures)

	# Water Sort and Block Puzzle keep their gameplay geometry on flat Controls/
	# grids. Their dimensional bottles/cubes and scenic background depth remain.
	_check("res://scripts/game/water_sort_casual.gd", [
		"gameplay_stage = PanelContainer.new()",
		"gameplay_stage.name = \"GameplayStage\"",
		"board = GridContainer.new()",
		"board.name = \"WaterBoard\""
	], failures)
	_check("res://scripts/game/block_puzzle_3d.gd", [
		"board_shell = PanelContainer.new()",
		"board_grid = GridContainer.new()",
		"BlockCellButton.new()"
	], failures)
	_check("res://scripts/ui/block_cell_button.gd", [
		"_draw_extruded_cube"
	], failures)
	_check("res://scripts/ui/water_tube_3d_motion.gd", [
		"SubViewport.UPDATE_ONCE"
	], failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Flat gameplay surface contract validated.")
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
			failures.append("Missing flat-board contract '%s' in %s" % [needle, path])

func _check_absent(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if text.contains(needle):
			failures.append("Perspective gameplay renderer '%s' still present in %s" % [needle, path])
