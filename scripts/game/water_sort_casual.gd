extends "res://scripts/game/water_sort_ultra_motion.gd"

func _water_button(text_value: String, tint: Color, role: String = "utility") -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_button(button, true, tint, role, 24)
	return button

func build_ui() -> void:
	var accent := PremiumDesignSystem.accent_for_game("water_sort")
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(PremiumDesignSystem.game_canvas("water_sort", true), accent, 1)
	add_child(bg)
	PremiumVisuals.set_accent(accent)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_bottom", 18)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 80)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := _water_button("←", accent)
	back.custom_minimum_size.x = 94
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_font_size_override("font_size", 34)
	back.tooltip_text = "Back"
	back.pressed.connect(_quit)
	header.add_child(back)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", PremiumDesignSystem.ink(true))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.30))
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_box.add_child(title_label)
	var mode := Label.new()
	mode.text = "POUR • SORT • RELAX"
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode.add_theme_font_size_override("font_size", 15)
	mode.add_theme_color_override("font_color", Color(accent, 0.92))
	title_box.add_child(mode)

	var retry := _water_button("↻", accent)
	retry.custom_minimum_size.x = 94
	retry.size_flags_horizontal = Control.SIZE_SHRINK_END
	retry.add_theme_font_size_override("font_size", 34)
	retry.tooltip_text = "Restart"
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var info := PanelContainer.new()
	info.name = "CompactGameInfo"
	info.custom_minimum_size = Vector2(0, 72)
	info.add_theme_stylebox_override("panel", PremiumDesignSystem.hud_box(accent, true))
	root.add_child(info)
	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 14)
	info_margin.add_theme_constant_override("margin_right", 14)
	info_margin.add_theme_constant_override("margin_top", 7)
	info_margin.add_theme_constant_override("margin_bottom", 7)
	info.add_child(info_margin)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	info_margin.add_child(info_row)
	meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 18)
	meta_label.add_theme_color_override("font_color", PremiumDesignSystem.muted(true))
	info_row.add_child(meta_label)
	move_label = Label.new()
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 21)
	move_label.add_theme_color_override("font_color", PremiumDesignSystem.ink(true))
	info_row.add_child(move_label)

	var instruction := PanelContainer.new()
	instruction.custom_minimum_size = Vector2(0, 48)
	instruction.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(accent, true))
	root.add_child(instruction)
	var instruction_text := Label.new()
	instruction_text.text = "💧  POUR FROM THE BOTTLE MOUTH • MATCH COLOURS • FILL EACH TUBE"
	instruction_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_text.add_theme_font_size_override("font_size", 16)
	instruction_text.add_theme_color_override("font_color", PremiumDesignSystem.ink(true))
	instruction.add_child(instruction_text)

	var center := CenterContainer.new()
	center.name = "GameplayStageHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var frame := PanelContainer.new()
	frame.name = "WaterGlassFrame"
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(PremiumDesignSystem.material_color("glass", true, accent), 38, Color(accent, 0.42), true, 11))
	center.add_child(frame)
	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 9)
	frame_margin.add_theme_constant_override("margin_right", 9)
	frame_margin.add_theme_constant_override("margin_top", 9)
	frame_margin.add_theme_constant_override("margin_bottom", 12)
	frame.add_child(frame_margin)
	var stage := PanelContainer.new()
	stage.name = "GameplayStage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", PremiumDesignSystem.recessed_box(Color("07192d"), 30, Color(accent, 0.34), true))
	frame_margin.add_child(stage)
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
	feedback.custom_minimum_size = Vector2(0, 60)
	feedback.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(accent, true))
	root.add_child(feedback)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 10)
	feedback.add_child(feedback_row)
	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", PremiumDesignSystem.muted(true))
	feedback_row.add_child(hint_label)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(accent, 0.95))
	feedback_row.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)
	var undo := _water_button("↶  UNDO", accent)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _water_button("💡  HINT", PremiumDesignSystem.GOLD, "reward")
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	var restart := _water_button("↻  RESTART", accent)
	restart.pressed.connect(restart_level)
	actions.add_child(restart)

	if not MotionSystem.reduced():
		PremiumVisuals.entrance(root, 0.014)
