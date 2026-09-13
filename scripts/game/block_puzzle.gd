extends Control

signal quit_requested

const GRID_SIZE := 8
const SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)]
]

var cells: Array = []
var cell_buttons: Array[Button] = []
var pieces: Array = []
var selected_piece := -1
var score := 0
var best := 0
var score_label: Label
var status_label: Label
var piece_row: HBoxContainer

func _ready() -> void:
	build_ui()
	new_game()

func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("071426")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-500, -850)
	root.custom_minimum_size = Vector2(1000, 1700)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var back := Button.new()
	back.text = "← HOME"
	back.custom_minimum_size = Vector2(210, 76)
	back.pressed.connect(func(): quit_requested.emit())
	header.add_child(back)
	var title := Label.new()
	title.text = "BLOCK PUZZLE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	header.add_child(title)
	var restart := Button.new()
	restart.text = "NEW"
	restart.custom_minimum_size = Vector2(170, 76)
	restart.pressed.connect(new_game)
	header.add_child(restart)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 28)
	root.add_child(score_label)

	var help := Label.new()
	help.text = "Choose a piece, then tap the board to place it.\nFill a complete row or column to clear it."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 21)
	help.modulate = Color("a8b8cf")
	root.add_child(help)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	root.add_child(grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var button := Button.new()
			button.custom_minimum_size = Vector2(102, 102)
			button.add_theme_font_size_override("font_size", 44)
			button.pressed.connect(place_selected.bind(Vector2i(x, y)))
			grid.add_child(button)
			cell_buttons.append(button)

	var pieces_title := Label.new()
	pieces_title.text = "PIECES"
	pieces_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pieces_title.add_theme_font_size_override("font_size", 24)
	root.add_child(pieces_title)

	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 20)
	root.add_child(piece_row)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(status_label)

func new_game() -> void:
	cells.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for _x in range(GRID_SIZE):
			row.append(false)
		cells.append(row)
	score = 0
	selected_piece = -1
	status_label.text = ""
	refill_pieces()
	render()

func refill_pieces() -> void:
	pieces.clear()
	for _i in range(3):
		pieces.append(SHAPES[randi_range(0, SHAPES.size() - 1)].duplicate())
	selected_piece = -1
	render_pieces()

func render() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			cell_buttons[index].text = "■" if bool(cells[y][x]) else ""
			cell_buttons[index].add_theme_color_override("font_color", Color("5da9ff"))
	score_label.text = "SCORE  %d    •    BEST  %d" % [score, best]
	render_pieces()

func render_pieces() -> void:
	if piece_row == null:
		return
	for child in piece_row.get_children():
		child.queue_free()
	for i in range(pieces.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(280, 170)
		button.text = shape_text(pieces[i])
		button.add_theme_font_size_override("font_size", 28)
		button.disabled = pieces[i].is_empty()
		button.modulate = Color(1.15,1.15,1.15) if i == selected_piece else Color.WHITE
		button.pressed.connect(select_piece.bind(i))
		piece_row.add_child(button)

func shape_text(shape: Array) -> String:
	if shape.is_empty():
		return "USED"
	var max_x := 0
	var max_y := 0
	for point in shape:
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	var lines: Array[String] = []
	for y in range(max_y + 1):
		var line := ""
		for x in range(max_x + 1):
			line += "■ " if Vector2i(x,y) in shape else "  "
		lines.append(line)
	return "\n".join(lines)

func select_piece(index: int) -> void:
	if pieces[index].is_empty():
		return
	selected_piece = index
	status_label.text = "Tap a board cell to place this piece"
	render_pieces()

func place_selected(origin: Vector2i) -> void:
	if selected_piece < 0 or selected_piece >= pieces.size():
		status_label.text = "Choose a piece first"
		return
	var shape: Array = pieces[selected_piece]
	if not can_place(shape, origin):
		status_label.text = "That piece does not fit there"
		return
	for point in shape:
		cells[origin.y + point.y][origin.x + point.x] = true
	score += shape.size()
	pieces[selected_piece] = []
	selected_piece = -1
	var cleared := clear_lines()
	if cleared > 0:
		score += cleared * 20
		status_label.text = "%d LINE%s CLEARED!" % [cleared, "S" if cleared != 1 else ""]
	else:
		status_label.text = ""
	best = max(best, score)
	if all_pieces_used():
		refill_pieces()
	render()
	if not any_move_available():
		status_label.text = "GAME OVER  •  SCORE %d  •  TAP NEW TO TRY AGAIN" % score
		AnalyticsManager.track("block_puzzle_game_over", {"score": score})

func can_place(shape: Array, origin: Vector2i) -> bool:
	for point in shape:
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
			return false
		if bool(cells[y][x]):
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
				if can_place(shape, Vector2i(x,y)):
					return true
	return false
