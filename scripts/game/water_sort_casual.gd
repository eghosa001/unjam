extends "res://scripts/game/water_sort_ultra_motion.gd"

func build_ui() -> void:
	clip_contents = true
	var environment_3d := Unjam3DGameplayStage.new()
	environment_3d.name = "WaterSort3DEnvironment"
	environment_3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	environment_3d.configure("water_sort", Unjam3DTheme.WATER)
	environment_3d.z_index = -100
	add_child(environment_3d)
	PremiumVisuals.set_accent(Unjam3DTheme.WATER)

	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 700.0 or viewport_size.y < 1100.0
	var outer := MarginContainer.new()
	outer.name = "WaterOuter"
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 16 if compact else 28)
	outer.add_theme_constant_override("margin_right", 16 if compact else 28)
	outer.add_theme_constant_override("margin_top", 10 if compact else 20)
	outer.add_theme_constant_override("margin_bottom", 12 if compact else 24)
	add_child(outer)
	var root := VBoxContainer.new()
	root.name = "WaterRoot"
	root.add_theme_constant_override("separation", 7 if compact else 11)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.name = "WaterHeader"
	header.custom_minimum_size = Vector2(0, 72 if compact else 86)
	header.add_theme_constant_override("separation", 8 if compact else 12)
	root.add_child(header)
	var back := Button.new()
	back.name = "WaterBackAction"
	back.text = "←"
	back.custom_minimum_size = Vector2(80, 72) if compact else Vector2(92, 78)
	back.add_theme_font_size_override("font_size", 30 if compact else 34)
	Unjam3DTheme.gloss_button(back, Unjam3DTheme.WATER_DARK, true, 24)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 27 if compact else 31)
	Unjam3DTheme.label_3d(title_label, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title_label)
	var retry := Button.new()
	retry.name = "WaterRetryAction"
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(80, 72) if compact else Vector2(92, 78)
	retry.add_theme_font_size_override("font_size", 30 if compact else 34)
	Unjam3DTheme.gloss_button(retry, Unjam3DTheme.WATER_DARK, true, 24)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var info := PanelContainer.new()
	info.name = "CompactGameInfo"
	info.custom_minimum_size = Vector2(0, 82 if compact else 94)
	info.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("0879cf"), 30, Color("69dcff"), 3, 10))
	root.add_child(info)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	info.add_child(info_row)
	meta_label = Label.new()
	meta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.label_3d(meta_label, Color.WHITE, Color("034477"), 3)
	info_row.add_child(meta_label)
	move_label = Label.new()
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 21 if compact else 24)
	Unjam3DTheme.label_3d(move_label, Color.WHITE, Color("034477"), 3)
	info_row.add_child(move_label)

	var objective := PanelContainer.new()
	objective.name = "WaterObjectiveCard"
	objective.custom_minimum_size = Vector2(0, 50 if compact else 56)
	objective.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.97, 0.995, 1.0, 0.94), 24, Color("8be6ff"), 2, 6))
	root.add_child(objective)
	var objective_label := Label.new()
	objective_label.text = "💧  SORT • POUR • SOLVE"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.name = "WaterObjectiveLabel"
	objective_label.add_theme_font_size_override("font_size", 20 if compact else 23)
	Unjam3DTheme.label_3d(objective_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	objective.add_child(objective_label)

	var center := MarginContainer.new()
	center.name = "GameplayStageHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var stage := PanelContainer.new()
	stage.name = "GameplayStage"
	stage.custom_minimum_size = Vector2(0, 520)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.80, 0.95, 1.0, 0.82), 38, Color("89e4ff"), 3, 16))
	center.add_child(stage)
	var stage_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		stage_margin.add_theme_constant_override("margin_%s" % side, 18)
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
	feedback.name = "CompactGameFeedback"
	feedback.custom_minimum_size = Vector2(0, 64 if compact else 72)
	feedback.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.94, 0.99, 1.0, 0.98), 24, Color("78d9ff"), 2, 7))
	root.add_child(feedback)
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 10)
	feedback.add_child(feedback_row)
	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.label_3d(hint_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	feedback_row.add_child(hint_label)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.label_3d(status_label, Unjam3DTheme.WATER_DARK, Color.WHITE, 2)
	feedback_row.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var undo := Button.new()
	undo.name = "WaterUndoAction"
	undo.text = "↶\nUNDO"
	undo.custom_minimum_size = Vector2(190, 100) if compact else Vector2(220, 116)
	undo.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.gloss_button(undo, Unjam3DTheme.WATER_DARK, true, 24)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.name = "WaterHintAction"
	hint.text = "💡\nHINT"
	hint.custom_minimum_size = Vector2(190, 100) if compact else Vector2(220, 116)
	hint.add_theme_font_size_override("font_size", 20 if compact else 22)
	Unjam3DTheme.gloss_button(hint, Unjam3DTheme.ORANGE, true, 24)
	# HintManager is the single owner of paid/rewarded hint delivery.
	actions.add_child(hint)
	PremiumVisuals.entrance(root, 0.008)

func apply_theme_mode(dark: bool) -> void:
	var environment := get_node_or_null("WaterSort3DEnvironment") as Unjam3DGameplayStage
	if environment != null:
		environment.set_dark_mode(dark)
