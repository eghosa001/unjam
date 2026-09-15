extends "res://scripts/game/water_sort_polished.gd"

const ReferenceTube = preload("res://scripts/ui/water_tube_reference_button.gd")

func build_ui() -> void:
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("07111f"), Color("5da9ff"), 1)
	add_child(bg)
	PremiumVisuals.set_accent(Color("5da9ff"))

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 30)
	outer.add_theme_constant_override("margin_bottom", 30)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var back := Button.new()
	back.text = "← BACK"
	back.custom_minimum_size = Vector2(288, 124)
	_style_round_control(back)
	back.pressed.connect(_quit)
	header.add_child(back)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("f5f9ff"))
	header.add_child(title_label)

	var retry := Button.new()
	retry.text = "↻ RETRY"
	retry.custom_minimum_size = Vector2(244, 120)
	_style_round_control(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", _panel_box(Color(0.055, 0.095, 0.16, 0.92), Color("5da9ff66"), 26))
	root.add_child(info)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	info.add_child(info_row)
	meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 20)
	meta_label.add_theme_color_override("font_color", Color("a9bed9"))
	info_row.add_child(meta_label)
	move_label = Label.new()
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 22)
	move_label.add_theme_color_override("font_color", Color("eaf4ff"))
	info_row.add_child(move_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var stage := PanelContainer.new()
	stage.custom_minimum_size = Vector2(0, 1040)
	stage.add_theme_stylebox_override("panel", _panel_box(Color(0.035, 0.070, 0.125, 0.84), Color("5da9ff4d"), 38))
	center.add_child(stage)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 26)
	stage_margin.add_theme_constant_override("margin_right", 26)
	stage_margin.add_theme_constant_override("margin_top", 34)
	stage_margin.add_theme_constant_override("margin_bottom", 34)
	stage.add_child(stage_margin)
	var stage_center := CenterContainer.new()
	stage_margin.add_child(stage_center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 20)
	board.add_theme_constant_override("v_separation", 30)
	stage_center.add_child(board)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.add_theme_color_override("font_color", Color("b9cbe0"))
	hint_label.custom_minimum_size = Vector2(0, 42)
	root.add_child(hint_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color("80c7ff"))
	status_label.custom_minimum_size = Vector2(0, 44)
	root.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 26)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(350, 116)
	_style_action(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT · 25"
	hint.custom_minimum_size = Vector2(350, 116)
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
	board.add_theme_constant_override("h_separation", 20 if tubes.size() <= 10 else 12)
	board.add_theme_constant_override("v_separation", 30)
	var tube_width := 164.0 if tubes.size() <= 10 else 136.0
	var tube_height := 330.0 if tubes.size() <= 10 else 298.0
	for i in range(tubes.size()):
		var button := ReferenceTube.new()
		button.custom_minimum_size = Vector2(tube_width, tube_height)
		button.tooltip_text = "Tube %d" % (i + 1)
		button.configure(tubes[i], i == selected, i)
		button.pressed.connect(select_tube.bind(i))
		board.add_child(button)
	move_label.text = "MOVES %d   •   PERFECT ≤ %d   •   %d COLORS" % [moves, par_moves, color_count]

func load_level() -> void:
	super.load_level()
	title_label.text = "DAILY SORT" if daily_mode else "WATER SORT · %d" % level_number
	meta_label.text = "%s  •  WORLD %d" % [difficulty().to_upper(), MultiGameManager.world_for_level(level_number)]

func _style_round_control(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", Color("f5f9ff"))
	button.add_theme_stylebox_override("normal", _button_box(Color(0.05, 0.09, 0.16, 0.96), 28, Color("5da9ff66"), 2))
	button.add_theme_stylebox_override("hover", _button_box(Color(0.08, 0.14, 0.24, 0.98), 28, Color("80c7ff"), 3))
	button.add_theme_stylebox_override("pressed", _button_box(Color(0.035, 0.07, 0.13, 1.0), 28, Color.WHITE, 2))

func _style_action(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", Color("f5f9ff"))
	button.add_theme_stylebox_override("normal", _button_box(Color(0.055, 0.10, 0.18, 0.96), 26, Color("5da9ff66"), 2))
	button.add_theme_stylebox_override("hover", _button_box(Color(0.08, 0.15, 0.26, 0.98), 26, Color("80c7ff"), 3))
	button.add_theme_stylebox_override("pressed", _button_box(Color(0.035, 0.07, 0.13, 1.0), 26, Color.WHITE, 2))

func _panel_box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	return s

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