extends Control

signal finished(level_number: int)
signal quit_requested

var level_number := 1
var level_data: Dictionary = {}
var width := 5
var height := 5
var moves := 0
var par_moves := 8
var rescue_id := "chick"
var rescue_pos := Vector2i.ZERO
var rescued := false
var pieces: Array[Dictionary] = []
var history: Array[Dictionary] = []
var chain_count := 0

var board_grid: GridContainer
var moves_label: Label
var chain_label: Label
var rescue_label: Label
var hint_label: Label

const DIRECTIONS := {
	"up": Vector2i.UP,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
	"right": Vector2i.RIGHT
}
const ARROWS := {"up":"↑", "down":"↓", "left":"←", "right":"→"}

func _ready() -> void:
	level_data = LevelManager.load_level(level_number)
	if level_data.is_empty():
		quit_requested.emit()
		queue_free()
		return
	width = int(level_data.get("width", 5))
	height = int(level_data.get("height", 5))
	par_moves = int(level_data.get("par_moves", 8))
	rescue_id = String(level_data.get("rescue_id", "chick"))
	var rp: Array = level_data.get("rescue", [2, 2])
	rescue_pos = Vector2i(int(rp[0]), int(rp[1]))
	pieces.clear()
	for raw_piece in level_data.get("pieces", []):
		var p: Dictionary = raw_piece.duplicate(true)
		p["active"] = bool(p.get("active", true))
		pieces.append(p)
	build_ui()
	render_board()

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0a1327")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 50)
	outer.add_theme_constant_override("margin_right", 50)
	outer.add_theme_constant_override("margin_top", 70)
	outer.add_theme_constant_override("margin_bottom", 70)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	outer.add_child(root)

	var top := HBoxContainer.new()
	var quit := Button.new()
	quit.text = "←"
	quit.custom_minimum_size = Vector2(90, 70)
	quit.add_theme_font_size_override("font_size", 32)
	quit.pressed.connect(_quit)
	top.add_child(quit)

	var title := Label.new()
	title.text = "LEVEL %02d" % level_number
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	top.add_child(title)

	var restart := Button.new()
	restart.text = "↻"
	restart.custom_minimum_size = Vector2(90, 70)
	restart.add_theme_font_size_override("font_size", 32)
	restart.pressed.connect(restart_level)
	top.add_child(restart)
	root.add_child(top)

	var status := HBoxContainer.new()
	moves_label = Label.new()
	moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_label.add_theme_font_size_override("font_size", 24)
	status.add_child(moves_label)
	rescue_label = Label.new()
	rescue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rescue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_label.add_theme_font_size_override("font_size", 24)
	status.add_child(rescue_label)
	chain_label = Label.new()
	chain_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chain_label.add_theme_font_size_override("font_size", 24)
	status.add_child(chain_label)
	root.add_child(status)

	var board_holder := CenterContainer.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(board_holder)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 10)
	board_grid.add_theme_constant_override("v_separation", 10)
	board_holder.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	var undo := Button.new()
	undo.text = "UNDO"
	undo.custom_minimum_size = Vector2(260, 82)
	undo.add_theme_font_size_override("font_size", 24)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(260, 82)
	hint.add_theme_font_size_override("font_size", 24)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	root.add_child(actions)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 21)
	root.add_child(hint_label)

func render_board() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	moves_label.text = "MOVES  %d / %d" % [moves, par_moves]
	rescue_label.text = ("SAFE! " if rescued else "RESCUE ") + rescue_id.capitalize()
	chain_label.text = "CHAIN x%d" % chain_count if chain_count > 1 else ""

	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(150, 150)
			button.add_theme_font_size_override("font_size", 46)
			var piece_index := get_piece_index_at(pos)
			if not rescued and pos == rescue_pos:
				button.text = rescue_icon()
				button.disabled = true
			elif piece_index >= 0:
				var piece := pieces[piece_index]
				button.text = piece_text(piece)
				button.tooltip_text = String(piece.get("type", "normal")).capitalize()
				button.pressed.connect(try_move.bind(piece_index))
			else:
				button.text = "·"
				button.disabled = true
			board_grid.add_child(button)

func rescue_icon() -> String:
	match rescue_id:
		"puppy": return "🐶"
		"kitten": return "🐱"
		"robot": return "🤖"
		"slime": return "🟢"
		"panda": return "🐼"
		"fox": return "🦊"
		"alien": return "👽"
		_: return "🐥"

func piece_text(piece: Dictionary) -> String:
	var type := String(piece.get("type", "normal"))
	var direction := String(piece.get("direction", "right"))
	var arrow := String(ARROWS.get(direction, "→"))
	match type:
		"rotate": return "⟳" + arrow
		"key": return "🔑" + arrow
		"gate": return "▣"
		"bomb": return "✹" + arrow
		"linked": return "◇" + arrow
		"blocker": return "■"
		_: return arrow

func get_piece_index_at(pos: Vector2i) -> int:
	for i in range(pieces.size()):
		var p := pieces[i]
		if not bool(p.get("active", true)):
			continue
		if Vector2i(int(p.get("x", -1)), int(p.get("y", -1))) == pos:
			return i
	return -1

