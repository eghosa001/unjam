extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var surface_manager := _read("res://scripts/ui/premium_surface_manager_static.gd")
	var motion_director := _read("res://scripts/ui/motion_director.gd")
	var main_scene := _read("res://scenes/Main.tscn")

	if not surface_manager.contains("MotionDirector owns navigation transitions"):
		failures.append("3D surface manager must delegate navigation animation to MotionDirector")
	if surface_manager.contains("content.create_tween()"):
		failures.append("3D surface manager still creates a competing content transition tween")
	if not motion_director.contains("_animate_surface_in") or not motion_director.contains("target.create_tween()"):
		failures.append("MotionDirector must remain the single navigation transition owner")
	for needle in ["_animate_key_elements", "cards.resize(6)", "float(i) * 0.012", "MotionSystem.duration(&\"settle\")"]:
		if not motion_director.contains(needle):
			failures.append("MotionDirector lost restrained premium card staging: " + needle)
	if not main_scene.contains("premium_surface_manager_static.gd") or not main_scene.contains("motion_director.gd"):
		failures.append("Main scene transition/skin ownership wiring changed unexpectedly")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Transition ownership validated: one skin owner, one motion owner.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
