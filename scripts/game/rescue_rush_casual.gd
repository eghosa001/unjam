extends "res://scripts/game/rescue_rush_motion_final.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const NAVY := Color(0.03,0.23,0.47)
const OFF_WHITE := Color(1.0,0.995,0.97)
const GREEN := Color(0.13,0.78,0.39)
const BLUE := Color(0.03,0.43,0.78)
const ORANGE := Color(1.0,0.55,0.12)

var figma_canvas: FigmaReferenceCanvas

func _add_rescue_identity_emblem(canvas: Control) -> void:
	var emblem := PanelContainer.new()
	emblem.name = "Identity/Rescue Emblem"
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#6be28e"),Color("#21c763"),Color("#0d9545"),9,Color(0.73,1.0,0.82,0.55),1))
	RefCanvas.set_rect(emblem,77,17,30,30)
	canvas.add_child(emblem)
	var chick := PanelContainer.new()
	chick.name = "Mark/Chick"
	chick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chick.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color("#ffd63d"),6,Color("#fff1a0"),1))
	RefCanvas.set_rect(chick,84,25,13,13)
	canvas.add_child(chick)
	var eye := ColorRect.new()
	eye.name = "Mark/Eye"
	eye.color = Color("#183b42")
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(eye,92,29,2,2)
	canvas.add_child(eye)
	var arrow := RefCanvas.label("↗",11,Color.WHITE,true)
	arrow.name = "Mark/Arrow"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(arrow,94,18,11,11)
	canvas.add_child(arrow)

func style_button(button: Button, accent: bool = false) -> void:
	var fill := ORANGE if accent else BLUE
	button.add_theme_stylebox_override("normal", RefCanvas.rounded_gradient3(fill.lightened(0.18), fill, fill.darkened(0.18), 16, fill.lightened(0.30), 1.3))
	button.add_theme_stylebox_override("hover", RefCanvas.rounded_gradient3(fill.lightened(0.24), fill.lightened(0.05), fill.darkened(0.13), 16, fill.lightened(0.38), 1.3))
	button.add_theme_stylebox_override("pressed", RefCanvas.rounded_gradient3(fill, fill.darkened(0.08), fill.darkened(0.25), 16, fill.lightened(0.20), 1.3))
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
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#45ccff"), Color("#a8f0f2"), Color("#e0fad4"), 34, Color("#b8d1e0"), 1, 0.55))
	RefCanvas.set_rect(sky, -15.9, -58.12, 419.81, 908.51)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#78d16e"), Color("#33a861"), Color("#146e4f"), 0, Color.TRANSPARENT, 0, 0.50))
	RefCanvas.set_rect(ground, -15.9, 43.06, 419.81, 441.34)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.polygon = PackedVector2Array([Vector2(22,481),Vector2(368,481),Vector2(340,147),Vector2(50,147)])
	platform.color = Color(0.59,0.78,0.55,0.65)
	canvas.add_child(platform)

	RefCanvas.add_shadow(canvas, Rect2(15,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var back := RefCanvas.premium_button("←",22,NAVY,Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1.4)
	back.name = "RescueBackAction"
	RefCanvas.set_rect(back,15,15,54,54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	RefCanvas.add_shadow(canvas, Rect2(319,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var retry := RefCanvas.premium_button("↻",23,Color("#088c3d"),Color(0.97,1.0,0.96),16,Color(0.67,0.90,0.72,0.55),1.4)
	retry.name = "RescueRetryAction"
	RefCanvas.set_rect(retry,319,15,54,54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)
	_add_rescue_identity_emblem(canvas)
	var title := RefCanvas.label("RESCUE RUSH",20,OFF_WHITE,true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(title,115,15,184,30)
	canvas.add_child(title)
	var world := int(level_data.get("world", 1))
	var subtitle := RefCanvas.label("LEVEL %d • WORLD %d" % [level_number,world],12,Color(0.92,0.98,1.0),false)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(subtitle,115,43,184,20)
	canvas.add_child(subtitle)

	var status_panel := PanelContainer.new()
	status_panel.name = "CompactStatusStrip"
	RefCanvas.add_shadow(canvas, Rect2(17,81,354,48), 15, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	status_panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#2c82bd"),Color("#0a6eb2"),Color("#085a92"),15,Color(0.47,0.69,0.84,0.52),1.4))
	RefCanvas.set_rect(status_panel,17,81,354,48)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(status_panel)
	moves_label = _status_label(HORIZONTAL_ALIGNMENT_LEFT)
	rescue_label = _status_label(HORIZONTAL_ALIGNMENT_CENTER)
	chain_label = _status_label(HORIZONTAL_ALIGNMENT_RIGHT)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation",4)
	RefCanvas.set_rect(status_row,27,81,334,48)
	canvas.add_child(status_row)
	for label in [moves_label,rescue_label,chain_label]:
		label.add_theme_font_size_override("font_size",12)
		label.add_theme_color_override("font_color",OFF_WHITE)
		status_row.add_child(label)

	var objective := PanelContainer.new()
	objective.name = "RescueObjectiveCard"
	RefCanvas.add_shadow(canvas, Rect2(17,137,354,34), 12, Color(0.02,0.10,0.18,0.14), 3, Vector2(0,3))
	objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(1,1,1,0.98),Color(0.97,1.0,0.98,0.98),Color("#ebfaf1"),12,Color(0.55,0.89,0.68,0.45),1.2))
	RefCanvas.set_rect(objective,17,137,354,34)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := RefCanvas.label(objective_instruction().to_upper(),16,Color("#088c3d"),true)
	objective_label.name = "RescueObjectiveLabel"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(objective_label,29,137,330,34)
	canvas.add_child(objective_label)

	var depth := PanelContainer.new()
	depth.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#335257"),Color("#25434b"),Color("#1a3340"),26))
	RefCanvas.set_rect(depth,27.15,195.92,338,338)
	canvas.add_child(depth)
	board_panel = PanelContainer.new()
	board_panel.name = "RescueBoardPanel"
	board_panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#d1ebc2"),Color("#99c4ab"),Color("#5e8c85"),26,Color(0.94,1.0,0.88,0.72),2,0.45))
	RefCanvas.set_rect(board_panel,25,183,338,338)
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
	RefCanvas.set_rect(actions,21,569,346,60)
	canvas.add_child(actions)
	var undo := _action("↶  UNDO",Color("#088c3d"))
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
	RefCanvas.set_rect(hint_label,21,639,346,40)
	canvas.add_child(hint_label)

	var frame_border := PanelContainer.new()
	frame_border.name = "RescueFrameBorder"
	frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_border.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color.TRANSPARENT, 34, Color("#b8d1e0"), 1))
	RefCanvas.set_rect(frame_border, 0, 0, 390, 844)
	frame_border.z_index = 900
	canvas.add_child(frame_border)

func _action(text_value: String, fill: Color) -> Button:
	var result := RefCanvas.premium_button(text_value,12,OFF_WHITE,fill,16,fill.lightened(0.30),1.3)
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

func render_board() -> void:
	super.render_board()
	if moves_label != null:
		var mistake_text := "FREE" if mistake_limit <= 0 else "%d/%d" % [mistakes_this_level,mistake_limit]
		moves_label.visible = true
		moves_label.text = "MOVES %d/%d   •   MISTAKES %s   •   CHAIN ×%d" % [moves,par_moves,mistake_text,maxi(chain_count,1)]
		moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		moves_label.add_theme_font_size_override("font_size",13)
	if rescue_label != null:
		rescue_label.visible = false
	if chain_label != null:
		chain_label.visible = false

func apply_theme_mode(_dark: bool) -> void:
	pass
