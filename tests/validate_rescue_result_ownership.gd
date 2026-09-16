extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var scene_text := _read("res://scenes/Game.tscn")
	if scene_text.contains("rescue_result_guard.gd") or scene_text.contains("ResultGuard"):
		failures.append("Rescue Rush still mounts the obsolete result-hiding guard")
	if FileAccess.file_exists("res://scripts/ui/rescue_result_guard.gd"):
		failures.append("Obsolete Rescue Rush result guard still exists")
	if failures.is_empty():
		print("Rescue result ownership validated: completion animation owns the handoff to results.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
