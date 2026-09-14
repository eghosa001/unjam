extends "res://scripts/game/water_sort.gd"

func generate_tubes(seed_value: int, colors: int) -> Array:
	# Build from a solved state using reversible reverse-moves. Replaying those
	# moves in reverse is always legal, so every generated board is solvable by
	# construction while still producing thousands of different mixes.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 104729 + colors * 1543 + campaign_tier() * 8191
	var result: Array = []
	for color in range(colors):
		var tube: Array = []
		for _i in range(CAPACITY): tube.append(color)
		result.append(tube)
	result.append([])
	result.append([])
	var steps := 8 + colors * 3 + campaign_tier() * 3
	if difficulty() == "hard": steps += 5
	elif difficulty() == "milestone": steps += 8
	elif difficulty() == "boss": steps += 12
	var successful := 0
	var guard := 0
	while successful < steps and guard < steps * 40:
		guard += 1
		var donors: Array[int] = []
		for i in range(result.size()):
			if _is_monochrome_nonempty(result[i]): donors.append(i)
		if donors.is_empty(): break
		var donor := donors[rng.randi_range(0, donors.size() - 1)]
		var donor_color := int((result[donor] as Array).back())
		var targets: Array[int] = []
		var preferred: Array[int] = []
		for j in range(result.size()):
			if j == donor: continue
			var target: Array = result[j]
			if target.size() >= CAPACITY: continue
			if not target.is_empty() and int(target.back()) == donor_color: continue
			targets.append(j)
			if not target.is_empty(): preferred.append(j)
		if targets.is_empty(): continue
		var pool := preferred if not preferred.is_empty() else targets
		var target_index := pool[rng.randi_range(0, pool.size() - 1)]
		var source: Array = result[donor]
		var target_tube: Array = result[target_index]
		var max_amount := mini(source.size(), CAPACITY - target_tube.size())
		if max_amount <= 0: continue
		var amount := 1
		if max_amount > 1 and campaign_tier() <= 1 and rng.randf() < 0.25:
			amount = 2
		for _m in range(amount):
			source.pop_back()
			target_tube.append(donor_color)
		result[donor] = source
		result[target_index] = target_tube
		successful += 1
	# Shuffle tube positions only; this preserves the known solution.
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp
	return result

func _is_monochrome_nonempty(tube: Array) -> bool:
	if tube.is_empty(): return false
	var color := int(tube[0])
	for value in tube:
		if int(value) != color: return false
	return true

func render_board() -> void:
	if board == null:
		return
	# queue_free() alone leaves the old buttons parented until the end of the
	# frame. A quick second tap can therefore hit a stale tube. Detach first so
	# get_child()/hit testing always sees only the new board immediately.
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	board.columns = 5 if tubes.size() <= 10 else 6
	board.add_theme_constant_override("h_separation", 14)
	board.add_theme_constant_override("v_separation", 18)
	var tube_width := 170.0 if tubes.size() <= 10 else 138.0
	var tube_height := 330.0 if tubes.size() <= 10 else 288.0
	for i in range(tubes.size()):
		var button := WaterTubeButton.new()
		button.custom_minimum_size = Vector2(tube_width, tube_height)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.configure(tubes[i], i == selected, i)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES  %d    •    PERFECT ≤ %d    •    %d COLORS" % [moves, par_moves, color_count]
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", 20)
		hint_label.custom_minimum_size = Vector2(0, 44)

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
