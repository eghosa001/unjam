extends "res://scripts/game/block_puzzle_3d.gd"

# Final competitive polish layer for the active Block Puzzle scene.
# Keep effects local to the board so the game feels stronger without adding
# full-screen flashes or permanent particle cost on Android.
const TENSION_THRESHOLD := 0.72
const TENSION_RELEASE_THRESHOLD := 0.60
const CLEAR_STREAK_WINDOW := 3.0
const FINAL_CELL_MAX := 108.0

var _clear_streak := 0
var _clear_streak_generation := 0
var _tension_active := false

func _ready() -> void:
	super._ready()
	_fit_3d_board_layout()
	_style_premium_surface(false)

func apply_theme_mode(dark: bool) -> void:
	var environment := get_node_or_null("BlockPuzzle3DEnvironment") as Unjam3DGameplayStage
	if environment != null:
		environment.set_dark_mode(dark)
	_style_premium_surface(dark)

func _style_premium_surface(dark: bool) -> void:
	var score_card := find_child("BlockScoreCard", true, false) as PanelContainer
	if score_card != null:
		score_card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("54207f") if dark else Color("8f35dd"), 30, Color("f2c6ff"), 3, 16))
	var objective := find_child("BlockObjectiveCard", true, false) as PanelContainer
	if objective != null:
		objective.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("25163a") if dark else Color(0.985, 0.955, 1.0, 0.98), 24, Color("dca8ff"), 2, 9))
	if board_shell != null:
		board_shell.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("32194f") if dark else Color("5a2d86"), 32, Color("f4c6ff"), 4, 22))
	var tray := find_child("BlockTray", true, false) as PanelContainer
	if tray != null:
		tray.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("211631") if dark else Color(0.99, 0.955, 1.0, 0.99), 32, Color("efbaff"), 3, 16))
	var tray_title := find_child("BlockTrayTitle", true, false) as Label
	if tray_title != null:
		Unjam3DTheme.label_3d(tray_title, Color("f5eaff") if dark else Unjam3DTheme.PURPLE_DARK, Color("12091e") if dark else Color.WHITE, 2)
	var boosters := find_child("CampaignBoosters", true, false) as HBoxContainer
	if boosters != null:
		for child in boosters.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 58.0)
				Unjam3DTheme.gloss_button(button, Unjam3DTheme.PURPLE_DARK, false, 22, dark)

func block_progression_band(level: int = level_number) -> String:
	if level <= 1: return "starter"
	if level <= 5: return "standard"
	if level <= 10: return "challenge"
	if level <= 30: return "medium"
	if level <= 130: return "hard"
	return "expert"

func difficulty() -> String:
	if daily_mode:
		return super.difficulty()
	var band := block_progression_band()
	if band == "starter": return "easy"
	if band in ["standard", "medium"]: return "medium"
	return "hard"

func level_config() -> Dictionary:
	if daily_mode or level_number > 10:
		return super.level_config()
	# The first ten levels now teach by escalating line planning and shape pressure
	# instead of repeating one-line clears with tiny score targets.
	var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
	var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
	var pars := [18, 18, 20, 20, 21, 22, 22, 23, 24, 24]
	var i := clampi(level_number - 1, 0, 9)
	return {"target_score": scores[i], "target_lines": lines[i], "par": pars[i]}

func refill_pieces() -> void:
	if daily_mode or level_number > 10:
		super.refill_pieces()
		return
	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	var band := block_progression_band()
	var max_shape := 8 if band == "starter" else (12 if band == "standard" else SHAPES.size() - 1)
	var forced_complex_min := 1 if band == "starter" else (7 if band == "standard" else 8)
	for i in range(3):
		var shape_index := rng.randi_range(0, max_shape)
		if i == 0:
			shape_index = rng.randi_range(forced_complex_min, max_shape)
		elif band == "challenge" and i == 1:
			shape_index = rng.randi_range(5, max_shape)
		pieces.append(SHAPES[shape_index].duplicate())
		piece_colors.append(COLOR_PALETTE[rng.randi_range(0, COLOR_PALETTE.size() - 1)])
	selected_piece = -1
	if not any_move_available():
		pieces[0] = SHAPES[0].duplicate()

