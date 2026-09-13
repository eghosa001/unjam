extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "block_puzzle"
const GRID_SIZE := 8
const SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)]
]

var level_number := 1
var daily_mode := false
var cells: Array = []
var cell_buttons: Array[BlockCellButton] = []
var pieces: Array = []
var selected_piece := -1
var score := 0
var lines_cleared := 0
var placements := 0
var target_score := 80
var target_lines := 2
var par_placements := 18
var history: Array = []
var rng := RandomNumberGenerator.new()
var score_label: Label
var goal_label: Label
var status_label: Label
var hint_label: Label
var piece_row: HBoxContainer
var title_label: Label
var meta_label: Label
var completed := false
var piece_batch := 0

func _ready() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()
	load_level()

func difficulty() -> String:
	return MultiGameManager.difficulty_for_level(level_number)

func level_config() -> Dictionary:
	var world := MultiGameManager.world_for_level(level_number)
	var d := difficulty()
	var base := 55 + mini(100, world * 3)
	var lines := 1 + int(world / 12)
	var par := 20 + int(world / 15)
	match d:
		"easy":
			base = int(base * 0.80)
			lines = maxi(1, lines - 1)
			par += 5
		"hard":
			base = int(base * 1.25)
			lines += 1
		"milestone":
			base = int(base * 1.45)
			lines += 2
		"boss":
			base = int(base * 1.70)
			lines += 3
	return {"target_score": base, "target_lines": mini(12, lines), "par": par}

func style_box(color: Color, radius: int = 22, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if border_width > 0:
		s.border_width_left = border_width
		s.border_width_right = border_width
		s.border_width_top = border_width
		s.border_width_bottom = border_width
		s.border_color = border
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.28)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 6)
	return s

func style_button(button: Button, accent: bool = false) -> void:
	var base := Color("8b7cf6") if accent else Color("24355a")
	button.add_theme_stylebox_override("normal", style_box(Color(base, 0.92), 20, Color(1,1,1,0.09), 1, 6))
	button.add_theme_stylebox_override("hover", style_box(base.lightened(0.08), 20, Color("c4b5fd"), 2, 8))
	button.add_theme_stylebox_override("pressed", style_box(base.darkened(0.12), 20, Color.WHITE, 2, 2))
	button.add_theme_stylebox_override("disabled", style_box(Color("172238"), 20))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)

func build_ui() -> void:
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("080d1d"), Color("8b7cf6"), MultiGameManager.world_for_level(level_number) - 1)
	add_child(bg)
	PremiumVisuals.set_accent(Color("8b7cf6"))
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 40)
	outer.add_theme_constant_override("margin_bottom", 38)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 11)
	outer.add_child(root)
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", style_box(Color(0.035,0.05,0.105,0.96), 27, Color(1,1,1,0.08), 1, 10))
	root.add_child(header_panel)
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 14)
	hm.add_theme_constant_override("margin_right", 14)
	hm.add_theme_constant_override("margin_top", 10)
	hm.add_theme_constant_override("margin_bottom", 10)
	header_panel.add_child(hm)
	var header := HBoxContainer.new()
	hm.add_child(header)
	var back := Button.new()
	back.text = "←  BACK"
	back.custom_minimum_size = Vector2(145, 66)
	style_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 31)
	title_label.add_theme_color_override("font_color", Color("f4f2ff"))
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(135, 66)
	style_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)
	meta_label = Label.new()
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 17)
	meta_label.add_theme_color_override("font_color", Color("a7b0cb"))
	root.add_child(meta_label)
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", style_box(Color(0.025,0.038,0.085,0.94), 23, Color("8b7cf655"), 2, 7))
	root.add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 2)
	stats_panel.add_child(stats_box)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color("ede9fe"))
	stats_box.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 17)
	goal_label.add_theme_color_override("font_color", Color("67e8cf"))
	stats_box.add_child(goal_label)
	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.012,0.02,0.052,0.97), 36, Color("8b7cf650"), 2, 14))
	root.add_child(board_panel)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 18)
	board_margin.add_theme_constant_override("margin_right", 18)
	board_margin.add_theme_constant_override("margin_top", 18)
	board_margin.add_theme_constant_override("margin_bottom", 18)
	board_panel.add_child(board_margin)
	var center := CenterContainer.new()
	board_margin.add_child(center)
	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	center.add_child(grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var button := BlockCellButton.new()
			button.custom_minimum_size = Vector2(105, 105)
			button.configure(false, false, Color("8b7cf6"), y * GRID_SIZE + x)
			button.pressed.connect(place_selected.bind(Vector2i(x, y)))
			grid.add_child(button)
			cell_buttons.append(button)
	var pieces_title := Label.new()
	pieces_title.text = "CHOOSE A PIECE"
	pieces_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pieces_title.add_theme_font_size_override("font_size", 17)
	pieces_title.add_theme_color_override("font_color", Color("b9c1d9"))
	root.add_child(pieces_title)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 12)
	root.add_child(piece_row)
	var action_panel := PanelContainer.new()
	action_panel.add_theme_stylebox_override("panel", style_box(Color(0.025,0.038,0.085,0.94), 24, Color(1,1,1,0.07), 1, 7))
	root.add_child(action_panel)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	action_panel.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(250, 70)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(250, 70)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("b7c1d8"))
	hint_label.custom_minimum_size = Vector2(0, 30)
	root.add_child(hint_label)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	status_label.custom_minimum_size = Vector2(0, 34)
	root.add_child(status_label)
	PremiumVisuals.entrance(root, 0.02)

