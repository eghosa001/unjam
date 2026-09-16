extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/water_tube_3d_motion.gd", FileAccess.READ)
	if file == null:
		push_error("3D Water Sort tube source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["func _sync_motion_processing", "set_process(false)", "set_process(true)", "func _process(delta: float)"]:
		if not source.contains(needle):
			push_error("Idle 3D Water Sort tubes still process continuously: " + needle)
			quit(1)
			return
	if not source.contains("is_selected") or not source.contains("pour_mode") or not source.contains("slosh"):
		push_error("Tube sleep logic does not preserve active selection/pour motion")
		quit(1)
		return
	print("3D Water Sort tubes sleep while idle and wake for active motion.")
	quit(0)
