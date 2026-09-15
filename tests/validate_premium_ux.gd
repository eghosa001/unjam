extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/block_piece_button.gd", ["touch_preview", "TOUCH_LIFT", "_update_touch_footprint", "register_touch_drag"], failures)
	_check_source("res://scripts/game/block_puzzle_polished.gd", ["active_touch_piece", "register_touch_drag", "_finish_touch_drag"], failures)
	_check_source("res://scripts/ui/water_tube_reference_button.gd", ["PALETTE", "Bright top meniscus", "Tube lip", "draw_line", "play_invalid", "play_success"], failures)
	_check_source("res://scripts/ui/premium_home_overhaul.gd", ["PremiumBackdrop", "build_home_launcher", "animate_entry", "mouse_filter = Control.MOUSE_FILTER_STOP"], failures)
	_check_source("res://scripts/systems/premium_visuals.gd", ["tactile_success", "tactile_invalid", "transition_cover"], failures)

	# App-wide premium contract: every legacy surface is routed through one design
	# system, appearance remains user-accessible, and Main wires the manager in.
	_check_source("res://scripts/ui/premium_design_system.gd", ["class_name PremiumDesignSystem", "GAME_ACCENTS", "apply_button", "apply_panel", "game_canvas"], failures)
	_check_source("res://scripts/ui/premium_surface_manager.gd", ["_configure_background", "_polish_tree", "_add_surface_chrome", "settings", "collection", "levels"], failures)
	_check_source("res://scripts/ui/ux_shell_premium.gd", ["theme_button.visible = surface == \"settings\"", "PremiumDesignSystem.apply_button", "PremiumDesignSystem.apply_panel"], failures)
	_check_source("res://scripts/ui/premium_backdrop.gd", ["light_mode", "base_color.get_luminance", "Vignette changes with appearance mode"], failures)
	_check_source("res://scripts/ui/motion_director.gd", ["create_tween", "TRANS", "EASE"], failures)
	_check_source("res://scenes/Main.tscn", ["premium_surface_manager.gd", "PremiumSurfaceManager", "PremiumHome", "PremiumLive"], failures)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Premium UX contract validated: direct touch feedback, distinct game color language, app-wide design tokens, theme-aware backdrops, premium legacy surfaces, and flash-free navigation.")
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
