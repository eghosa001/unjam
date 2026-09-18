extends "res://scripts/game/block_puzzle_ultra_motion.gd"

# Bright 3D presentation layer. Core placement, scoring and grid rules remain
# inherited from the proven motion/gameplay stack. This layer owns the premium
# clear transaction so cubes collapse before the authoritative clear commits.
var _clear_transition_active := false

func _ready() -> void:
	super._ready()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_queue_board_fit):
		viewport.size_changed.connect(_queue_board_fit)

func _queue_board_fit() -> void:
	call_deferred("_fit_3d_board_layout")

func _fit_3d_board_layout() -> void:
	if board_grid == null or board_shell == null or board_grid.get_child_count() == 0:
		return
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 700.0 or viewport_size.y < 1100.0
	var side_margin := 16.0 if compact else 28.0
	var width_budget := maxf(260.0, viewport_size.x - side_margin * 2.0 - 18.0)
	var height_ratio := 0.40 if viewport_size.y < 1100.0 else (0.44 if viewport_size.y < 1500.0 else 0.50)
	var height_budget := maxf(260.0, viewport_size.y * height_ratio)
	var gap := float(board_grid.get_theme_constant("h_separation"))
	var cell_size := clampf(floor(minf(
		(width_budget - 18.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE),
		(height_budget - 18.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE)
	)), 30.0, PREMIUM_CELL_MAX)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	board_shell.custom_minimum_size = Vector2(
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0,
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0
	)
	if piece_row != null:
		piece_row.custom_minimum_size.y = 112.0 if viewport_size.y < 1050.0 else (136.0 if viewport_size.y < 1400.0 else 180.0)

