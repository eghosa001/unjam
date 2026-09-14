extends Control

signal finished(level_number: int)
signal quit_requested

const GAME_ID := "block_puzzle"
const GRID_SIZE := 8
const CELL_SIZE := 92.0
const COLOR_PALETTE := [
	Color("39df63"), Color("466df2"), Color("ef4248"), Color("f4b83d"),
	Color("9d5add"), Color("35c9e8"), Color("ff8b3e")
]
const SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)]
]

var level_number := 1
var daily_mode := false
var cells: Array = []
var cell_colors: Array = []
var cell_buttons: Array[BlockCellButton] = []
var pieces: Array = []
var piece_colors: Array[Color] = []
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
var completed := false
var piece_batch := 0
var board_grid: GridContainer
var board_shell: Control
var effects_layer: Control

func _ready() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()
	load_level()

func difficulty() -> String:
	return MultiGameManager.difficulty_for_level(level_number)

func level_config() -> Dictionary:
	var world: int = int(MultiGameManager.world_for_level(level_number))
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

func style_box(color: Color, radius: int = 10, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 0) -> StyleBoxFlat:
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
		s.shadow_offset = Vector2(0, 5)
	return s

func style_small_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", style_box(Color("304a94cc"), 18, Color("ffffff22"), 1, 4))
	button.add_theme_stylebox_override("hover", style_box(Color("3b59a9"), 18, Color("ffffff44"), 1, 5))
	button.add_theme_stylebox_override("pressed", style_box(Color("263c7d"), 18, Color("ffffff66"), 1, 2))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 18)

