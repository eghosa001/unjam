extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check("res://scripts/ui/unjam_3d_theme.gd", ["class_name Unjam3DTheme", "gloss_button", "panel_3d", "SKY_TOP"], failures)
	_check("res://scripts/ui/unjam_3d_backdrop.gd", ["class_name Unjam3DBackdrop", "_draw_floating_island", "_draw_water_world", "_draw_foreground"], failures)
	_check("res://scripts/ui/unjam_3d_mascot.gd", ["extends SubViewportContainer", "Camera3D", "SphereMesh", "ExplorerMascot"], failures)
	_check("res://scripts/ui/unjam_3d_game_art.gd", ["extends SubViewportContainer", "_build_rescue_rush", "_build_water_sort", "_build_block_puzzle"], failures)
	_check("res://scripts/ui/unjam_3d_gameplay_stage.gd", ["class_name Unjam3DGameplayStage", "SubViewport", "Camera3D", "configure", "_build_rescue_world", "_build_water_world", "_build_block_world"], failures)
	_check("res://scripts/ui/rescue_token.gd", ["extends SubViewportContainer", "Camera3D", "SphereMesh", "celebrate", "RescueCharacter3D"], failures)
	_check("res://scripts/ui/premium_home_casual.gd", ["UNJAM", "build_home_launcher", "_make_game_card", "_make_bottom_nav", "Unjam3DBackdrop", "Unjam3DMascot"], failures)
	_check("res://scripts/ui/premium_live_hub_3d.gd", ["CHOOSE A GAME", "Unjam3DGameArt", "_add_game_card"], failures)
	_check("res://scripts/ui/monetization_hub_3d.gd", ["UNJAM SHOP", "Unjam3DBackdrop", "POWER UP YOUR JOURNEY"], failures)
	_check("res://scripts/ui/retention_hub_3d.gd", ["_apply_3d_retention_skin", "Unjam3DBackdrop"], failures)
	_check("res://scripts/ui/premium_result_overlay.gd", ["ResultCard3D", "ONE MOVE CLOSER", "Unjam3DTheme"], failures)
	_check("res://scripts/ui/ux_shell_casual.gd", ["_restyle_3d_shell", "Unjam3DTheme"], failures)
	_check("res://scripts/ui/premium_piece_button.gd", ["chunky toy depth", "Unjam3DTheme.GOLD"], failures)
	_check("res://scripts/game/rescue_rush_casual.gd", ["Unjam3DGameplayStage", "rescue_rush", "CLEAR THE LANE", "RESTART"], failures)
	_check("res://scripts/game/water_sort_casual.gd", ["Unjam3DGameplayStage", "water_sort", "SORT THE COLOURS", "RESTART"], failures)
	_check("res://scripts/game/block_puzzle_3d.gd", ["Unjam3DGameplayStage", "block_puzzle", "DRAG • PLACE • CLEAR", "board_shell"], failures)
	_check("res://scenes/Main.tscn", ["premium_live_hub_3d.gd", "monetization_hub_3d.gd", "PremiumHome", "PremiumLive"], failures)
	_check("res://scenes/BlockPuzzle.tscn", ["block_puzzle_3d.gd"], failures)
	_check("res://scenes/RetentionHub.tscn", ["retention_hub_3d.gd"], failures)
	_check("res://project.godot", ["boot_splash/bg_color=Color(0.255, 0.725, 1, 1)", "environment/defaults/default_clear_color=Color(0.255, 0.725, 1, 1)"], failures)

	var home_base := _read("res://scripts/ui/premium_home_overhaul.gd")
	for legacy in ["PremiumBackdrop.new()", "GameShowcaseArt", "GameSelectTile", "UnjamLogo"]:
		if home_base.contains(legacy):
			failures.append("Retired home visual dependency still active: " + legacy)
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
	print("3D visual reboot contract validated: real 3D mascot, rescue character, game previews and gameplay environments with retired flat visual paths removed.")
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
			failures.append("Missing 3D visual contract '%s' in %s" % [needle, path])
