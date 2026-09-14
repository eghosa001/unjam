extends "res://scripts/game/water_sort.gd"

func select_tube(index: int) -> void:
	if completed or animating:
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
	history.append({"tubes": tubes.duplicate(true), "moves": moves})
	animating = true
	status_label.text = "Pouring…"
	await _play_pour_sequence(from_idx, index)
	super.pour(from_idx, index)
	moves += 1
	selected = -1
	status_label.text = "Perfect pour"
	render_board()
	_play_success(index)
	FeedbackManager.tap()
	PremiumVisuals.screen_flash(Color("5da9ff"), 0.018)
	_save_checkpoint()
	animating = false
	if is_complete():
		complete_level()

func _play_pour_sequence(from_idx: int, to_idx: int) -> void:
	if board == null or from_idx < 0 or to_idx < 0 or from_idx >= board.get_child_count() or to_idx >= board.get_child_count():
		return
	if tubes[from_idx].is_empty():
		return
	var source := board.get_child(from_idx) as Control
	var target := board.get_child(to_idx) as Control
	if source == null or target == null:
		return
	var color_index := clampi(int(tubes[from_idx].back()), 0, WaterTubeButton.PALETTE.size() - 1)
	var liquid: Color = WaterTubeButton.PALETTE[color_index]
	var source_center := source.get_global_rect().get_center() - global_position
	var target_center := target.get_global_rect().get_center() - global_position
	var direction_sign := 1.0 if target_center.x >= source_center.x else -1.0
	var source_rotation := source.rotation
	var source_position := source.position

	var prep := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	prep.tween_property(source, "position", source_position + Vector2(direction_sign * 18.0, -20.0), 0.10)
	prep.parallel().tween_property(source, "rotation", deg_to_rad(direction_sign * 23.0), 0.10)
	prep.parallel().tween_property(source, "scale", Vector2(1.06, 1.06), 0.10)
	await prep.finished

	var start := source.get_global_rect().get_center() - global_position + Vector2(direction_sign * source.size.x * 0.22, -source.size.y * 0.29)
	var finish := target.get_global_rect().get_center() - global_position + Vector2(0, -target.size.y * 0.31)
	var arc_height := maxf(84.0, absf(finish.x - start.x) * 0.16)
	var stream := Line2D.new()
	stream.width = 12.0
	stream.default_color = Color(liquid, 0.92)
	stream.begin_cap_mode = Line2D.LINE_CAP_ROUND
	stream.end_cap_mode = Line2D.LINE_CAP_ROUND
	stream.z_index = 420
	stream.add_point(start)
	stream.add_point(start)
	add_child(stream)

	var droplet := Panel.new()
	droplet.size = Vector2(24, 24)
	droplet.pivot_offset = droplet.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = liquid.lightened(0.04)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(liquid, 0.28)
	style.shadow_size = 7
	droplet.add_theme_stylebox_override("panel", style)
	droplet.position = start - droplet.size * 0.5
	droplet.z_index = 430
	add_child(droplet)

	for step in range(1, 11):
		var progress := float(step) / 10.0
		var p := start.lerp(finish, progress)
		p.y -= sin(progress * PI) * arc_height
		var segment := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		segment.tween_property(droplet, "position", p - droplet.size * 0.5, 0.026)
		await segment.finished
		if is_instance_valid(stream) and is_instance_valid(droplet):
			stream.set_point_position(1, droplet.position + droplet.size * 0.5)

	var land := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	land.tween_property(target, "scale", Vector2(1.09, 0.96), 0.07)
	land.tween_property(target, "scale", Vector2.ONE, 0.13)
	land.parallel().tween_property(droplet, "scale", Vector2(1.5, 0.55), 0.07)
	await land.finished
	PremiumVisuals.burst(finish, liquid, 8)
	if is_instance_valid(stream):
		stream.queue_free()
	if is_instance_valid(droplet):
		droplet.queue_free()

	var settle := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(source, "position", source_position, 0.13)
	settle.parallel().tween_property(source, "rotation", source_rotation, 0.13)
	settle.parallel().tween_property(source, "scale", Vector2.ONE, 0.13)
	await settle.finished

func complete_level() -> void:
	if completed:
		return
	completed = true
	animating = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if moves <= par_moves else (2 if moves <= par_moves + maxi(6, color_count) else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 25 + color_count * 2)
	status_label.text = "SORT COMPLETE"
	PremiumVisuals.burst(Vector2(540, 880), Color("5da9ff"), 28)
	PremiumVisuals.screen_flash(Color("5da9ff"), 0.10)
	AnalyticsManager.track("water_sort_completed", {"level": level_number, "moves": moves, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.28).timeout
	var result := PremiumResultOverlay.new()
	result.configure(
		"WATER SORT COMPLETE",
		"Every colour is cleanly separated.",
		"%d MOVES   •   PERFECT ≤ %d\n%d COLOURS SORTED" % [moves, par_moves, color_count],
		stars,
		Color("5da9ff"),
		"BACK HOME" if daily_mode else "NEXT PUZZLE"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
