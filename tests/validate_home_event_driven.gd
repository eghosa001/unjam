extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/premium_home_overhaul.gd", FileAccess.READ)
	if file == null:
		push_error("Home controller source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	if source.contains("func _process("):
		push_error("Home still polls surface state every frame")
		quit(1)
		return
	if not source.contains("surface_changed.connect") or not source.contains("func _on_surface_changed"):
		push_error("Home is not driven by surface_changed events")
		quit(1)
		return
	print("Home surface ownership is event-driven.")
	quit(0)
