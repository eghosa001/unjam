extends "res://scripts/game/water_sort_reference_motion.gd"

const FinalMotionTube = preload("res://scripts/ui/water_tube_reference_motion.gd")

func render_board() -> void:
	super.render_board()
	if board != null and tubes.size() == 6:
		board.columns = 3
		board.add_theme_constant_override("h_separation", 28)
		board.add_theme_constant_override("v_separation", 28)

func _quadratic_bezier_points(start: Vector2, curve_control: Vector2, finish: Vector2, segments: int = 18) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var omt := 1.0 - t
		points.append(omt * omt * start + 2.0 * omt * t * curve_control + t * t * finish)
	return points

func _visual_mouth_local(control: Control) -> Vector2:
	var outer_x := control.size.x * 0.18
	var outer_y := 13.0
	var outer_w := control.size.x * 0.64
	var outer_h := control.size.y - 42.0
	var neck_h := outer_h * 0.10
	var lip_y := outer_y + neck_h * 0.28 + 1.0
	if control.rotation > 0.08:
		return Vector2(outer_x + outer_w * 0.92, lip_y)
	if control.rotation < -0.08:
		return Vector2(outer_x + outer_w * 0.08, lip_y)
	return Vector2(outer_x + outer_w * 0.5, lip_y)

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	var adjusted := local_point
	if local_point.y <= 42.0 and absf(local_point.x - control.size.x * 0.5) <= control.size.x * 0.18:
		adjusted = _visual_mouth_local(control)
	return super._control_point(control, adjusted)

func _play_premium_concurrent_pour(source_values: Array, target_values: Array, from_rect: Rect2, to_rect: Rect2, color_index: int, amount: int, source_index: int, target_index: int, will_complete: bool = false) -> void:
	var liquid: Color = FinalMotionTube.PALETTE[color_index]
	var ghost := FinalMotionTube.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = from_rect.size
	ghost.size = from_rect.size
	ghost.configure(source_values, false, -1)
	ghost.position = _game_local(from_rect.position)
	ghost.pivot_offset = Vector2(ghost.size.x * 0.5, ghost.size.y * 0.11)
	ghost.z_index = 650
	add_child(ghost)

	var receiver := FinalMotionTube.new()
	receiver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	receiver.custom_minimum_size = to_rect.size
	receiver.size = to_rect.size
	receiver.configure(target_values, false, -1)
	receiver.position = _game_local(to_rect.position)
	receiver.pivot_offset = receiver.size * 0.5
	receiver.z_index = 630
	receiver.call("begin_pour_in", color_index, amount)
	add_child(receiver)

	var direction := 1.0 if to_rect.get_center().x >= from_rect.get_center().x else -1.0
	var home_pos := ghost.position
	var lift := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_property(ghost, "position", home_pos + Vector2(direction * 10.0, -34.0), 0.08)
	lift.parallel().tween_property(ghost, "scale", Vector2(1.04, 1.04), 0.08)
	await lift.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	var target_lip := _control_point(receiver, Vector2(receiver.size.x * 0.5, 34.0))
	var desired := target_lip - ghost.pivot_offset + Vector2(direction * 13.0, -34.0)
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(ghost, "position", desired, 0.15)
	await travel.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	var tip := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tip.tween_property(ghost, "rotation", deg_to_rad(70.0 * direction), 0.11)
	await tip.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	ghost.call("begin_pour_out", amount)
	var stream := Line2D.new()
	stream.width = 10.0
	stream.default_color = Color(liquid, 0.96)
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.joint_mode = Line2D.LINE_JOINT_ROUND
	stream.z_index = 670
	add_child(stream)
	var shine := Line2D.new()
	shine.width = 3.0
	shine.default_color = Color(liquid.lightened(0.42), 0.90)
	shine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shine.end_cap_mode = Line2D.LINE_CAP_ROUND
	shine.joint_mode = Line2D.LINE_JOINT_ROUND
	shine.z_index = 671
	add_child(shine)

	var pour_time := 0.28 + float(amount) * 0.075
	var flow := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var update_flow := func(v: float) -> void:
		if not is_instance_valid(ghost) or not is_instance_valid(receiver):
			return
		ghost.call("set_pour_progress", v)
		receiver.call("set_pour_progress", v)
		var source_local := Vector2(ghost.size.x * 0.5, 30.0)
		if ghost.has_method("visual_pour_rim_local"):
			source_local = Vector2(ghost.call("visual_pour_rim_local", direction))
		var receiver_local := Vector2(receiver.size.x * 0.5, 34.0)
		if receiver.has_method("visual_receive_rim_local"):
			receiver_local = Vector2(receiver.call("visual_receive_rim_local"))
		var source_mouth := _control_point(ghost, source_local)
		var receiver_mouth := _control_point(receiver, receiver_local)
		var horizontal := receiver_mouth.x - source_mouth.x
		var curve_control := Vector2(source_mouth.x + horizontal * 0.42, minf(source_mouth.y, receiver_mouth.y) - 38.0)
		stream.points = _quadratic_bezier_points(source_mouth, curve_control, receiver_mouth)
		shine.points = stream.points
	flow.tween_method(update_flow, 0.0, 1.0, pour_time)
	flow.parallel().tween_property(stream, "width", 13.5, pour_time * 0.55)
	flow.parallel().tween_property(receiver, "scale", Vector2(1.025, 0.988), pour_time * 0.45)
	await flow.finished

	if is_instance_valid(stream):
		var fade := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade.tween_property(stream, "modulate:a", 0.0, 0.055)
		fade.parallel().tween_property(shine, "modulate:a", 0.0, 0.055)
		fade.parallel().tween_property(receiver, "scale", Vector2.ONE, 0.07)
		await fade.finished
	if is_instance_valid(stream): stream.queue_free()
	if is_instance_valid(shine): shine.queue_free()
	if is_instance_valid(receiver):
		PremiumVisuals.burst(_control_point(receiver, Vector2(receiver.size.x * 0.5, 34.0)), liquid, 9)

	if not is_instance_valid(ghost):
		return
	var upright := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	upright.tween_property(ghost, "rotation", 0.0, 0.09)
	await upright.finished
	if not is_instance_valid(ghost):
		return
	var returning := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	returning.tween_property(ghost, "position", home_pos, 0.14)
	returning.parallel().tween_property(ghost, "scale", Vector2.ONE, 0.14)
	await returning.finished
	if is_instance_valid(ghost): ghost.queue_free()
	if is_instance_valid(receiver): receiver.queue_free()

	active_source_tubes.erase(source_index)
	active_target_tubes.erase(target_index)
	for idx in [source_index, target_index]:
		if board != null and idx >= 0 and idx < board.get_child_count():
			var live := board.get_child(idx)
			if live != null and is_instance_valid(live):
				live.modulate = Color.WHITE
				live.disabled = false
				live.call("configure", tubes[idx], false, idx)
	if will_complete and pending_completion and not completed:
		pending_completion = false
		complete_level()
