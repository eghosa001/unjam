extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _rescue_uses_height(): return
	if not _water_uses_balanced_six_tube_layout(): return
	if not _water_uses_curved_stream(): return
	if not _block_uses_centroid_magnetism(): return
	if not _surface_root_is_stationary(): return
	print("UI/UX regression checks passed")
	quit(0)

func _rescue_uses_height() -> bool:
	var source := FileAccess.open("res://scripts/game/rescue_rush_premium.gd", FileAccess.READ).get_as_text()
	if not source.contains("viewport_height") or not source.contains("max_board_height") or not source.contains("float(maxi(height, 1))"):
		return _fail("Rescue board sizing must use viewport height and row count")
	return true

func _water_uses_balanced_six_tube_layout() -> bool:
	var source := FileAccess.open("res://scripts/game/water_sort_reference_motion.gd", FileAccess.READ).get_as_text()
	if not source.contains("tubes.size() == 6") or not source.contains("board.columns = 3"):
		return _fail("Six-tube Water Sort levels must use a balanced 3x2 layout")
	return true

func _water_uses_curved_stream() -> bool:
	var source := FileAccess.open("res://scripts/game/water_sort_reference_motion.gd", FileAccess.READ).get_as_text()
	if not source.contains("_quadratic_bezier_points") or not source.contains("curve_control"):
		return _fail("Water Sort must draw a sampled curved stream")
	return true

func _block_uses_centroid_magnetism() -> bool:
	var source := FileAccess.open("res://scripts/ui/block_piece_button.gd", FileAccess.READ).get_as_text()
	if not source.contains("_shape_centroid_grid") or not source.contains("_candidate_origins"):
		return _fail("Block placement must use the shape centroid plus nearby legal origins")
	return true

func _surface_root_is_stationary() -> bool:
	var source := FileAccess.open("res://scripts/ui/premium_surface_manager.gd", FileAccess.READ).get_as_text()
	if source.contains("content.position =") or source.contains("tween_property(content, \"position\"") or source.contains("content.scale =") or source.contains("tween_property(content, \"scale\""):
		return _fail("PremiumSurfaceManager must not move or scale the content root")
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
