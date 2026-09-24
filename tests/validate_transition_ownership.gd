extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var surface_manager := _read("res://scripts/ui/premium_surface_manager_static.gd")
	var motion_director := _read("res://scripts/ui/motion_director.gd")
	var main_scene := _read("res://scenes/Main.tscn")
	var home_state := _read("res://scripts/ui/premium_home_overhaul.gd")
	var home_view := _read("res://scripts/ui/premium_home_direct_levels.gd")
	var live_state := _read("res://scripts/ui/premium_live_hub.gd")
	var live_view := _read("res://scripts/ui/premium_live_hub_3d.gd")
	var casual_main := _read("res://scripts/ui/premium_main_casual.gd")

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
	if not home_state.contains("_last_home_signature") or not home_state.contains("if built and signature == _last_home_signature"):
		failures.append("Home must reuse an unchanged persistent launcher instead of rebuilding on every return")
	if not live_state.contains("_last_live_signature") or not live_state.contains("if built and signature == _last_live_signature"):
		failures.append("Games selector must reuse an unchanged persistent surface instead of rebuilding on every entry")
	for source in [home_view, live_view, casual_main]:
		if not source.contains("BaseButton.ACTION_MODE_BUTTON_PRESS"):
			failures.append("Primary navigation must react on touch-down instead of waiting for release")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Transition ownership validated: one motion owner, persistent surfaces reused, navigation fires on touch-down.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
