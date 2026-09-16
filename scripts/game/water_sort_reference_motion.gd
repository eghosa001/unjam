extends "res://scripts/game/water_sort_reference.gd"

const MotionTube = preload("res://scripts/ui/water_tube_3d_motion.gd")

var active_source_tubes: Dictionary = {}
var active_target_tubes: Dictionary = {}
var pending_completion := false
var _queued_action := ""

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
			FeedbackManager.invalid()
			_play_invalid(index)
			return
		selected = index
		status_label.text = "Ready to pour"
		FeedbackManager.lift()
		render_board()
		return
	if selected == index:
		selected = -1
		status_label.text = ""
		FeedbackManager.drop()
		render_board()
		return
	if not can_pour(selected, index):
		status_label.text = "That pour is blocked"
		FeedbackManager.invalid()
		_play_invalid(index)
		_play_invalid(selected)
		selected = -1
		render_board()
		_save_checkpoint()
		return

	var from_idx := selected
	var transfer := _build_transfer_plan(tubes, from_idx, index)
	if transfer.is_empty():
		return
	var amount := int(transfer.get("amount", 0))
	if amount <= 0:
		return
	var source_values: Array = transfer.get("source_before", []).duplicate()
	var target_values: Array = transfer.get("target_before", []).duplicate()
	var source_control := board.get_child(from_idx) as Control
	var target_control := board.get_child(index) as Control
	var from_rect := source_control.get_global_rect()
	var to_rect := target_control.get_global_rect()
	var color_index := clampi(int(transfer.get("color", 0)), 0, MotionTube.PALETTE.size() - 1)

	history.append({"tubes": tubes.duplicate(true), "moves": moves})
	_commit_transfer_plan(transfer)
	moves += 1
	selected = -1
	status_label.text = "Pouring — keep going"
	active_source_tubes[from_idx] = true
	active_target_tubes[index] = true
	if is_complete():
		pending_completion = true
	render_board()
	_play_premium_concurrent_pour(source_values, target_values, from_rect, to_rect, color_index, amount, from_idx, index)
	_save_checkpoint()

func _has_active_pours() -> bool:
	return not active_source_tubes.is_empty() or not active_target_tubes.is_empty()

func _complete_if_visuals_settled() -> void:
	# A logical win can be reached while an older independent pour is still in
	# flight. Only expose the result once every source/target animation has fully
	# settled so no glass, stream or return tween survives behind the overlay.
	if not pending_completion or completed or _has_active_pours():
		return
	pending_completion = false
	FeedbackManager.complete("water")
	complete_level()

func _refresh_idle_status_after_pours() -> void:
	if status_label == null or completed or pending_completion or _has_active_pours() or not _queued_action.is_empty():
		return
	status_label.text = "Ready to pour"

func undo_move() -> void:
	if _has_active_pours():
		_queued_action = "undo"
		if status_label != null:
			status_label.text = "Undo queued — finishing active pours"
		return
	super.undo_move()

func show_hint() -> void:
	if _has_active_pours():
		if status_label != null:
			status_label.text = "Finish active pours to use a hint"
		return
	super.show_hint()

func restart_level() -> void:
	if _has_active_pours():
		_queued_action = "restart"
		if status_label != null:
			status_label.text = "Retry queued — finishing active pours"
		return
	super.restart_level()

func _quit() -> void:
	if _has_active_pours():
		_queued_action = "quit"
		if status_label != null:
			status_label.text = "Back queued — finishing active pours"
		return
	super._quit()

func _run_queued_action_if_ready() -> bool:
	if _queued_action.is_empty() or _has_active_pours():
		return false
	var action := _queued_action
	_queued_action = ""
	# A queued navigation/state command takes precedence over a completion that
	# was detected while its final visual pour was still in flight.
	pending_completion = false
	match action:
		"undo": super.undo_move()
		"restart": super.restart_level()
		"quit": super._quit()
	return true

func _build_transfer_plan(state: Array, from_idx: int, to_idx: int) -> Dictionary:
	# Pure rules/state stage. Nothing in the live game is mutated here.
	if from_idx < 0 or to_idx < 0 or from_idx >= state.size() or to_idx >= state.size() or from_idx == to_idx:
		return {}
	if not (state[from_idx] is Array) or not (state[to_idx] is Array):
		return {}
	var source: Array = (state[from_idx] as Array).duplicate()
	var target: Array = (state[to_idx] as Array).duplicate()
	if source.is_empty() or target.size() >= CAPACITY:
		return {}
	var color := int(source.back())
	if not target.is_empty() and int(target.back()) != color:
		return {}
	var contiguous := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) == color:
			contiguous += 1
		else:
			break
	var amount := mini(contiguous, CAPACITY - target.size())
	if amount <= 0:
		return {}
	var source_after := source.duplicate()
	var target_after := target.duplicate()
	for _step in range(amount):
		source_after.pop_back()
		target_after.append(color)
	return {
		"from": from_idx,
		"to": to_idx,
		"color": color,
		"amount": amount,
		"source_before": source,
		"target_before": target,
		"source_after": source_after,
		"target_after": target_after
	}

