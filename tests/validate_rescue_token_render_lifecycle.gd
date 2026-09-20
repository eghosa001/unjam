extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/rescue_token.gd", FileAccess.READ)
	if file == null:
		push_error("Rescue token source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in [
		"add_to_group(\"reduced_motion_aware\")",
		"visibility_changed.connect",
		"func apply_motion_preference",
		"SubViewport.UPDATE_DISABLED",
		"SubViewport.UPDATE_ONCE",
		"DECORATIVE_RENDER_FPS := 30.0",
		"DECORATIVE_RENDER_INTERVAL",
		"set_process(false)",
		"set_process(true)"
	]:
		if not source.contains(needle):
			push_error("Rescue token render lifecycle is incomplete: " + needle)
			quit(1)
			return
	if source.contains("SubViewport.UPDATE_ALWAYS"):
		push_error("Rescue token still renders its 3D viewport continuously")
		quit(1)
		return
	print("Rescue token pauses hidden/reduced-motion rendering and caps live decorative 3D updates at 30 FPS.")
	quit(0)
