extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []

	# Rescue Rush gameplay must read as a flat board. Depth is provided by the
	# 2D bevel/gloss/shadow renderer, not perspective Camera3D/SubViewport tiles.
	_check("res://scripts/game/rescue_rush_premium.gd", [
		"premium_piece_button.gd",
		"PremiumPieceButton.new()",
		"board_grid = GridContainer.new()"
	], failures)
	_check_absent("res://scripts/game/rescue_rush_premium.gd", [
		"rescue_piece_3d_button.gd",
		"RescuePiece3D.new()",
		"Camera3D",
		"SubViewport"
	], failures)
	_check("res://scripts/game/rescue_rush_polished.gd", [
		"premium_piece_button.gd",
		"PremiumPieceButton.new()"
	], failures)
	_check_absent("res://scripts/game/rescue_rush_polished.gd", [
		"rescue_piece_3d_button.gd",
		"RescueEscapePiece3D.new()",
		"Camera3D",
		"SubViewport"
	], failures)

	# Water Sort and Block Puzzle keep their gameplay geometry on flat Controls/
	# grids. Their 3D-looking bottles/cubes and background depth remain allowed.
	_check("res://scripts/game/water_sort_casual.gd", [
		"stage := PanelContainer.new()",
		"board = GridContainer.new()"
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
			failures.append("Perspective gameplay path '%s' still present in %s" % [needle, path])
