extends "res://scripts/game/block_puzzle.gd"

const PIECE_COLORS := [
	Color("8b7cf6"), Color("5da9ff"), Color("2dd4b6"),
	Color("ffb454"), Color("ff6b8a"), Color("67e8cf")
]

const ADVANCED_SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0),Vector2i(1,0)],
	[Vector2i(0,0),Vector2i(0,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)],
	[Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,2),Vector2i(1,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2),Vector2i(2,2)],
	[Vector2i(2,0),Vector2i(1,1),Vector2i(2,1),Vector2i(0,2),Vector2i(1,2)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)],
	[Vector2i(0,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]
]

var active_touch_piece: BlockPieceButton

func register_touch_drag(piece: BlockPieceButton) -> void:
	active_touch_piece = piece

func clear_touch_drag(piece: BlockPieceButton) -> void:
	if active_touch_piece == piece:
		active_touch_piece = null

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if active_touch_piece == null or not is_instance_valid(active_touch_piece):
			active_touch_piece = _piece_at_screen_position(event.position)
		if active_touch_piece != null and is_instance_valid(active_touch_piece):
			active_touch_piece.touch_drag_started = true
			active_touch_piece._begin_drag_feedback()
			active_touch_piece._show_touch_preview(event.position)
			active_touch_piece._update_touch_preview_position(event.position)
			active_touch_piece._update_touch_footprint(event.position)
		return
	if active_touch_piece == null or not is_instance_valid(active_touch_piece):
		return
	if event is InputEventScreenDrag:
		active_touch_piece._show_touch_preview(event.position)
		active_touch_piece._update_touch_preview_position(event.position)
		active_touch_piece._update_touch_footprint(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		var piece := active_touch_piece
		active_touch_piece = null
		piece.touch_drag_started = false
		piece._finish_touch_drag(event.position)
		get_viewport().set_input_as_handled()

func _piece_at_screen_position(screen_position: Vector2) -> BlockPieceButton:
	if piece_row == null:
		return null
	for child in piece_row.get_children():
		if child is BlockPieceButton:
			var piece := child as BlockPieceButton
			if not piece.used and piece.visible and piece.get_global_rect().has_point(screen_position):
				return piece
	return null

func campaign_tier() -> int:
	if level_number <= 100: return 0
	if level_number <= 500: return 1
	if level_number <= 1500: return 2
	if level_number <= 3000: return 3
	if level_number <= 5000: return 4
	if level_number <= 7500: return 5
	return 6

func level_config() -> Dictionary:
	if not daily_mode and level_number <= 2:
		return {"target_score": 20 + level_number * 15, "target_lines": 0, "par": 6}
	if not daily_mode and level_number <= 5:
		return {"target_score": 55 + level_number * 8, "target_lines": 1, "par": 11}
	if not daily_mode and level_number <= 10:
		return {"target_score": 105 + level_number * 4, "target_lines": 1, "par": 15}
	var world: int = int(MultiGameManager.world_for_level(level_number))
	# Goal pacing follows the canonical campaign rhythm. Presentation/gameplay
	# subclasses may override difficulty() for local pressure without collapsing
	# score/line/par variety across the 10,000-level campaign.
	var d := MultiGameManager.difficulty_for_level(level_number)
	var tier := campaign_tier()
	var base := 70 + mini(170, world * 4) + tier * 18
	var lines := 2 + int(world / 10) + int(tier / 2)
	var par := 18 + int(world / 18) + tier
	match d:
		"easy": base = int(base * 0.82); lines = maxi(1, lines - 2); par += 5
		"hard": base = int(base * 1.25); lines += 2
		"milestone": base = int(base * 1.48); lines += 3
		"boss": base = int(base * 1.78); lines += 5
	return {"target_score": base, "target_lines": mini(18, lines), "par": par}

func load_level() -> void:
	var checkpoint_before := MultiGameManager.checkpoint(GAME_ID)
	super.load_level()
	if checkpoint_before.is_empty():
		_apply_start_pattern()
		if not any_move_available():
			for y in range(GRID_SIZE):
				for x in range(GRID_SIZE):
					if bool(cells[y][x]) and rng.randf() < 0.35:
						cells[y][x] = false
						cell_colors[y][x] = Color.TRANSPARENT
			if not any_move_available():
				pieces[0] = [Vector2i(0,0)]
				piece_colors[0] = PIECE_COLORS[0]
		render()
		_save_checkpoint()

func _apply_start_pattern() -> void:
	var tier := campaign_tier()
	if tier <= 0 and level_number <= 40: return
	var d := difficulty()
	var count := 3 if tier == 0 else 4 + tier * 2
	if d == "easy": count = maxi(2, count - 3)
	elif d == "hard": count += 2
	elif d == "milestone": count += 4
	elif d == "boss": count += 6
	count = clampi(count, 2, 20)
	var pattern := posmod(level_number * 7 + tier * 11, 6)
	var candidates: Array[Vector2i] = []
	match pattern:
		0:
			for x in range(GRID_SIZE):
				if x not in [3,4]: candidates.append(Vector2i(x, 3))
		1:
			for y in range(GRID_SIZE):
				if y not in [3,4]: candidates.append(Vector2i(4, y))
		2:
			for i in range(GRID_SIZE):
				if i not in [2,5]: candidates.append(Vector2i(i, i))
		3:
			for i in range(GRID_SIZE):
				if i not in [2,5]: candidates.append(Vector2i(GRID_SIZE - 1 - i, i))
		4:
			for x in range(1, GRID_SIZE - 1): candidates.append(Vector2i(x, 1)); candidates.append(Vector2i(x, GRID_SIZE - 2))
		_:
			for y in range(1, GRID_SIZE - 1): candidates.append(Vector2i(1, y)); candidates.append(Vector2i(GRID_SIZE - 2, y))
	while candidates.size() < count:
		var p := Vector2i(rng.randi_range(0, GRID_SIZE - 1), rng.randi_range(0, GRID_SIZE - 1))
		if p not in candidates: candidates.append(p)
	for i in range(mini(count, candidates.size())):
		var p: Vector2i = candidates[i]
		cells[p.y][p.x] = true
		cell_colors[p.y][p.x] = PIECE_COLORS[posmod(i + tier, PIECE_COLORS.size())]

func refill_pieces() -> void:
	pieces.clear(); piece_colors.clear(); piece_batch += 1
	var tier := campaign_tier(); var d := difficulty(); var max_index := 9
	if not daily_mode and level_number <= 5: max_index = 4
	elif not daily_mode and level_number <= 10: max_index = 7
	elif tier >= 1: max_index = 17
	if tier >= 2: max_index = 23
	if tier >= 4: max_index = ADVANCED_SHAPES.size() - 1
	if d == "easy": max_index = mini(max_index, 11)
	elif d == "medium": max_index = mini(max_index, 19)
	for i in range(3):
		var lower := 6 if tier >= 3 and d in ["hard", "milestone", "boss"] and i > 0 else 0
		var shape_index := rng.randi_range(lower, max_index)
		pieces.append((ADVANCED_SHAPES[shape_index] as Array).duplicate())
		piece_colors.append(PIECE_COLORS[posmod(piece_batch * 3 + i + tier, PIECE_COLORS.size())])
	selected_piece = -1
	if not any_move_available():
		pieces[0] = (ADVANCED_SHAPES[rng.randi_range(0, 2)] as Array).duplicate()
		piece_colors[0] = PIECE_COLORS[posmod(piece_batch * 3 + tier, PIECE_COLORS.size())]
		if not any_move_available(): pieces[0] = [Vector2i(0,0)]

func _checkpoint_point(raw: Variant) -> Vector2i:
	if raw is Vector2i: return raw
	if raw is Vector2: return Vector2i(raw)
	if raw is Dictionary: return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2: return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		var cleaned := String(raw).replace("Vector2i", "").replace("Vector2", "").replace("(", "").replace(")", "").strip_edges()
		var parts := cleaned.split(",")
		if parts.size() >= 2:
			var xs := parts[0].strip_edges(); var ys := parts[1].strip_edges()
			if xs.is_valid_int() and ys.is_valid_int(): return Vector2i(int(xs), int(ys))
	return Vector2i(-1, -1)

func _normalize_shape(raw_shape: Variant) -> Array:
	var result: Array = []
	if not (raw_shape is Array): return result
	for raw in raw_shape:
		var point := _checkpoint_point(raw)
		if point.x >= 0 and point.y >= 0: result.append(point)
	return result

func _checkpoint_color(raw: Variant, fallback: Color) -> Color:
	if raw is Color: return raw
	if raw is String:
		var text := String(raw).strip_edges()
		if text.begins_with("Color("):
			text = text.trim_prefix("Color(").trim_suffix(")")
			var parts := text.split(",")
			if parts.size() >= 3:
				var r := float(parts[0].strip_edges()); var g := float(parts[1].strip_edges()); var b := float(parts[2].strip_edges()); var a := float(parts[3].strip_edges()) if parts.size() >= 4 else 1.0
				return Color(r, g, b, a)
		return Color.from_string(text, fallback)
	if raw is Array and raw.size() >= 3: return Color(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]) if raw.size() >= 4 else 1.0)
	if raw is Dictionary: return Color(float(raw.get("r", fallback.r)), float(raw.get("g", fallback.g)), float(raw.get("b", fallback.b)), float(raw.get("a", fallback.a)))
	return fallback

