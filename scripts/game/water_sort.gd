extends Control

signal quit_requested

const CAPACITY := 4
const COLORS := [Color("ff6b7a"), Color("5da9ff"), Color("ffd166"), Color("57d69a")]

var tubes: Array = []
var selected := -1
var moves := 0
var board: HBoxContainer
var move_label: Label
var status_label: Label

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
	root.position = Vector2(-500, -820)
	root.custom_minimum_size = Vector2(1000, 1640)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 28)
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
	title.text = "WATER SORT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	header.add_child(title)
	var restart := Button.new()
	restart.text = "NEW"
	restart.custom_minimum_size = Vector2(170, 76)
	restart.pressed.connect(new_game)
	header.add_child(restart)

	var help := Label.new()
	help.text = "Tap a tube, then tap another tube to pour matching colors.\nComplete every color into its own tube."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 22)
	help.modulate = Color("a8b8cf")
	root.add_child(help)

	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 24)
	root.add_child(move_label)

	board = HBoxContainer.new()
	board.alignment = BoxContainer.ALIGNMENT_CENTER
	board.add_theme_constant_override("separation", 22)
	board.custom_minimum_size = Vector2(960, 760)
	root.add_child(board)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 30)
	status_label.add_theme_color_override("font_color", Color("67e8cf"))
	root.add_child(status_label)

func new_game() -> void:
	# Bottom-to-top values. This layout is intentionally solvable and shuffled by rotating colors.
	var shift := randi_range(0, COLORS.size() - 1)
	tubes = [
		[(0 + shift) % 4, (1 + shift) % 4, (0 + shift) % 4, (1 + shift) % 4],
		[(2 + shift) % 4, (3 + shift) % 4, (2 + shift) % 4, (3 + shift) % 4],
		[(1 + shift) % 4, (0 + shift) % 4, (1 + shift) % 4, (0 + shift) % 4],
		[(3 + shift) % 4, (2 + shift) % 4, (3 + shift) % 4, (2 + shift) % 4],
		[], []
	]
	selected = -1
	moves = 0
	status_label.text = ""
	render_board()

func render_board() -> void:
	for child in board.get_children():
		child.queue_free()
	for i in range(tubes.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(135, 620)
		button.text = tube_text(tubes[i])
		button.add_theme_font_size_override("font_size", 40)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.modulate = Color(1.15, 1.15, 1.15) if i == selected else Color.WHITE
		button.tooltip_text = "Tube %d" % (i + 1)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES  %d" % moves

func tube_text(tube: Array) -> String:
	var lines: Array[String] = []
	for slot in range(CAPACITY - 1, -1, -1):
		if slot < tube.size():
			lines.append(color_symbol(int(tube[slot])))
		else:
			lines.append("·")
	return "\n".join(lines)

func color_symbol(index: int) -> String:
	match index:
		0: return "●"
		1: return "◆"
		2: return "■"
		_: return "▲"

func select_tube(index: int) -> void:
	if selected < 0:
		if tubes[index].is_empty():
			return
		selected = index
		render_board()
		return
	if selected == index:
		selected = -1
		render_board()
		return
	if can_pour(selected, index):
		pour(selected, index)
		moves += 1
	selected = -1
	render_board()
	if is_complete():
		status_label.text = "PUZZLE COMPLETE!  %d MOVES" % moves
		AnalyticsManager.track("water_sort_completed", {"moves": moves})

func can_pour(from_idx: int, to_idx: int) -> bool:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	if source.is_empty() or target.size() >= CAPACITY:
		return false
	return target.is_empty() or int(target.back()) == int(source.back())

func pour(from_idx: int, to_idx: int) -> void:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	var color := int(source.back())
	var count := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) != color:
			break
		count += 1
	var amount := min(count, CAPACITY - target.size())
	for _i in range(amount):
		target.append(source.pop_back())

func is_complete() -> bool:
	for tube in tubes:
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY:
			return false
		for value in tube:
			if int(value) != int(tube[0]):
				return false
	return true
