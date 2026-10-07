extends SceneTree

func _initialize() -> void:
	var source := _read("res://scripts/ui/rescue_token.gd")
	if source.is_empty():
		return _fail("Rescue token source is missing")
	for needle in [
		"extends Control",
		"add_to_group(\"reduced_motion_aware\")",
		"visibility_changed.connect",
		"func apply_motion_preference",
		"DECORATIVE_RENDER_FPS := 20.0",
		"DECORATIVE_RENDER_INTERVAL",
		"set_process(is_visible_in_tree() and not reduced)",
		"func celebrate()",
	]:
		if not source.contains(needle):
			return _fail("Rescue 2D mascot lifecycle is incomplete: " + needle)
	for forbidden in ["SubViewport", "Node3D", "MeshInstance3D", "Camera3D"]:
		if source.contains(forbidden):
			return _fail("Rescue mascot still owns retired 3D rendering: " + forbidden)
	print("RESCUE_2D_MASCOT_LIFECYCLE_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
