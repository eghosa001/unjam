extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		return _fail("Water Sort scene failed to load")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if not game.has_method("_liquid_arc_points"):
		game.queue_free()
		return _fail("Active Water Sort motion layer does not expose curved pour geometry")

	var source := Vector2(100.0, 100.0)
	var receiver := Vector2(260.0, 280.0)
	var points: PackedVector2Array = game.call("_liquid_arc_points", source, receiver, 1.0)
	if points.size() < 12:
		game.queue_free()
		return _fail("Water stream is under-sampled and will render as a kinked polyline")
	if points[0].distance_to(source) > 0.01:
		game.queue_free()
		return _fail("Water stream does not start exactly at the source rim")
	var expected_entry := receiver + Vector2(0.0, 8.0)
	if points[points.size() - 1].distance_to(expected_entry) > 0.01:
		game.queue_free()
		return _fail("Water stream does not finish just inside the receiver mouth")
	var apex_y := INF
	for point in points:
		apex_y = minf(apex_y, point.y)
	if apex_y >= source.y - 3.0:
		game.queue_free()
		return _fail("Water stream has no visible ballistic arc above the source rim")

	var mirrored: PackedVector2Array = game.call("_liquid_arc_points", Vector2(260.0, 100.0), Vector2(100.0, 280.0), -1.0)
	if mirrored.size() != points.size():
		game.queue_free()
		return _fail("Left/right Water Sort pour arcs do not use the same quality")
	if mirrored[0].x <= mirrored[mirrored.size() - 1].x:
		game.queue_free()
		return _fail("Leftward Water Sort pour arc has the wrong direction")

	var motion_text := _read("res://scripts/game/water_sort_reference_motion.gd")
	for token in ["_source_rim_local", "_receiver_rim_local", "_position_for_tilted_rim", "_liquid_arc_points", "_release_pour_visual_lock"]:
		if not motion_text.contains(token):
			game.queue_free()
			return _fail("Water Sort motion contract missing %s" % token)
	if motion_text.contains("PackedVector2Array([source_mouth, exit_point, receiver_mouth])"):
		game.queue_free()
		return _fail("Legacy three-point kinked Water Sort stream is still active")

	game.queue_free()
	await process_frame
	print("WATER_POUR_ARC_OK: source-rim launch, curved ballistic path, receiver-mouth entry and lock recovery are wired.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
