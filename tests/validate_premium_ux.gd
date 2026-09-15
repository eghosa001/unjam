extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/block_piece_button.gd", ["touch_preview", "TOUCH_LIFT", "_update_touch_footprint", "register_touch_drag"], failures)
	_check_source("res://scripts/ui/smooth_block_piece_button.gd", ["_shape_centroid_grid", "_candidate_origin_for_probe", "_best_origin"], failures)
	_check_source("res://scripts/game/block_puzzle_polished.gd", ["active_touch_piece", "register_touch_drag", "_finish_touch_drag"], failures)
	_check_source("res://scripts/ui/ui_touch_enhancer.gd", ["Release when the placement preview locks into place"], failures)
	_check_source("res://scripts/ui/water_tube_reference_button.gd", ["PALETTE", "Bright top meniscus", "Tube lip", "draw_line", "play_invalid", "play_success"], failures)
	_check_source("res://scripts/game/water_sort_reference_motion.gd", ["_stream_curve_points", "source_tangent", "receiver_mouth", "PackedVector2Array"], failures)
	_check_source("res://scripts/game/water_sort_ultra_motion.gd", ["_balanced_columns", "tube_count <= 6", "return 3", "GAME_FIRST_WATER"], failures)
	_check_source("res://scripts/game/rescue_rush_motion_final.gd", ["_fit_board_to_viewport", "max_board_height", "calculated_height", "board_panel.custom_minimum_size"], failures)
	_check_source("res://scripts/ui/rescue_layout_polish.gd", ["GAME_FIRST_RESCUE", "board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL", "deck.custom_minimum_size = Vector2(0, 116)"], failures)
	_check_source("res://scripts/game/block_puzzle_premium_layout.gd", ["GAME_FIRST_BLOCK", "score_card.custom_minimum_size = Vector2(0, 92)", "tray.custom_minimum_size = Vector2(0, 196)"], failures)
	_check_source("res://scripts/ui/premium_home_overhaul.gd", ["PremiumBackdrop", "build_home_launcher", "GAME_FIRST_HOME", "HomePrimaryAction", "quick.columns = 2", "screen itself remains geometrically fixed"], failures)
	_check_source("res://scripts/ui/main.gd", ["GAME_FIRST_SETTINGS", "YOUR PROGRESS LIVES ON THE HOME AND COLLECTION SCREENS", "SOUND", "HAPTICS", "MUSIC", "APPEARANCE"], failures)
	_check_source("res://scripts/systems/premium_visuals.gd", ["tactile_success", "tactile_invalid", "transition_cover"], failures)
	_check_source("res://scripts/ui/premium_design_system.gd", ["class_name PremiumDesignSystem", "GAME_ACCENTS", "apply_button", "apply_panel", "game_canvas"], failures)
	_check_source("res://scripts/ui/premium_surface_manager.gd", ["_configure_background", "_polish_tree", "_add_surface_chrome", "MotionDirector is the single owner of surface-entry motion", "settings", "collection", "levels"], failures)
	_check_source("res://scripts/ui/ux_shell_premium.gd", ["theme_button.visible = surface == \"settings\"", "PremiumDesignSystem.apply_button", "PremiumDesignSystem.apply_panel"], failures)
	_check_source("res://scripts/ui/premium_backdrop.gd", ["light_mode", "base_color.get_luminance", "Vignette changes with appearance mode"], failures)
	_check_source("res://scripts/ui/motion_director.gd", ["create_tween", "TRANS", "EASE", "screen itself must remain geometrically fixed"], failures)
	_check_source("res://scenes/Main.tscn", ["premium_surface_manager.gd", "PremiumSurfaceManager", "PremiumHome", "PremiumLive"], failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Premium UX contract validated: game-first home and settings, larger Rescue Rush playfield, focused Block Puzzle canvas, readable Water Sort pours, stable navigation, and premium surfaces.")
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