func load_level() -> void:
	completed = false
	selected_piece = -1
	score = 0
	lines_cleared = 0
	placements = 0
	piece_batch = 0
	history.clear()
	status_label.text = ""
	hint_label.text = "Select a shape, then place it on the grid"
	var config := level_config()
	target_score = int(config.get("target_score", 80))
	target_lines = int(config.get("target_lines", 2))
	par_placements = int(config.get("par", 18))
	title_label.text = "DAILY BLOCK PUZZLE" if daily_mode else "BLOCK PUZZLE  •  LEVEL %04d" % level_number
	meta_label.text = "%s  •  %s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_name(GAME_ID, MultiGameManager.world_for_level(level_number)).to_upper(), MultiGameManager.world_for_level(level_number)]
	rng.seed = level_number * 104729 + (1 if daily_mode else 0)
	cells.clear()
	for _y in range(GRID_SIZE):
		var row: Array = []
		for _x in range(GRID_SIZE): row.append(false)
		cells.append(row)
	refill_pieces()
	_restore_checkpoint()
	render()
	AnalyticsManager.track("block_puzzle_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func refill_pieces() -> void:
	pieces.clear()
	piece_batch += 1
	for _i in range(3):
		var max_shape := SHAPES.size() - 1
		if difficulty() == "easy":
			max_shape = 5
		elif difficulty() == "medium":
			max_shape = 7
		var shape_index := rng.randi_range(0, max_shape)
		pieces.append(SHAPES[shape_index].duplicate())
	selected_piece = -1
	if not any_move_available():
		pieces[0] = SHAPES[0].duplicate()

func render() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			cell_buttons[index].configure(bool(cells[y][x]), false, Color("8b7cf6"), index)
	score_label.text = "SCORE  %d / %d    •    LINES  %d / %d" % [score, target_score, lines_cleared, target_lines]
	goal_label.text = "PLACEMENTS  %d    •    PERFECT ≤ %d" % [placements, par_placements]
	render_pieces()

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := BlockPieceButton.new()
		button.custom_minimum_size = Vector2(285, 130)
		button.configure(pieces[i], i == selected_piece, Color("8b7cf6"), i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func select_piece(index: int) -> void:
	if completed or pieces[index].is_empty(): return
	selected_piece = index
	status_label.text = "Piece %d selected" % (index + 1)
	hint_label.text = "Drag the piece onto a glowing valid cell, or tap a grid cell"
	render_pieces()

func place_selected(origin: Vector2i) -> void:
	if completed: return
	if selected_piece < 0 or selected_piece >= pieces.size():
		status_label.text = "Choose a piece first"
		return
	var shape: Array = pieces[selected_piece]
	if not can_place(shape, origin):
		status_label.text = "That shape does not fit there"
		PremiumVisuals.screen_flash(Color("ff6b7a"), 0.045)
		return
	history.append({"cells": cells.duplicate(true), "pieces": pieces.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state})
	for point in shape:
		var px: int = origin.x + int(point.x)
		var py: int = origin.y + int(point.y)
		cells[py][px] = true
	_spawn_placement_feedback(shape, origin)
	score += shape.size()
	placements += 1
	pieces[selected_piece] = []
	selected_piece = -1
	var cleared := clear_lines()
	if cleared > 0:
		lines_cleared += cleared
		score += cleared * 20
		status_label.text = "%d LINE%s CLEARED  •  COMBO +%d" % [cleared, "S" if cleared != 1 else "", cleared * 20]
		PremiumVisuals.burst(Vector2(540, 840), Color("8b7cf6"), 10 + cleared * 4)
	else:
		status_label.text = "Placed"
	if reached_goal():
		render()
		complete_level()
		return
	if all_pieces_used(): refill_pieces()
	render()
	_save_checkpoint()
	if not any_move_available(): status_label.text = "NO MOVES — UNDO, HINT OR RETRY"

func _spawn_placement_feedback(shape: Array, origin: Vector2i) -> void:
	var order := 0
	for raw in shape:
		var point: Vector2i = raw
		var x := origin.x + point.x
		var y := origin.y + point.y
		var index := y * GRID_SIZE + x
		_spawn_cell_overlay(index, Color("8b7cf6"), 0.34, 1.22, float(order) * 0.025)
		order += 1
	_spawn_score_popup("+%d" % shape.size(), Color("c4b5fd"), 0.0)

func _spawn_clear_feedback(rows: Array[int], cols: Array[int]) -> void:
	var seen := {}
	for y in rows:
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			if not seen.has(index):
				seen[index] = true
				_spawn_cell_overlay(index, Color("67e8cf"), 0.52, 1.42, float(x) * 0.035)
	for x in cols:
		for y in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			if not seen.has(index):
				seen[index] = true
				_spawn_cell_overlay(index, Color("67e8cf"), 0.52, 1.42, float(y) * 0.035)
	var count := rows.size() + cols.size()
	if count > 0:
		var cheer := "GREAT!" if count == 1 else ("AMAZING!" if count == 2 else "SPECTACULAR!")
		var reward := count * 20
		_spawn_score_popup("%s  +%d" % [cheer, reward], Color("67e8cf"), 0.10)
		if count >= 2:
			_spawn_score_popup("%d× CLEAR" % count, Color("c4b5fd"), 0.22)
		PremiumVisuals.screen_flash(Color("67e8cf"), 0.055 + minf(0.055, float(count) * 0.012))
		PremiumVisuals.burst(Vector2(540, 840), Color("67e8cf"), 12 + count * 7)

func _spawn_score_popup(text_value: String, color: Color, delay: float = 0.0) -> void:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 750
	label.position = Vector2(350, 790)
	label.size = Vector2(380, 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 42 if "!" in text_value else 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.modulate.a = 0.0
	label.scale = Vector2(0.72, 0.72)
	label.pivot_offset = label.size * 0.5
	add_child(label)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(label, "modulate:a", 1.0, 0.07)
	tween.parallel().tween_property(label, "scale", Vector2(1.18, 1.18), 0.11)
	tween.tween_property(label, "scale", Vector2.ONE, 0.10)
	tween.tween_property(label, "position:y", label.position.y - 96.0, 0.38).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.42)
	tween.finished.connect(label.queue_free)

func _spawn_cell_overlay(index: int, color: Color, duration: float, peak_scale: float, delay: float = 0.0) -> void:
	if index < 0 or index >= cell_buttons.size(): return
	var cell := cell_buttons[index]
	if cell == null or not is_instance_valid(cell): return
	var overlay := Panel.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 600
	overlay.position = cell.global_position - global_position
	overlay.size = cell.size
	overlay.pivot_offset = overlay.size * 0.5
	overlay.add_theme_stylebox_override("panel", style_box(Color(color, 0.76), 18, color.lightened(0.25), 2))
	add_child(overlay)
	overlay.scale = Vector2(0.72, 0.72)
	overlay.modulate.a = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(overlay, "scale", Vector2(peak_scale, peak_scale), duration * 0.45)
	tween.parallel().tween_property(overlay, "modulate:a", 1.0, duration * 0.25)
	tween.tween_property(overlay, "scale", Vector2(0.72, 0.72), duration * 0.55)
	tween.parallel().tween_property(overlay, "modulate:a", 0.0, duration * 0.55)
	tween.finished.connect(overlay.queue_free)

func can_place(shape: Array, origin: Vector2i) -> bool:
	for point in shape:
		var x: int = origin.x + int(point.x)
		var y: int = origin.y + int(point.y)
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE: return false
		if bool(cells[y][x]): return false
	return true

func clear_lines() -> int:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full: full_rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full: full_cols.append(x)
	if not full_rows.is_empty() or not full_cols.is_empty():
		_spawn_clear_feedback(full_rows, full_cols)
	for y in full_rows:
		for x in range(GRID_SIZE): cells[y][x] = false
	for x in full_cols:
		for y in range(GRID_SIZE): cells[y][x] = false
	return full_rows.size() + full_cols.size()

func reached_goal() -> bool:
	return score >= target_score and lines_cleared >= target_lines

func all_pieces_used() -> bool:
	for shape in pieces:
		if not shape.is_empty(): return false
	return true

func any_move_available() -> bool:
	for shape in pieces:
		if shape.is_empty(): continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)): return true
	return false

