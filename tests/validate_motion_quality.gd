extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_rescue_completion_buffer(): return
	if not _validate_water_lip_geometry(): return
	if not await _validate_block_follow_response(): return
	print("Motion quality validated: rescue completion buffer, bottle-lip pour geometry, responsive continuous block drag.")
	quit(0)

func _validate_rescue_completion_buffer() -> bool:
	var file := FileAccess.open("res://scripts/game/rescue_rush_motion_final.gd", FileAccess.READ)
	if file == null:
		return _fail("Rescue motion final script is missing")
	var source: String = file.get_as_text()
	if not source.contains("_escape_visual_deadline_msec") or not source.contains("render_board()") or not source.contains("await get_tree().process_frame"):
		return _fail("Rescue Rush no longer guarantees the final escape clears before completion")
	return true

func _validate_water_lip_geometry() -> bool:
	var script := load("res://scripts/game/water_sort_ultra_motion.gd") as Script
	if script == null:
		return _fail("Water Sort ultra motion script is missing")
	var water: Node = script.new()
	var bottle := Control.new()
	bottle.size = Vector2(154, 316)
	bottle.rotation = 1.0
	var right_mouth: Vector2 = water.call("_visual_mouth_local", bottle)
	bottle.rotation = -1.0
	var left_mouth: Vector2 = water.call("_visual_mouth_local", bottle)
	bottle.rotation = 0.0
	var center_mouth: Vector2 = water.call("_visual_mouth_local", bottle)
	water.free()
	bottle.free()
	if right_mouth.x <= center_mouth.x or left_mouth.x >= center_mouth.x:
		return _fail("Water Sort stream is not anchored to the downhill bottle rim")
	if center_mouth.y > 45.0:
		return _fail("Water Sort receiver mouth probe is too low in the bottle")
	return true

func _validate_block_follow_response() -> bool:
	var script := load("res://scripts/ui/smooth_block_drag_preview.gd") as Script
	if script == null:
		return _fail("Smooth Block Puzzle drag preview is missing")
	var preview: Control = script.new()
	root.add_child(preview)
	preview.call("configure", [Vector2i(0,0), Vector2i(1,0)], Color.WHITE)
	preview.position = Vector2.ZERO
	preview.call("set_drag_target", Vector2(300, 0), true)
	preview.call("_process", 1.0 / 60.0)
	var followed_x: float = preview.position.x
	preview.queue_free()
	await process_frame
	if followed_x < 210.0:
		return _fail("Block Puzzle drag preview still lags too far behind touch input")
	var button_file := FileAccess.open("res://scripts/ui/smooth_block_piece_button.gd", FileAccess.READ)
	if button_file == null or button_file.get_as_text().contains("desired = _preview_position_for_origin"):
		return _fail("Block Puzzle drag preview is snapping between board centroids during movement")
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
