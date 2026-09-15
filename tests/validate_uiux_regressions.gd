extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue := FileAccess.open("res://scripts/ui/rescue_layout_polish.gd", FileAccess.READ).get_as_text()
	var rescue_ui := FileAccess.open("res://scripts/game/rescue_rush_casual.gd", FileAccess.READ).get_as_text()
	var water_motion := FileAccess.open("res://scripts/game/water_sort_ultra_motion.gd", FileAccess.READ).get_as_text()
	var water_ui := FileAccess.open("res://scripts/game/water_sort_casual.gd", FileAccess.READ).get_as_text()
	var block_drag := FileAccess.open("res://scripts/ui/smooth_block_piece_button.gd", FileAccess.READ).get_as_text()
	var block_ui := FileAccess.open("res://scripts/ui/puzzle_casual_polish.gd", FileAccess.READ).get_as_text()
	var home := FileAccess.open("res://scripts/ui/premium_home_casual.gd", FileAccess.READ).get_as_text()
	var settings := FileAccess.open("res://scripts/ui/premium_main_casual.gd", FileAccess.READ).get_as_text()
	var motion := FileAccess.open("res://scripts/ui/motion_director.gd", FileAccess.READ).get_as_text()
	var ux_shell := FileAccess.open("res://scripts/ui/ux_shell_casual.gd", FileAccess.READ).get_as_text()
	var ux_shell_base := FileAccess.open("res://scripts/ui/ux_shell_premium.gd", FileAccess.READ).get_as_text()
	var monetization := FileAccess.open("res://scripts/ui/monetization_hub.gd", FileAccess.READ).get_as_text()
	var main_scene := FileAccess.open("res://scenes/Main.tscn", FileAccess.READ).get_as_text()
	var water_scene := FileAccess.open("res://scenes/WaterSort.tscn", FileAccess.READ).get_as_text()
	var block_scene := FileAccess.open("res://scenes/BlockPuzzle.tscn", FileAccess.READ).get_as_text()
	var rescue_scene := FileAccess.open("res://scenes/Game.tscn", FileAccess.READ).get_as_text()
	var surface := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ).get_as_text()

	if not rescue.contains("viewport_height") or not rescue.contains("max_board_height"):
		return _fail("Rescue height-aware sizing missing")
	if not water_motion.contains("tubes.size() == 6") or not water_motion.contains("board.columns = 3") or not water_motion.contains("_quadratic_bezier_points"):
		return _fail("Water Sort layout or curved pour missing")
	if not block_drag.contains("_shape_centroid_grid") or not block_drag.contains("_candidate_origins"):
		return _fail("Block centroid magnetism missing")
	if not main_scene.contains("premium_surface_manager_static.gd") or not main_scene.contains("premium_home_casual.gd") or not main_scene.contains("premium_main_casual.gd"):
		return _fail("Active main scene is not using the casual-polish surfaces")
	if main_scene.contains("home_ux_patch.gd") or main_scene.contains("secondary_surface_fill.gd") or main_scene.contains("global_finish_polish.gd"):
		return _fail("Legacy dashboard/flash polish layers are still active")
	if surface.contains("content.position =") or surface.contains("tween_property(content, \"position\""):
		return _fail("Active surface manager still moves content root")
	if not motion.contains("reduced_motion"):
		return _fail("Reduced Motion preference is not wired into navigation motion")

	if not home.contains("HomeSecondaryActions") or home.contains("LIVE\nPLAY HUB"):
		return _fail("Home still uses dashboard-like equally weighted secondary actions")
	if not home.contains("SHOP") or not home.contains("open_shop"):
		return _fail("Home does not expose a Shop path")
	if not monetization.contains("func open_shop"):
		return _fail("MonetizationHub does not expose a public Shop opener")
	if ux_shell.contains("shop.visible = false") or ux_shell_base.contains("shop.visible = false"):
		return _fail("UXShell still force-hides the Shop")
	if not settings.contains("REDUCED MOTION") or settings.contains("PLAY HISTORY"):
		return _fail("Settings is not yet a compact preferences surface")
	if not water_ui.contains("GameplayStage") or water_ui.contains("Vector2(0, 1040)") or not water_scene.contains("water_sort_casual.gd"):
		return _fail("Water Sort is not using the gameplay-first stage")
	if not block_ui.contains("CompactProgressStrip") or not block_ui.contains("available_height") or not block_scene.contains("puzzle_casual_polish.gd"):
		return _fail("Block Puzzle is not using the board-first responsive polish")
	if not rescue_ui.contains("GameplayBoardHolder") or rescue_ui.contains("EVERY RESCUE COUNTS") or rescue_ui.contains("Tip: clear blockers") or not rescue_scene.contains("rescue_rush_casual.gd"):
		return _fail("Rescue Rush still contains duplicate gameplay chrome")

	print("UI/UX regression checks passed")
	quit(0)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