func piece_position(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", 0)), int(piece.get("y", 0)))

func is_path_clear(index: int) -> bool:
	if index < 0 or index >= pieces.size():
		return false
	var piece := pieces[index]
	if not bool(piece.get("active", true)):
		return false
	var type := String(piece.get("type", "normal"))
	if type in ["blocker", "gate"]:
		return false
	var direction: Vector2i = DIRECTIONS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var pos := piece_position(piece) + direction
	while is_inside(pos):
		if not rescued and pos == rescue_pos:
			return false
		if get_piece_index_at(pos) >= 0:
			return false
		pos += direction
	return true

func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

func snapshot() -> Dictionary:
	return {
		"pieces": pieces.duplicate(true),
		"moves": moves,
		"rescued": rescued,
		"chain": chain_count
	}

func try_move(index: int) -> void:
	hint_label.text = ""
	if not is_path_clear(index):
		chain_count = 0
		hint_label.text = "Blocked — clear its path first."
		return
	history.append(snapshot())
	moves += 1
	chain_count = 1
	escape_piece(index, true)
	resolve_rescue()
	render_board()

func escape_piece(index: int, trigger_effect: bool) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	var piece := pieces[index]
	pieces[index]["active"] = false
	if not trigger_effect:
		return
	match String(piece.get("type", "normal")):
		"rotate": rotate_neighbors(piece_position(piece))
		"key": open_gates(String(piece.get("key_id", "default")))
		"bomb": explode_at(piece_position(piece))
		"linked": activate_link(String(piece.get("link_id", "")), index)

func rotate_neighbors(center: Vector2i) -> void:
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var idx := get_piece_index_at(center + dir)
		if idx >= 0:
			var type := String(pieces[idx].get("type", "normal"))
			if type not in ["blocker", "gate"]:
				pieces[idx]["direction"] = rotate_direction(String(pieces[idx].get("direction", "right")))

func rotate_direction(direction: String) -> String:
	match direction:
		"up": return "right"
		"right": return "down"
		"down": return "left"
		_: return "up"

func open_gates(key_id: String) -> void:
	for i in range(pieces.size()):
		if bool(pieces[i].get("active", true)) and String(pieces[i].get("type", "")) == "gate" and String(pieces[i].get("key_id", "default")) == key_id:
			pieces[i]["active"] = false
			chain_count += 1

func explode_at(center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var idx := get_piece_index_at(Vector2i(x, y))
			if idx >= 0 and String(pieces[idx].get("type", "")) != "gate":
				pieces[idx]["active"] = false
				chain_count += 1

func activate_link(link_id: String, source_index: int) -> void:
	if link_id.is_empty():
		return
	for i in range(pieces.size()):
		if i == source_index or not bool(pieces[i].get("active", true)):
			continue
		if String(pieces[i].get("type", "")) == "linked" and String(pieces[i].get("link_id", "")) == link_id:
			if is_path_clear(i):
				pieces[i]["active"] = false
				chain_count += 1
			else:
				pieces[i]["direction"] = rotate_direction(String(pieces[i].get("direction", "right")))

func rescue_has_exit() -> bool:
	if rescued:
		return true
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var pos := rescue_pos + direction
		var blocked := false
		while is_inside(pos):
			if get_piece_index_at(pos) >= 0:
				blocked = true
				break
			pos += direction
		if not blocked:
			return true
	return false

func resolve_rescue() -> void:
	if rescue_has_exit():
		rescued = true
		chain_count += 1
		complete_level()

func complete_level() -> void:
	var stars := 3
	if moves > par_moves:
		stars = 2
	if moves > par_moves + 3:
		stars = 1
	SaveManager.complete_level(level_number, stars, rescue_id, 25 * stars)
	show_result(stars)

func show_result(stars: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.04, 0.08, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-300, -360)
	box.custom_minimum_size = Vector2(600, 720)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	overlay.add_child(box)
	var icon := Label.new()
	icon.text = rescue_icon()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 96)
	box.add_child(icon)
	var title := Label.new()
	title.text = "RESCUED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	box.add_child(title)
	var star_label := Label.new()
	star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 58)
	box.add_child(star_label)
	var stats := Label.new()
	stats.text = "%d moves  •  +%d coins" % [moves, 25 * stars]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 24)
	box.add_child(stats)
	var next := Button.new()
	next.text = "NEXT RESCUE"
	next.custom_minimum_size = Vector2(430, 90)
	next.add_theme_font_size_override("font_size", 28)
	next.pressed.connect(func(): finished.emit(level_number); queue_free())
	box.add_child(next)

func undo_move() -> void:
	if history.is_empty() or rescued:
		return
	var state := history.pop_back()
	pieces = state.pieces.duplicate(true)
	moves = int(state.moves)
	rescued = bool(state.rescued)
	chain_count = int(state.chain)
	hint_label.text = "Move undone."
	render_board()

func show_hint() -> void:
	for i in range(pieces.size()):
		if is_path_clear(i):
			var p := pieces[i]
		hint_label.text = "Try the %s piece at row %d, column %d." % [String(p.get("type", "normal")), int(p.get("y", 0)) + 1, int(p.get("x", 0)) + 1]
			return
	hint_label.text = "No direct escape is available. Restart or undo and try another order."

func restart_level() -> void:
	var replacement := load("res://scenes/Game.tscn").instantiate()
	replacement.level_number = level_number
	replacement.finished.connect(func(n): finished.emit(n))
	replacement.quit_requested.connect(func(): quit_requested.emit())
	get_parent().add_child(replacement)
	queue_free()

func _quit() -> void:
	quit_requested.emit()
	queue_free()
