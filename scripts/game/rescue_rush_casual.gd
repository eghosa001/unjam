extends "res://scripts/game/rescue_rush_motion_final.gd"

func build_ui() -> void:
	var world: int = int(level_data.get("world", 1))
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Color("061224"), world_accent(), world - 1)
	add_child(backdrop)
	PremiumVisuals.set_accent(world_accent())

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 22)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 74)
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var back := Button.new()
	back.text = "←"
	back.tooltip_text = "Back"
	back.custom_minimum_size = Vector2(104, 70)
	back.add_theme_font_size_override("font_size", 34)
	style_button(back)
	back.pressed.connect(_quit)
	header.add_child(back)
	var title := Label.new()
	title.text = ("DAILY" if daily_mode else "LEVEL %d" % level_number) + "   •   RESCUE RUSH   •   WORLD %d" % world
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("eef7ff"))
	header.add_child(title)
	var retry := Button.new()
	retry.text = "↻"
	retry.tooltip_text = "Retry"
	retry.custom_minimum_size = Vector2(104, 70)
	retry.add_theme_font_size_override("font_size", 32)
	style_button(retry)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	status_panel.custom_minimum_size = Vector2(0, 64)
	status_panel.add_theme_stylebox_override("panel", style_box(Color(0.018, 0.043, 0.085, 0.90), 22, Color(world_accent(), 0.32), 1))
	root.add_child(status_panel)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 10)
	status_panel.add_child(status)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	moves_label.add_theme_font_size_override("font_size", 18)
	status.add_child(moves_label)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	rescue_label.add_theme_font_size_override("font_size", 18)
	rescue_label.add_theme_color_override("font_color", Color("ffd166"))
	status.add_child(rescue_label)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	chain_label.add_theme_font_size_override("font_size", 18)
	chain_label.add_theme_color_override("font_color", Color("67e8ff"))
	status.add_child(chain_label)

	var holder := CenterContainer.new()
	holder.name = "GameplayBoardHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(holder)
	board_panel = PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", style_box(Color(0.008, 0.024, 0.052, 0.975), 34, Color(world_accent(), 0.46), 3))
	holder.add_child(board_panel)
	var board_margin := _panel_margin(14, 14, 14, 14)
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
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(220, 70)
	undo.add_theme_font_size_override("font_size", 19)
	style_button(undo)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(220, 70)
	hint.add_theme_font_size_override("font_size", 19)
	style_button(hint, true)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("b9c9dc"))
	hint_label.custom_minimum_size = Vector2(0, 38)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint_label)
	PremiumVisuals.entrance(root, 0.012)