func _commit_transfer_plan(plan: Dictionary) -> void:
	var from_idx := int(plan.get("from", -1))
	var to_idx := int(plan.get("to", -1))
	if from_idx < 0 or to_idx < 0 or from_idx >= tubes.size() or to_idx >= tubes.size():
		return
	var source_after: Array = plan.get("source_after", [])
	var target_after: Array = plan.get("target_after", [])
	tubes[from_idx] = source_after.duplicate()
	tubes[to_idx] = target_after.duplicate()

func _transfer_amount(from_idx: int, to_idx: int) -> int:
	var plan := _build_transfer_plan(tubes, from_idx, to_idx)
	return int(plan.get("amount", 0))

func _game_local(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point

func _control_point(control: Control, local_point: Vector2) -> Vector2:
	return _game_local(control.get_global_transform_with_canvas() * local_point)

func _play_premium_concurrent_pour(source_values: Array, target_values: Array, from_rect: Rect2, to_rect: Rect2, color_index: int, amount: int, source_index: int, target_index: int) -> void:
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
	var lift_distance := 12.0 if MotionSystem.reduced() else 34.0
	var lift_time := MotionSystem.duration(&"press")
	var lift := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(ghost, "position", home_pos + Vector2(direction * 10.0, -lift_distance), lift_time)
	if not MotionSystem.reduced():
		lift.parallel().tween_property(ghost, "scale", Vector2(1.04, 1.04), lift_time)
	FeedbackManager.lift()
	await lift.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	var target_lip := _control_point(receiver, Vector2(receiver.size.x * 0.5, 34.0))
	var desired := target_lip - ghost.pivot_offset + Vector2(direction * 13.0, -lift_distance)
	var travel_time := MotionSystem.duration(&"travel")
	var travel := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	travel.tween_property(ghost, "position", desired, travel_time)
	await travel.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	var tilt_degrees := 34.0 if MotionSystem.reduced() else 70.0
	var tip_time := MotionSystem.duration(&"settle") * 0.78
	var tip := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tip.tween_property(ghost, "rotation", deg_to_rad(tilt_degrees * direction), tip_time)
	await tip.finished
	if not is_instance_valid(ghost) or not is_instance_valid(receiver):
		return

	ghost.call("begin_pour_out", amount)
	FeedbackManager.pour_start()
	var stream := Line2D.new()
	stream.width = 10.0
	stream.default_color = Color(liquid, 0.96)
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.z_index = 670
	add_child(stream)
	var shine := Line2D.new()
	shine.width = 3.0
	shine.default_color = Color(liquid.lightened(0.42), 0.90)
	shine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shine.end_cap_mode = Line2D.LINE_CAP_ROUND
	shine.z_index = 671
	add_child(shine)

	var pour_time := MotionSystem.duration(&"pour") + float(amount) * MotionSystem.duration(&"micro") * 0.75
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
		var exit_point := _control_point(ghost, source_local + Vector2(direction * 34.0, 20.0))
		var receiver_mouth := _control_point(receiver, receiver_local)
		# The short outward segment makes the liquid visibly leave the downhill
		# glass lip before falling toward the receiver.
		stream.points = PackedVector2Array([source_mouth, exit_point, receiver_mouth])
		shine.points = stream.points
	flow.tween_method(update_flow, 0.0, 1.0, pour_time)
	flow.parallel().tween_property(stream, "width", 13.5, pour_time * 0.55)
	if not MotionSystem.reduced():
		flow.parallel().tween_property(receiver, "scale", Vector2(1.025, 0.988), pour_time * 0.45)
	await flow.finished
	FeedbackManager.pour_land()

	if is_instance_valid(stream) and is_instance_valid(shine):
		var fade_time := MotionSystem.duration(&"micro")
		var fade := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fade.tween_property(stream, "modulate:a", 0.0, fade_time)
		fade.parallel().tween_property(shine, "modulate:a", 0.0, fade_time)
		fade.parallel().tween_property(receiver, "scale", Vector2.ONE, fade_time)
		await fade.finished
	if is_instance_valid(stream):
		stream.queue_free()
	if is_instance_valid(shine):
		shine.queue_free()
	if is_instance_valid(receiver):
		PremiumVisuals.burst(_control_point(receiver, Vector2(receiver.size.x * 0.5, 34.0)), liquid, 9)

	if not is_instance_valid(ghost):
		return
	var upright_time := MotionSystem.duration(&"settle") * 0.64
	var upright := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	upright.tween_property(ghost, "rotation", 0.0, upright_time)
	await upright.finished
	if not is_instance_valid(ghost):
		return
	var return_time := MotionSystem.duration(&"travel") * 0.72
	var returning := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	returning.tween_property(ghost, "position", home_pos, return_time)
	returning.parallel().tween_property(ghost, "scale", Vector2.ONE, return_time)
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

	if _run_queued_action_if_ready():
		return
	_complete_if_visuals_settled()
	_refresh_idle_status_after_pours()