func undo_move() -> void:
	if history.is_empty() or completed:
		status_label.text = "Nothing to undo"
		return
	var state: Dictionary = history.pop_back()
	cells = state.get("cells", []).duplicate(true)
	pieces = state.get("pieces", []).duplicate(true)
	selected_piece = int(state.get("selected", -1))
	score = int(state.get("score", 0))
	lines_cleared = int(state.get("lines", 0))
	placements = int(state.get("placements", 0))
	piece_batch = int(state.get("batch", 0))
	rng.state = int(state.get("rng_state", rng.state))
	SaveManager.record_undo()
	status_label.text = "Move undone"
	render()
	_save_checkpoint()

func show_hint() -> void:
	if completed: return
	for piece_index in range(pieces.size()):
		var shape: Array = pieces[piece_index]
		if shape.is_empty(): continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)):
					selected_piece = piece_index
					hint_label.text = "Try piece %d at row %d, column %d" % [piece_index + 1, y + 1, x + 1]
					SaveManager.record_hint()
					render_pieces()
					return
	hint_label.text = "No placement found — undo or retry"

func complete_level() -> void:
	if completed: return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode: MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else: MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "LEVEL COMPLETE  •  %d ★" % stars
	PremiumVisuals.burst(Vector2(540, 850), Color("8b7cf6"), 26)
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.9).timeout
	finished.emit(-1 if daily_mode else level_number)

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func _save_checkpoint() -> void:
	if completed: return
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "cells": cells.duplicate(true), "pieces": pieces.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state, "history": history.duplicate(true)})

func _restore_checkpoint() -> void:
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode: return
	var saved_cells = checkpoint.get("cells", [])
	if saved_cells is Array and saved_cells.size() == GRID_SIZE:
		cells = saved_cells.duplicate(true)
		var saved_pieces = checkpoint.get("pieces", [])
		if saved_pieces is Array: pieces = saved_pieces.duplicate(true)
		selected_piece = int(checkpoint.get("selected", -1))
		score = maxi(0, int(checkpoint.get("score", 0)))
		lines_cleared = maxi(0, int(checkpoint.get("lines", 0)))
		placements = maxi(0, int(checkpoint.get("placements", 0)))
		piece_batch = maxi(0, int(checkpoint.get("batch", 0)))
		rng.state = int(checkpoint.get("rng_state", rng.state))
		var saved_history = checkpoint.get("history", [])
		if saved_history is Array: history = saved_history.duplicate(true)

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()
