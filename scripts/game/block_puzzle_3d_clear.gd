extends "res://scripts/game/block_puzzle_3d.gd"

# Presentation transaction for premium line clears. The logical board remains
# authoritative, but a completed line is first planned, then its still-occupied
# cubes collapse/explode, and only at the collapse apex is the clear committed.
var _clear_transition_active := false

func load_level() -> void:
	_clear_transition_active = false
	super.load_level()

func select_piece(index: int) -> void:
	if _clear_transition_active:
		return
	super.select_piece(index)

func place_piece_from_drag(piece_index: int, origin: Vector2i) -> void:
	if _clear_transition_active:
		return
	super.place_piece_from_drag(piece_index, origin)

func place_selected(origin: Vector2i) -> void:
	if completed or _clear_transition_active:
		return
	if selected_piece < 0 or selected_piece >= pieces.size():
		status_label.text = "Choose a block"
		return
	var shape: Array = pieces[selected_piece]
	if shape.is_empty():
		return
	if not can_place(shape, origin):
		status_label.text = "Doesn't fit"
		_invalid_bump()
		return

	history.append({
		"cells": cells.duplicate(true),
		"cell_colors": cell_colors.duplicate(true),
		"pieces": pieces.duplicate(true),
		"piece_colors": piece_colors.duplicate(true),
		"selected": selected_piece,
		"score": score,
		"lines": lines_cleared,
		"placements": placements,
		"batch": piece_batch,
		"rng_state": rng.state
	})
	if history.size() > 5:
		history.pop_front()

	var placed_color: Color = piece_colors[selected_piece]
	var placed_indices: Array[int] = []
	for raw in shape:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		var px: int = origin.x + point.x
		var py: int = origin.y + point.y
		cells[py][px] = true
		cell_colors[py][px] = placed_color
		placed_indices.append(py * GRID_SIZE + px)
	pieces[selected_piece] = []
	placements += 1
	var placement_score := shape.size() * 10
	score += placement_score

	_sync_placed_cells(placed_indices, placed_color)
	render_pieces()
	_play_place_feedback(placed_indices, placed_color, placement_score)

	var clear_plan := _plan_line_clear()
	var cleared := int(clear_plan.get("line_count", 0))
	if cleared > 0:
		_clear_transition_active = true
		await _animate_line_clear(clear_plan)
		if not is_inside_tree():
			return
		_commit_line_clear(clear_plan)
		_clear_transition_active = false
		lines_cleared += cleared
		score += cleared * 120 + maxi(0, cleared - 1) * 80
		_spawn_score_popup("+%d" % (cleared * 120 + maxi(0, cleared - 1) * 80), Color("ff665e"), 0.18)

	if reached_goal():
		complete_level()
		return
	if all_pieces_used():
		refill_pieces()
	if not any_move_available():
		status_label.text = "No moves — new blocks"
		refill_pieces()
	selected_piece = -1
	render()
	_save_checkpoint()

func undo_move() -> void:
	if _clear_transition_active:
		return
	super.undo_move()

func show_hint() -> void:
	if _clear_transition_active:
		return
	super.show_hint()

func restart_level() -> void:
	if _clear_transition_active:
		return
	super.restart_level()

func _quit() -> void:
	if _clear_transition_active:
		return
	super._quit()

func _sync_placed_cells(indices: Array[int], color: Color) -> void:
	for idx in indices:
		if idx < 0 or idx >= cell_buttons.size():
			continue
		var cell := cell_buttons[idx]
		if cell == null or not is_instance_valid(cell):
			continue
		cell.occupied = true
		cell.preview = false
		cell.accent = color
		cell.queue_redraw()

func _plan_line_clear() -> Dictionary:
	var rows: Array[int] = []
	var cols: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full:
			rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full:
			cols.append(x)

	var cleared_indices: Array[int] = []
	for y in rows:
		for x in range(GRID_SIZE):
			var idx := y * GRID_SIZE + x
			if idx not in cleared_indices:
				cleared_indices.append(idx)
	for x in cols:
		for y in range(GRID_SIZE):
			var idx := y * GRID_SIZE + x
			if idx not in cleared_indices:
				cleared_indices.append(idx)
	return {
		"rows": rows,
		"cols": cols,
		"indices": cleared_indices,
		"line_count": rows.size() + cols.size()
	}

func _clear_stagger(count: int) -> float:
	if count <= 1:
		return 0.0
	return minf(0.018, 0.16 / float(count - 1))

func _animate_line_clear(plan: Dictionary) -> void:
	var line_count := int(plan.get("line_count", 0))
	var indices: Array = plan.get("indices", [])
	if line_count <= 0 or indices.is_empty():
		return
	_spawn_clear_feedback(indices, line_count)
	var last_delay := _clear_stagger(indices.size()) * float(maxi(0, indices.size() - 1))
	# BlockCellButton reaches the collapsed apex after 220 ms. Commit exactly
	# there; debris and score effects may continue without delaying gameplay.
	await get_tree().create_timer(0.22 + last_delay).timeout

func _commit_line_clear(plan: Dictionary) -> void:
	var indices: Array = plan.get("indices", [])
	for raw_idx in indices:
		var idx := int(raw_idx)
		if idx < 0 or idx >= GRID_SIZE * GRID_SIZE:
			continue
		var y: int = idx / GRID_SIZE
		var x: int = idx % GRID_SIZE
		if idx < cell_buttons.size():
			var cell := cell_buttons[idx]
			if cell != null and is_instance_valid(cell):
				# The collapse already played. Set the presentation state directly so
				# render() cannot trigger a second clear animation.
				cell.occupied = false
				cell.clear_phase = 0.0
				cell.queue_redraw()
		cells[y][x] = false
		cell_colors[y][x] = Color.TRANSPARENT

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	FeedbackManager.line_clear(line_count)
	if line_count >= 2:
		FeedbackManager.combo(line_count)
	var stagger := _clear_stagger(indices.size())
	for i in range(indices.size()):
		var idx := indices[i]
		if idx < 0 or idx >= cell_buttons.size():
			continue
		var cell := cell_buttons[idx]
		var delay := stagger * float(i)
		cell.play_clear(delay)
		_spawn_neon_debris(cell, delay * 0.75)
	var phrase := "Excellent!"
	if line_count >= 2:
		phrase = "Amazing!"
	if line_count >= 3:
		phrase = "Spectacular!"
	_spawn_score_popup(phrase, Color("ff665e"), 0.10, true)
	if board_shell != null:
		MotionSystem.local_punch(board_shell, clampf(float(line_count), 1.0, 2.4))
		var glow := Panel.new()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.position = board_shell.global_position - Vector2(12, 12)
		glow.size = board_shell.size + Vector2(24, 24)
		glow.add_theme_stylebox_override("panel", style_box(Color("ff335511"), 8, Color("ff416c"), 5, 8))
		effects_layer.add_child(glow)
		glow.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(glow, "modulate:a", 1.0, 0.05)
		tw.tween_property(glow, "modulate:a", 0.0, 0.26)
		tw.finished.connect(glow.queue_free)
