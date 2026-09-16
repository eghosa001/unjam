extends SceneTree

func _initialize() -> void:
	for path in ["res://scripts/ui/premium_home_casual.gd", "res://scripts/ui/premium_live_hub_3d.gd"]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Persistent surface source is missing: " + path)
			quit(1)
			return
		var source := file.get_as_text()
		if not source.contains("remove_child(child)"):
			push_error("Persistent surface rebuild can overlap old and new children: " + path)
			quit(1)
			return
	print("Persistent surface rebuilds detach old children immediately.")
	quit(0)
