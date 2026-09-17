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

func apply_theme_mode(dark: bool) -> void:
	var environment := get_node_or_null("BlockPuzzle3DEnvironment") as Unjam3DGameplayStage
	if environment != null:
		environment.set_dark_mode(dark)

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
	hint_label.text = "Best placement: block %d at row %d, column %d." % [piece_index + 1, origin.y + 1, origin.x + 1]
	await place_selected(origin)

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
	if board_grid == null or board_shell == null or board_grid.get_child_count() == 0:
		return
	var viewport_size := get_viewport_rect().size
	var available_board_width := maxf(320.0, viewport_size.x - 72.0)
	var available_board_height := maxf(320.0, viewport_size.y * 0.54)
	var gap := float(board_grid.get_theme_constant("h_separation"))
	var cell_size := clampf(floor(minf(
		(available_board_width - 22.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE),
		(available_board_height - 22.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE)
	)), 44.0, FINAL_CELL_MAX)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	board_shell.custom_minimum_size = Vector2(
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0,
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0
	)
	if piece_row != null:
		piece_row.custom_minimum_size.y = 150.0

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
		center += cell.get_global_rect().get_center() - global_position
		count += 1
	if count <= 0: return Vector2.INF
	return center / float(count)

func _spawn_tension_frame() -> void:
	if effects_layer == null or board_shell == null:
		return
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = board_shell.global_position - global_position - Vector2(10, 10)
	frame.size = board_shell.size + Vector2(20, 20)
	frame.add_theme_stylebox_override("panel", style_box(Color("ff9f1c0a"), 30, Color("ffb347"), 4, 8))
	frame.modulate.a = 0.0
	effects_layer.add_child(frame)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 0.92, 0.08)
	tween.tween_property(frame, "modulate:a", 0.0, 0.34)
	tween.finished.connect(frame.queue_free)
