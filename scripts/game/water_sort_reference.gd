extends "res://scripts/game/water_sort_polished.gd"

const ReferenceBackdrop = preload("res://scripts/ui/water_sort_reference_backdrop.gd")
const ReferenceTube = preload("res://scripts/ui/water_tube_reference_button.gd")

func build_ui() -> void:
	var bg := ReferenceBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	PremiumVisuals.set_accent(Color("ffb02e"))

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_top", 36)
	outer.add_theme_constant_override("margin_bottom", 34)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var back := Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(82, 74)
	_style_round_control(back)
	back.pressed.connect(_quit)
	header.add_child(back)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color("fff6dc"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.60))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title_label)

	var retry := Button.new()
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(82, 74)
	_style_round_control(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	meta_label = Label.new()
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 17)
	meta_label.add_theme_color_override("font_color", Color("ffe7b0"))
	meta_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	root.add_child(meta_label)

	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 21)
	move_label.add_theme_color_override("font_color", Color.WHITE)
	move_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	move_label.add_theme_constant_override("shadow_offset_x", 2)
	move_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(move_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 18)
	board.add_theme_constant_override("v_separation", 24)
	center.add_child(board)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color("fff2cf"))
	hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.70))
	hint_label.custom_minimum_size = Vector2(0, 38)
	root.add_child(hint_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color("ffe26a"))
	status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	status_label.custom_minimum_size = Vector2(0, 42)
	root.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	root.add_child(actions)

	var undo := Button.new()
	undo.text = "UNDO"
	undo.custom_minimum_size = Vector2(230, 76)
	_style_action(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)

	var hint := Button.new()
	hint.text = "HINT"
	hint.custom_minimum_size = Vector2(230, 76)
	_style_action(hint)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)

	PremiumVisuals.entrance(root, 0.02)

func render_board() -> void:
	if board == null:
		return
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	board.columns = 5 if tubes.size() <= 10 else 6
	board.add_theme_constant_override("h_separation", 18 if tubes.size() <= 10 else 10)
	board.add_theme_constant_override("v_separation", 25)
	var tube_width := 154.0 if tubes.size() <= 10 else 128.0
	var tube_height := 316.0 if tubes.size() <= 10 else 286.0
	for i in range(tubes.size()):
		var button := ReferenceTube.new()
		button.custom_minimum_size = Vector2(tube_width, tube_height)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.configure(tubes[i], i == selected, i)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES %d   •   PERFECT ≤ %d   •   %d COLORS" % [moves, par_moves, color_count]
	if hint_label != null:
		hint_label.custom_minimum_size = Vector2(0, 40)

func load_level() -> void:
	super.load_level()
	if daily_mode:
		title_label.text = "DAILY SORT"
	else:
		title_label.text = "LEVEL %d" % level_number
	meta_label.text = "%s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_for_level(level_number)]

func _style_round_control(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", Color("fff7df"))
	button.add_theme_stylebox_override("normal", _button_box(Color(0.10, 0.07, 0.06, 0.64), 30, Color(1.0, 0.83, 0.42, 0.45), 2))
	button.add_theme_stylebox_override("hover", _button_box(Color(0.18, 0.10, 0.06, 0.78), 30, Color("ffd467"), 3))
	button.add_theme_stylebox_override("pressed", _button_box(Color(0.08, 0.05, 0.04, 0.86), 30, Color.WHITE, 2))

func _style_action(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("fff7df"))
	button.add_theme_stylebox_override("normal", _button_box(Color(0.10, 0.07, 0.06, 0.72), 24, Color(1.0, 0.74, 0.23, 0.52), 2))
	button.add_theme_stylebox_override("hover", _button_box(Color(0.18, 0.10, 0.06, 0.84), 24, Color("ffd467"), 3))
	button.add_theme_stylebox_override("pressed", _button_box(Color(0.08, 0.05, 0.04, 0.90), 24, Color.WHITE, 2))

func _button_box(color: Color, radius: int, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = width
	s.border_width_right = width
	s.border_width_top = width
	s.border_width_bottom = width
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	return s