func _normalize_cells(raw_cells: Variant) -> Array:
	var result: Array = []
	if not (raw_cells is Array) or raw_cells.size() != GRID_SIZE: return result
	for y in range(GRID_SIZE):
		if not (raw_cells[y] is Array) or raw_cells[y].size() != GRID_SIZE: return []
		var row: Array = []
		for x in range(GRID_SIZE): row.append(bool(raw_cells[y][x]))
		result.append(row)
	return result

func _polished_normalize_cell_colors(raw_colors: Variant, normalized_cells: Array) -> Array:
	var result: Array = []
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			var fallback: Color = PIECE_COLORS[posmod(y * GRID_SIZE + x, PIECE_COLORS.size())] if bool(normalized_cells[y][x]) else Color.TRANSPARENT
			var value: Variant = raw_colors[y][x] if raw_colors is Array and raw_colors.size() == GRID_SIZE and raw_colors[y] is Array and raw_colors[y].size() == GRID_SIZE else null
			row.append(_checkpoint_color(value, fallback))
		result.append(row)
	return result

func _normalize_pieces(raw_pieces: Variant) -> Array:
	var result: Array = []
	if not (raw_pieces is Array): return result
	for raw_shape in raw_pieces: result.append(_normalize_shape(raw_shape))
	return result

