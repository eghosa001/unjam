extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/unjam_3d_mascot.gd", FileAccess.READ)
	if file == null:
		push_error("3D mascot source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["_sync_render_activity", "is_visible_in_tree()", "SubViewport.UPDATE_DISABLED", "visibility_changed.connect"]:
		if not source.contains(needle):
			push_error("3D mascot does not pause off-screen rendering: " + needle)
			quit(1)
			return
	print("3D mascot rendering is visibility-gated.")
	quit(0)