func show_hint() -> void:
	if completed or _clear_transition_active:
		return
	var best := _best_hint_placement()
	if best.is_empty():
		hint_label.text = "No safe placement found — Undo or refresh the tray."
		FeedbackManager.blocked()
		return
	var piece_index := int(best.get("piece", -1))
	var origin: Vector2i = best.get("origin", Vector2i(-1, -1))
	if piece_index < 0 or origin.x < 0:
		return
	selected_piece = piece_index
	SaveManager.record_hint()
	FeedbackManager.tap()
	var guidance := "Best placement: block %d at row %d, column %d." % [piece_index + 1, origin.y + 1, origin.x + 1]
	hint_label.text = guidance
	await place_selected(origin)
	# Placement re-renders the board. Restore the paid Hint guidance afterward
	# so the player sees what was executed instead of an empty feedback row.
	if hint_label != null and is_instance_valid(hint_label) and not completed:
		hint_label.text = guidance
		_fit_3d_board_layout()

func _best_hint_placement() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for piece_index in range(pieces.size()):
		var shape: Array = pieces[piece_index]
		if shape.is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				var origin := Vector2i(x, y)
				if not can_place(shape, origin):
					continue
				var result := _simulate_block_placement(shape, origin)
				var sim: Array = result.get("grid", [])
				var cleared := int(result.get("lines", 0))
				var future := _future_fit_score(sim, piece_index)
				var pockets := _empty_pocket_penalty(sim)
				var occupied := _occupied_count(sim)
				var score := float(cleared * 100000 + future * 80 + shape.size() * 18 - pockets * 420 - occupied * 3)
				if score > best_score:
					best_score = score
					best = {"piece": piece_index, "origin": origin, "score": score, "lines": cleared}
	return best

func _simulate_block_placement(shape: Array, origin: Vector2i) -> Dictionary:
	var sim: Array = cells.duplicate(true)
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			sim[origin.y + point.y][origin.x + point.x] = true
	var rows: Array[int] = []
	var cols: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if not bool(sim[y][x]):
				full = false
				break
		if full: rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if not bool(sim[y][x]):
				full = false
				break
		if full: cols.append(x)
	for y in rows:
		for x in range(GRID_SIZE): sim[y][x] = false
	for x in cols:
		for y in range(GRID_SIZE): sim[y][x] = false
	return {"grid": sim, "lines": rows.size() + cols.size()}

func _future_fit_score(state: Array, used_piece: int) -> int:
	var total := 0
	for piece_index in range(pieces.size()):
		if piece_index == used_piece:
			continue
		var shape: Array = pieces[piece_index]
		if shape.is_empty():
			continue
		var fits := 0
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if _can_place_on(state, shape, Vector2i(x, y)):
					fits += 1
					if fits >= 24:
						break
			if fits >= 24: break
		total += fits
	return total

func _can_place_on(state: Array, shape: Array, origin: Vector2i) -> bool:
	for raw in shape:
		var point := _as_point(raw)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if point.x < 0 or point.y < 0 or x < 0 or y < 0 or x >= GRID_SIZE or y >= GRID_SIZE:
			return false
		if bool(state[y][x]):
			return false
	return true

func _empty_pocket_penalty(state: Array) -> int:
	var penalty := 0
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if bool(state[y][x]):
				continue
			var blocked := 0
			for dir: Vector2i in dirs:
				var p: Vector2i = Vector2i(x, y) + dir
				if p.x < 0 or p.y < 0 or p.x >= GRID_SIZE or p.y >= GRID_SIZE or bool(state[p.y][p.x]):
					blocked += 1
			if blocked >= 3:
				penalty += 1
	return penalty

func _occupied_count(state: Array) -> int:
	var count := 0
	for row in state:
		for value in row:
			if bool(value): count += 1
	return count

