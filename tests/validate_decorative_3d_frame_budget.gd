extends SceneTree

func _initialize() -> void:
	var mascot := _read("res://scripts/ui/unjam_3d_mascot.gd")
	var rescue := _read("res://scripts/ui/rescue_token.gd")
	var preview := _read("res://scripts/ui/unjam_3d_game_art.gd")
	var stage := _read("res://scripts/ui/unjam_3d_gameplay_stage.gd")
	if mascot.is_empty() or rescue.is_empty() or preview.is_empty() or stage.is_empty():
		return _fail("Decorative 3D source is missing")
	for source in [mascot, rescue]:
		if not source.contains("DECORATIVE_RENDER_FPS := 30.0"):
			return _fail("Animated decorative 3D is not capped at 30 FPS")
		if source.contains("SubViewport.UPDATE_ALWAYS"):
			return _fail("Animated decorative 3D still owns an always-rendering viewport")
		if not source.contains("SubViewport.UPDATE_ONCE") or not source.contains("SubViewport.UPDATE_DISABLED"):
			return _fail("Decorative 3D lifecycle is missing one-shot/disabled rendering")
	if preview.contains("SubViewport.UPDATE_ALWAYS") and not preview.contains("_finish_initial_render"):
		return _fail("Game-card 3D preview can render continuously without an initial-render shutdown")
	if not preview.contains("viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE"):
		return _fail("Game-card 3D preview does not settle to one-shot rendering")
	if stage.contains("SubViewport.UPDATE_ALWAYS"):
		return _fail("Gameplay scenic 3D stage renders continuously")
	print("DECORATIVE_3D_FRAME_BUDGET_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
