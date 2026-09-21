extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")

func _init() -> void:
	var errors: Array[String] = []
	_validate_opening_rhythm(errors)
	_require_source("res://scripts/ui/smooth_block_piece_button.gd", ["func _get_drag_data", "touch_drag_started", "_clear_single_touch_preview"], "Block Puzzle single touch-preview ownership", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["func _inject_game_tabs", "YOUR UNJAM JOURNEY", "func _level_column_count"], "Levels/Collection responsive ownership", errors)
	_require_source("res://scripts/ui/premium_live_hub.gd", ["func _refresh_progress_on_entry"], "Choose Game progress refresh", errors)
	_require_source("res://scripts/ui/ux_shell_casual.gd", ["apply_theme_mode"], "active-game theme propagation", errors)
	_require_source("res://scripts/ui/unjam_3d_backdrop.gd", ["dark_mode"], "3D backdrop dark theme", errors)
	_require_source("res://scripts/game/rescue_rush_motion_final.gd", ["BOARD_HEIGHT_RATIO", "MAX_CELL_SIZE"], "Rescue Rush responsive density", errors)
	_require_source("res://scripts/game/water_sort_ultra_motion.gd", ["_available_tube_height", "row_count"], "Water Sort height-aware tube sizing", errors)
	_require_source("res://scripts/game/rescue_rush_casual.gd", ["func apply_theme_mode"], "Rescue Rush immediate dark theme", errors)
	_require_source("res://scripts/game/water_sort_casual.gd", ["func apply_theme_mode"], "Water Sort immediate dark theme", errors)
	_require_source("res://scripts/game/block_puzzle_final_polish.gd", ["func apply_theme_mode", "BlockPuzzle3DEnvironment"], "Block Puzzle immediate dark theme", errors)
	_require_source("res://scripts/ui/premium_home_direct_levels.gd", ["HomeWorldProgressRoot", "HomeWorldShowcase3D", "_add_world_progress(figma_canvas)", "progress_accent"], "Home Quick Switch world-progress synchronization", errors)
	_require_source("res://scripts/ui/premium_home_direct_levels.gd", ["WORLD JOURNEY\", Rect2(195, 596, 152, 17), 12", "LEVEL %d • %d/%d", "%d%% COMPLETE", "Rect2(195, 706, 150, 16), 11"], "Home world-journey text readability", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["SurfaceGlossSweep", "SurfaceWorldDepth", "DONE TODAY", "PLAY TODAY", "FIGMA_DARK_INK if _dark() else FIGMA_INK"], "gloss/independent-Daily/dark-level readability", errors)
	_require_source("res://scripts/ui/ux_shell_casual.gd", ["TutorialStepCard", "Rect2(43,409,302,76)", "Rect2(43,598,302,58)"], "tutorial collision-safe layout", errors)
	_require_source("res://scripts/ui/premium_result_overlay.gd", ["Rect2(27,76,334,570 if has_secondary else 500)", "Rect2(47,568,294,48)"], "result collision-safe layout", errors)
	_require_source("res://scripts/game/game.gd", ["moves > par_moves", "moves > par_moves + 3", "assist_penalty"], "Rescue star move/assist scoring", errors)
	_require_source("res://scripts/game/water_sort_10000.gd", ["moves <= par_moves", "moves <= two_star_moves"], "Water Sort star move scoring", errors)
	_require_source("res://scripts/game/block_puzzle.gd", ["placements <= par_placements", "placements <= par_placements + 6"], "Block Puzzle star placement scoring", errors)
	_require_source("res://scripts/game/block_puzzle_3d.gd", ["Vector2(326, 112)", "Rect2(17,526,354,150)", "return Vector2(104, 112)"], "Block tray phone-scale fit", errors)
	_require_source("res://scripts/ui/block_piece_button.gd", ["pedestal_rect", "pedestal_gloss"], "Block tray visual hierarchy", errors)
	_require_source("res://scripts/game/water_sort_reference_motion.gd", ["tilt_degrees := 32.0 if MotionSystem.reduced() else 62.0"], "Water pour silhouette cohesion", errors)
	_require_source("res://scripts/ui/water_tube_3d_motion.gd", ["Color(0.76, 0.95, 1.0, 0.44)", "Color(0.86, 0.995, 1.0, 0.54)"], "Water bottle glass readability", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["Rect2(83,49,186,34), 14", "premium_button(\"PRIVACY OPTIONS\",14", "premium_button(\"HOW TO PLAY\",14"], "Header/Settings readable action text", errors)
	_require_source("res://scripts/ui/ux_shell_casual.gd", ["premium_button(\"‹ BACK\",14", "premium_button(\"NEXT ›\",14"], "Tutorial navigation readability", errors)
	_require_source("res://scripts/ui/monetization_hub_3d.gd", ["premium_button(\"▶ +50 COINS\",14", "premium_button(\"RESTORE PURCHASES\",14", "premium_button(buy_text,14"], "Shop readable action text", errors)
	_require_source("res://scripts/ui/premium_result_overlay.gd", ["premium_button(secondary_text, 14"], "Result secondary action readability", errors)
	_require_source("res://scripts/game/block_puzzle_3d.gd", ["set_rect(status_region, 18, 682", "set_rect(hint_region, 18, 706"], "Block tray/status/guidance separation", errors)
	_require_source("res://scripts/game/block_puzzle_10000.gd", ["set_rect(bar, 17, 732, 349, 54)"], "Block booster lower thumb-zone separation", errors)
	_require_source("res://scripts/ui/ux_shell_casual.gd", ["label(\"EXIT\",12,Color.WHITE", "set_rect(exit_label,160,34,46,17)"], "Tutorial exit label containment", errors)
	_require_source("res://scripts/ui/figma_reference_canvas.gd", ["second dark glyph", "font_shadow_color\", Color.TRANSPARENT", "shadow_offset_y\", 2", "shadow_outline_size\", 1"], "crisp scaled Figma text", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["Rect2(34,label_y-7,210,30),14", "button_text_color,19,14", "theme_text,19,14"], "Settings compact text minimums", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["Rect2(17,539,354,112)", "Rect2(37,y+8,184,18),14", "Rect2(37,y+48,192,15),12", "Rect2(251,y+13,96,44)", "state_text_color,\n\t\t\t12,\n\t\t\t13"], "Collection compact spacing/readability", errors)
	_require_source("res://scripts/ui/premium_main_casual.gd", ["func _figma_daily_progress", "DailyProgressBar", "Each Daily is independent • play in any order", "Rect2(33,703,318,18), 12", "Rect2(17,610,354,116)"], "Daily independent progress panel", errors)

	if not errors.is_empty():
		for error in errors:
			printerr(error)
		printerr("Reported polish regression contract failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Reported polish regression contract passed.")
	quit(0)

func _validate_opening_rhythm(errors: Array[String]) -> void:
	var first_score := -1
	var last_score := -1
	for level_number in range(1, 11):
		var level: Dictionary = CampaignGeneratorScript.generate(level_number)
		var score := int(level.get("difficulty_score", -1))
		if score < 10 or score > 25:
			errors.append("Rescue Rush level %d opening difficulty score is outside 10..25: %d" % [level_number, score])
		if int(level.get("mistake_limit", -1)) != 0:
			errors.append("Rescue Rush level %d should not punish blocked taps during onboarding" % level_number)
		if int(level.get("width", 0)) != 7 or int(level.get("height", 0)) != 7:
			errors.append("Rescue Rush level %d should use the readable 7x7 opening board" % level_number)
		if level_number == 1:
			first_score = score
		if level_number == 10:
			last_score = score
	if last_score < first_score:
		errors.append("Rescue Rush opening difficulty must not regress across levels 1..10")

func _require_source(path: String, needles: Array[String], label: String, errors: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("%s source missing: %s" % [label, path])
		return
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			errors.append("%s missing contract token: %s" % [label, needle])
