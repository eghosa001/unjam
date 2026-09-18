extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_require_source("res://scripts/ui/premium_home_direct_levels.gd", ["open_game_campaign", "rescue_rush", "water_sort", "block_puzzle"], "Home direct game-level shortcuts", failures)
	_require_source("res://scripts/game/block_puzzle_final_polish.gd", ["func block_progression_band", "func _best_hint_placement", "func show_hint", "place_selected"], "Block Puzzle progression and executing hint", failures)
	_require_source("res://scripts/ui/smooth_block_piece_button.gd", ["func _finish_touch_drag", "_hide_touch_preview(true)", "place_piece_from_drag"], "Block Puzzle single-copy drop lifecycle", failures)
	_require_source("res://scripts/game/water_sort_assisted.gd", ["func add_extra_tube", "func _best_water_move", "func show_hint", "select_tube"], "Water Sort solver hint and extra tube", failures)
	_require_source("res://scripts/game/water_sort_10000.gd", ["water_sort_progression.gd", "generate_tubes_with_solution", "target_difficulty", "empty_bottles", "two_star_moves"], "Water Sort 10K progression runtime", failures)
	_require_source("res://scripts/game/rescue_rush_assisted.gd", ["PuzzleSolver.find_solution", "Hint 1/3", "Hint 2/3", "Hint 3/3", "await try_move", "func show_hint"], "Rescue Rush executing solution hint", failures)
	_require_source("res://scenes/Game.tscn", ["rescue_rush_assisted.gd"], "Rescue Rush assisted leaf wiring", failures)
	_require_source("res://scenes/WaterSort.tscn", ["water_sort_10000.gd"], "Water Sort 10K leaf wiring", failures)
	_require_source("res://scenes/Main.tscn", ["premium_home_direct_levels.gd"], "Home direct-level leaf wiring", failures)

	var smooth := _read("res://scripts/ui/smooth_block_piece_button.gd")
	var start := smooth.find("func _finish_touch_drag")
	if start >= 0:
		var finish := smooth.find("\nfunc ", start + 1)
		var block := smooth.substr(start, finish - start if finish > start else smooth.length() - start)
		var hide := block.find("_hide_touch_preview(true)")
		var commit := block.find("place_piece_from_drag")
		if hide < 0 or commit < 0 or hide > commit:
			failures.append("Block Puzzle successful drop must remove the floating preview before committing board cells")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Assist/difficulty regression contract passed.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _require_source(path: String, needles: Array[String], label: String, failures: Array[String]) -> void:
	var source := _read(path)
	if source.is_empty():
		failures.append("%s source missing: %s" % [label, path])
		return
	for needle in needles:
		if not source.contains(needle):
			failures.append("%s missing contract token: %s" % [label, needle])