func build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("405ca8")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	for i in range(20):
		var shard := ColorRect.new()
		shard.color = Color(1, 1, 1, 0.10 + float(i % 3) * 0.03)
		shard.size = Vector2(4 + (i % 3) * 2, 8 + (i % 4) * 3)
		shard.rotation = deg_to_rad(float((i * 17) % 60 - 30))
		shard.position = Vector2(35 + (i * 137) % 980, 100 + (i * 211) % 1550)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(shard)
		var drift := shard.create_tween().set_loops()
		drift.tween_property(shard, "position:y", shard.position.y + 38.0, 2.8 + float(i % 5) * 0.45)
		drift.tween_property(shard, "position:y", shard.position.y, 0.01)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	add_child(outer)
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var back := Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(74, 62)
	style_small_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(74, 62)
	style_small_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.30))
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 16)
	goal_label.add_theme_color_override("font_color", Color("dfe8ff"))
	root.add_child(goal_label)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board_shell = PanelContainer.new()
	board_shell.custom_minimum_size = Vector2(CELL_SIZE * GRID_SIZE + 18, CELL_SIZE * GRID_SIZE + 18)
	board_shell.add_theme_stylebox_override("panel", style_box(Color("151d3c"), 4, Color("0b1027"), 4, 9))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 7)
	board_margin.add_theme_constant_override("margin_right", 7)
	board_margin.add_theme_constant_override("margin_top", 7)
	board_margin.add_theme_constant_override("margin_bottom", 7)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 1)
	board_grid.add_theme_constant_override("v_separation", 1)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var button := BlockCellButton.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			button.configure(false, false, Color("466df2"), y * GRID_SIZE + x)
			button.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(button)
			cell_buttons.append(button)
	var spacer := Label.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	root.add_child(spacer)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 24)
	root.add_child(piece_row)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color("ffcf63"))
	status_label.custom_minimum_size = Vector2(0, 34)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color("d9e3ff"))
	hint_label.custom_minimum_size = Vector2(0, 26)
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
	hint_label.text = "Drag a block onto the board"
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
		var colors: Array = []
		for _x in range(GRID_SIZE):
			row.append(false)
			colors.append(Color.TRANSPARENT)
		cells.append(row)
		cell_colors.append(colors)
	refill_pieces()
	_restore_checkpoint()
	render()
	AnalyticsManager.track("block_puzzle_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func refill_pieces() -> void:
	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	for _i in range(3):
		var max_shape := SHAPES.size() - 1
		if difficulty() == "easy":
			max_shape = 7
		elif difficulty() == "medium":
			max_shape = 11
		var shape_index := rng.randi_range(0, max_shape)
		pieces.append(SHAPES[shape_index].duplicate())
		piece_colors.append(COLOR_PALETTE[rng.randi_range(0, COLOR_PALETTE.size() - 1)])
	selected_piece = -1
	if not any_move_available():
		pieces[0] = SHAPES[0].duplicate()

func render() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			var color: Color = cell_colors[y][x] if bool(cells[y][x]) else Color("466df2")
			cell_buttons[index].configure(bool(cells[y][x]), false, color, index)
	score_label.text = "%d" % score
	goal_label.text = "CLEAR %d/%d LINES  •  TARGET %d" % [lines_cleared, target_lines, target_score]
	render_pieces()

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := BlockPieceButton.new()
		button.custom_minimum_size = Vector2(260, 142)
		button.configure(pieces[i], i == selected_piece, piece_colors[i], i)
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func select_piece(index: int) -> void:
	if completed or index < 0 or index >= pieces.size() or pieces[index].is_empty():
		return
	selected_piece = index
	status_label.text = ""
	hint_label.text = "Drag to place"
	render_pieces()

func place_piece_from_drag(piece_index: int, origin: Vector2i) -> void:
	if completed or piece_index < 0 or piece_index >= pieces.size():
		return
	selected_piece = piece_index
	place_selected(origin)

func place_selected(origin: Vector2i) -> void:
	if completed:
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
	history.append({"cells": cells.duplicate(true), "cell_colors": cell_colors.duplicate(true), "pieces": pieces.duplicate(true), "piece_colors": piece_colors.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state})
	var placed_color: Color = piece_colors[selected_piece]
	for point in shape:
		var px: int = origin.x + int(point.x)
		var py: int = origin.y + int(point.y)
		cells[py][px] = true
		cell_colors[py][px] = placed_color
	_spawn_placement_feedback(shape, origin, placed_color)
	score += shape.size() * 10
	placements += 1
	pieces[selected_piece] = []
	selected_piece = -1
	var cleared := clear_lines()
	if cleared > 0:
		lines_cleared += cleared
		score += cleared * 40 + maxi(0, cleared - 1) * 20
	if reached_goal():
		render()
		complete_level()
		return
	if all_pieces_used():
		refill_pieces()
	render()
	_save_checkpoint()
	if not any_move_available():
		status_label.text = "NO MOVES"
		hint_label.text = "Retry this level"

func _invalid_bump() -> void:
	if board_shell == null:
		return
	var start := board_shell.position
	var tw := create_tween()
	tw.tween_property(board_shell, "position:x", start.x - 8.0, 0.035)
	tw.tween_property(board_shell, "position:x", start.x + 8.0, 0.055)
	tw.tween_property(board_shell, "position:x", start.x, 0.04)

func _spawn_placement_feedback(shape: Array, origin: Vector2i, color: Color) -> void:
	var order := 0
	for raw in shape:
		var point: Vector2i = raw
		var index := (origin.y + point.y) * GRID_SIZE + origin.x + point.x
		_spawn_cell_overlay(index, color, float(order) * 0.018)
		order += 1
	_spawn_score_popup("+%d" % (shape.size() * 10), color.lightened(0.22), 0.0)

func _spawn_cell_overlay(index: int, color: Color, delay: float) -> void:
	if index < 0 or index >= cell_buttons.size():
		return
	var cell := cell_buttons[index]
	var flash := Panel.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = cell.global_position
	flash.size = cell.size
	flash.pivot_offset = flash.size * 0.5
	flash.add_theme_stylebox_override("panel", style_box(Color(color, 0.58), 3, color.lightened(0.35), 2))
	effects_layer.add_child(flash)
	flash.scale = Vector2(0.62, 0.62)
	flash.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(flash, "modulate:a", 1.0, 0.04)
	tw.parallel().tween_property(flash, "scale", Vector2(1.08, 1.08), 0.085)
	tw.tween_property(flash, "scale", Vector2.ONE, 0.08)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.10)
	tw.finished.connect(flash.queue_free)

