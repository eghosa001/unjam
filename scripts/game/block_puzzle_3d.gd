extends "res://scripts/game/block_puzzle_ultra_motion.gd"

# Bright 3D presentation layer. Core placement, scoring, drag and clear logic
# remain inherited from the proven motion/gameplay stack.

func _ready() -> void:
	super._ready()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_queue_board_fit):
		viewport.size_changed.connect(_queue_board_fit)

func _queue_board_fit() -> void:
	call_deferred("_fit_3d_board_layout")

func _fit_3d_board_layout() -> void:
	if board_grid == null or board_shell == null or board_grid.get_child_count() == 0:
		return
	var viewport_size := get_viewport_rect().size
	var available_board_width := maxf(320.0, viewport_size.x - 104.0)
	var available_board_height := maxf(320.0, viewport_size.y * 0.50)
	var gap := float(board_grid.get_theme_constant("h_separation"))
	var cell_size := clampf(floor(minf(
		(available_board_width - 22.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE),
		(available_board_height - 22.0 - gap * float(GRID_SIZE - 1)) / float(GRID_SIZE)
	)), 44.0, PREMIUM_CELL_MAX)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size, cell_size)
	board_shell.custom_minimum_size = Vector2(
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0,
		cell_size * GRID_SIZE + gap * float(GRID_SIZE - 1) + 18.0
	)
	if piece_row != null:
		piece_row.custom_minimum_size.y = 150.0

func build_ui() -> void:
	var accent := Unjam3DTheme.PURPLE
	var environment_3d := Unjam3DGameplayStage.new()
	environment_3d.name = "BlockPuzzle3DEnvironment"
	environment_3d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	environment_3d.configure("block_puzzle", accent)
	environment_3d.z_index = -100
	add_child(environment_3d)
	PremiumVisuals.set_accent(accent)

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
	Unjam3DTheme.gloss_button(back, Unjam3DTheme.PURPLE_DARK, true, 24)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 31)
	Unjam3DTheme.label_3d(title_label, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻"
	retry.custom_minimum_size = Vector2(92, 78)
	retry.add_theme_font_size_override("font_size", 34)
	Unjam3DTheme.gloss_button(retry, Unjam3DTheme.PURPLE_DARK, true, 24)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var score_card := PanelContainer.new()
	score_card.custom_minimum_size = Vector2(0, 105)
	score_card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("8d27d7"), 30, Color("e58cff"), 3, 10))
	root.add_child(score_card)
	var score_box := VBoxContainer.new()
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_box.add_theme_constant_override("separation", 2)
	score_card.add_child(score_box)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 35)
	Unjam3DTheme.label_3d(score_label, Color.WHITE, Color("541285"), 4)
	score_box.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(goal_label, Color("fff0ff"), Color("541285"), 3)
	score_box.add_child(goal_label)

	var objective := PanelContainer.new()
	objective.custom_minimum_size = Vector2(0, 62)
	objective.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(1.0, 0.97, 1.0, 0.94), 24, Color("e7a4ff"), 2, 6))
	root.add_child(objective)
	var objective_label := Label.new()
	objective_label.text = "▦  DRAG • PLACE • CLEAR • KEEP THE BOARD TIDY"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(objective_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	objective.add_child(objective_label)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	var viewport_size := get_viewport_rect().size
	var available_board_width := maxf(360.0, viewport_size.x - 104.0)
	var available_board_height := maxf(360.0, viewport_size.y * 0.50)
	var cell_size := clampf(floor(minf((available_board_width - 24.0) / float(GRID_SIZE), (available_board_height - 24.0) / float(GRID_SIZE))), 44.0, PREMIUM_CELL_MAX)
	board_shell = PanelContainer.new()
	board_shell.custom_minimum_size = Vector2(cell_size * GRID_SIZE + 22, cell_size * GRID_SIZE + 22)
	board_shell.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("66338a"), 30, Color("f0bdff"), 4, 16))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		board_margin.add_theme_constant_override("margin_%s" % side, 9)
	board_shell.add_child(board_margin)
	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", 3)
	board_grid.add_theme_constant_override("v_separation", 3)
	board_margin.add_child(board_grid)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := BlockCellButton.new()
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.configure(false, false, Unjam3DTheme.WATER, y * GRID_SIZE + x)
			cell.pressed.connect(place_selected.bind(Vector2i(x, y)))
			board_grid.add_child(cell)
			cell_buttons.append(cell)

	var tray := PanelContainer.new()
	tray.custom_minimum_size = Vector2(0, 190)
	tray.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color(0.98, 0.94, 1.0, 0.94), 30, Color("dda0ff"), 3, 9))
	root.add_child(tray)
	var tray_margin := MarginContainer.new()
	tray_margin.add_theme_constant_override("margin_left", 18)
	tray_margin.add_theme_constant_override("margin_right", 18)
	tray_margin.add_theme_constant_override("margin_top", 12)
	tray_margin.add_theme_constant_override("margin_bottom", 12)
	tray.add_child(tray_margin)
	var tray_box := VBoxContainer.new()
	tray_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_box.add_theme_constant_override("separation", 4)
	tray_margin.add_child(tray_box)
	var tray_title := Label.new()
	tray_title.text = "DRAG A BLOCK ONTO THE BOARD"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 18)
	Unjam3DTheme.label_3d(tray_title, Unjam3DTheme.PURPLE_DARK, Color.WHITE, 2)
	tray_box.add_child(tray_title)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 24)
	piece_row.custom_minimum_size = Vector2(0, 150)
	tray_box.add_child(piece_row)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 21)
	status_label.custom_minimum_size = Vector2(0, 32)
	Unjam3DTheme.label_3d(status_label, Color.WHITE, Unjam3DTheme.PURPLE_DARK, 3)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.custom_minimum_size = Vector2(0, 28)
	Unjam3DTheme.label_3d(hint_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(hint_label)

	effects_layer = Control.new()
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)
