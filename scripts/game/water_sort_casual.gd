extends "res://scripts/game/water_sort_ultra_motion.gd"

const VIBRANT_REFERENCE_TARGET := "approved-colorful-reference"

func build_ui() -> void:
	var game_id := "water_sort"
	var gradient: Array = PremiumDesignSystem.game_gradient(game_id)
	var primary: Color = gradient[0]
	var secondary: Color = gradient[1]
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(PremiumDesignSystem.vibrant_canvas(game_id), secondary, 1)
	add_child(bg)
	PremiumVisuals.set_accent(primary)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 14)
	outer.add_theme_constant_override("margin_right", 14)
	outer.add_theme_constant_override("margin_top", 14)
	outer.add_theme_constant_override("margin_bottom", 14)
	add_child(outer)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 82)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := Button.new()
	back.text = "←"
	back.tooltip_text = "Back"
	back.custom_minimum_size = Vector2(108, 76)
	PremiumDesignSystem.apply_button(back, true, secondary, "utility", 24)
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0.05,0.15,0.38,0.42))
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻"
	retry.tooltip_text = "Retry"
	retry.custom_minimum_size = Vector2(108, 76)
	PremiumDesignSystem.apply_button(retry, true, primary, "utility", 24)
	retry.add_theme_font_size_override("font_size", 34)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var info := PanelContainer.new()
	info.name = "CompactGameInfo"
	info.custom_minimum_size = Vector2(0, 76)
	info.add_theme_stylebox_override("panel", _panel_box(Color("176fd1"), Color("8ceeff"), 24))
	root.add_child(info)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	info.add_child(info_row)
	meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 19)
	meta_label.add_theme_color_override("font_color", Color("dffaff"))
	info_row.add_child(meta_label)
	move_label = Label.new()
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 20)
	move_label.add_theme_color_override("font_color", Color.WHITE)
	info_row.add_child(move_label)

	var tip := PanelContainer.new()
	tip.name = "VibrantWaterTip"
	tip.custom_minimum_size = Vector2(0, 58)
	tip.add_theme_stylebox_override("panel", _panel_box(Color("fff6d0"), Color("ffd95c"), 20))
	root.add_child(tip)
	var tip_label := Label.new()
	tip_label.text = "💧  POUR • SORT • RELAX — BUILD THE PERFECT FLOW"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 18)
	tip_label.add_theme_color_override("font_color", Color("23506d"))
	tip.add_child(tip_label)

	var center := CenterContainer.new()
	center.name = "GameplayStageHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var stage := PanelContainer.new()
	stage.name = "GameplayStage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", _panel_box(Color("145b9a"), Color("7befff"), 36))
	center.add_child(stage)
	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 14)
	stage_margin.add_theme_constant_override("margin_right", 14)
	stage_margin.add_theme_constant_override("margin_top", 14)
	stage_margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(stage_margin)
	var stage_center := CenterContainer.new()
	stage_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_margin.add_child(stage_center)
	board = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 18)
	board.add_theme_constant_override("v_separation", 24)
	stage_center.add_child(board)

	var feedback := PanelContainer.new()
	feedback.custom_minimum_size = Vector2(0, 64)
	feedback.add_theme_stylebox_override("panel", _panel_box(Color("5a38c8"), Color("c9b7ff"), 22))
	root.add_child(feedback)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 10)
	feedback.add_child(feedback_row)
	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color("f8f2ff"))
	feedback_row.add_child(hint_label)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("9ff9ff"))
	feedback_row.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(250, 78)
	undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PremiumDesignSystem.apply_button(undo, true, secondary, "secondary", 24)
	undo.add_theme_font_size_override("font_size", 21)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(250, 78)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PremiumDesignSystem.apply_button(hint, true, Color("ffbd38"), "reward", 24)
	hint.add_theme_font_size_override("font_size", 21)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	PremiumVisuals.entrance(root, 0.014)
