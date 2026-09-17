extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")

func _init() -> void:
	var errors: Array[String] = []
	_validate_opening_rhythm(errors)
	_require_source("res://scripts/ui/smooth_block_piece_button.gd", ["func _get_drag_data", "touch_drag_started", "_clear_single_touch_preview"], "Block Puzzle single touch-preview ownership", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["func _inject_game_tabs", "JOURNEY OVERVIEW", "func _level_column_count"], "Levels/Collection responsive ownership", errors)
	_require_source("res://scripts/ui/premium_live_hub.gd", ["func _refresh_progress_on_entry"], "Choose Game progress refresh", errors)
	_require_source("res://scripts/ui/ux_shell_casual.gd", ["apply_theme_mode"], "active-game theme propagation", errors)
	_require_source("res://scripts/ui/unjam_3d_backdrop.gd", ["dark_mode"], "3D backdrop dark theme", errors)
	_require_source("res://scripts/game/rescue_rush_motion_final.gd", ["BOARD_HEIGHT_RATIO", "MAX_CELL_SIZE"], "Rescue Rush responsive density", errors)
	_require_source("res://scripts/game/water_sort_ultra_motion.gd", ["_available_tube_height", "row_count"], "Water Sort height-aware tube sizing", errors)
	_require_source("res://scripts/game/rescue_rush_casual.gd", ["func apply_theme_mode"], "Rescue Rush immediate dark theme", errors)
	_require_source("res://scripts/game/water_sort_casual.gd", ["func apply_theme_mode"], "Water Sort immediate dark theme", errors)
	_require_source("res://scripts/game/block_puzzle_final_polish.gd", ["func apply_theme_mode", "BlockPuzzle3DEnvironment"], "Block Puzzle immediate dark theme", errors)

	if not errors.is_empty():
		for error in errors:
			printerr(error)
		printerr("Reported polish regression contract failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Reported polish regression contract passed.")
	quit(0)

func _validate_opening_rhythm(errors: Array[String]) -> void:
	var expected := ["easy", "easy", "medium", "easy", "medium", "medium", "easy", "medium", "medium", "hard"]
	for level_number in range(1, 11):
		var level: Dictionary = CampaignGeneratorScript.generate(level_number)
		var actual := String(level.get("difficulty", ""))
		if actual != expected[level_number - 1]:
			errors.append("Rescue Rush level %d difficulty is %s, expected %s" % [level_number, actual, expected[level_number - 1]])

func _require_source(path: String, needles: Array[String], label: String, errors: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s source missing: %s" % [label, path])
		return
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			errors.append("%s missing contract token: %s" % [label, needle])
