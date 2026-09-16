extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _validate_shared_motion_system(): return
	if not _validate_rescue_completion_buffer(): return
	if not _validate_water_lip_geometry(): return
	if not _validate_water_stream_layering(): return
	if not await _validate_block_follow_response(): return
	if not _validate_single_block_drag_owner(): return
	if not _validate_gameplay_controls_keep_layout_size(): return
	if not _validate_screen_geometry_static(): return
	print("Motion quality validated: shared motion preferences, rescue completion buffer, visible bottle-rim pour, responsive continuous block drag, single drag owner, gameplay controls preserve layout size, screen roots never move/scale on interaction.")
	quit(0)

func _validate_shared_motion_system() -> bool:
	var script := load("res://scripts/ui/motion_system.gd") as Script
	if script == null:
		return _fail("Shared motion system is missing")
	var motion: Node = script.new()
	root.add_child(motion)
	var normal_travel := float(motion.call("duration_for_flags", &"travel", false, false))
	var fast_travel := float(motion.call("duration_for_flags", &"travel", false, true))
	var reduced_travel := float(motion.call("duration_for_flags", &"travel", true, false))
	motion.queue_free()
	await process_frame
	if normal_travel <= 0.0:
		return _fail("Normal motion duration must stay positive")
	if fast_travel >= normal_travel:
		return _fail("Fast animation does not reduce travel duration")
	if reduced_travel > fast_travel:
		return _fail("Reduced motion should be no slower than fast animation")
	var save_file := FileAccess.open("res://scripts/core/save_manager.gd", FileAccess.READ)
	if save_file == null:
		return _fail("Save manager is missing")
	var save_source := save_file.get_as_text()
	if not save_source.contains("\"reduce_motion\": false") or not save_source.contains("\"fast_animation\": false"):
		return _fail("Motion accessibility preferences are not persisted in save defaults")
	return true

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

func _validate_water_stream_layering() -> bool:
	var file := FileAccess.open("res://scripts/game/water_sort_reference_motion.gd", FileAccess.READ)
	if file == null:
		return _fail("Water Sort reference motion script is missing")
	var source := file.get_as_text()
	if not source.contains("visual_pour_rim_local") or not source.contains("exit_point"):
		return _fail("Water Sort pour no longer visibly exits from the bottle rim")
	if not source.contains("stream.z_index = 670"):
		return _fail("Water Sort stream can render behind the translucent bottle and look centre-originated")
	return true

func _validate_gameplay_controls_keep_layout_size() -> bool:
	var file := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ)
	if file == null:
		return _fail("UI touch enhancer is missing")
	var source := file.get_as_text()
	if not source.contains("_is_block_cell_button(button)") or not source.contains("_is_water_tube_widget(button)"):
		return _fail("Global touch sizing can inflate Block Puzzle cells or Water Sort bottles")
	return true

func _validate_screen_geometry_static() -> bool:
	var director := FileAccess.open("res://scripts/ui/motion_director.gd", FileAccess.READ)
	if director == null:
		return _fail("Motion director is missing")
	var director_source := director.get_as_text()
	if director_source.contains("target.position =") or director_source.contains("target.scale =") or director_source.contains("tween_property(target, \"position\"") or director_source.contains("tween_property(target, \"scale\""):
		return _fail("Motion director can still move/scale whole screens")
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

func _validate_single_block_drag_owner() -> bool:
	var enhancer := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ)
	if enhancer == null:
		return _fail("UI touch enhancer is missing")
	var source: String = enhancer.get_as_text()
	if source.contains("func _input(") or source.contains("func _begin_drag(") or source.contains("func _finish_drag("):
		return _fail("A legacy global Block Puzzle drag handler is competing with the piece control")
	if not source.contains("set_process_input(false)"):
		return _fail("Global touch enhancer can still intercept Block Puzzle drag input")
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
