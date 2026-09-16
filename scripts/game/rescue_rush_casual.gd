extends "res://scripts/game/rescue_rush_motion_final.gd"

const VIBRANT_REFERENCE_TARGET := "approved-colorful-reference"

func build_ui() -> void:
	var world: int = int(level_data.get("world", 1))
	var game_id := "rescue_rush"
	var gradient: Array = PremiumDesignSystem.game_gradient(game_id)
	var primary: Color = gradient[0]
	var secondary: Color = gradient[1]
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(PremiumDesignSystem.vibrant_canvas(game_id), secondary, world - 1)
	add_child(backdrop)
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
	back.add_theme_font_size_override("font_size", 36)
	PremiumDesignSystem.apply_button(back, true, secondary, "utility", 24)
	back.pressed.connect(_quit)
	header.add_child(back)
	var title := Label.new()
	title.text = ("DAILY" if daily_mode else "LEVEL %d" % level_number) + "   •   RESCUE RUSH   •   WORLD %d" % world
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("ffffff"))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.13, 0.18, 0.48))
	title.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title)
	var retry := Button.new()
	retry.text = "↻"
	retry.tooltip_text = "Retry"
	retry.custom_minimum_size = Vector2(108, 76)
	retry.add_theme_font_size_override("font_size", 34)
	PremiumDesignSystem.apply_button(retry, true, primary, "utility", 24)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var objective := PanelContainer.new()
	objective.name = "VibrantObjectiveBanner"
	objective.custom_minimum_size = Vector2(0, 72)
	objective.add_theme_stylebox_override("panel", style_box(Color("fff7d1"), 24, Color("ffd64f"), 3))
	root.add_child(objective)
	var objective_label := Label.new()
	objective_label.text = "✦  CLEAR THE LANE • FREE THE RESCUE • BUILD THE CHAIN  ✦"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 19)
	objective_label.add_theme_color_override("font_color", Color("244b47"))
	objective.add_child(objective_label)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	status_panel.custom_minimum_size = Vector2(0, 76)
	status_panel.add_theme_stylebox_override("panel", style_box(Color("087c75"), 24, Color(primary.lightened(0.32), 0.96), 3))
	root.add_child(status_panel)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 10)
	status_panel.add_child(status)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	moves_label.add_theme_font_size_override("font_size", 20)
	moves_label.add_theme_color_override("font_color", Color.WHITE)
	status.add_child(moves_label)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	rescue_label.add_theme_font_size_override("font_size", 20)
	rescue_label.add_theme_color_override("font_color", Color("ffe45c"))
	status.add_child(rescue_label)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	chain_label.add_theme_font_size_override("font_size", 20)
	chain_label.add_theme_color_override("font_color", Color("8ffcff"))
	status.add_child(chain_label)

	var holder := CenterContainer.new()
	holder.name = "GameplayBoardHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(holder)
	board_panel = PanelContainer.new()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel", style_box(Color("10334d"), 36, Color(primary.lightened(0.30), 0.98), 4))
	holder.add_child(board_panel)
	var board_margin := _panel_margin(14, 14, 14, 14)
	board_panel.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation", 8)
	board_grid.add_theme_constant_override("v_separation", 8)
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	root.add_child(actions)
	var undo := Button.new()
	undo.text = "↶  UNDO"
	undo.custom_minimum_size = Vector2(250, 78)
	undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo.add_theme_font_size_override("font_size", 21)
	PremiumDesignSystem.apply_button(undo, true, secondary, "secondary", 24)
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := Button.new()
	hint.text = "✦  HINT"
	hint.custom_minimum_size = Vector2(250, 78)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_font_size_override("font_size", 21)
	PremiumDesignSystem.apply_button(hint, true, Color("ffbd38"), "reward", 24)
	hint.pressed.connect(show_hint)
	actions.add_child(hint)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color("174451"))
	hint_label.custom_minimum_size = Vector2(0, 42)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint_label)
	PremiumVisuals.entrance(root, 0.012)
