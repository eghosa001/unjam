extends "res://scripts/game/rescue_rush_motion_final.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const NAVY := Color(0.03,0.23,0.47)
const OFF_WHITE := Color(1.0,0.995,0.97)
const GREEN := Color(0.13,0.78,0.39)
const BLUE := Color(0.03,0.43,0.78)
const ORANGE := Color(1.0,0.55,0.12)

var figma_canvas: FigmaReferenceCanvas

func style_button(button: Button, accent: bool = false) -> void:
	var fill := ORANGE if accent else BLUE
	var style := RefCanvas.solid_box(fill, 16, fill.lightened(0.30), 1)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", RefCanvas.solid_box(fill.lightened(0.06), 16, fill.lightened(0.38), 1))
	button.add_theme_stylebox_override("pressed", RefCanvas.solid_box(fill.darkened(0.08), 16, fill.lightened(0.20), 1))
	button.add_theme_color_override("font_color", OFF_WHITE)
	button.add_theme_color_override("font_hover_color", OFF_WHITE)
	button.add_theme_color_override("font_pressed_color", OFF_WHITE)

func restart_level() -> void:
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
	PremiumVisuals.set_accent(GREEN)
	var bg := ColorRect.new()
	bg.name = "RescueFigmaViewportBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.10,0.30,0.22)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaRescue390x844"
	add_child(figma_canvas)
	_build_figma_rescue(figma_canvas)

func _build_figma_rescue(canvas: Control) -> void:
	var sky := PanelContainer.new()
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color(0.37,0.83,0.69), Color(0.88,0.98,0.83), 0))
	RefCanvas.set_rect(sky, 0, 0, 390, 844)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color(0.28,0.66,0.45), Color(0.10,0.30,0.22), 0))
	RefCanvas.set_rect(ground, 0, 100, 390, 400)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.polygon = PackedVector2Array([Vector2(22,481),Vector2(368,481),Vector2(340,147),Vector2(50,147)])
	platform.color = Color(0.59,0.78,0.55,0.65)
	canvas.add_child(platform)

	var back := RefCanvas.button("←",22,NAVY,Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1)
	back.name = "RescueBackAction"
	RefCanvas.set_rect(back,16,16,54,54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	var retry := RefCanvas.button("↻",23,Color(0.08,0.45,0.25),Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1)
	retry.name = "RescueRetryAction"
	RefCanvas.set_rect(retry,320,16,54,54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)
	var title := RefCanvas.label("RESCUE RUSH",20,OFF_WHITE,true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(title,116,16,184,30)
	canvas.add_child(title)
	var world := int(level_data.get("world", 1))
	var subtitle := RefCanvas.label("LEVEL %d • WORLD %d" % [level_number,world],12,Color(0.92,0.98,1.0),false)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(subtitle,116,44,184,20)
	canvas.add_child(subtitle)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	status_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color(0.13,0.56,0.48),Color(0.05,0.40,0.34),14,Color(0.55,1.0,0.72,0.45),1))
	RefCanvas.set_rect(status_panel,18,82,354,48)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_panel)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation",4)
	RefCanvas.set_rect(status_row,28,82,334,48)
	canvas.add_child(status_row)
	for label in [moves_label,rescue_label,chain_label]:
		label.add_theme_font_size_override("font_size",12)
		label.add_theme_color_override("font_color",OFF_WHITE)
		status_row.add_child(label)

	var objective := PanelContainer.new()
	objective.name = "RescueObjectiveCard"
	objective.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.96,0.99,1.0,0.94),12,Color(0.61,0.90,0.70,0.60),1))
	RefCanvas.set_rect(objective,18,138,354,34)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := RefCanvas.label(objective_instruction().to_upper(),16,NAVY,true)
	objective_label.name = "RescueObjectiveLabel"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(objective_label,30,138,330,34)
	canvas.add_child(objective_label)

	var depth := PanelContainer.new()
	depth.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(0.22,0.28,0.25),22))
	RefCanvas.set_rect(depth,28.2,196.9,338,338)
	canvas.add_child(depth)
	board_panel = PanelContainer.new()
	board_panel.name = "RescueBoardPanel"
	board_panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient(Color(0.45,0.56,0.50),Color(0.28,0.39,0.35),22,Color(0.84,0.95,0.89),2))
	RefCanvas.set_rect(board_panel,26,184,338,338)
	canvas.add_child(board_panel)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_%s" % side,20)
	board_panel.add_child(margin)
	board_grid = GridContainer.new()
	board_grid.name = "RescueBoardGrid"
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation",22)
	board_grid.add_theme_constant_override("v_separation",22)
	margin.add_child(board_grid)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.add_theme_constant_override("separation",14)
	RefCanvas.set_rect(actions,22,570,346,60)
	canvas.add_child(actions)
	var undo := _action("↶  UNDO",BLUE)
	undo.name = "RescueUndoAction"
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _action("💡  HINT",ORANGE)
	hint.name = "RescueHintAction"
	actions.add_child(hint)
	var restart := _action("↻  RESTART",BLUE)
	restart.name = "RescueRestartAction"
	restart.pressed.connect(restart_level)
	actions.add_child(restart)

	hint_label = RefCanvas.label("",12,NAVY,true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	RefCanvas.set_rect(hint_label,22,640,346,40)
	canvas.add_child(hint_label)

func _action(text_value: String, fill: Color) -> Button:
	var result := RefCanvas.button(text_value,12,OFF_WHITE,fill,16,fill.lightened(0.30),1)
	result.custom_minimum_size = Vector2(106,60)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func _fit_board_to_viewport() -> void:
	if board_grid == null or board_panel == null:
		return
	board_grid.columns = width
	board_grid.add_theme_constant_override("h_separation",22)
	board_grid.add_theme_constant_override("v_separation",22)
	var cell_size := 41
	if width > 5 or height > 5:
		var available := 298.0
		var gap := 10
		cell_size = int(clampf(floor((available - float(gap * maxi(width - 1,0))) / float(maxi(width,1))),28.0,41.0))
		board_grid.add_theme_constant_override("h_separation",gap)
		board_grid.add_theme_constant_override("v_separation",gap)
	for child in board_grid.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(cell_size,cell_size)
			if child.get_child_count() > 0 and child.get_child(0) is Control:
				(child.get_child(0) as Control).custom_minimum_size = Vector2(cell_size,cell_size)
	board_panel.custom_minimum_size = Vector2(338,338)
	board_panel.size = Vector2(338,338)

func apply_theme_mode(_dark: bool) -> void:
	pass
