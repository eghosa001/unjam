extends "res://scripts/game/water_sort_ultra_motion.gd"

func build_ui() -> void:
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("07111f"), Color("5da9ff"), 1)
	add_child(bg)
	PremiumVisuals.set_accent(Color("5da9ff"))

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 26)
	outer.add_theme_constant_override("margin_right", 26)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 22)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 78)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := Button.new()
	back.text = "←"
	back.tooltip_text = "Back"
	back.custom_minimum_size = Vector2(104, 72)
	_style_round_control(back)
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color("f5f9ff"))
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻"
	retry.tooltip_text = "Retry"
	retry.custom_minimum_size = Vector2(104, 72)
	_style_round_control(retry)
	retry.add_theme_font_size_override("font_size", 34)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var info := PanelContainer.new()
	info.name = "CompactGameInfo"
	info.custom_minimum_size = Vector2(0, 62)
	info.add_theme_stylebox_override("panel", _panel_box(Color(0.045, 0.083, 0.14, 0.88), Color("5da9ff55"), 22))
	root.add_child(info)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	info.add_child(info_row)
	meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 17)
	meta_label.add_theme_color_override("font_color", Color("9fb5ce"))
	info_row.add_child(meta_label)
	move_label = Label.new()
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 18)
	move_label.add_theme_color_override("font_color", Color("eef7ff"))
	info_row.add_child(move_label)

	var center := CenterContainer.new()
	center.name = "GameplayStageHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var stage := PanelContainer.new()
	stage.name = "GameplayStage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", _panel_box(Color(0.027, 0.058, 0.105, 0.72), Color("5da9ff38"), 34))
	center.add_child(stage)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 16)
	stage_margin.add_theme_constant_override("margin_right", 16)
	stage_margin.add_theme_constant_override("margin_top", 16)
	stage_margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(stage_margin)
	var stage_center := CenterContainer.new()
	stage_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.add_child(stage_center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 18)
	board.add_theme_constant_override("v_separation", 24)
	stage_center.add_child(board)

	var feedback := PanelContainer.new()
	feedback.custom_minimum_size = Vector2(0, 58)
	feedback.add_theme_stylebox_override("panel", _panel_box(Color(0.035, 0.070, 0.125, 0.72), Color("ffffff18"), 20))
	root.add_child(feedback)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 10)
	feedback.add_child(feedback_row)
	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("b9cbe0"))
	feedback_row.add_child(hint_label)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color("80c7ff"))
	feedback_row.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(230, 72)
	_style_action(undo)
	undo.add_theme_font_size_override("font_size", 19)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(230, 72)
	_style_action(hint)
	hint.add_theme_font_size_override("font_size", 19)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	PremiumVisuals.entrance(root, 0.014)
