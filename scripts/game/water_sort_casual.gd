extends "res://scripts/game/water_sort_ultra_motion.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const SKY_TOP := Color(0.27, 0.76, 1.0)
const SKY_MID := Color(0.63, 0.91, 1.0)
const SKY_BOTTOM := Color(0.91, 0.99, 1.0)
const NAVY := Color(0.03, 0.23, 0.47)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const BLUE := Color(0.03, 0.43, 0.78)
const ORANGE := Color(1.0, 0.55, 0.12)

var figma_canvas: Control
var gameplay_stage: PanelContainer

func build_ui() -> void:
	clip_contents = true
	PremiumVisuals.set_accent(Unjam3DTheme.WATER)

	var viewport_bg := ColorRect.new()
	viewport_bg.name = "WaterFigmaViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_bg.color = Color(0.04, 0.39, 0.67)
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaWater390x844"
	add_child(figma_canvas)
	_build_figma_water(figma_canvas)

func _build_figma_water(canvas: Control) -> void:
	var sky := PanelContainer.new()
	sky.name = "WaterScenicSky"
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(SKY_TOP, SKY_MID, SKY_BOTTOM, 34, Color("#b8d1e0"), 1, 0.58))
	RefCanvas.set_rect(sky, 0, 0, 390, 844)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.name = "WaterScenicGround"
	ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#33c2e0"), Color("#1494c7"), Color("#0a63ab"), 0, Color.TRANSPARENT, 0, 0.55))
	RefCanvas.set_rect(ground, 0, 93, 390, 410)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.name = "WaterPerspectivePlatform"
	platform.polygon = PackedVector2Array([Vector2(34, 500), Vector2(356, 500), Vector2(330, 190), Vector2(60, 190)])
	platform.color = Color(0.45, 0.89, 0.95, 0.72)
	canvas.add_child(platform)

	RefCanvas.add_shadow(canvas, Rect2(15,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var back := RefCanvas.premium_button("←", 22, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1.4)
	back.name = "WaterBackAction"
	RefCanvas.set_rect(back, 15, 15, 54, 54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	RefCanvas.add_shadow(canvas, Rect2(319,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var retry := RefCanvas.premium_button("↻", 23, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1.4)
	retry.name = "WaterRetryAction"
	RefCanvas.set_rect(retry, 319, 15, 54, 54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)

	_add_water_identity_emblem(canvas)

	var info := PanelContainer.new()
	info.name = "WaterInfo"
	RefCanvas.add_shadow(canvas, Rect2(17,79,354,42), 14, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	info.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#2a82cf"), Color("#086ec7"), Color("#065aa3"), 14, Color(0.47, 0.69, 0.88, 0.52), 1.4))
	RefCanvas.set_rect(info, 17, 79, 354, 42)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(info)
	meta_label = _make_label("", 12, Color(0.92, 0.98, 1.0), true)
	RefCanvas.set_rect(meta_label, 37, 91, 135, 20)
	canvas.add_child(meta_label)
	move_label = _make_label("", 12, OFF_WHITE, true)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	RefCanvas.set_rect(move_label, 173, 91, 180, 20)
	canvas.add_child(move_label)

	var objective := PanelContainer.new()
	objective.name = "WaterObjective"
	RefCanvas.add_shadow(canvas, Rect2(17,129,354,30), 12, Color(0.02,0.10,0.18,0.14), 3, Vector2(0,3))
	objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(1,1,1,0.98), Color(0.96,0.99,1.0,0.98), Color(0.919, 0.9694, 1.0,0.98), 12, Color(0.532, 0.823, 1.0, 0.45), 1.2))
	RefCanvas.set_rect(objective, 17, 129, 354, 30)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := _make_label("SORT • POUR • SOLVE", 16, NAVY, true)
	objective_label.name = "WaterObjectiveLabel"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(objective_label, 76, 129, 250, 30)
	canvas.add_child(objective_label)
	_add_water_drop_icon(canvas)

	gameplay_stage = PanelContainer.new()
	gameplay_stage.name = "GameplayStage"
	RefCanvas.add_shadow(canvas, Rect2(17,169,354,420), 20, Color(0.01,0.12,0.23,0.18), 8, Vector2(0,7))
	gameplay_stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(0.94,1.0,1.0,0.40), Color(0.90,0.99,1.0,0.38), Color(0.82,0.95,1.0,0.34), 20, Color(0.55, 0.91, 1.0, 0.80), 1.5))
	RefCanvas.set_rect(gameplay_stage, 17, 169, 354, 420)
	gameplay_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(gameplay_stage)

	board = GridContainer.new()
	board.name = "WaterBoard"
	board.columns = 5
	board.add_theme_constant_override("h_separation", 11)
	board.add_theme_constant_override("v_separation", 14)
	RefCanvas.set_rect(board, 37, 201.73, 294, 251)
	canvas.add_child(board)

	status_label = _make_label("READY", 12, NAVY, true)
	RefCanvas.set_rect(status_label, 17, 599, 354, 20)
	canvas.add_child(status_label)
	hint_label = _make_label("", 12, ORANGE, true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	RefCanvas.set_rect(hint_label, 119, 599, 252, 20)
	canvas.add_child(hint_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.add_theme_constant_override("separation", 14)
	RefCanvas.set_rect(actions, 21, 627, 346, 60)
	canvas.add_child(actions)

	var undo := _action_button("↶  UNDO", BLUE)
	undo.name = "WaterUndoAction"
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _action_button("HINT", ORANGE)
	hint.name = "WaterHintAction"
	# HintManager is the single owner of hint cost/reward handling.
	actions.add_child(hint)
	_add_water_bulb_icon(hint)

	title_label = _make_label("",20,OFF_WHITE,true)
	title_label.name = "WaterLevelTitle"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(title_label,116,19,158,28)
	canvas.add_child(title_label)

	var frame_border := PanelContainer.new()
	frame_border.name = "WaterFrameBorder"
	frame_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_border.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color.TRANSPARENT, 34, Color("#b8d1e0"), 1))
	RefCanvas.set_rect(frame_border, 0, 0, 390, 844)
	frame_border.z_index = 900
	canvas.add_child(frame_border)

func _add_water_identity_emblem(canvas: Control) -> void:
	var emblem := PanelContainer.new()
	emblem.name = "Identity/Water Emblem"
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(Color("#4ad0ff"),Color("#19b9ff"),Color("#0e91d8"),9,Color(0.72,0.94,1.0,0.55),1))
	RefCanvas.set_rect(emblem,77,17,30,30)
	canvas.add_child(emblem)
	var glass := PanelContainer.new()
	glass.name = "Mark/Glass"
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(1,1,1,0.02),5,Color(1,1,1,0.96),2))
	RefCanvas.set_rect(glass,85,22,14,19)
	canvas.add_child(glass)
	var liquid := PanelContainer.new()
	liquid.name = "Mark/Liquid"
	liquid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	liquid.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(1,1,1,0.92),3))
	RefCanvas.set_rect(liquid,87,32,10,7)
	canvas.add_child(liquid)
	var rim := PanelContainer.new()
	rim.name = "Mark/Rim"
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color.WHITE,1))
	RefCanvas.set_rect(rim,84,22,16,2)
	canvas.add_child(rim)

