extends "res://scripts/game/water_sort_reference.gd"

const MotionTube = preload("res://scripts/ui/water_tube_reference_motion.gd")

var active_source_tubes: Dictionary = {}
var active_target_tubes: Dictionary = {}
var pending_completion := false

func render_board() -> void:
	if board == null:
		return
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
		if active_source_tubes.has(i) or active_target_tubes.has(i):
			button.modulate = Color(1, 1, 1, 0.08)
			button.disabled = true
		board.add_child(button)
	move_label.text = "MOVES %d   •   PERFECT ≤ %d   •   %d COLORS" % [moves, par_moves, color_count]

func select_tube(index: int) -> void:
	if completed or pending_completion:
		return
	if active_source_tubes.has(index) or active_target_tubes.has(index):
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
	var target_values: Array = tubes[index].duplicate()
	var source_control := board.get_child(from_idx) as Control
	var target_control := board.get_child(index) as Control
	var from_rect := source_control.get_global_rect()
	var to_rect := target_control.get_global_rect()
	var color_index := clampi(int(tubes[from_idx].back()), 0, MotionTube.PALETTE.size() - 1)

	history.append({"tubes": tubes.duplicate(true), "moves": moves})
	super.pour(from_idx, index)
	moves += 1
	selected = -1
	status_label.text = "Pouring — keep going"
	active_source_tubes[from_idx] = true
	active_target_tubes[index] = true
	var will_complete := is_complete()
	if will_complete:
		pending_completion = true
	render_board()
	_play_premium_concurrent_pour(source_values, target_values, from_rect, to_rect, color_index, amount, from_idx, index, will_complete)
	FeedbackManager.tap()
	_save_checkpoint()

func _transfer_amount(from_idx: int, to_idx: int) -> int:
	if not can_pour(from_idx, to_idx):
		return 0
	var color := int(tubes[from_idx].back())
	var amount := 0
	for i in range(tubes[from_idx].size() - 1, -1, -1):
		if int(tubes[from_idx][i]) == color:
			amount += 1
		else:
			break
	return mini(amount, CAPACITY - tubes[to_idx].size())

func _game_local(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	return _game_local(control.get_global_transform_with_canvas() * local_point)

func _play_premium_concurrent_pour(source_values: Array, target_values: Array, from_rect: Rect2, to_rect: Rect2, color_index: int, amount: int, source_index: int, target_index: int, will_complete: bool = false) -> void:
	var liquid: Color = MotionTube.PALETTE[color_index]
	var ghost := MotionTube.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = from_rect.size
	ghost.size = from_rect.size
	ghost.configure(source_values, false, -1)
	ghost.position = _game_local(from_rect.position)
	ghost.pivot_offset = Vector2(ghost.size.x * 0.5, ghost.size.y * 0.11)
	ghost.z_index = 650
	add_child(ghost)

	var receiver := MotionTube.new()
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
	stream.z_index = 640
	add_child(stream)
	var shine := Line2D.new()
	shine.width = 3.0
	shine.default_color = Color(liquid.lightened(0.42), 0.90)
	shine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shine.end_cap_mode = Line2D.LINE_CAP_ROUND
	shine.z_index = 641
	add_child(shine)

	var pour_time := 0.28 + float(amount) * 0.075
	var flow := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var update_flow := func(v: float) -> void:
		if not is_instance_valid(ghost) or not is_instance_valid(receiver):
			return
		ghost.call("set_pour_progress", v)
		receiver.call("set_pour_progress", v)
		var source_mouth := _control_point(ghost, Vector2(ghost.size.x * 0.5, 30.0))
		var receiver_mouth := _control_point(receiver, Vector2(receiver.size.x * 0.5, 34.0))
		stream.points = PackedVector2Array([source_mouth, receiver_mouth])
		shine.points = stream.points
	flow.tween_method(update_flow, 0.0, 1.0, pour_time)
	flow.parallel().tween_property(stream, "width", 13.5, pour_time * 0.55)
	flow.parallel().tween_property(receiver, "scale", Vector2(1.025, 0.988), pour_time * 0.45)
	await flow.finished

	if is_instance_valid(stream) and is_instance_valid(shine):
		var fade := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fade.tween_property(stream, "modulate:a", 0.0, 0.055)
		fade.parallel().tween_property(shine, "modulate:a", 0.0, 0.055)
		fade.parallel().tween_property(receiver, "scale", Vector2.ONE, 0.07)
		await fade.finished
	if is_instance_valid(stream):
		stream.queue_free()
	if is_instance_valid(shine):
		shine.queue_free()
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
	if is_instance_valid(ghost):
		ghost.queue_free()
	if is_instance_valid(receiver):
		receiver.queue_free()

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
