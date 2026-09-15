extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "block_puzzle"
const GRID_SIZE := 8

var level_number := 1
var daily_mode := false
var cells: Array = []
var cell_colors: Array = []
var pieces: Array = []
var piece_colors: Array = []
var selected_piece := -1
var score := 0
var lines_cleared := 0
var placements := 0
var piece_batch := 0
var target_score := 80
var target_lines := 2
var par_placements := 18
var history: Array = []
var rng := RandomNumberGenerator.new()
var completed := false

var board_grid: GridContainer
var piece_row: HBoxContainer
var cell_buttons: Array = []
var score_label: Label
var goal_label: Label
var status_label: Label
var hint_label: Label
var title_label: Label
var board_shell: PanelContainer
var effects_layer: Control

const BASE_SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0),Vector2i(1,0)],
	[Vector2i(0,0),Vector2i(0,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]
]

func _ready() -> void:
	build_ui()
	load_level()

func difficulty() -> String:
	return MultiGameManager.difficulty_for_level(level_number)

func level_config() -> Dictionary:
	if not daily_mode and level_number <= 2:
		return {"target_score": 20 + level_number * 15, "target_lines": 0, "par": 6}
	if not daily_mode and level_number <= 5:
		return {"target_score": 55 + level_number * 8, "target_lines": 1, "par": 11}
	if not daily_mode and level_number <= 10:
		return {"target_score": 105 + level_number * 4, "target_lines": 1, "par": 15}
	var world := MultiGameManager.world_for_level(level_number)
	var base := 70 + mini(140, world * 4)
	var lines := 2 + int(world / 10)
	var par := 18 + int(world / 18)
	match difficulty():
		"easy": base = int(base * 0.82); lines = maxi(1, lines - 2); par += 5
		"hard": base = int(base * 1.25); lines += 2
		"milestone": base = int(base * 1.48); lines += 3
		"boss": base = int(base * 1.78); lines += 5
	return {"target_score": base, "target_lines": mini(16, lines), "par": par}

func style_box(color: Color, radius: int = 24, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 0) -> StyleBoxFlat:
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
		s.shadow_color = Color(0, 0, 0, 0.25)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, 6)
	return s

func style_small_button(button: Button) -> void:
	button.flat = false
	button.add_theme_stylebox_override("normal", style_box(Color("304f9c"), 22, Color("ffffff22"), 1, 5))
	button.add_theme_stylebox_override("hover", style_box(Color("3b61bd"), 22, Color("ffffff3a"), 2, 7))
	button.add_theme_stylebox_override("pressed", style_box(Color("264483"), 22, Color.WHITE, 2, 2))
	button.add_theme_color_override("font_color", Color.WHITE)

func build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("405ca8")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 32)
	outer.add_theme_constant_override("margin_bottom", 32)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	outer.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var back := Button.new()
	back.text = "← BACK"
	back.custom_minimum_size = Vector2(210, 86)
	style_small_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻ RETRY"
	retry.custom_minimum_size = Vector2(190, 86)
	style_small_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var score_card := PanelContainer.new()
	score_card.add_theme_stylebox_override("panel", style_box(Color("304a94aa"), 26, Color("ffffff20"), 1, 4))
	root.add_child(score_card)
	var score_box := VBoxContainer.new()
	score_card.add_child(score_box)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 38)
	score_box.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 18)
	score_box.add_child(goal_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board_shell = PanelContainer.new()
	board_shell.add_theme_stylebox_override("panel", style_box(Color("111936"), 8, Color("080d22"), 4, 12))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 8)
	board_margin.add_theme_constant_override("margin_right", 8)
	board_margin.add_theme_constant_override("margin_top", 8)
	board_margin.add_theme_constant_override("margin_bottom", 8)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 2)
	board_grid.add_theme_constant_override("v_separation", 2)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := BlockCellButton.new()
			cell.custom_minimum_size = Vector2(96, 96)
			cell.configure(false, false, Color("466df2"), y * GRID_SIZE + x)
			cell.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(cell)
			cell_buttons.append(cell)

	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel", style_box(Color("304a9477"), 28, Color("ffffff22"), 1, 5))
	root.add_child(tray)
	var tray_box := VBoxContainer.new()
	tray.add_child(tray_box)
	var tray_title := Label.new()
	tray_title.text = "DRAG A BLOCK ONTO THE BOARD"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 18)
	tray_box.add_child(tray_title)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 24)
	piece_row.custom_minimum_size = Vector2(0, 158)
	tray_box.add_child(piece_row)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	root.add_child(hint_label)

	effects_layer = Control.new()
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)

