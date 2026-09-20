extends "res://scripts/game/block_puzzle_polished.gd"

const PREMIUM_CELL_MAX := 90.0

var run_score_bar: ProgressBar
var run_line_bar: ProgressBar
var run_pace_label: Label
var run_objective_label: Label

func build_ui() -> void:
	var accent := PremiumDesignSystem.accent_for_game("block_puzzle")
	var background := PremiumBackdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.configure(PremiumDesignSystem.game_canvas("block_puzzle", true), accent, 2)
	add_child(background)
	PremiumVisuals.set_accent(accent)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 22)
	add_child(outer)
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_theme_constant_override("separation", 12)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	var back := Button.new()
	back.text = "← BACK"
	back.custom_minimum_size = Vector2(156, 76)
	style_small_button(back)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_quit)
	header.add_child(back)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title_label)
	var retry := Button.new()
	retry.text = "↻ RETRY"
	retry.custom_minimum_size = Vector2(156, 76)
	style_small_button(retry)
	retry.add_theme_font_size_override("font_size", 20)
	retry.pressed.connect(restart_level)
	header.add_child(retry)

	var score_card := PanelContainer.new()
	score_card.custom_minimum_size = Vector2(0, 94)
	score_card.add_theme_stylebox_override("panel", style_box(Color(0.10, 0.09, 0.22, 0.92), 28, Color(accent, 0.34), 2, 8))
	root.add_child(score_card)
	var score_box := VBoxContainer.new()
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_box.add_theme_constant_override("separation", 2)
	score_card.add_child(score_box)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.30))
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	score_box.add_child(score_label)
	goal_label = Label.new()
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 19)
	goal_label.add_theme_color_override("font_color", Color("d6ddff"))
	score_box.add_child(goal_label)

	var center := CenterContainer.new()
	root.add_child(center)
	var viewport_size := get_viewport_rect().size
	var available_board_width := maxf(360.0, viewport_size.x - 96.0)
	var available_board_height := maxf(360.0, viewport_size.y * 0.52)
	var premium_cell := clampf(floor(minf((available_board_width - 22.0) / float(GRID_SIZE), (available_board_height - 22.0) / float(GRID_SIZE))), 44.0, PREMIUM_CELL_MAX)
	board_shell = PanelContainer.new()
	board_shell.custom_minimum_size = Vector2(premium_cell * GRID_SIZE + 18, premium_cell * GRID_SIZE + 18)
	board_shell.add_theme_stylebox_override("panel", style_box(Color(0.05, 0.06, 0.14, 0.98), 24, Color(accent, 0.22), 2, 12))
	center.add_child(board_shell)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 8)
	board_margin.add_theme_constant_override("margin_right", 8)
	board_margin.add_theme_constant_override("margin_top", 8)
	board_margin.add_theme_constant_override("margin_bottom", 8)
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
	tray.custom_minimum_size = Vector2(0, 182)
	tray.add_theme_stylebox_override("panel", style_box(Color(0.09, 0.10, 0.22, 0.90), 28, Color(accent, 0.28), 1, 6))
	root.add_child(tray)
	var tray_margin := MarginContainer.new()
	tray_margin.add_theme_constant_override("margin_left", 20)
	tray_margin.add_theme_constant_override("margin_right", 20)
	tray_margin.add_theme_constant_override("margin_top", 14)
	tray_margin.add_theme_constant_override("margin_bottom", 14)
	tray.add_child(tray_margin)
	var tray_box := VBoxContainer.new()
	tray_box.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_box.add_theme_constant_override("separation", 4)
	tray_margin.add_child(tray_box)
	var tray_title := Label.new()
	tray_title.text = "DRAG A BLOCK ONTO THE BOARD"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 18)
	tray_title.add_theme_color_override("font_color", Color("eef2ff"))
	tray_box.add_child(tray_title)
	piece_row = HBoxContainer.new()
	piece_row.alignment = BoxContainer.ALIGNMENT_CENTER
	piece_row.add_theme_constant_override("separation", 24)
	piece_row.custom_minimum_size = Vector2(0, 158)
	tray_box.add_child(piece_row)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color("ffd978"))
	status_label.custom_minimum_size = Vector2(0, 32)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", Color("cfd9ff"))
	hint_label.custom_minimum_size = Vector2(0, 28)
	root.add_child(hint_label)

	_add_run_progress_deck(root)

	effects_layer = Control.new()
	effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.z_index = 800
	add_child(effects_layer)

func _add_run_progress_deck(root: VBoxContainer) -> void:
	var accent := PremiumDesignSystem.accent_for_game("block_puzzle")
	var deck := PanelContainer.new()
	deck.custom_minimum_size = Vector2(0, 112)
	deck.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck.add_theme_stylebox_override("panel", style_box(Color(0.09, 0.10, 0.22, 0.88), 24, Color(accent, 0.22), 1, 4))
	root.add_child(deck)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	deck.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	run_objective_label = Label.new()
	run_objective_label.text = "RUN PROGRESS"
	run_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_objective_label.add_theme_font_size_override("font_size", 20)
	run_objective_label.add_theme_color_override("font_color", Color("f4f7ff"))
	box.add_child(run_objective_label)
	var bars := GridContainer.new()
	bars.columns = 2
	bars.add_theme_constant_override("h_separation", 18)
	bars.add_theme_constant_override("v_separation", 7)
	box.add_child(bars)
	var score_name := Label.new()
	score_name.text = "SCORE TARGET"
	score_name.add_theme_font_size_override("font_size", 15)
	score_name.add_theme_color_override("font_color", Color("dfe7ff"))
	bars.add_child(score_name)
	var line_name := Label.new()
	line_name.text = "LINE TARGET"
	line_name.add_theme_font_size_override("font_size", 15)
	line_name.add_theme_color_override("font_color", Color("dfe7ff"))
	bars.add_child(line_name)
	run_score_bar = ProgressBar.new()
	run_score_bar.show_percentage = false
	run_score_bar.custom_minimum_size = Vector2(430, 18)
	run_score_bar.add_theme_stylebox_override("background", style_box(Color("162551"), 9))
	run_score_bar.add_theme_stylebox_override("fill", style_box(accent, 9))
	bars.add_child(run_score_bar)
	run_line_bar = ProgressBar.new()
	run_line_bar.show_percentage = false
	run_line_bar.custom_minimum_size = Vector2(430, 18)
	run_line_bar.add_theme_stylebox_override("background", style_box(Color("162551"), 9))
	run_line_bar.add_theme_stylebox_override("fill", style_box(accent.lightened(0.22), 9))
	bars.add_child(run_line_bar)
	run_pace_label = Label.new()
	run_pace_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_pace_label.add_theme_font_size_override("font_size", 16)
	run_pace_label.add_theme_color_override("font_color", Color("d7e2ff"))
	box.add_child(run_pace_label)

func render() -> void:
	super.render()
	_update_run_progress()

func _update_run_progress() -> void:
	if run_score_bar == null or run_line_bar == null or run_pace_label == null:
		return
	run_score_bar.max_value = maxf(1.0, float(target_score))
	run_score_bar.value = minf(float(score), float(target_score))
	run_line_bar.max_value = maxf(1.0, float(target_lines))
	run_line_bar.value = minf(float(lines_cleared), float(target_lines))
	var pace_left := maxi(0, par_placements - placements)
	run_pace_label.text = "%d / %d SCORE   •   %d / %d LINES   •   PERFECT PACE: %d PLACEMENTS LEFT" % [score, target_score, lines_cleared, target_lines, pace_left]
