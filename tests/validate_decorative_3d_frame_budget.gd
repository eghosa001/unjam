extends SceneTree

func _initialize() -> void:
	var mascot := _read("res://scripts/ui/unjam_3d_mascot.gd")
	var preview := _read("res://scripts/ui/unjam_3d_game_art.gd")
	var stage := _read("res://scripts/ui/unjam_3d_gameplay_stage.gd")
	var rescue := _read("res://scripts/ui/rescue_token.gd")
	var home_art := _read("res://scripts/ui/unjam_2d_game_art.gd")
	if mascot.is_empty() or preview.is_empty() or stage.is_empty() or rescue.is_empty() or home_art.is_empty():
		return _fail("Visual renderer source is missing")
	if not mascot.contains("DECORATIVE_RENDER_FPS := 30.0"):
		return _fail("Remaining decorative mascot 3D is not frame-capped")
	if mascot.contains("SubViewport.UPDATE_ALWAYS"):
		return _fail("Decorative mascot 3D still owns an always-rendering viewport")
	if preview.contains("SubViewport.UPDATE_ALWAYS") and not preview.contains("_finish_initial_render"):
		return _fail("Game-card 3D preview can render continuously")
	if not preview.contains("viewport_3d.render_target_update_mode = SubViewport.UPDATE_ONCE"):
		return _fail("Game-card preview does not settle to one-shot rendering")
	if stage.contains("SubViewport.UPDATE_ALWAYS"):
		return _fail("Scenic 3D stage renders continuously")
	if not rescue.contains("DECORATIVE_RENDER_FPS := 20.0") or rescue.contains("SubViewport"):
		return _fail("Rescue mascot is not using the lightweight 2D frame budget")
	if not home_art.contains("ACTIVE_FPS := 20.0"):
		return _fail("Home illustrated art lost its capped redraw budget")
	print("VISUAL_FRAME_BUDGET_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