func _fit_3d_board_layout() -> void:
	if find_child("FigmaBlock390x844", true, false) != null:
		_fit_figma_board_layout()
		return
	if board_grid == null or board_shell == null or board_grid.get_child_count() == 0:
		return
	var viewport_size := get_viewport_rect().size
	var compact_width := viewport_size.x < 700.0
	var compact_height := viewport_size.y < 1100.0
	var compact := compact_width or compact_height

	var outer := get_node_or_null("BlockOuter") as MarginContainer
	if outer != null:
		var side := 16 if compact_width else 28
		outer.add_theme_constant_override("margin_left", side)
		outer.add_theme_constant_override("margin_right", side)
		outer.add_theme_constant_override("margin_top", 10 if compact_height else 18)
		outer.add_theme_constant_override("margin_bottom", 10 if compact_height else 22)
	var root_box := get_node_or_null("BlockOuter/BlockRoot") as VBoxContainer
	if root_box != null:
		root_box.add_theme_constant_override("separation", 6 if compact else 8)

	var header := find_child("BlockHeader", true, false) as HBoxContainer
	if header != null:
		header.custom_minimum_size.y = 72.0 if compact else 82.0
		header.add_theme_constant_override("separation", 6 if compact_width else 12)
	for spec in [["BackAction", 74.0, 68.0, 32], ["RetryAction", 74.0, 68.0, 32], ["HintAction", 120.0, 68.0, 22]]:
		var button := find_child(String(spec[0]), true, false) as Button
		if button == null:
			continue
		if compact:
			button.custom_minimum_size = Vector2(float(spec[1]), float(spec[2]))
			button.add_theme_font_size_override("font_size", int(spec[3]))
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 27 if compact_width else (29 if viewport_size.x < 900.0 else 33))

	var score_card := find_child("BlockScoreCard", true, false) as PanelContainer
	if score_card != null:
		score_card.custom_minimum_size.y = 80.0 if compact_height else 92.0
	if score_label != null:
		score_label.add_theme_font_size_override("font_size", 31 if compact else 39)
	if goal_label != null:
		goal_label.add_theme_font_size_override("font_size", 21 if compact_width else (22 if viewport_size.x < 900.0 else 24))

	var objective_card := find_child("BlockObjectiveCard", true, false) as PanelContainer
	if objective_card != null:
		objective_card.custom_minimum_size.y = 42.0 if compact_height else 52.0
	var objective_label := find_child("BlockObjectiveLabel", true, false) as Label
	if objective_label != null:
		objective_label.add_theme_font_size_override("font_size", 21 if compact_width else 24)

	var tray := find_child("BlockTray", true, false) as PanelContainer
	if tray != null:
		tray.custom_minimum_size.y = 150.0 if viewport_size.y < 1050.0 else (174.0 if viewport_size.y < 1400.0 else 218.0)
	var tray_title := find_child("BlockTrayTitle", true, false) as Label
	if tray_title != null:
		tray_title.add_theme_font_size_override("font_size", 21 if compact_width else 23)
	if piece_row != null:
		piece_row.add_theme_constant_override("separation", 8 if compact_width else 18)
		piece_row.custom_minimum_size.y = 112.0 if viewport_size.y < 1050.0 else (136.0 if viewport_size.y < 1400.0 else 180.0)

	var boosters := find_child("CampaignBoosters", true, false) as HBoxContainer
	if boosters != null:
		boosters.custom_minimum_size.y = 68.0 if compact_height else 74.0
		boosters.add_theme_constant_override("separation", 4 if compact_width else 8)
		for child in boosters.get_children():
			if child is Button:
				(child as Button).add_theme_font_size_override("font_size", 20 if compact_width else 22)
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 21 if compact_width else 23)
		# Empty feedback rows consume no layout space at any stretch scale.
		# They grow back to a readable row only when actionable text exists.
		status_label.custom_minimum_size.y = 0.0 if status_label.text.strip_edges().is_empty() else (30.0 if compact_height else 34.0)
	if hint_label != null:
		hint_label.add_theme_font_size_override("font_size", 20 if compact_width else 21)
		hint_label.custom_minimum_size.y = 0.0 if hint_label.text.strip_edges().is_empty() else (28.0 if compact_height else 30.0)

	var side_margin := 16.0 if compact_width else 28.0
	var width_budget := maxf(260.0, viewport_size.x - side_margin * 2.0 - 18.0)
	# Reserve more vertical space for the tray/boosters on short phones instead of
	# enforcing a desktop-sized minimum board that spills below the viewport.
	var height_ratio := 0.40 if viewport_size.y < 1100.0 else (0.44 if viewport_size.y < 1500.0 else 0.50)
	var height_budget := maxf(260.0, viewport_size.y * height_ratio)
	var gap := float(board_grid.get_theme_constant("h_separation"))
	var cell_size := clampf(floor(minf(
		(width_budget - 18.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE),
		(height_budget - 18.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE)
	)), 30.0, FINAL_CELL_MAX)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	board_shell.custom_minimum_size = Vector2(
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0,
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0
	)
	# Recompute tray controls after the row geometry changes; this keeps all three
	# pieces inside the tray instead of retaining a stale desktop width.
	render_pieces()

