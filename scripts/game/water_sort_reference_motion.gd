extends "res://scripts/game/water_sort_reference.gd"

const MotionTube = preload("res://scripts/ui/water_tube_reference_motion.gd")

func render_board() -> void:
	if board == null: return
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	board.columns = 5 if tubes.size() <= 10 else 6
	board.add_theme_constant_override("h_separation", 18 if tubes.size() <= 10 else 10)
	board.add_theme_constant_override("v_separation", 25)
	var tube_width := 154.0 if tubes.size() <= 10 else 128.0
	var tube_height := 316.0 if tubes.size() <= 10 else 286.0
	for i in range(tubes.size()):
		var button := MotionTube.new()
		button.custom_minimum_size = Vector2(tube_width, tube_height)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.configure(tubes[i], i == selected, i)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES %d   •   PERFECT ≤ %d   •   %d COLORS" % [moves, par_moves, color_count]

func _transfer_amount(from_idx: int, to_idx: int) -> int:
	if not can_pour(from_idx, to_idx): return 0
	var color := int(tubes[from_idx].back())
	var amount := 0
	for i in range(tubes[from_idx].size() - 1, -1, -1):
		if int(tubes[from_idx][i]) == color: amount += 1
		else: break
	return mini(amount, CAPACITY - tubes[to_idx].size())

func _play_pour_sequence(from_idx: int, to_idx: int) -> void:
	if board == null or from_idx < 0 or to_idx < 0 or from_idx >= board.get_child_count() or to_idx >= board.get_child_count(): return
	var amount := _transfer_amount(from_idx, to_idx)
	if amount <= 0: return
	var source := board.get_child(from_idx) as Control
	var target := board.get_child(to_idx) as Control
	if source == null or target == null: return
	var color_index := clampi(int(tubes[from_idx].back()), 0, MotionTube.PALETTE.size() - 1)
	var liquid: Color = MotionTube.PALETTE[color_index]
	var home_pos := source.position
	var home_rot := source.rotation
	var home_scale := source.scale
	var home_pivot := source.pivot_offset
	var source_center := source.get_global_rect().get_center()
	var target_center := target.get_global_rect().get_center()
	var direction := 1.0 if target_center.x >= source_center.x else -1.0
	source.z_index = 500

	var lift := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_property(source, "position", home_pos + Vector2(0, -34), 0.11)
	lift.parallel().tween_property(source, "scale", Vector2(1.035, 1.035), 0.11)
	await lift.finished

	source.pivot_offset = Vector2(source.size.x * 0.5, source.size.y * 0.10)
	var target_mouth_global := target.global_position + Vector2(target.size.x * 0.5, target.size.y * 0.10)
	var desired_global := target_mouth_global - source.pivot_offset + Vector2(direction * 9.0, -42.0)
	var desired_local := desired_global - board.global_position
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(source, "position", desired_local, 0.24)
	await travel.finished

	var pour_angle := deg_to_rad(74.0 * direction)
	var tip := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tip.tween_property(source, "rotation", pour_angle, 0.17)
	await tip.finished

	source.call("begin_pour_out", amount)
	target.call("begin_pour_in", color_index, amount)
	var mouth_local := source.global_position + source.pivot_offset - global_position
	var target_lip_local := target.global_position + Vector2(target.size.x * 0.5, target.size.y * 0.12) - global_position
	var stream := Line2D.new()
	stream.width = 10.0
	stream.default_color = Color(liquid, 0.96)
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.z_index = 490
	stream.points = PackedVector2Array([mouth_local, target_lip_local])
	add_child(stream)
	var shine := Line2D.new()
	shine.width = 3.0
	shine.default_color = Color(liquid.lightened(0.42), 0.85)
	shine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shine.end_cap_mode = Line2D.LINE_CAP_ROUND
	shine.z_index = 491
	shine.points = stream.points
	add_child(shine)

	var pour_time := 0.48 + float(amount) * 0.16
	var flow := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flow.tween_method(func(v: float) -> void: source.call("set_pour_progress", v), 0.0, 1.0, pour_time)
	flow.parallel().tween_method(func(v: float) -> void: target.call("set_pour_progress", v), 0.0, 1.0, pour_time)
	flow.parallel().tween_property(stream, "width", 13.5, pour_time * 0.48)
	flow.parallel().tween_property(target, "scale", Vector2(1.025, 0.99), pour_time * 0.48)
	await flow.finished

	var fade := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.tween_property(stream, "modulate:a", 0.0, 0.08)
	fade.parallel().tween_property(shine, "modulate:a", 0.0, 0.08)
	fade.parallel().tween_property(target, "scale", Vector2.ONE, 0.10)
	await fade.finished
	stream.queue_free()
	shine.queue_free()
	PremiumVisuals.burst(target_lip_local, liquid, 7)

	var upright := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	upright.tween_property(source, "rotation", home_rot, 0.15)
	await upright.finished
	var returning := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	returning.tween_property(source, "position", home_pos, 0.24)
	returning.parallel().tween_property(source, "scale", home_scale, 0.24)
	await returning.finished
	source.pivot_offset = home_pivot
	source.z_index = 0
	var settle := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(source, "scale", Vector2(1.03, 0.98), 0.06)
	settle.tween_property(source, "scale", home_scale, 0.11)
	await settle.finished
