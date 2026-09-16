extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/premium_surface_manager_static.gd", FileAccess.READ)
	if file == null:
		push_error("Premium surface manager source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	if not source.contains("unjam_surface_base_font_size"):
		push_error("Repeated secondary-surface refreshes can cumulatively enlarge labels")
		quit(1)
		return
	if not source.contains("label.set_meta(\"unjam_surface_base_font_size\""):
		push_error("Surface label base font size is not captured before polishing")
		quit(1)
		return
	if not source.contains("label.get_meta(\"unjam_surface_base_font_size\""):
		push_error("Surface polish does not reuse the original label font size")
		quit(1)
		return
	print("Secondary surface font polishing is idempotent across refreshes.")
	quit(0)