func _add_water_drop_icon(canvas: Control) -> void:
	var drop := Polygon2D.new()
	drop.name = "WaterObjectiveDrop"
	drop.color = Color("#1aa8ff")
	drop.polygon = PackedVector2Array([
		Vector2(0,-8), Vector2(5,-1), Vector2(6,3),
		Vector2(4,7), Vector2(0,9), Vector2(-4,7),
		Vector2(-6,3), Vector2(-5,-1)
	])
	drop.position = Vector2(74,144)
	canvas.add_child(drop)

func _add_water_bulb_icon(button: Button) -> void:
	var bulb := PanelContainer.new()
	bulb.name = "WaterHintBulb"
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bulb_style := StyleBoxFlat.new()
	bulb_style.bg_color = Color("#ffe47a")
	bulb_style.corner_radius_top_left = 7
	bulb_style.corner_radius_top_right = 7
	bulb_style.corner_radius_bottom_left = 7
	bulb_style.corner_radius_bottom_right = 7
	bulb.add_theme_stylebox_override("panel", bulb_style)
	bulb.position = Vector2(16,17)
	bulb.size = Vector2(14,14)
	button.add_child(bulb)
	var base := ColorRect.new()
	base.name = "WaterHintBulbBase"
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.color = Color("#fff3aa")
	base.position = Vector2(20,31)
	base.size = Vector2(6,4)
	button.add_child(base)

func _action_button(text_value: String, fill: Color) -> Button:
	var button := RefCanvas.premium_button(text_value, 12, OFF_WHITE, fill, 16, fill.lightened(0.30), 1.3)
	button.custom_minimum_size = Vector2(106, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	return RefCanvas.label(text_value, font_size, color, bold)

func render_board() -> void:
	# Keep the authoritative motion/pour renderer, then remap its real tube
	# controls into the audited Figma stage instead of the old oversized fitter.
	super.render_board()
	_apply_tube_layout()
	if move_label != null:
		move_label.text = "MOVES %d   •   3★ ≤ %d" % [moves, par_moves]
	if status_label != null and status_label.text.strip_edges().is_empty():
		status_label.text = "READY"

func _apply_tube_layout() -> void:
	if board == null or not is_instance_valid(board):
		return
	var count := tubes.size()
	if count <= 0:
		return
	var columns := 5 if count <= 5 else (3 if count <= 6 else (4 if count <= 8 else 5))
	var rows := int(ceil(float(count) / float(columns)))
	var tube_size := Vector2(50, 251)
	var h_gap := 11
	var v_gap := 14
	if rows > 1:
		if count <= 6:
			tube_size = Vector2(58, 176)
			h_gap = 28
			v_gap = 20
		elif count <= 8:
			tube_size = Vector2(48, 174)
			h_gap = 22
			v_gap = 20
		else:
			tube_size = Vector2(42, 168)
			h_gap = 15
			v_gap = 18
	board.columns = columns
	board.add_theme_constant_override("h_separation", h_gap)
	board.add_theme_constant_override("v_separation", v_gap)
	for child in board.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = tube_size
	var content_w := tube_size.x * columns + float(h_gap * maxi(columns - 1, 0))
	var content_h := tube_size.y * rows + float(v_gap * maxi(rows - 1, 0))
	board.size = Vector2(content_w, content_h)
	board.custom_minimum_size = Vector2(content_w, content_h)
	board.position = Vector2(194.0 - content_w * 0.5, 169.0 + (420.0 - content_h) * 0.5)

func apply_theme_mode(_dark: bool) -> void:
	# Production Figma gameplay is intentionally bright; Settings owns the
	# explicit dark variant. Keep gameplay geometry/colors faithful here.
	pass
