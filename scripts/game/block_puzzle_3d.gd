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
	_fit_figma_board_layout()

func _fit_figma_board_layout() -> void:
	if board_grid == null or board_shell == null:
		return
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 5)
	board_grid.add_theme_constant_override("v_separation", 5)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(32.6, 32.6)
	board_shell.custom_minimum_size = Vector2(330, 330)
	board_shell.size = Vector2(330, 330)
	if piece_row != null:
		piece_row.custom_minimum_size = Vector2(326, 72)
		piece_row.size = Vector2(326, 72)
		piece_row.add_theme_constant_override("separation", 7)

func build_ui() -> void:
	clip_contents = true
	PremiumVisuals.set_accent(Unjam3DTheme.PURPLE)
	var bg := ColorRect.new()
	bg.name = "BlockFigmaViewportBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.14, 0.10, 0.32)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var canvas := FigmaReferenceCanvas.new()
	canvas.name = "FigmaBlock390x844"
	add_child(canvas)
	_build_figma_block(canvas)

	effects_layer = Control.new()
	effects_layer.name = "BlockEffectsLayer"
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)

func _build_figma_block(canvas: Control) -> void:
	var sky := PanelContainer.new()
	sky.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(Color(0.44, 0.36, 0.98), Color(0.94, 0.91, 1.0), 0))
	FigmaReferenceCanvas.set_rect(sky, 0, 0, 390, 844)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(Color(0.47, 0.31, 0.76), Color(0.14, 0.10, 0.32), 0))
	FigmaReferenceCanvas.set_rect(ground, 0, 94, 390, 410)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.polygon = PackedVector2Array([Vector2(14, 434), Vector2(376, 434), Vector2(350, 86), Vector2(40, 86)])
	platform.color = Color(0.64, 0.43, 0.91, 0.62)
	canvas.add_child(platform)

	var back := FigmaReferenceCanvas.button("←", 22, Color(0.03,0.23,0.47), Color(0.98,0.96,1.0), 16, Color(0.84,0.68,0.98,0.52), 1)
	back.name = "BackAction"
	FigmaReferenceCanvas.set_rect(back, 16, 16, 54, 54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	var retry := FigmaReferenceCanvas.button("↻", 23, Color(0.49,0.13,0.84), Color(0.98,0.96,1.0), 16, Color(0.84,0.68,0.98,0.52), 1)
	retry.name = "RetryAction"
	FigmaReferenceCanvas.set_rect(retry, 320, 16, 54, 54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)

	title_label = FigmaReferenceCanvas.label("", 20, Color(1,0.995,0.97), true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(title_label, 106, 16, 204, 30)
	canvas.add_child(title_label)
	var campaign := FigmaReferenceCanvas.label("CAMPAIGN • HARD", 12, Color(0.92,0.98,1.0), false)
	campaign.name = "BlockCampaignSubtitle"
	campaign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(campaign, 106, 45, 204, 20)
	canvas.add_child(campaign)

	var score_card := PanelContainer.new()
	score_card.name = "BlockScoreCard"
	score_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(Color(0.622,0.321,0.845), Color(0.459,0.172,0.672), 16, Color(0.758,0.566,0.901,0.52), 1))
	FigmaReferenceCanvas.set_rect(score_card, 18, 86, 354, 58)
	score_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(score_card)
	score_label = FigmaReferenceCanvas.label("", 22, Color(1,0.995,0.97), true)
	FigmaReferenceCanvas.set_rect(score_label, 34, 94, 190, 28)
	canvas.add_child(score_label)
	goal_label = FigmaReferenceCanvas.label("", 12, Color(0.96,0.87,1.0), false)
	FigmaReferenceCanvas.set_rect(goal_label, 34, 119, 240, 20)
	canvas.add_child(goal_label)

	var hint := FigmaReferenceCanvas.button("💡", 20, Color(1,0.995,0.97), Color(0.78,0.24,1.0), 16, Color(0.89,0.62,1.0,0.56), 1)
	hint.name = "HintAction"
	FigmaReferenceCanvas.set_rect(hint, 304, 88, 52, 52)
	# HintManager owns the actual paid/rewarded hint signal.
	canvas.add_child(hint)

	var depth := PanelContainer.new()
	depth.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.14,0.08,0.27), 20))
	FigmaReferenceCanvas.set_rect(depth, 32.2, 192.3, 330, 330)
	canvas.add_child(depth)
	board_shell = PanelContainer.new()
	board_shell.name = "BlockBoardShell"
	board_shell.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient(Color(0.38,0.22,0.58), Color(0.18,0.10,0.33), 20, Color(0.72,0.52,1.0,0.80), 1))
	FigmaReferenceCanvas.set_rect(board_shell, 30, 180, 330, 330)
	canvas.add_child(board_shell)
	var board_margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		board_margin.add_theme_constant_override("margin_%s" % side, 17)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.name = "BlockBoardGrid"
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 5)
	board_grid.add_theme_constant_override("v_separation", 5)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := BlockCellButton.new()
			cell.custom_minimum_size = Vector2(32.6, 32.6)
			cell.configure(false, false, Unjam3DTheme.WATER, y * GRID_SIZE + x)
			cell.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(cell)
			cell_buttons.append(cell)

	var tray := PanelContainer.new()
	tray.name = "BlockTray"
	tray.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.985,0.945,1.0,0.97), 18, Color(0.90,0.72,1.0,0.70), 1))
	FigmaReferenceCanvas.set_rect(tray, 18, 535, 354, 104)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tray)
	piece_row = HBoxContainer.new()
	piece_row.name = "BlockPieceRow"
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 7)
	FigmaReferenceCanvas.set_rect(piece_row, 32, 557, 326, 72)
	canvas.add_child(piece_row)

	var status_region := Control.new()
	status_region.name = "BlockStatus"
	status_region.clip_contents = true
	FigmaReferenceCanvas.set_rect(status_region, 18, 712, 354, 20)
	canvas.add_child(status_region)
	status_label = FigmaReferenceCanvas.label("", 12, Color(1,0.995,0.97), true)
	status_label.name = "BlockStatusText"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	FigmaReferenceCanvas.set_rect(status_label, 0, 0, 354, 20)
	status_region.add_child(status_label)

	var hint_region := Control.new()
	hint_region.name = "BlockHint"
	hint_region.clip_contents = true
	FigmaReferenceCanvas.set_rect(hint_region, 18, 734, 354, 20)
	canvas.add_child(hint_region)
	hint_label = FigmaReferenceCanvas.label("", 12, Color(1,0.995,0.97), true)
	hint_label.name = "BlockHintText"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.clip_text = true
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	FigmaReferenceCanvas.set_rect(hint_label, 0, 0, 354, 20)
	hint_region.add_child(hint_label)

func _tray_piece_button_size() -> Vector2:
	return Vector2(104, 72)

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
