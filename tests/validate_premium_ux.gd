extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check_source("res://scripts/ui/block_piece_button.gd", ["touch_preview", "TOUCH_LIFT", "_update_touch_footprint", "register_touch_drag"], failures)
	_check_source("res://scripts/game/block_puzzle_polished.gd", ["active_touch_piece", "register_touch_drag", "_finish_touch_drag"], failures)
	_check_source("res://scripts/ui/water_tube_reference_button.gd", ["PALETTE", "Tube lip", "play_invalid", "play_success"], failures)
	_check_source("res://scripts/ui/premium_home_casual.gd", ["Unjam3DBackdrop", "Unjam3DMascot", "_make_sign_stack", "_make_motto", "HomePrimaryAction", "_open_game_selector"], failures)
	_check_source("res://scripts/ui/premium_live_hub_3d.gd", ["CHOOSE A GAME", "Unjam3DGameArt", "_add_game_card"], failures)
	_check_source("res://scripts/ui/unjam_3d_mascot.gd", ["extends SubViewportContainer", "Camera3D", "SphereMesh", "DirectionalLight3D"], failures)
	_check_source("res://scripts/ui/unjam_3d_game_art.gd", ["extends SubViewportContainer", "_build_rescue_rush", "_build_water_sort", "_build_block_puzzle"], failures)
	_check_source("res://scripts/ui/unjam_3d_backdrop.gd", ["_draw_floating_island", "_draw_water_world", "_draw_foreground"], failures)
	_check_source("res://scripts/systems/premium_visuals.gd", ["tactile_success", "tactile_invalid", "transition_cover"], failures)
	_check_source("res://scripts/ui/motion_director.gd", ["create_tween", "TRANS", "EASE"], failures)
	_check_source("res://scenes/Main.tscn", ["premium_home_casual.gd", "premium_live_hub_3d.gd", "PremiumHome", "PremiumLive"], failures)

	for retired in [
		"res://scripts/ui/game_select_tile.gd",
		"res://scripts/ui/game_showcase_art.gd",
		"res://scripts/ui/unjam_logo.gd",
		"res://scripts/ui/polished_block_piece_button.gd"
	]:
		if FileAccess.file_exists(retired):
			failures.append("Retired visual source still present: " + retired)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Premium UX contract validated: reference-composed Home, true 3D game selection art, bright scenery, direct touch feedback, and retired flat visual paths removed.")
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
