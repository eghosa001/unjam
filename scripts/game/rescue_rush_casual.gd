extends "res://scripts/game/rescue_rush_motion_final.gd"

func style_button(button: Button, accent: bool = false) -> void:
	Unjam3DTheme.gloss_button(button, Unjam3DTheme.ORANGE if accent else Unjam3DTheme.WATER_DARK, true, 24)


func restart_level() -> void:
	# The scene-owned touch enhancer must survive retries. Detach it while the
	# inherited restart retires runtime UI, and remove those runtime controls
	# immediately so old/new screen trees never overlap in the same frame.
	var enhancer := get_node_or_null("UiTouchEnhancer")
	if enhancer != null and enhancer.get_parent() == self:
		remove_child(enhancer)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	super.restart_level()
	if enhancer != null and is_instance_valid(enhancer):
		add_child(enhancer)

func build_ui() -> void:
	clip_contents = true
	var world: int = int(level_data.get("world", 1))
	var environment_3d := Unjam3DGameplayStage.new()
	environment_3d.name = "RescueRush3DEnvironment"
	environment_3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	environment_3d.configure("rescue_rush", Unjam3DTheme.GREEN)
	environment_3d.z_index = -100
	add_child(environment_3d)
	PremiumVisuals.set_accent(Unjam3DTheme.GREEN)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 28)
	outer.add_theme_constant_override("margin_right", 28)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 28)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 11)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 86)
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var back := Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(92, 78)
	back.add_theme_font_size_override("font_size", 34)
	style_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	var title := Label.new()
	title.text = "RESCUE RUSH\nLEVEL %d  •  WORLD %d" % [level_number, world]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title)
	var retry := Button.new()
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(92, 78)
	retry.add_theme_font_size_override("font_size", 34)
	style_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	status_panel.custom_minimum_size = Vector2(0, 94)
	status_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("0760ad"), 30, Color("55cfff"), 3, 10))
	root.add_child(status_panel)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 12)
	status_panel.add_child(status)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	for label in [moves_label, rescue_label, chain_label]:
		label.add_theme_font_size_override("font_size", 21)
		Unjam3DTheme.label_3d(label, Color.WHITE, Color("043666"), 3)
		status.add_child(label)

	var objective := PanelContainer.new()
	objective.custom_minimum_size = Vector2(0, 56)
	objective.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.96, 0.99, 1.0, 0.94), 25, Color("82dbff"), 2, 6))
	root.add_child(objective)
	var objective_label := Label.new()
	objective_label.text = "🐥  " + objective_instruction().to_upper()
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.label_3d(objective_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	objective.add_child(objective_label)

	var holder := CenterContainer.new()
	holder.name = "GameplayBoardHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(holder)
	board_panel = PanelContainer.new()
	# Warm stone frame with pale rim reads more like a toy diorama than a dark app panel.
	board_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("566b6a"), 38, Color("d7f3e4"), 5, 20))
	holder.add_child(board_panel)
	var board_margin := _panel_margin(18, 18, 18, 18)
	board_panel.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	board_margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "↶\nUNDO"
	undo.custom_minimum_size = Vector2(220, 116)
	undo.add_theme_font_size_override("font_size", 19)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "💡\nHINT"
	hint.custom_minimum_size = Vector2(220, 116)
	hint.add_theme_font_size_override("font_size", 19)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	var restart := Button.new()
	restart.text = "↻\nRESTART"
	restart.custom_minimum_size = Vector2(220, 116)
	restart.add_theme_font_size_override("font_size", 19)
	style_button(restart)
	restart.pressed.connect(restart_level)
	actions.add_child(restart)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.custom_minimum_size = Vector2(0, 40)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Unjam3DTheme.label_3d(hint_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(hint_label)
	PremiumVisuals.entrance(root, 0.008)

func apply_theme_mode(dark: bool) -> void:
	var environment := get_node_or_null("RescueRush3DEnvironment") as Unjam3DGameplayStage
	if environment != null:
		environment.set_dark_mode(dark)
