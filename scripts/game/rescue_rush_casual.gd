extends "res://scripts/game/rescue_rush_motion_final.gd"

func _premium_game_button(text_value: String, accent: Color, role: String = "utility") -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_button(button, true, accent, role, 24)
	return button

func build_ui() -> void:
	var world: int = int(level_data.get("world", 1))
	var accent := world_accent()
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(PremiumDesignSystem.game_canvas("rescue_rush", true), accent, world - 1)
	add_child(backdrop)
	PremiumVisuals.set_accent(accent)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 22)
	outer.add_theme_constant_override("margin_right", 22)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_bottom", 18)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 78)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := _premium_game_button("←", accent)
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
	var title := Label.new()
	title.text = "RESCUE RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", PremiumDesignSystem.ink(true))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.30))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = ("DAILY" if daily_mode else "LEVEL %d" % level_number) + "  •  WORLD %d" % world
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(accent, 0.92))
	title_box.add_child(subtitle)
	var retry := _premium_game_button("↻", accent)
	retry.custom_minimum_size.x = 94
	retry.size_flags_horizontal = Control.SIZE_SHRINK_END
	retry.add_theme_font_size_override("font_size", 32)
	retry.tooltip_text = "Restart"
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	status_panel.custom_minimum_size = Vector2(0, 78)
	status_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.hud_box(accent, true))
	root.add_child(status_panel)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 16)
	status_margin.add_theme_constant_override("margin_right", 16)
	status_margin.add_theme_constant_override("margin_top", 7)
	status_margin.add_theme_constant_override("margin_bottom", 7)
	status_panel.add_child(status_margin)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 12)
	status_margin.add_child(status)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	moves_label.add_theme_font_size_override("font_size", 21)
	status.add_child(moves_label)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	rescue_label.add_theme_font_size_override("font_size", 21)
	rescue_label.add_theme_color_override("font_color", PremiumDesignSystem.GOLD)
	status.add_child(rescue_label)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	chain_label.add_theme_font_size_override("font_size", 21)
	chain_label.add_theme_color_override("font_color", Color("67e8ff"))
	status.add_child(chain_label)

	var instruction := PanelContainer.new()
	instruction.custom_minimum_size = Vector2(0, 50)
	instruction.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(accent, true))
	root.add_child(instruction)
	var instruction_label := Label.new()
	instruction_label.text = "💡  CLEAR THE LANE • FREE THE CHAIN • RESCUE THE FRIEND"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", PremiumDesignSystem.ink(true))
	instruction.add_child(instruction_label)

	var holder := CenterContainer.new()
	holder.name = "GameplayBoardHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(holder)
	var board_frame := PanelContainer.new()
	board_frame.name = "RescueStoneFrame"
	board_frame.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(PremiumDesignSystem.material_color("stone", true, accent), 38, Color(accent, 0.48), true, 12))
	holder.add_child(board_frame)
	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 12)
	frame_margin.add_theme_constant_override("margin_right", 12)
	frame_margin.add_theme_constant_override("margin_top", 12)
	frame_margin.add_theme_constant_override("margin_bottom", 14)
	board_frame.add_child(frame_margin)
	board_panel = PanelContainer.new()
	board_panel.name = "RescueRecessedBoard"
	board_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.recessed_box(Color("0a1626"), 30, Color("52657c"), true))
	frame_margin.add_child(board_panel)
	var board_margin := _panel_margin(15, 15, 15, 15)
	board_panel.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	board_margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)
	var undo := _premium_game_button("↶  UNDO", Color("5da9ff"))
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _premium_game_button("💡  HINT", PremiumDesignSystem.GOLD, "reward")
	hint.pressed.connect(show_hint)
	actions.add_child(hint)
	var restart := _premium_game_button("↻  RESTART", accent)
	restart.pressed.connect(restart_level)
	actions.add_child(restart)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", PremiumDesignSystem.muted(true))
	hint_label.custom_minimum_size = Vector2(0, 38)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint_label)

	if not MotionSystem.reduced():
		PremiumVisuals.entrance(root, 0.012)
