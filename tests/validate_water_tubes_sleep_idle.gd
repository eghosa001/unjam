extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/water_tube_3d_motion.gd", FileAccess.READ)
	if file == null:
		push_error("3D Water Sort tube source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["func _sync_motion_processing", "set_process(needs_motion)", "set_process(true)", "func _process(delta: float)"]:
		if not source.contains(needle):
			push_error("Idle 3D Water Sort tubes do not use the expected active-motion lifecycle: " + needle)
			quit(1)
			return
	for state_needle in ["is_selected", "invalid_flash", "success_flash", "pour_mode", "slosh"]:
		if not source.contains(state_needle):
			push_error("Tube sleep logic does not preserve active motion state: " + state_needle)
			quit(1)
			return
	print("3D Water Sort tubes sleep while idle and wake for active motion.")
	quit(0)
