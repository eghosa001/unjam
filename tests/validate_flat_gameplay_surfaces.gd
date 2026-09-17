extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_contains("res://scripts/game/rescue_rush_premium.gd", ["PremiumPieceButton.new()"], failures)
	_check_absent("res://scripts/game/rescue_rush_premium.gd", ["RescuePiece3D", "rescue_piece_3d_button.gd"], failures)
	_check_contains("res://scripts/game/rescue_rush_casual.gd", ["board_grid = GridContainer.new()"], failures)
	_check_contains("res://scripts/game/water_sort_casual.gd", ["board = GridContainer.new()", "GameplayStage"], failures)
	_check_contains("res://scripts/game/block_puzzle_3d.gd", ["board_grid = GridContainer.new()", "BlockCellButton.new()"], failures)
	_check_contains("res://scripts/ui/unjam_3d_gameplay_stage.gd", ["mouse_filter = Control.MOUSE_FILTER_IGNORE"], failures)
	if FileAccess.file_exists("res://scripts/ui/rescue_piece_3d_button.gd"):
		failures.append("Obsolete perspective-rendered Rescue Rush piece renderer still exists")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Flat gameplay surface contract validated for Rescue Rush, Water Sort, and Block Puzzle.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _check_contains(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if not text.contains(needle):
			failures.append("Missing flat-surface contract '%s' in %s" % [needle, path])

func _check_absent(path: String, needles: Array[String], failures: Array[String]) -> void:
	var text := _read(path)
	if text.is_empty():
		failures.append("Missing source: " + path)
		return
	for needle in needles:
		if text.contains(needle):
			failures.append("Perspective gameplay path '%s' still present in %s" % [needle, path])
