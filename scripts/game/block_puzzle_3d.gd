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

func _add_block_hint_bulb(button: Button) -> void:
	var bulb := PanelContainer.new()
	bulb.name = "BlockHintBulb"
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bulb_style := StyleBoxFlat.new()
	bulb_style.bg_color = Color("#ffe47a")
	bulb_style.corner_radius_top_left = 8
	bulb_style.corner_radius_top_right = 8
	bulb_style.corner_radius_bottom_left = 8
	bulb_style.corner_radius_bottom_right = 8
	bulb.add_theme_stylebox_override("panel", bulb_style)
	bulb.position = Vector2(18,12)
	bulb.size = Vector2(16,16)
	button.add_child(bulb)
	var base := ColorRect.new()
	base.name = "BlockHintBulbBase"
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.color = Color("#fff3aa")
	base.position = Vector2(22,29)
	base.size = Vector2(8,4)
	button.add_child(base)

func _add_block_identity_emblem(canvas: Control) -> void:
	var emblem := PanelContainer.new()
	emblem.name = "Identity/Block Emblem"
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(Color("#c77cff"),Color("#a855f7"),Color("#7a2cc2"),9,Color(0.88,0.73,1.0,0.55),1))
	FigmaReferenceCanvas.set_rect(emblem,77,17,30,30)
	canvas.add_child(emblem)
	var blocks := [
		[Rect2(83,31,8,8),Color.WHITE,"Mark/Block A"],
		[Rect2(92,31,8,8),Color("#f5e9ff"),"Mark/Block B"],
		[Rect2(88,23,8,8),Color.WHITE,"Mark/Block C"],
	]
	for spec in blocks:
		var tile := PanelContainer.new()
		tile.name = String(spec[2])
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(spec[1] as Color,2))
		var rect: Rect2 = spec[0] as Rect2
		FigmaReferenceCanvas.set_rect(tile,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
		canvas.add_child(tile)
	var highlight := PanelContainer.new()
	highlight.name = "Mark/Highlight"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(1,1,1,0.55),1))
	FigmaReferenceCanvas.set_rect(highlight,89,24,6,2)
	canvas.add_child(highlight)

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
	board_shell.position = Vector2(29, 179)
	board_shell.size = Vector2(330, 330)
	if piece_row != null:
		piece_row.custom_minimum_size = Vector2(326, 72)
		piece_row.position = Vector2(31, 556)
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
	sky.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#705cfa"), Color("#b094ff"), Color("#f0e8ff"), 34, Color("#b8d1e0"), 1, 0.55))
	FigmaReferenceCanvas.set_rect(sky, -24.88, -128.55, 437.76, 947.35)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#784fc2"), Color("#4a3087"), Color("#241a52"), 0, Color.TRANSPARENT, 0, 0.50))
	FigmaReferenceCanvas.set_rect(ground, -24.88, -23.04, 437.76, 460.20)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.polygon = PackedVector2Array([Vector2(14, 434), Vector2(376, 434), Vector2(350, 86), Vector2(40, 86)])
	platform.color = Color(0.64, 0.43, 0.91, 0.62)
	canvas.add_child(platform)

	FigmaReferenceCanvas.add_shadow(canvas, Rect2(15,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var back := FigmaReferenceCanvas.premium_button("←", 22, Color(0.03,0.23,0.47), Color(0.98,0.96,1.0), 16, Color(0.84,0.68,0.98,0.52), 1.4)
	back.name = "BackAction"
	back.tooltip_text = "Back to levels"
	FigmaReferenceCanvas.set_rect(back, 15, 15, 54, 54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(319,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var retry := FigmaReferenceCanvas.premium_button("↻", 23, Color("#7d21d6"), Color(0.98,0.96,1.0), 16, Color(0.84,0.68,0.98,0.52), 1.4)
	retry.name = "RetryAction"
	retry.tooltip_text = "Restart level"
	FigmaReferenceCanvas.set_rect(retry, 319, 15, 54, 54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)

	_add_block_identity_emblem(canvas)

	title_label = FigmaReferenceCanvas.label("", 20, Color(1,0.995,0.97), true)
	FigmaReferenceCanvas.style_display_title(title_label, Color("#d5a0ff"), Color("#42106f"), 2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(title_label, 115, 15, 184, 30)
	canvas.add_child(title_label)
	var campaign := FigmaReferenceCanvas.label("CAMPAIGN • HARD", 14, Color(0.92,0.98,1.0), false)
	campaign.name = "BlockCampaignSubtitle"
	campaign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(campaign, 115, 43, 184, 20)
	canvas.add_child(campaign)

	var score_card := PanelContainer.new()
	score_card.name = "BlockScoreCard"
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(17,85,354,58), 16, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	score_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#9f52d8"), Color("#8f36d1"), Color("#752cab"), 16, Color(0.758,0.566,0.901,0.52), 1.4))
	FigmaReferenceCanvas.set_rect(score_card, 17, 85, 354, 58)
	score_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(score_card)
	score_label = FigmaReferenceCanvas.label("", 22, Color(1,0.995,0.97), true)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(score_label, 33, 94, 52, 44)
	canvas.add_child(score_label)
	goal_label = FigmaReferenceCanvas.label("", 14, Color(0.96,0.87,1.0), false)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.clip_text = true
	FigmaReferenceCanvas.set_rect(goal_label, 92, 94, 198, 44)
	canvas.add_child(goal_label)

	FigmaReferenceCanvas.add_shadow(canvas, Rect2(303,87,52,52), 16, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	var hint := FigmaReferenceCanvas.premium_button("", 20, Color(1,0.995,0.97), Color("#c73dff"), 16, Color(0.89,0.62,1.0,0.56), 1.3)
	hint.name = "HintAction"
	hint.tooltip_text = "Hint"
	FigmaReferenceCanvas.set_rect(hint, 303, 87, 52, 52)
	# HintManager owns the actual paid/rewarded hint signal.
	canvas.add_child(hint)
	_add_block_hint_bulb(hint)

	var depth := PanelContainer.new()
	depth.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color("#241445"), 20))
	FigmaReferenceCanvas.set_rect(depth, 31.24, 191.35, 330, 330)
	canvas.add_child(depth)
	board_shell = PanelContainer.new()
	board_shell.name = "BlockBoardShell"
	board_shell.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#613894"), Color("#452670"), Color("#2e1a54"), 20, Color(0.72,0.52,1.0,0.80), 2))
	FigmaReferenceCanvas.set_rect(board_shell, 29, 179, 330, 330)
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
	FigmaReferenceCanvas.add_shadow(canvas, Rect2(17,534,354,104), 22, Color(0.07,0.03,0.16,0.20), 6, Vector2(0,5))
	tray.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		Color("#fffaff"), Color("#fbf4ff"), Color("#eee1fb"), 22,
		Color(0.88,0.68,1.0,0.78), 1.5, 0.42
	))
	FigmaReferenceCanvas.set_rect(tray, 17, 534, 354, 104)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tray)
	piece_row = HBoxContainer.new()
	piece_row.name = "BlockPieceRow"
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 7)
	FigmaReferenceCanvas.set_rect(piece_row, 31, 556, 326, 72)
	canvas.add_child(piece_row)

	var status_region := Control.new()
	status_region.name = "BlockStatus"
	status_region.clip_contents = true
	FigmaReferenceCanvas.set_rect(status_region, 18, 712, 354, 20)
	canvas.add_child(status_region)
	status_label = FigmaReferenceCanvas.label("", 14, Color(1,0.995,0.97), true)
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
	hint_label = FigmaReferenceCanvas.label("", 14, Color(1,0.995,0.97), true)
	hint_label.name = "BlockHintText"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.clip_text = true
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	FigmaReferenceCanvas.set_rect(hint_label, 0, 0, 354, 20)
	hint_region.add_child(hint_label)

	var frame_border := PanelContainer.new()
	frame_border.name = "BlockFrameBorder"
	frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_border.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color.TRANSPARENT, 34, Color("#b8d1e0"), 1))
	FigmaReferenceCanvas.set_rect(frame_border, 0, 0, 390, 844)
	frame_border.z_index = 900
	canvas.add_child(frame_border)

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
		if has_method("_handle_no_legal_moves"):
			call("_handle_no_legal_moves")
		else:
			status_label.text = "No legal moves"
		return
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
