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

	var tube_script = load("res://scripts/ui/water_tube_3d_motion.gd")
	var ghost = tube_script.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = Vector2(154.0, 316.0)
	ghost.custom_minimum_size = ghost.size
	ghost.pivot_offset = Vector2(ghost.size.x * 0.5, ghost.size.y * 0.11)
	ghost.scale = Vector2(1.04, 1.04)
	ghost.configure([0, 1, 2, 3], false, -1)
	game.add_child(ghost)
	await process_frame
	var projected_receive: Vector2 = ghost.call("visual_receive_rim_local")
	var projected_left: Vector2 = ghost.call("visual_pour_rim_local", -1.0)
	var projected_right: Vector2 = ghost.call("visual_pour_rim_local", 1.0)
	if not (projected_left.x < projected_receive.x and projected_receive.x < projected_right.x):
		ghost.queue_free()
		game.queue_free()
		return _fail("3D Water Sort rim projection does not expose distinct left/center/right mouth anchors")
	for projected in [projected_left, projected_receive, projected_right]:
		if projected.x < 0.0 or projected.x > ghost.size.x or projected.y < 0.0 or projected.y > ghost.size.y:
			ghost.queue_free()
			game.queue_free()
			return _fail("Projected 3D Water Sort rim anchor falls outside the rendered tube control")
	var direction := 1.0
	var final_rotation := deg_to_rad(70.0)
	var local_rim: Vector2 = game.call("_source_rim_local", ghost, direction)
	var desired_rim := Vector2(420.0, 260.0)
	ghost.position = game.call("_position_for_tilted_rim", ghost, local_rim, desired_rim, final_rotation)
	ghost.rotation = final_rotation
	var actual_rim: Vector2 = game.call("_control_point", ghost, local_rim)
	if actual_rim.distance_to(desired_rim) > 0.75:
		ghost.queue_free()
		game.queue_free()
		return _fail("Tilted Water Sort source rim does not land on the calculated arc launch point")
	ghost.queue_free()

	# Same-column pours on the outer columns must always place the tilted source
	# toward the screen centre, never outside the phone viewport.
	var phone_width := 540.0
	var source_size := Vector2(120.0, 220.0)
	var left_column := Rect2(Vector2(18.0, 430.0), source_size)
	var left_target := Rect2(Vector2(18.0, 160.0), source_size)
	var right_column := Rect2(Vector2(402.0, 430.0), source_size)
	var right_target := Rect2(Vector2(402.0, 160.0), source_size)
	var left_direction := float(game.call("_pour_direction", left_column, left_target, source_size.x, phone_width))
	var right_direction := float(game.call("_pour_direction", right_column, right_target, source_size.x, phone_width))
	if left_direction != -1.0:
		game.queue_free()
		return _fail("Left-edge same-column Water pour does not place the source inward")
	if right_direction != 1.0:
		game.queue_free()
		return _fail("Right-edge same-column Water pour does not place the source inward")
	var clamped_left: Vector2 = game.call("_clamp_pour_source_position", Vector2(-90.0, 120.0), source_size, phone_width)
	var clamped_right: Vector2 = game.call("_clamp_pour_source_position", Vector2(520.0, 120.0), source_size, phone_width)
	if clamped_left.x < 10.0 or clamped_right.x + source_size.x > phone_width - 9.0:
		game.queue_free()
		return _fail("Water pour source clamp allows a tilted bottle outside the phone viewport")

	var motion_text := _read("res://scripts/game/water_sort_reference_motion.gd")
	for token in ["_source_rim_local", "_receiver_rim_local", "_position_for_tilted_rim", "_liquid_arc_points", "_pour_direction", "_clamp_pour_source_position", "_release_pour_visual_lock"]:
		if not motion_text.contains(token):
			game.queue_free()
			return _fail("Water Sort motion contract missing %s" % token)
	if motion_text.contains("PackedVector2Array([source_mouth, exit_point, receiver_mouth])"):
		game.queue_free()
		return _fail("Legacy three-point kinked Water Sort stream is still active")

	game.queue_free()
	await process_frame
	print("WATER_POUR_ARC_OK: source-rim launch, curved ballistic path, receiver-mouth entry, same-column edge safety and lock recovery are wired.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