func clear_lines() -> int:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full:
			full_rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if not bool(cells[y][x]):
				full = false
				break
		if full:
			full_cols.append(x)
	if full_rows.is_empty() and full_cols.is_empty():
		return 0
	_spawn_clear_feedback(full_rows, full_cols)
	for y in full_rows:
		for x in range(GRID_SIZE):
			cells[y][x] = false
			cell_colors[y][x] = Color.TRANSPARENT
	for x in full_cols:
		for y in range(GRID_SIZE):
			cells[y][x] = false
			cell_colors[y][x] = Color.TRANSPARENT
	return full_rows.size() + full_cols.size()

func _spawn_clear_feedback(rows: Array[int], cols: Array[int]) -> void:
	var count := rows.size() + cols.size()
	var neon := Color("ff476f")
	for y in rows:
		_spawn_neon_line(true, y, neon)
	for x in cols:
		_spawn_neon_line(false, x, neon)
	var word := "Excellent!" if count == 1 else ("Amazing!" if count <= 3 else "Spectacular!")
	_spawn_score_popup(word, Color("ff665e"), 0.05, true)
	_spawn_score_popup("+%d" % (count * 40 + maxi(0, count - 1) * 20), Color("65e7ff"), 0.14)
	_spawn_particles(rows, cols, neon)

func _spawn_neon_line(horizontal: bool, index: int, neon: Color) -> void:
	var first_idx := index * GRID_SIZE if horizontal else index
	var last_idx := first_idx + (GRID_SIZE - 1 if horizontal else (GRID_SIZE - 1) * GRID_SIZE)
	var a := cell_buttons[first_idx]
	var b := cell_buttons[last_idx]
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = a.global_position - Vector2(3, 3)
	panel.size = Vector2((b.global_position.x + b.size.x) - a.global_position.x + 6, a.size.y + 6) if horizontal else Vector2(a.size.x + 6, (b.global_position.y + b.size.y) - a.global_position.y + 6)
	panel.add_theme_stylebox_override("panel", style_box(Color(neon, 0.06), 2, neon, 3, 5))
	effects_layer.add_child(panel)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.055)
	tw.tween_interval(0.12)
	tw.tween_property(panel, "modulate:a", 0.0, 0.24)
	tw.finished.connect(panel.queue_free)

func _spawn_particles(rows: Array[int], cols: Array[int], color: Color) -> void:
	var centers: Array[Vector2] = []
	for y in rows:
		centers.append((cell_buttons[y * GRID_SIZE].global_position + cell_buttons[y * GRID_SIZE + GRID_SIZE - 1].global_position) * 0.5 + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5))
	for x in cols:
		centers.append((cell_buttons[x].global_position + cell_buttons[(GRID_SIZE - 1) * GRID_SIZE + x].global_position) * 0.5 + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5))
	for center in centers:
		for i in range(18):
			var p := ColorRect.new()
			p.color = Color(color.lightened(float(i % 4) * 0.06), 0.9)
			p.size = Vector2(5 + i % 4, 5 + i % 3)
			p.position = center
			p.rotation = rng.randf_range(-0.7, 0.7)
			effects_layer.add_child(p)
			var direction := Vector2.from_angle(rng.randf_range(0, TAU))
			var distance := rng.randf_range(60.0, 220.0)
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(p, "position", center + direction * distance, rng.randf_range(0.28, 0.48))
			tw.parallel().tween_property(p, "modulate:a", 0.0, 0.48)
			tw.finished.connect(p.queue_free)

