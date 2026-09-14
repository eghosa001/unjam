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

func campaign_tier() -> int:
	if level_number <= 100: return 0
	if level_number <= 500: return 1
	if level_number <= 1500: return 2
	if level_number <= 3000: return 3
	if level_number <= 5000: return 4
	if level_number <= 7500: return 5
	return 6

func level_config() -> Dictionary:
	var world: int = int(MultiGameManager.world_for_level(level_number))
	var d := difficulty()
	var tier := campaign_tier()
	var base := 70 + mini(170, world * 4) + tier * 18
	var lines := 2 + int(world / 10) + int(tier / 2)
	var par := 18 + int(world / 18) + tier
	match d:
		"easy":
			base = int(base * 0.82)
			lines = maxi(1, lines - 2)
			par += 5
		"hard":
			base = int(base * 1.25)
			lines += 2
		"milestone":
			base = int(base * 1.48)
			lines += 3
		"boss":
			base = int(base * 1.78)
			lines += 5
	return {"target_score": base, "target_lines": mini(18, lines), "par": par}

func load_level() -> void:
	# Let the current Color Blast base implementation initialize cells, colors,
	# score UI, checkpoints, and analytics. The old override duplicated legacy UI
	# state (meta_label) and no longer matched the production base class.
	var checkpoint_before := MultiGameManager.checkpoint(GAME_ID)
	super.load_level()
	if checkpoint_before.is_empty():
		_apply_start_pattern()
		if not any_move_available():
			# Preserve a playable opening even when a high-tier pattern is dense.
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
	if tier <= 0 and level_number <= 40:
		return
	var d := difficulty()
	var count := 0
	if tier == 0: count = 3
	else: count = 4 + tier * 2
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
			for x in range(1, GRID_SIZE - 1):
				candidates.append(Vector2i(x, 1))
				candidates.append(Vector2i(x, GRID_SIZE - 2))
		_:
			for y in range(1, GRID_SIZE - 1):
				candidates.append(Vector2i(1, y))
				candidates.append(Vector2i(GRID_SIZE - 2, y))
	while candidates.size() < count:
		var p := Vector2i(rng.randi_range(0, GRID_SIZE - 1), rng.randi_range(0, GRID_SIZE - 1))
		if p not in candidates:
			candidates.append(p)
	for i in range(mini(count, candidates.size())):
		var p: Vector2i = candidates[i]
		cells[p.y][p.x] = true
		cell_colors[p.y][p.x] = PIECE_COLORS[posmod(i + tier, PIECE_COLORS.size())]

func refill_pieces() -> void:
	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	var tier := campaign_tier()
	var d := difficulty()
	var max_index := 9
	if tier >= 1: max_index = 17
	if tier >= 2: max_index = 23
	if tier >= 4: max_index = ADVANCED_SHAPES.size() - 1
	if d == "easy": max_index = mini(max_index, 11)
	elif d == "medium": max_index = mini(max_index, 19)
	for i in range(3):
		var lower := 0
		if tier >= 3 and d in ["hard", "milestone", "boss"] and i > 0:
			lower = 6
		var shape_index := rng.randi_range(lower, max_index)
		pieces.append((ADVANCED_SHAPES[shape_index] as Array).duplicate())
		piece_colors.append(PIECE_COLORS[posmod(piece_batch * 3 + i + tier, PIECE_COLORS.size())])
	selected_piece = -1
	if not any_move_available():
		pieces[0] = (ADVANCED_SHAPES[rng.randi_range(0, 2)] as Array).duplicate()
		piece_colors[0] = PIECE_COLORS[posmod(piece_batch * 3 + tier, PIECE_COLORS.size())]
		if not any_move_available():
			pieces[0] = [Vector2i(0,0)]

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := PolishedBlockPieceButton.new()
		button.custom_minimum_size = Vector2(260, 142)
		var color: Color = piece_colors[i] if i < piece_colors.size() else PIECE_COLORS[posmod(piece_batch * 3 + i + campaign_tier(), PIECE_COLORS.size())]
		button.configure(pieces[i], i == selected_piece, color, i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func complete_level() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "BOARD MASTERED"
	PremiumVisuals.burst(Vector2(540, 850), Color("8b7cf6"), 32)
	PremiumVisuals.screen_flash(Color("8b7cf6"), 0.11)
	PremiumVisuals.show_combo("BOARD CLEAR", Vector2(540, 720), Color("67e8cf"))
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.30).timeout
	var result := PremiumResultOverlay.new()
	result.configure(
		"BLOCK PUZZLE COMPLETE",
		"Strong placements. Clean lines. Space controlled.",
		"SCORE %d   •   %d LINES\n%d PLACEMENTS   •   PERFECT ≤ %d" % [score, lines_cleared, placements, par_placements],
		stars,
		Color("8b7cf6"),
		"BACK HOME" if daily_mode else "NEXT PUZZLE"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
