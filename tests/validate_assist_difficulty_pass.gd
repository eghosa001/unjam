extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_require_source("res://scripts/ui/premium_home_direct_levels.gd", ["func _continue_selected_game", "start_level", "start_multi_level", "Callable(self, \"_open_game_selector\")", "rescue_rush", "water_sort", "block_puzzle"], "Home active game-level navigation", failures)
	_require_source("res://scripts/ui/premium_home_casual.gd", ["func _open_game_selector()", "current_surface", "FeedbackManager.tap()"], "Inherited Home game selector", failures)
	_require_source("res://scripts/game/block_puzzle_final_polish.gd", ["func block_progression_band", "func _best_hint_placement", "func show_hint", "place_selected"], "Block Puzzle progression and executing hint", failures)
	_require_source("res://scripts/ui/smooth_block_piece_button.gd", ["func _finish_touch_drag", "_hide_touch_preview(true)", "place_piece_from_drag"], "Block Puzzle single-copy drop lifecycle", failures)
	_require_source("res://scripts/game/water_sort_assisted.gd", ["func add_extra_tube", "func _best_water_move", "func show_hint", "select_tube"], "Water Sort solver hint and extra tube", failures)
	_require_source("res://scripts/game/water_sort_10000.gd", ["water_sort_progression.gd", "generate_tubes_with_solution", "target_difficulty", "empty_bottles", "two_star_moves"], "Water Sort 10K progression runtime", failures)
	_require_source("res://scripts/game/rescue_rush_assisted.gd", ["PuzzleSolver.find_solution", "func show_hint", "await super.show_hint()"], "Rescue Rush direct-removal hint", failures)
	_require_source("res://scripts/game/rescue_rush_casual.gd", ["func _hint_arrow_index", "escape_piece(index, true)", "history.append(snapshot())"], "Rescue Rush arrow-removal implementation", failures)
	_require_source("res://scenes/Game.tscn", ["rescue_rush_assisted.gd"], "Rescue Rush assisted leaf wiring", failures)
	_require_source("res://scenes/WaterSort.tscn", ["water_sort_10000.gd"], "Water Sort 10K leaf wiring", failures)
	_require_source("res://scenes/Main.tscn", ["premium_home_direct_levels.gd"], "Home direct-level leaf wiring", failures)


	var rescue_assisted := _read("res://scripts/game/rescue_rush_assisted.gd")
	for stale in ["Hint 1/3", "Hint 2/3", "Hint 3/3", "await try_move"]:
		if rescue_assisted.contains(stale):
			failures.append("Rescue Hint still contains tutorial/escalation behavior: %s" % stale)
	var rescue_casual := _read("res://scripts/game/rescue_rush_casual.gd")
	var hint_start := rescue_casual.find("func show_hint")
	if hint_start >= 0:
		var hint_end := rescue_casual.find("\nfunc ", hint_start + 1)
		var hint_block := rescue_casual.substr(hint_start, hint_end - hint_start if hint_end > hint_start else rescue_casual.length() - hint_start)
		if hint_block.contains("moves +="):
			failures.append("Rescue Hint must remove an arrow without consuming a player move")

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
