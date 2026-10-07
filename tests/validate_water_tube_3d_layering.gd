extends SceneTree

func _initialize() -> void:
	var source := _read("res://scripts/ui/water_tube_3d_motion.gd")
	var base := _read("res://scripts/ui/water_tube_reference_motion.gd")
	var motion := _read("res://scripts/game/water_sort_reference_motion.gd")
	if source.is_empty() or base.is_empty() or motion.is_empty():
		return _fail("Water Sort 2D bottle sources are missing")
	for needle in [
		"extends \"res://scripts/ui/water_tube_reference_motion.gd\"",
		"func begin_pour_out",
		"func begin_pour_in",
		"func set_pour_progress",
		"func _draw()",
	]:
		if not source.contains(needle):
			return _fail("Water bottle 2D compatibility API is incomplete: " + needle)
	for forbidden in ["SubViewport", "Camera3D", "Node3D", "MeshInstance3D", "StandardMaterial3D"]:
		if source.contains(forbidden):
			return _fail("Water bottle still allocates retired 3D rendering: " + forbidden)
	if not base.contains("_draw_glass_shape") or not base.contains("_slot_fill"):
		return _fail("Water bottle lost 2D glass/liquid rendering")
	if not motion.contains("button.modulate = Color(1, 1, 1, 0.0)"):
		return _fail("Animated pour ghosts lost single visual ownership")
	print("WATER_2D_BOTTLE_LAYERING_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
