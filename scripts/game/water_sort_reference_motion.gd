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

func select_tube(index: int) -> void:
	if completed:
		return
	hint_label.text = ""
	if selected < 0:
		if tubes[index].is_empty():
			status_label.text = "Choose a tube that contains colour"
			_play_invalid(index)
			return
		selected = index
		status_label.text = "Ready to pour"
		render_board()
		return
	if selected == index:
		selected = -1
		status_label.text = ""
		render_board()
		return
	if not can_pour(selected, index):
		status_label.text = "That pour is blocked"
		_play_invalid(index)
		_play_invalid(selected)
		selected = -1
		render_board()
		_save_checkpoint()
		return

	var from_idx := selected
	var amount := _transfer_amount(from_idx, index)
	if amount <= 0:
		return
	var source_values: Array = tubes[from_idx].duplicate()
	var source_control := board.get_child(from_idx) as Control
	var target_control := board.get_child(index) as Control
	var from_rect := source_control.get_global_rect()
	var to_rect := target_control.get_global_rect()
	var color_index := clampi(int(tubes[from_idx].back()), 0, MotionTube.PALETTE.size() - 1)

	# Commit the logical move immediately. This keeps input responsive while the
	# premium physical pour continues independently above the live board.
	history.append({"tubes": tubes.duplicate(true), "moves": moves})
	super.pour(from_idx, index)
	moves += 1
	selected = -1
	status_label.text = "Pouring — keep going"
	render_board()
	_play_premium_concurrent_pour(source_values, from_rect, to_rect, color_index, amount, index)
	FeedbackManager.tap()
	_save_checkpoint()
	if is_complete():
		complete_level()

func _transfer_amount(from_idx: int, to_idx: int) -> int:
	if not can_pour(from_idx, to_idx): return 0
	var color := int(tubes[from_idx].back())
	var amount := 0
	for i in range(tubes[from_idx].size() - 1, -1, -1):
		if int(tubes[from_idx][i]) == color: amount += 1
		else: break
	return mini(amount, CAPACITY - tubes[to_idx].size())

func _play_premium_concurrent_pour(source_values: Array, from_rect: Rect2, to_rect: Rect2, color_index: int, amount: int, target_index: int) -> void:
	var liquid: Color = MotionTube.PALETTE[color_index]
	var ghost := MotionTube.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = from_rect.size
	ghost.size = from_rect.size
	ghost.configure(source_values, false, -1)
	ghost.position = from_rect.position - global_position
	ghost.pivot_offset = Vector2(ghost.size.x * 0.5, ghost.size.y * 0.10)
	ghost.z_index = 650
	add_child(ghost)

	var direction := 1.0 if to_rect.get_center().x >= from_rect.get_center().x else -1.0
	var home_pos := ghost.position
	var lift := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_property(ghost, "position", home_pos + Vector2(direction * 12.0, -38.0), 0.10)
	lift.parallel().tween_property(ghost, "scale", Vector2(1.045, 1.045), 0.10)
	await lift.finished
	if not is_instance_valid(ghost): return

	var target_mouth := to_rect.position - global_position + Vector2(to_rect.size.x * 0.5, to_rect.size.y * 0.10)
	var desired := target_mouth - ghost.pivot_offset + Vector2(direction * 10.0, -44.0)
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(ghost, "position", desired, 0.20)
	await travel.finished
	if not is_instance_valid(ghost): return

	var tip := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tip.tween_property(ghost, "rotation", deg_to_rad(72.0 * direction), 0.14)
	await tip.finished
	if not is_instance_valid(ghost): return

	ghost.call("begin_pour_out", amount)
	var mouth := ghost.global_position + ghost.pivot_offset - global_position
	var lip := to_rect.position - global_position + Vector2(to_rect.size.x * 0.5, to_rect.size.y * 0.12)
	var stream := Line2D.new()
	stream.width = 11.0
	stream.default_color = Color(liquid, 0.96)
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.z_index = 640
	stream.points = PackedVector2Array([mouth, lip])
	add_child(stream)
	var shine := Line2D.new()
	shine.width = 3.0
	shine.default_color = Color(liquid.lightened(0.42), 0.88)
	shine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shine.end_cap_mode = Line2D.LINE_CAP_ROUND
	shine.z_index = 641
	shine.points = stream.points
	add_child(shine)

	var target_now: Control = null
	if board != null and target_index >= 0 and target_index < board.get_child_count():
		target_now = board.get_child(target_index) as Control
		if target_now != null:
			target_now.z_index = 40

	var pour_time := 0.34 + float(amount) * 0.10
	var flow := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flow.tween_method(func(v: float) -> void:
		if is_instance_valid(ghost): ghost.call("set_pour_progress", v), 0.0, 1.0, pour_time)
	flow.parallel().tween_property(stream, "width", 14.0, pour_time * 0.5)
	if target_now != null:
		flow.parallel().tween_property(target_now, "scale", Vector2(1.035, 0.985), pour_time * 0.45)
	await flow.finished

	if is_instance_valid(stream) and is_instance_valid(shine):
		var fade := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade.tween_property(stream, "modulate:a", 0.0, 0.07)
		fade.parallel().tween_property(shine, "modulate:a", 0.0, 0.07)
		if target_now != null and is_instance_valid(target_now):
			fade.parallel().tween_property(target_now, "scale", Vector2.ONE, 0.09)
		await fade.finished
	if is_instance_valid(stream): stream.queue_free()
	if is_instance_valid(shine): shine.queue_free()
	PremiumVisuals.burst(lip, liquid, 9)

	if not is_instance_valid(ghost): return
	var upright := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	upright.tween_property(ghost, "rotation", 0.0, 0.13)
	await upright.finished
	if not is_instance_valid(ghost): return
	var return_target := from_rect.position - global_position
	var returning := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	returning.tween_property(ghost, "position", return_target, 0.18)
	returning.parallel().tween_property(ghost, "scale", Vector2.ONE, 0.18)
	returning.parallel().tween_property(ghost, "modulate:a", 0.0, 0.18)
	await returning.finished
	if is_instance_valid(ghost): ghost.queue_free()
