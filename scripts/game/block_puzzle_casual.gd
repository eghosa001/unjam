extends "res://scripts/game/block_puzzle_ultra_motion.gd"

func build_ui() -> void:
	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(Color("202d63"), Color("8b7cf6"), 2)
	add_child(bg)
	PremiumVisuals.set_accent(Color("8b7cf6"))

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
	style_small_button(back)
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻"
	retry.tooltip_text = "Retry"
	retry.custom_minimum_size = Vector2(104, 70)
	style_small_button(retry)
	retry.add_theme_font_size_override("font_size", 32)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var score_card := PanelContainer.new()
	score_card.name = "CompactScoreStrip"
	score_card.custom_minimum_size = Vector2(0, 84)
	score_card.add_theme_stylebox_override("panel", style_box(Color("304a94aa"), 24, Color("ffffff24"), 1, 4))
	root.add_child(score_card)
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 16)
	score_card.add_child(score_row)
	score_label = Label.new()
	score_label.custom_minimum_size = Vector2(190, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 38)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_row.add_child(score_label)
	goal_label = Label.new()
	goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 18)
	goal_label.add_theme_color_override("font_color", Color("e7edff"))
	score_row.add_child(goal_label)

	var center := CenterContainer.new()
	center.name = "GameplayBoardHolder"
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var viewport_size := get_viewport_rect().size
	var available_width := maxf(560.0, viewport_size.x - 92.0)
	var available_height := maxf(560.0, viewport_size.y - 610.0)
	var width_cell := floor((available_width - 30.0) / float(GRID_SIZE))
	var height_cell := floor((available_height - 30.0) / float(GRID_SIZE))
	var premium_cell := clampf(minf(width_cell, height_cell), 68.0, 104.0)
	board_shell = PanelContainer.new()
	board_shell.custom_minimum_size = Vector2(premium_cell * GRID_SIZE + 20, premium_cell * GRID_SIZE + 20)
	board_shell.add_theme_stylebox_override("panel", style_box(Color("111936"), 12, Color("080d22"), 4, 12))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		board_margin.add_theme_constant_override("margin_%s" % side, 8)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 2)
	board_grid.add_theme_constant_override("v_separation", 2)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := BlockCellButton.new()
			cell.custom_minimum_size = Vector2(premium_cell, premium_cell)
			cell.configure(false, false, Color("466df2"), y * GRID_SIZE + x)
			cell.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(cell)
			cell_buttons.append(cell)

	var tray := PanelContainer.new()
	tray.name = "PieceTray"
	tray.custom_minimum_size = Vector2(0, 174)
	tray.add_theme_stylebox_override("panel", style_box(Color("304a9477"), 26, Color("ffffff22"), 1, 5))
	root.add_child(tray)
	var tray_margin := MarginContainer.new()
	tray_margin.add_theme_constant_override("margin_left", 16)
	tray_margin.add_theme_constant_override("margin_right", 16)
	tray_margin.add_theme_constant_override("margin_top", 10)
	tray_margin.add_theme_constant_override("margin_bottom", 8)
	tray.add_child(tray_margin)
	var tray_box := VBoxContainer.new()
	tray_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_box.add_theme_constant_override("separation", 2)
	tray_margin.add_child(tray_box)
	var tray_title := Label.new()
	tray_title.text = "DRAG A BLOCK • RELEASE WHEN THE PREVIEW LOCKS"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 15)
	tray_title.add_theme_color_override("font_color", Color("e9efff"))
	tray_box.add_child(tray_title)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 18)
	piece_row.custom_minimum_size = Vector2(0, 138)
	tray_box.add_child(piece_row)

	var feedback := HBoxContainer.new()
	feedback.custom_minimum_size = Vector2(0, 42)
	feedback.add_theme_constant_override("separation", 10)
	root.add_child(feedback)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color("ffcf63"))
	feedback.add_child(status_label)
	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color("e1e8ff"))
	feedback.add_child(hint_label)

	var progress := PanelContainer.new()
	progress.name = "CompactProgressStrip"
	progress.custom_minimum_size = Vector2(0, 66)
	progress.add_theme_stylebox_override("panel", style_box(Color("263f868c"), 20, Color("ffffff1c"), 1, 3))
	root.add_child(progress)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	progress.add_child(progress_row)
	run_score_bar = ProgressBar.new()
	run_score_bar.show_percentage = false
	run_score_bar.custom_minimum_size = Vector2(250, 14)
	run_score_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_score_bar.add_theme_stylebox_override("background", style_box(Color("162551"), 7))
	run_score_bar.add_theme_stylebox_override("fill", style_box(Color("8b7cf6"), 7))
	progress_row.add_child(run_score_bar)
	run_pace_label = Label.new()
	run_pace_label.custom_minimum_size = Vector2(340, 0)
	run_pace_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_pace_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	run_pace_label.add_theme_font_size_override("font_size", 14)
	run_pace_label.add_theme_color_override("font_color", Color("d7e2ff"))
	progress_row.add_child(run_pace_label)
	run_line_bar = ProgressBar.new()
	run_line_bar.show_percentage = false
	run_line_bar.custom_minimum_size = Vector2(250, 14)
	run_line_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_line_bar.add_theme_stylebox_override("background", style_box(Color("162551"), 7))
	run_line_bar.add_theme_stylebox_override("fill", style_box(Color("2dd4b6"), 7))
	progress_row.add_child(run_line_bar)

	effects_layer = Control.new()
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)
	PremiumVisuals.entrance(root, 0.012)
