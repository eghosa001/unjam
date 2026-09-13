@tool
extends Control

var board_width := 5
var board_height := 5
var rescue := Vector2i(2, 2)
var pieces: Array[Dictionary] = []
var selected_type := "normal"
var selected_direction := "right"
var grid: GridContainer
var status: Label
var path_edit: LineEdit

const TYPES := ["normal", "rotate", "key", "gate", "bomb", "linked", "blocker"]
const DIRECTIONS := ["up", "right", "down", "left"]
const ARROWS := {"up":"↑", "right":"→", "down":"↓", "left":"←"}
const LEVEL_ROOT := "res://data/levels/"

func _ready() -> void:
	build_ui()
	render()

func build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := Label.new()
	title.text = "UNJAM LEVEL EDITOR"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)
	var controls := HBoxContainer.new()
	root.add_child(controls)
	var type_option := OptionButton.new()
	for t in TYPES:
		type_option.add_item(t.capitalize())
	type_option.item_selected.connect(func(i): selected_type = TYPES[i])
	controls.add_child(type_option)
	var dir_option := OptionButton.new()
	for d in DIRECTIONS:
		dir_option.add_item(d.capitalize())
	dir_option.item_selected.connect(func(i): selected_direction = DIRECTIONS[i])
	controls.add_child(dir_option)
	var rescue_button := Button.new()
	rescue_button.text = "Place Rescue"
	rescue_button.pressed.connect(func():
		selected_type = "rescue"
		status.text = "Click a cell to place the rescue target."
	)
	controls.add_child(rescue_button)
	var clear := Button.new()
	clear.text = "Clear Board"
	clear.pressed.connect(func():
		pieces.clear()
		render()
	)
	controls.add_child(clear)
	grid = GridContainer.new()
	grid.columns = board_width
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid)
	var save_row := HBoxContainer.new()
	root.add_child(save_row)
	path_edit = LineEdit.new()
	path_edit.text = "res://data/levels/level_custom.json"
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(path_edit)
	var save_button := Button.new()
	save_button.text = "Validate & Save JSON"
	save_button.pressed.connect(save_level)
	save_row.add_child(save_button)
	status = Label.new()
	status.text = "Choose a piece type, then click cells. Click an occupied cell to remove it."
	root.add_child(status)

func render() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		child.queue_free()
	grid.columns = board_width
	for y in range(board_height):
		for x in range(board_width):
			var pos := Vector2i(x, y)
			var b := Button.new()
			b.custom_minimum_size = Vector2(92, 92)
			b.add_theme_font_size_override("font_size", 24)
			if pos == rescue:
				b.text = "RESCUE"
			else:
				var idx := piece_at(pos)
				b.text = piece_label(pieces[idx]) if idx >= 0 else "·"
			b.pressed.connect(on_cell.bind(pos))
			grid.add_child(b)

func on_cell(pos: Vector2i) -> void:
	if selected_type == "rescue":
		var idx := piece_at(pos)
		if idx >= 0:
			pieces.remove_at(idx)
		rescue = pos
		selected_type = "normal"
		render()
		return
	if pos == rescue:
		status.text = "Move the rescue target before placing a piece here."
		return
	var existing := piece_at(pos)
	if existing >= 0:
		pieces.remove_at(existing)
	else:
		var p := {"x": pos.x, "y": pos.y, "type": selected_type, "direction": selected_direction}
		if selected_type in ["gate", "key"]:
			p["key_id"] = "default"
		if selected_type == "linked":
			p["link_id"] = "pair"
		pieces.append(p)
	render()

func piece_at(pos: Vector2i) -> int:
	for i in range(pieces.size()):
		if int(pieces[i].get("x", -1)) == pos.x and int(pieces[i].get("y", -1)) == pos.y:
			return i
	return -1

func piece_label(piece: Dictionary) -> String:
	var type := String(piece.get("type", "normal"))
	if type == "blocker": return "BLOCK"
	if type == "gate": return "GATE"
	var arrow := String(ARROWS.get(String(piece.get("direction", "right")), "→"))
	match type:
		"rotate": return "ROT " + arrow
		"key": return "KEY " + arrow
		"bomb": return "BOMB " + arrow
		"linked": return "LINK " + arrow
		_: return arrow

func save_level() -> void:
	var destination := path_edit.text.strip_edges()
	if not destination.begins_with(LEVEL_ROOT) or not destination.ends_with(".json") or ".." in destination:
		status.text = "Save path must be a .json file inside res://data/levels/."
		return
	var payload := {
		"width": board_width,
		"height": board_height,
		"par_moves": maxi(2, int(pieces.size() / 2)),
		"rescue_id": "chick",
		"rescue": [rescue.x, rescue.y],
		"pieces": pieces
	}
	var solution: Array[int] = PuzzleSolver.find_solution(payload, [], 10000)
	var initially_open := _rescue_has_open_lane(payload)
	if solution.is_empty() and not initially_open:
		status.text = "Not saved: puzzle has no verified solution."
		return
	if not solution.is_empty():
		payload["par_moves"] = maxi(2, solution.size() + 1)
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		status.text = "Could not write: " + destination
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	status.text = "Validated and saved: %s%s" % [destination, "  •  solution %d moves" % solution.size() if not solution.is_empty() else ""]

func _rescue_has_open_lane(payload: Dictionary) -> bool:
	var occupied: Dictionary = {}
	for piece in payload.pieces:
		occupied[Vector2i(int(piece.x), int(piece.y))] = true
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction: Vector2i in directions:
		var pos: Vector2i = rescue + direction
		var blocked := false
		while pos.x >= 0 and pos.y >= 0 and pos.x < board_width and pos.y < board_height:
			if occupied.has(pos):
				blocked = true
				break
			pos += direction
		if not blocked:
			return true
	return false