func _spawn_score_popup(text_value: String, color: Color, delay: float = 0.0, emphatic: bool = false) -> void:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(size.x * 0.5 - 260, size.y * 0.47)
	label.size = Vector2(520, 86)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 46 if emphatic else 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("4b1d2b" if emphatic else "23305e"))
	label.add_theme_constant_override("outline_size", 5 if emphatic else 3)
	label.modulate.a = 0.0
	label.scale = Vector2(0.68, 0.68)
	label.pivot_offset = label.size * 0.5
	effects_layer.add_child(label)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(label, "modulate:a", 1.0, 0.05)
	tw.parallel().tween_property(label, "scale", Vector2(1.18, 1.18), 0.10)
	tw.tween_property(label, "scale", Vector2.ONE, 0.08)
	tw.tween_property(label, "position:y", label.position.y - 82.0, 0.34).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.36)
	tw.finished.connect(label.queue_free)

func can_place(shape: Array, origin: Vector2i) -> bool:
	for point in shape:
		var x: int = origin.x + int(point.x)
		var y: int = origin.y + int(point.y)
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
			return false
		if bool(cells[y][x]):
			return false
	return true

func reached_goal() -> bool:
	return score >= target_score and lines_cleared >= target_lines

func all_pieces_used() -> bool:
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

func undo_move() -> void:
	if history.is_empty() or completed:
		return
	var state: Dictionary = history.pop_back()
	cells = state.get("cells", []).duplicate(true)
	cell_colors = state.get("cell_colors", []).duplicate(true)
	pieces = state.get("pieces", []).duplicate(true)
	piece_colors = state.get("piece_colors", []).duplicate(true)
	selected_piece = int(state.get("selected", -1))
	score = int(state.get("score", 0))
	lines_cleared = int(state.get("lines", 0))
	placements = int(state.get("placements", 0))
	piece_batch = int(state.get("batch", 0))
	rng.state = int(state.get("rng_state", rng.state))
	SaveManager.record_undo()
	render()
	_save_checkpoint()

func show_hint() -> void:
	if completed:
		return
	for piece_index in range(pieces.size()):
		var shape: Array = pieces[piece_index]
		if shape.is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)):
					selected_piece = piece_index
					hint_label.text = "Try the highlighted block near row %d, column %d" % [y + 1, x + 1]
					SaveManager.record_hint()
					render_pieces()
					return
	hint_label.text = "No placement found"

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
	status_label.text = "LEVEL COMPLETE  •  %d ★" % stars
	_spawn_score_popup("SPECTACULAR!", Color("ff665e"), 0.0, true)
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.9).timeout
	finished.emit(-1 if daily_mode else level_number)

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func _save_checkpoint() -> void:
	if completed:
		return
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "cells": cells.duplicate(true), "cell_colors": cell_colors.duplicate(true), "pieces": pieces.duplicate(true), "piece_colors": piece_colors.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state, "history": history.duplicate(true)})

func _restore_checkpoint() -> void:
	var checkpoint: Dictionary = MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	var saved_cells = checkpoint.get("cells", [])
	if saved_cells is Array and saved_cells.size() == GRID_SIZE:
		cells = saved_cells.duplicate(true)
		var saved_colors = checkpoint.get("cell_colors", [])
		if saved_colors is Array and saved_colors.size() == GRID_SIZE:
			cell_colors = saved_colors.duplicate(true)
		var saved_pieces = checkpoint.get("pieces", [])
		if saved_pieces is Array:
			pieces = saved_pieces.duplicate(true)
		var saved_piece_colors = checkpoint.get("piece_colors", [])
		if saved_piece_colors is Array and saved_piece_colors.size() == pieces.size():
			piece_colors = saved_piece_colors.duplicate(true)
		selected_piece = int(checkpoint.get("selected", -1))
		score = maxi(0, int(checkpoint.get("score", 0)))
		lines_cleared = maxi(0, int(checkpoint.get("lines", 0)))
		placements = maxi(0, int(checkpoint.get("placements", 0)))
		piece_batch = maxi(0, int(checkpoint.get("batch", 0)))
		rng.state = int(checkpoint.get("rng_state", rng.state))
		var saved_history = checkpoint.get("history", [])
		if saved_history is Array:
			history = saved_history.duplicate(true)

func _quit() -> void:
	_save_checkpoint()
	quit_requested.emit()
