extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/premium_backdrop.gd", FileAccess.READ)
	if file == null:
		push_error("Premium backdrop source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["visibility_changed.connect", "_sync_process_state", "is_visible_in_tree()"]:
		if not source.contains(needle):
			push_error("Hidden backdrop lifecycle gate is missing: " + needle)
			quit(1)
			return
	if source.contains("set_process(not reduced)"):
		push_error("Backdrop can keep processing while hidden")
		quit(1)
		return
	print("Premium backdrop rendering is visibility-gated.")
	quit(0)
