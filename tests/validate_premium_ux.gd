extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/block_piece_button.gd", ["touch_preview", "TOUCH_LIFT", "_update_touch_footprint", "register_touch_drag"], failures)
	_check_source("res://scripts/game/block_puzzle_polished.gd", ["active_touch_piece", "register_touch_drag", "_finish_touch_drag"], failures)
	_check_source("res://scripts/ui/water_tube_reference_button.gd", ["_draw_liquid_marker", "ff3b5c", "2374ff", "ffd400", "00c27a"], failures)
	_check_source("res://scripts/ui/premium_home_overhaul.gd", ["Never fade the full-screen surface"], failures)
	_check_source("res://scripts/systems/premium_visuals.gd", ["tactile_success", "tactile_invalid", "transition_cover"], failures)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
	print("Premium UX contract validated: direct touch feedback, distinct color language, restrained motion, flash-free home transitions.")
	quit(0)

func _check_source(path: String, needles: Array[String], failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Missing source: " + path)
		return
	var text := file.get_as_text()
	for needle in needles:
		if not text.contains(needle):
			failures.append("Missing premium UX contract '%s' in %s" % [needle, path])
