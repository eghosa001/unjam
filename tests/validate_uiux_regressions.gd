extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue := FileAccess.open("res://scripts/ui/rescue_layout_polish.gd", FileAccess.READ).get_as_text()
	var water := FileAccess.open("res://scripts/game/water_sort_ultra_motion.gd", FileAccess.READ).get_as_text()
	var block := FileAccess.open("res://scripts/ui/smooth_block_piece_button.gd", FileAccess.READ).get_as_text()
	var main_scene := FileAccess.open("res://scenes/Main.tscn", FileAccess.READ).get_as_text()
	var surface := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ).get_as_text()
	if not rescue.contains("viewport_height") or not rescue.contains("max_board_height"):
		return _fail("Rescue height-aware sizing missing")
	if not water.contains("tubes.size() == 6") or not water.contains("board.columns = 3") or not water.contains("_quadratic_bezier_points"):
		return _fail("Water Sort layout or curved pour missing")
	if not block.contains("_shape_centroid_grid") or not block.contains("_candidate_origins"):
		return _fail("Block centroid magnetism missing")
	if not main_scene.contains("premium_surface_manager_static.gd"):
		return _fail("Stationary surface manager is not active")
	if surface.contains("content.position =") or surface.contains("tween_property(content, \"position\""):
		return _fail("Active surface manager still moves content root")
	print("UI/UX regression checks passed")
	quit(0)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
