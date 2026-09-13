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

var level_number: int = 1
var daily_mode: bool = false
var cells: Array = []
var cell_buttons: Array[Button] = []
var pieces: Array = []
var selected_piece: int = -1
var score: int = 0
var lines_cleared: int = 0
var placements: int = 0
var target_score: int = 80
var target_lines: int = 2
var par_placements: int = 18
var history: Array = []
var rng := RandomNumberGenerator.new()
var score_label: Label
var goal_label: Label
var status_label: Label
var hint_label: Label
var piece_row: HBoxContainer
var title_label: Label
var meta_label: Label
var completed: bool = false
var piece_batch: int = 0

func _ready() -> void:
	build_ui()
	load_level()

func difficulty() -> String:
	return MultiGameManager.difficulty_for_level(level_number)

func level_config() -> Dictionary:
	var world: int = MultiGameManager.world_for_level(level_number)
	var d: String = difficulty()
	var base: int = 55 + mini(100, world * 3)
	var lines: int = 1 + int(world / 12)
	var par: int = 20 + int(world / 15)
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

func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("071426"), Color("8b7cf6"), MultiGameManager.world_for_level(level_number) - 1)
	add_child(bg)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 36)
	outer.add_theme_constant_override("margin_right", 36)
	outer.add_theme_constant_override("margin_top", 48)
	outer.add_theme_constant_override("margin_bottom", 48)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 13)
	outer.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(140, 68)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 33)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(140, 68)
	retry.pressed.connect(restart_level)
	header.add_child(retry)
	meta_label = Label.new()
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 18)
	meta_label.modulate = Color("a8b8cf")
	root.add_child(meta_label)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 25)
	root.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 19)
	goal_label.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(goal_label)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	center.add_child(grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var button := Button.new()
			button.custom_minimum_size = Vector2(111, 111)
			button.add_theme_font_size_override("font_size", 42)
			button.pressed.connect(place_selected.bind(Vector2i(x, y)))
			grid.add_child(button)
			cell_buttons.append(button)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 14)
	root.add_child(piece_row)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "UNDO"
	undo.custom_minimum_size = Vector2(270, 72)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(270, 72)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.custom_minimum_size = Vector2(0, 38)
	root.add_child(hint_label)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(status_label)

func load_level() -> void:
	completed = false
	selected_piece = -1
	score = 0
	lines_cleared = 0
	placements = 0
	piece_batch = 0
	history.clear()
	var config: Dictionary = level_config()
	target_score = int(config.get("target_score", 80))
	target_lines = int(config.get("target_lines", 2))
	par_placements = int(config.get("par", 18))
	title_label.text = "DAILY BLOCK PUZZLE" if daily_mode else "BLOCK PUZZLE  •  LEVEL %04d" % level_number
	meta_label.text = "%s  •  %s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_name(GAME_ID, MultiGameManager.world_for_level(level_number)).to_upper(), MultiGameManager.world_for_level(level_number)]
	rng.seed = level_number * 104729 + (1 if daily_mode else 0)
	cells.clear()
	for _y in range(GRID_SIZE):
		var row: Array = []
		for _x in range(GRID_SIZE):
			row.append(false)
		cells.append(row)
	refill_pieces()
	_restore_checkpoint()
	render()
	AnalyticsManager.track("block_puzzle_level_started", {"level": level_number, "difficulty": difficulty(), "daily": daily_mode})

func refill_pieces() -> void:
	pieces.clear()
	piece_batch += 1
	for _i in range(3):
		var max_shape: int = SHAPES.size() - 1
		if difficulty() == "easy":
			max_shape = 5
		elif difficulty() == "medium":
			max_shape = 7
		pieces.append(SHAPES[rng.randi_range(0, max_shape)].duplicate())
	selected_piece = -1

func render() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index: int = y * GRID_SIZE + x
			cell_buttons[index].text = "■" if bool(cells[y][x]) else ""
			cell_buttons[index].add_theme_color_override("font_color", Color("8b7cf6"))
	score_label.text = "SCORE %d / %d   •   LINES %d / %d" % [score, target_score, lines_cleared, target_lines]
	goal_label.text = "PLACEMENTS %d  •  PERFECT ≤ %d" % [placements, par_placements]
	render_pieces()