func load_level() -> void:
	completed = false
	selected_piece = -1
	score = 0
	lines_cleared = 0
	placements = 0
	piece_batch = 0
	history.clear()
	status_label.text = ""
	hint_label.text = "Release when the placement preview locks into place"
	var config := level_config()
	target_score = int(config.get("target_score", 80))
	target_lines = int(config.get("target_lines", 2))
	par_placements = int(config.get("par", 18))
	title_label.text = "DAILY" if daily_mode else "LEVEL %d" % level_number
	rng.seed = level_number * 104729 + (1 if daily_mode else 0)
	cells.clear()
	cell_colors.clear()
	for _y in range(GRID_SIZE):
		var row: Array = []
		var color_row: Array = []
		for _x in range(GRID_SIZE):
			row.append(false)
			color_row.append(Color.TRANSPARENT)
		cells.append(row)
		cell_colors.append(color_row)
	refill_pieces()
	_restore_checkpoint()
	render()
	AnalyticsManager.track("block_puzzle_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func refill_pieces() -> void:
	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	for i in range(3):
		var shape_index := rng.randi_range(0, BASE_SHAPES.size() - 1)
		pieces.append((BASE_SHAPES[shape_index] as Array).duplicate())
		piece_colors.append([Color("8b7cf6"), Color("5da9ff"), Color("2dd4b6")][i])
	selected_piece = -1

func render() -> void:
	score_label.text = str(score)
	goal_label.text = "CLEAR %d/%d LINES  •  TARGET %d" % [lines_cleared, target_lines, target_score]
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			var button := cell_buttons[index] as BlockCellButton
			button.configure(bool(cells[y][x]), false, cell_colors[y][x], index)
	render_pieces()

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := BlockPieceButton.new()
		button.custom_minimum_size = Vector2(230, 132)
		button.configure(pieces[i], i == selected_piece, piece_colors[i], i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func select_piece(index: int) -> void:
	if completed or index < 0 or index >= pieces.size() or pieces[index].is_empty():
		return
	selected_piece = index
	status_label.text = "Choose a highlighted placement"
	render()

func can_place(shape: Array, origin: Vector2i) -> bool:
	for raw in shape:
		var point := _as_point(raw)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
			return false
		if bool(cells[y][x]):
			return false
	return true

func place_selected(origin: Vector2i) -> void:
	if selected_piece < 0 or selected_piece >= pieces.size():
		return
	place_piece_from_drag(selected_piece, origin)

func place_piece_from_drag(piece_index: int, origin: Vector2i) -> void:
	if completed or piece_index < 0 or piece_index >= pieces.size():
		return
	var shape: Array = pieces[piece_index]
	if shape.is_empty() or not can_place(shape, origin):
		status_label.text = "That block does not fit there"
		return
	history.append(_snapshot())
	for raw in shape:
		var point := _as_point(raw)
		cells[origin.y + point.y][origin.x + point.x] = true
		cell_colors[origin.y + point.y][origin.x + point.x] = piece_colors[piece_index]
	pieces[piece_index] = []
	placements += 1
	score += shape.size() * 5
	_clear_completed_lines()
	if _all_pieces_used():
		refill_pieces()
	status_label.text = ""
	render()
	_save_checkpoint()
	_check_completion()

func _clear_completed_lines() -> void:
	var rows: Array[int] = []
	var columns: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			full = full and bool(cells[y][x])
		if full: rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			full = full and bool(cells[y][x])
		if full: columns.append(x)
	if rows.is_empty() and columns.is_empty():
		return
	for y in rows:
		for x in range(GRID_SIZE):
			cells[y][x] = false
			cell_colors[y][x] = Color.TRANSPARENT
	for x in columns:
		for y in range(GRID_SIZE):
			cells[y][x] = false
			cell_colors[y][x] = Color.TRANSPARENT
	var cleared := rows.size() + columns.size()
	lines_cleared += cleared
	score += cleared * 40
	PremiumVisuals.screen_flash(Color("8b7cf6"), 0.10)

func _all_pieces_used() -> bool:
	for shape in pieces:
		if not shape.is_empty():
			return false
	return true

func any_move_available() -> bool:
	for shape in pieces:
		if shape.is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)):
					return true
	return false

func _check_completion() -> void:
	if score >= target_score and lines_cleared >= target_lines:
		completed = true
		MultiGameManager.complete_level(GAME_ID, level_number, score, placements, daily_mode)
		finished.emit(level_number)
	elif not any_move_available():
		status_label.text = "No moves — retry or undo"

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func undo_move() -> void:
	if history.is_empty():
		return
	_restore_snapshot(history.pop_back())
	render()
	_save_checkpoint()

func show_hint() -> void:
	for i in range(pieces.size()):
		var shape: Array = pieces[i]
		if shape.is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)):
					selected_piece = i
					status_label.text = "Try the highlighted block near row %d, column %d" % [y + 1, x + 1]
					render()
					return

func _snapshot() -> Dictionary:
	return {"cells": cells.duplicate(true), "colors": cell_colors.duplicate(true), "pieces": pieces.duplicate(true), "piece_colors": piece_colors.duplicate(true), "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch}

func _restore_snapshot(snapshot: Dictionary) -> void:
	cells = snapshot.get("cells", []).duplicate(true)
	cell_colors = snapshot.get("colors", []).duplicate(true)
	pieces = snapshot.get("pieces", []).duplicate(true)
	piece_colors = snapshot.get("piece_colors", []).duplicate(true)
	score = int(snapshot.get("score", 0))
	lines_cleared = int(snapshot.get("lines", 0))
	placements = int(snapshot.get("placements", 0))
	piece_batch = int(snapshot.get("batch", 0))

func _save_checkpoint() -> void:
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "state": _snapshot()})

func _restore_checkpoint() -> void:
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty():
		return
	if int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	var state: Dictionary = checkpoint.get("state", {})
	if not state.is_empty():
		_restore_snapshot(state)

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i: return raw
	if raw is Vector2: return Vector2i(raw)
	if raw is Array and raw.size() >= 2: return Vector2i(int(raw[0]), int(raw[1]))
	if raw is Dictionary: return Vector2i(int(raw.get("x", 0)), int(raw.get("y", 0)))
	return Vector2i.ZERO
