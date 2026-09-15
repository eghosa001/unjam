extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue := FileAccess.open("res://scripts/ui/rescue_layout_polish.gd", FileAccess.READ).get_as_text()
	var rescue_ui := FileAccess.open("res://scripts/game/rescue_rush_premium.gd", FileAccess.READ).get_as_text()
	var water := FileAccess.open("res://scripts/game/water_sort_ultra_motion.gd", FileAccess.READ).get_as_text()
	var water_ui := FileAccess.open("res://scripts/game/water_sort_reference.gd", FileAccess.READ).get_as_text()
	var block_drag := FileAccess.open("res://scripts/ui/smooth_block_piece_button.gd", FileAccess.READ).get_as_text()
	var block_ui := FileAccess.open("res://scripts/game/block_puzzle_premium_layout.gd", FileAccess.READ).get_as_text()
	var home := FileAccess.open("res://scripts/ui/premium_home_overhaul.gd", FileAccess.READ).get_as_text()
	var settings := FileAccess.open("res://scripts/ui/premium_main.gd", FileAccess.READ).get_as_text()
	var main_scene := FileAccess.open("res://scenes/Main.tscn", FileAccess.READ).get_as_text()
	var surface := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ).get_as_text()

	if not rescue.contains("viewport_height") or not rescue.contains("max_board_height"):
		return _fail("Rescue height-aware sizing missing")
	if not water.contains("tubes.size() == 6") or not water.contains("board.columns = 3") or not water.contains("_quadratic_bezier_points"):
		return _fail("Water Sort layout or curved pour missing")
	if not block_drag.contains("_shape_centroid_grid") or not block_drag.contains("_candidate_origins"):
		return _fail("Block centroid magnetism missing")
	if not main_scene.contains("premium_surface_manager_static.gd"):
		return _fail("Stationary surface manager is not active")
	if surface.contains("content.position =") or surface.contains("tween_property(content, \"position\""):
		return _fail("Active surface manager still moves content root")

	if not home.contains("HomeSecondaryActions") or home.contains("LIVE\nPLAY HUB"):
		return _fail("Home still uses dashboard-like equally weighted secondary actions")
	if not settings.contains("REDUCED MOTION") or settings.contains("PLAY HISTORY"):
		return _fail("Settings is not yet a compact preferences surface")
	if not water_ui.contains("GameplayStage") or water_ui.contains("Vector2(0, 1040)"):
		return _fail("Water Sort still uses oversized fixed chrome/stage geometry")
	if block_ui.contains("_add_run_progress_deck(root)") or not block_ui.contains("CompactProgressStrip"):
		return _fail("Block Puzzle still uses the large run-progress deck")
	if rescue_ui.contains("EVERY RESCUE COUNTS") or rescue_ui.contains("Tip: clear blockers") or not rescue_ui.contains("GameplayBoardHolder"):
		return _fail("Rescue Rush still contains duplicate gameplay chrome")

	print("UI/UX regression checks passed")
	quit(0)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