func _polished_normalize_piece_colors(raw_colors: Variant, count: int) -> Array[Color]:
	var result: Array[Color] = []
	for i in range(count):
		var fallback: Color = PIECE_COLORS[posmod(piece_batch * 3 + i + campaign_tier(), PIECE_COLORS.size())]
		var value: Variant = raw_colors[i] if raw_colors is Array and i < raw_colors.size() else null
		result.append(_checkpoint_color(value, fallback))
	return result

func can_place(shape: Array, origin: Vector2i) -> bool:
	var normalized := _normalize_shape(shape)
	if normalized.is_empty() and not shape.is_empty(): return false
	for point: Vector2i in normalized:
		var x := origin.x + point.x; var y := origin.y + point.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE or bool(cells[y][x]): return false
	return true

func _restore_checkpoint() -> void:
	var checkpoint: Dictionary = MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode: return
	var restored_cells := _normalize_cells(checkpoint.get("cells", []))
	if restored_cells.is_empty(): MultiGameManager.clear_checkpoint(GAME_ID); return
	cells = restored_cells
	cell_colors = _polished_normalize_cell_colors(checkpoint.get("cell_colors", []), cells)
	var restored_pieces := _normalize_pieces(checkpoint.get("pieces", []))
	if restored_pieces.size() == 3: pieces = restored_pieces
	else: refill_pieces()
	piece_colors = _polished_normalize_piece_colors(checkpoint.get("piece_colors", []), pieces.size())
	selected_piece = clampi(int(checkpoint.get("selected", -1)), -1, pieces.size() - 1)
	if selected_piece >= 0 and pieces[selected_piece].is_empty(): selected_piece = -1
	score = maxi(0, int(checkpoint.get("score", 0))); lines_cleared = maxi(0, int(checkpoint.get("lines", 0))); placements = maxi(0, int(checkpoint.get("placements", 0))); piece_batch = maxi(0, int(checkpoint.get("batch", piece_batch))); rng.state = int(checkpoint.get("rng_state", rng.state)); history.clear()
	if not any_move_available():
		for i in range(pieces.size()):
			if pieces[i].is_empty(): continue
			pieces[i] = [Vector2i(0,0)]; piece_colors[i] = PIECE_COLORS[posmod(i, PIECE_COLORS.size())]
			if any_move_available(): break

func render_pieces() -> void:
	for child in piece_row.get_children(): child.queue_free()
	for i in range(pieces.size()):
		var button := BlockPieceButton.new(); button.custom_minimum_size = Vector2(300, 176)
		var color: Color = piece_colors[i] if i < piece_colors.size() else PIECE_COLORS[posmod(piece_batch * 3 + i + campaign_tier(), PIECE_COLORS.size())]
		button.configure(pieces[i], i == selected_piece, color, i); button.pressed.connect(select_piece.bind(i)); piece_row.add_child(button)

func _play_place_feedback(indices: Array[int], color: Color, points: int) -> void:
	super._play_place_feedback(indices, color, points)
	if indices.is_empty():
		return
	var center := Vector2.ZERO
	var count := 0
	for idx in indices:
		if idx >= 0 and idx < cell_buttons.size():
			center += cell_buttons[idx].get_global_rect().get_center()
			count += 1
	if count > 0:
		center /= float(count)
		PremiumVisuals.burst(center, color, 12)

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	super._spawn_clear_feedback(indices, line_count)
	if board_shell != null:
		PremiumVisuals.burst(board_shell.get_global_rect().get_center(), Color("ff6688"), 18 + line_count * 4)

func complete_level() -> void:
	if completed: return
	selected_piece = -1
	render()
	completed = true; MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode: MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else: MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "BOARD MASTERED"; PremiumVisuals.burst(Vector2(540, 850), Color("8b7cf6"), 32); PremiumVisuals.screen_flash(Color("8b7cf6"), 0.11); PremiumVisuals.show_combo("BOARD CLEAR", Vector2(540, 720), Color("67e8cf")); AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.78).timeout
	var result := PremiumResultOverlay.new(); result.configure("BLOCK PUZZLE COMPLETE", "Strong placements. Clean lines. Space controlled.", "SCORE %d   •   %d LINES\n%d PLACEMENTS   •   PERFECT ≤ %d" % [score, lines_cleared, placements, par_placements], stars, Color("8b7cf6"), "BACK HOME" if daily_mode else "NEXT PUZZLE"); add_child(result)
	result.continue_requested.connect(func() -> void: finished.emit(-1 if daily_mode else level_number); queue_free())