func build_ui() -> void:
	var accent := Unjam3DTheme.PURPLE
	var environment_3d := Unjam3DGameplayStage.new()
	environment_3d.name = "BlockPuzzle3DEnvironment"
	environment_3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	environment_3d.configure("block_puzzle", accent)
	environment_3d.z_index = -100
	add_child(environment_3d)
	PremiumVisuals.set_accent(accent)

	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 700.0 or viewport_size.y < 1100.0
	var outer := MarginContainer.new()
	outer.name = "BlockOuter"
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var side_margin := 16 if compact else 28
	outer.add_theme_constant_override("margin_left", side_margin)
	outer.add_theme_constant_override("margin_right", side_margin)
	outer.add_theme_constant_override("margin_top", 10 if compact else 18)
	outer.add_theme_constant_override("margin_bottom", 10 if compact else 22)
	add_child(outer)
	var root := VBoxContainer.new()
	root.name = "BlockRoot"
	root.add_theme_constant_override("separation", 6 if compact else 8)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.name = "BlockHeader"
	header.custom_minimum_size = Vector2(0, 60 if compact else 78)
	header.add_theme_constant_override("separation", 6 if compact else 12)
	root.add_child(header)
	var back := Button.new()
	back.name = "BackAction"
	back.text = "←"
	back.custom_minimum_size = Vector2(74, 68) if compact else Vector2(92, 78)
	back.add_theme_font_size_override("font_size", 28 if compact else 34)
	Unjam3DTheme.gloss_button(back, Unjam3DTheme.PURPLE_DARK, true, 24)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.name = "BlockTitle"
	title_label.add_theme_font_size_override("font_size", 27 if compact else 33)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Unjam3DTheme.label_3d(title_label, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title_label)
	var retry := Button.new()
	retry.name = "RetryAction"
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(74, 68) if compact else Vector2(92, 78)
	retry.add_theme_font_size_override("font_size", 28 if compact else 34)
	Unjam3DTheme.gloss_button(retry, Unjam3DTheme.PURPLE_DARK, true, 24)
	retry.pressed.connect(restart_level)
	header.add_child(retry)
	var hint := Button.new()
	hint.name = "HintAction"
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(120, 68) if compact else Vector2(184, 82)
	hint.add_theme_font_size_override("font_size", 22 if compact else 24)
	Unjam3DTheme.gloss_button(hint, Unjam3DTheme.PURPLE, true, 22)
	# HintManager owns cost deduction, solver gating, rewarded recovery and the
	# live wallet label. Leaving this button unbound here prevents a free hint path.
	header.add_child(hint)

	var score_card := PanelContainer.new()
	score_card.name = "BlockScoreCard"
	score_card.custom_minimum_size = Vector2(0, 80 if compact else 92)
	score_card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("8f35dd"), 28, Color("f0b8ff"), 3, 14))
	root.add_child(score_card)
	var score_box := VBoxContainer.new()
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_box.add_theme_constant_override("separation", 2)
	score_card.add_child(score_box)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 31 if compact else 39)
	Unjam3DTheme.label_3d(score_label, Color.WHITE, Color("541285"), 4)
	score_box.add_child(score_label)
	goal_label = Label.new()
	goal_label.name = "BlockGoal"
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.add_theme_font_size_override("font_size", 20 if compact else 23)
	Unjam3DTheme.label_3d(goal_label, Color("fff0ff"), Color("541285"), 3)
	score_box.add_child(goal_label)

	var objective := PanelContainer.new()
	objective.name = "BlockObjectiveCard"
	objective.custom_minimum_size = Vector2(0, 42 if compact else 52)
	objective.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(1.0, 0.98, 1.0, 0.96), 22, Color("f0b8ff"), 2, 8))
	root.add_child(objective)
	var objective_label := Label.new()
	objective_label.name = "BlockObjectiveLabel"
	objective_label.text = "▦  DRAG • PLACE • CLEAR"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 20 if compact else 23)
	Unjam3DTheme.label_3d(objective_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	objective.add_child(objective_label)

	var center := CenterContainer.new()
	center.name = "BlockBoardHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var available_board_width := maxf(260.0, viewport_size.x - float(side_margin * 2) - 18.0)
	var available_board_height := maxf(260.0, viewport_size.y * (0.40 if viewport_size.y < 1100.0 else 0.50))
	var cell_size := clampf(floor(minf((available_board_width - 46.0) / float(GRID_SIZE), (available_board_height - 46.0) / float(GRID_SIZE))), 30.0, PREMIUM_CELL_MAX)
	board_shell = PanelContainer.new()
	board_shell.custom_minimum_size = Vector2(cell_size * GRID_SIZE + 46, cell_size * GRID_SIZE + 46)
	board_shell.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("5a2d86"), 30, Color("f5c8ff"), 4, 22))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		board_margin.add_theme_constant_override("margin_%s" % side, 9)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := BlockCellButton.new()
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.configure(false, false, Unjam3DTheme.WATER, y * GRID_SIZE + x)
			cell.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(cell)
			cell_buttons.append(cell)

	var tray := PanelContainer.new()
	tray.name = "BlockTray"
	tray.custom_minimum_size = Vector2(0, 150 if compact else 218)
	tray.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.985, 0.945, 1.0, 0.97), 30, Color("f3c6ff"), 3, 14))
	root.add_child(tray)
	var tray_margin := MarginContainer.new()
	tray_margin.add_theme_constant_override("margin_left", 10 if compact else 18)
	tray_margin.add_theme_constant_override("margin_right", 10 if compact else 18)
	tray_margin.add_theme_constant_override("margin_top", 8 if compact else 12)
	tray_margin.add_theme_constant_override("margin_bottom", 8 if compact else 12)
	tray.add_child(tray_margin)
	var tray_box := VBoxContainer.new()
	tray_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_box.add_theme_constant_override("separation", 4)
	tray_margin.add_child(tray_box)
	var tray_title := Label.new()
	tray_title.name = "BlockTrayTitle"
	tray_title.text = "DRAG A BLOCK ONTO THE BOARD"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.label_3d(tray_title, Unjam3DTheme.PURPLE_DARK, Color.WHITE, 2)
	tray_box.add_child(tray_title)
	piece_row = HBoxContainer.new()
	piece_row.name = "BlockPieceRow"
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 8 if compact else 18)
	piece_row.custom_minimum_size = Vector2(0, 112 if compact else 180)
	tray_box.add_child(piece_row)

	status_label = Label.new()
	status_label.name = "BlockStatus"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 20 if compact else 23)
	status_label.custom_minimum_size = Vector2(0, 26 if compact else 32)
	Unjam3DTheme.label_3d(status_label, Color.WHITE, Unjam3DTheme.PURPLE_DARK, 3)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.name = "BlockHint"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 19 if compact else 21)
	hint_label.custom_minimum_size = Vector2(0, 24 if compact else 28)
	Unjam3DTheme.label_3d(hint_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(hint_label)

	effects_layer = Control.new()
	effects_layer.name = "BlockEffectsLayer"
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)

func load_level() -> void:
	_clear_transition_active = false
	_clear_transient_effects()
	super.load_level()

func _clear_transient_effects() -> void:
	active_touch_piece = null
	if effects_layer == null:
		return
	for child in effects_layer.get_children():
		effects_layer.remove_child(child)
		child.queue_free()

func _effects_rect(control: Control, grow_by: float = 0.0) -> Rect2:
	if effects_layer == null or control == null:
		return Rect2()
	var global_rect := control.get_global_rect()
	var inverse := effects_layer.get_global_transform_with_canvas().affine_inverse()
	var local_position := inverse * global_rect.position
	return Rect2(local_position - Vector2.ONE * grow_by, global_rect.size + Vector2.ONE * grow_by * 2.0)

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
		var glow_rect := _effects_rect(board_shell, 12.0)
		glow.position = glow_rect.position
		glow.size = glow_rect.size
		glow.add_theme_stylebox_override("panel", style_box(Color("ff335511"), 8, Color("ff416c"), 5, 8))
		effects_layer.add_child(glow)
		glow.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(glow, "modulate:a", 1.0, 0.05)
		tw.tween_property(glow, "modulate:a", 0.0, 0.26)
		tw.finished.connect(glow.queue_free)