func render_pieces() -> void:
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(290, 145)
		button.text = shape_text(pieces[i])
		button.add_theme_font_size_override("font_size", 24)
		button.disabled = pieces[i].is_empty()
		button.modulate = Color(1.16, 1.16, 1.16) if i == selected_piece else Color.WHITE
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func shape_text(shape: Array) -> String:
	if shape.is_empty():
		return "USED"
	var max_x: int = 0
	var max_y: int = 0
	for point in shape:
		var p: Vector2i = point
		max_x = maxi(max_x, p.x)
		max_y = maxi(max_y, p.y)
	var lines: Array[String] = []
	for y in range(max_y + 1):
		var line := ""
		for x in range(max_x + 1):
			line += "■ " if Vector2i(x, y) in shape else "  "
		lines.append(line)
	return "\n".join(lines)

func select_piece(index: int) -> void:
	if completed or pieces[index].is_empty():
		return
	selected_piece = index
	status_label.text = ""
	hint_label.text = "Tap the grid to place it"
	render_pieces()

func place_selected(origin: Vector2i) -> void:
	if completed:
		return
	if selected_piece < 0 or selected_piece >= pieces.size():
		status_label.text = "Choose a piece first"
		return
	var shape: Array = pieces[selected_piece]
	if not can_place(shape, origin):
		status_label.text = "That piece does not fit there"
		return
	history.append({"cells": cells.duplicate(true), "pieces": pieces.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state})
	for point in shape:
		var p: Vector2i = point
		cells[origin.y + p.y][origin.x + p.x] = true
	score += shape.size()
	placements += 1
	pieces[selected_piece] = []
	selected_piece = -1
	var cleared: int = clear_lines()
	if cleared > 0:
		lines_cleared += cleared
		score += cleared * 20
		status_label.text = "%d LINE%s CLEARED" % [cleared, "S" if cleared != 1 else ""]
	else:
		status_label.text = ""
	if reached_goal():
		render()
		complete_level()
		return
	if all_pieces_used():
		refill_pieces()
	render()
	_save_checkpoint()
	if not any_move_available():
		status_label.text = "NO MOVES — UNDO, HINT OR RETRY"

func can_place(shape: Array, origin: Vector2i) -> bool:
	for point in shape:
		var p: Vector2i = point
		var x: int = origin.x + p.x
		var y: int = origin.y + p.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE or bool(cells[y][x]):
			return false
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
	for y in full_rows:
		for x in range(GRID_SIZE):
			cells[y][x] = false
	for x in full_cols:
		for y in range(GRID_SIZE):
			cells[y][x] = false
	return full_rows.size() + full_cols.size()

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
	cells = (state.get("cells", []) as Array).duplicate(true)
	pieces = (state.get("pieces", []) as Array).duplicate(true)
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
					hint_label.text = "Try piece %d at row %d, column %d" % [piece_index + 1, y + 1, x + 1]
					SaveManager.record_hint()
					render_pieces()
					return
	hint_label.text = "No placement found — undo or retry"

func complete_level() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars: int = 3 if placements <= par_placements else (2 if placements <= par_placements + 6 else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 30)
	status_label.text = "LEVEL COMPLETE  •  %d ★" % stars
	AnalyticsManager.track("block_puzzle_completed", {"level": level_number, "score": score, "lines": lines_cleared, "placements": placements, "stars": stars, "daily": daily_mode})
	await get_tree().create_timer(0.9).timeout
	finished.emit(-1 if daily_mode else level_number)

func restart_level() -> void:
	MultiGameManager.clear_checkpoint(GAME_ID)
	load_level()

func _save_checkpoint() -> void:
	if completed:
		return
	MultiGameManager.save_checkpoint(GAME_ID, {"level": level_number, "daily": daily_mode, "cells": cells.duplicate(true), "pieces": pieces.duplicate(true), "selected": selected_piece, "score": score, "lines": lines_cleared, "placements": placements, "batch": piece_batch, "rng_state": rng.state, "history": history.duplicate(true)})

func _restore_checkpoint() -> void:
	var checkpoint: Dictionary = MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	var saved_cells = checkpoint.get("cells", [])
	if saved_cells is Array and saved_cells.size() == GRID_SIZE:
		cells = saved_cells.duplicate(true)
		var saved_pieces = checkpoint.get("pieces", [])
		if saved_pieces is Array:
			pieces = saved_pieces.duplicate(true)
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