func load_level() -> void:
	_clear_streak = 0
	_clear_streak_generation += 1
	_tension_active = false
	super.load_level()
	_refresh_tension_feedback()

func render() -> void:
	super.render()
	_refresh_tension_feedback()

func _play_place_feedback(indices: Array[int], color: Color, points: int) -> void:
	super._play_place_feedback(indices, color, points)
	var impact_center := _cell_group_center(indices)
	if impact_center != Vector2.INF:
		PremiumVisuals.burst(impact_center, color.lightened(0.08), mini(10, 4 + indices.size()))
	if score_label != null:
		MotionSystem.local_punch(score_label, 0.72)

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	_clear_streak += 1
	_clear_streak_generation += 1
	var generation := _clear_streak_generation
	super._spawn_clear_feedback(indices, line_count)
	var clear_center := _cell_group_center(indices)
	if clear_center != Vector2.INF:
		PremiumVisuals.burst(clear_center, Color("ff7a66"), mini(28, 10 + line_count * 5))
	if _clear_streak >= 2:
		_spawn_score_popup("CLEAR STREAK ×%d" % _clear_streak, Color("ffd166"), 0.14, true)
		if line_count < 2:
			FeedbackManager.combo(_clear_streak)
	get_tree().create_timer(CLEAR_STREAK_WINDOW).timeout.connect(_expire_clear_streak.bind(generation))

func _expire_clear_streak(generation: int) -> void:
	if generation == _clear_streak_generation:
		_clear_streak = 0

func _refresh_tension_feedback() -> void:
	if completed or cells.is_empty():
		return
	var occupancy := _board_occupancy()
	if occupancy >= TENSION_THRESHOLD:
		if not _tension_active:
			_tension_active = true
			if board_shell != null:
				MotionSystem.local_punch(board_shell, 1.32)
			_spawn_tension_frame()
			_spawn_score_popup("TIGHT BOARD", Color("ffb347"), 0.0, true)
	elif occupancy <= TENSION_RELEASE_THRESHOLD:
		_tension_active = false

func _board_occupancy() -> float:
	var occupied := 0
	for row in cells:
		if not (row is Array):
			continue
		for value in row:
			if bool(value): occupied += 1
	return float(occupied) / float(GRID_SIZE * GRID_SIZE)

func _cell_group_center(indices: Array[int]) -> Vector2:
	var center := Vector2.ZERO
	var count := 0
	for idx in indices:
		if idx < 0 or idx >= cell_buttons.size(): continue
		var cell := cell_buttons[idx] as Control
		if cell == null or not is_instance_valid(cell): continue
		center += cell.get_global_rect().get_center()
		count += 1
	if count <= 0: return Vector2.INF
	return center / float(count)

func _spawn_tension_frame() -> void:
	if effects_layer == null or board_shell == null:
		return
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_rect := _effects_rect(board_shell, 10.0)
	frame.position = frame_rect.position
	frame.size = frame_rect.size
	frame.add_theme_stylebox_override("panel", style_box(Color("ff9f1c0a"), 30, Color("ffb347"), 4, 8))
	frame.modulate.a = 0.0
	effects_layer.add_child(frame)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 0.92, 0.08)
	tween.tween_property(frame, "modulate:a", 0.0, 0.34)
	tween.finished.connect(frame.queue_free)
