extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	_check("res://scripts/ui/premium_design_system.gd", ["MIN_TOUCH_HEIGHT", "raised_box", "recessed_box", "gloss_button", "hud_box", "status_chip"], failures)
	_check("res://scripts/ui/premium_home_casual.gd", ["PremiumUnjamLogo", "HomePrimaryAction", "THREE PUZZLES  •  ONE JOURNEY", "GameSelectTile", "MotionSystem.reduced"], failures)
	_check("res://scripts/ui/game_select_tile.gd", ["_draw_game_scene", "_draw_water_scene", "_draw_block_scene", "_draw_rescue_scene", "Progress strip", "Tactile circular action button"], failures)
	_check("res://scripts/ui/premium_surface_manager.gd", ["settings", "collection", "levels", "shop", "daily", "_polish_tree", "_add_surface_chrome"], failures)
	_check("res://scripts/game/rescue_rush_casual.gd", ["RESCUE RUSH", "RescueStoneFrame", "RescueRecessedBoard", "RESTART", "hud_box"], failures)
	_check("res://scripts/game/water_sort_casual.gd", ["POUR FROM THE BOTTLE MOUTH", "WaterGlassFrame", "GameplayStage", "RESTART", "hud_box"], failures)
	_check("res://scripts/game/water_sort_ultra_motion.gd", ["_visual_mouth_local", "_control_point"], failures)
	_check("res://scripts/game/block_puzzle_ultra_motion.gd", ["_apply_premium_block_surface", "_is_block_gameplay_widget", "raised_box", "recessed_box"], failures)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("All-screen premium visual consistency contract validated.")
	quit(0)

func _check(path: String, needles: Array[String], failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Missing source: " + path)
		return
	var source := file.get_as_text()
	for needle in needles:
		if not source.contains(needle):
			failures.append("Missing all-screen visual contract '%s' in %s" % [needle, path])
