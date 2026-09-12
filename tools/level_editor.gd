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
	for t in TYPES: type_option.add_item(t.capitalize())
	type_option.item_selected.connect(func(i): selected_type = TYPES[i])
	controls.add_child(type_option)
	var dir_option := OptionButton.new()
	for d in DIRECTIONS: dir_option.add_item(d.capitalize())
	dir_option.item_selected.connect(func(i): selected_direction = DIRECTIONS[i])
	controls.add_child(dir_option)
	var rescue_button := Button.new()
	rescue_button.text = "Place Rescue"
	rescue_button.pressed.connect(func(): selected_type = "rescue"; status.text = "Click a cell to place the rescue target.")
	controls.add_child(rescue_button)
	var clear := Button.new()
	clear.text = "Clear Board"
	clear.pressed.connect(func(): pieces.clear(); render())
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
	save_button.text = "Save JSON"
	save_button.pressed.connect(save_level)
	save_row.add_child(save_button)
	status = Label.new()
	status.text = "Choose a piece type, then click cells. Click an occupied cell to remove it."
	root.add_child(status)

func render() -> void:
	if grid == null: return
	for child in grid.get_children(): child.queue_free()
	grid.columns = board_width
	for y in range(board_height):
		for x in range(board_width):
			var pos := Vector2i(x, y)
			var b := Button.new()
			b.custom_minimum_size = Vector2(92, 92)
			b.add_theme_font_size_override("font_size", 24)
			if pos == rescue:
				b.text = "🐥"
			else:
				var idx := piece_at(pos)
				b.text = piece_label(pieces[idx]) if idx >= 0 else "·"
			b.pressed.connect(on_cell.bind(pos))
			grid.add_child(b)

func on_cell(pos: Vector2i) -> void:
	if selected_type == "rescue":
		var idx := piece_at(pos)
		if idx >= 0: pieces.remove_at(idx)
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
		if selected_type == "gate": p["key_id"] = "default"
		if selected_type == "key": p["key_id"] = "default"
		if selected_type == "linked": p["link_id"] = "pair"
		pieces.append(p)
	render()

func piece_at(pos: Vector2i) -> int:
	for i in range(pieces.size()):
		if int(pieces[i].get("x", -1)) == pos.x and int(pieces[i].get("y", -1)) == pos.y: return i
	return -1

func piece_label(piece: Dictionary) -> String:
	var type := String(piece.get("type", "normal"))
	if type == "blocker": return "■"
	if type == "gate": return "▣"
	var arrow := String(ARROWS.get(String(piece.get("direction", "right")), "→"))
	match type:
		"rotate": return "⟳" + arrow
		"key": return "◆" + arrow
		"bomb": return "✹" + arrow
		"linked": return "◇" + arrow
		_: return arrow

func save_level() -> void:
	var payload := {
		"width": board_width,
		"height": board_height,
		"par_moves": max(2, pieces.size() / 2),
		"rescue_id": "chick",
		"rescue": [rescue.x, rescue.y],
		"pieces": pieces
	}
	var file := FileAccess.open(path_edit.text, FileAccess.WRITE)
	if file == null:
		status.text = "Could not write: " + path_edit.text
		return
	file.store_string(JSON.stringify(payload, "\t"))
	status.text = "Saved: " + path_edit.text
