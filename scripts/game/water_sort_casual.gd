extends "res://scripts/game/water_sort_ultra_motion.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")
const MotionTube = preload("res://scripts/ui/water_tube_3d_motion.gd")

const SKY_TOP := Color(0.27, 0.76, 1.0)
const SKY_MID := Color(0.63, 0.91, 1.0)
const SKY_BOTTOM := Color(0.91, 0.99, 1.0)
const NAVY := Color(0.03, 0.23, 0.47)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const BLUE := Color(0.03, 0.43, 0.78)
const ORANGE := Color(1.0, 0.55, 0.12)

var figma_canvas: FigmaReferenceCanvas
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
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(SKY_TOP, SKY_BOTTOM, 0))
	RefCanvas.set_rect(sky, 0, 0, 390, 844)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.name = "WaterScenicGround"
	ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color(0.20, 0.76, 0.88), Color(0.04, 0.39, 0.67), 0))
	RefCanvas.set_rect(ground, 0, 94, 390, 410)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.name = "WaterPerspectivePlatform"
	platform.polygon = PackedVector2Array([Vector2(34, 500), Vector2(356, 500), Vector2(330, 190), Vector2(60, 190)])
	platform.color = Color(0.45, 0.89, 0.95, 0.72)
	canvas.add_child(platform)

	var back := RefCanvas.button("←", 22, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1)
	back.name = "WaterBackAction"
	RefCanvas.set_rect(back, 16, 16, 54, 54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	var retry := RefCanvas.button("↻", 23, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1)
	retry.name = "WaterRetryAction"
	RefCanvas.set_rect(retry, 320, 16, 54, 54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)

	var info := PanelContainer.new()
	info.name = "WaterInfo"
	info.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color(0.166, 0.510, 0.811), Color(0.025, 0.353, 0.640), 14, Color(0.47, 0.69, 0.88, 0.52), 1))
	RefCanvas.set_rect(info, 18, 80, 354, 42)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(info)
	meta_label = _make_label("", 12, Color(0.92, 0.98, 1.0), true)
	RefCanvas.set_rect(meta_label, 38, 92, 135, 20)
	canvas.add_child(meta_label)
	move_label = _make_label("", 12, OFF_WHITE, true)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	RefCanvas.set_rect(move_label, 174, 92, 180, 20)
	canvas.add_child(move_label)

	var objective := PanelContainer.new()
	objective.name = "WaterObjective"
	objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(Color.WHITE, Color(0.919, 0.9694, 1.0), 12, Color(0.532, 0.823, 1.0, 0.45), 1))
	RefCanvas.set_rect(objective, 18, 130, 354, 30)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := _make_label("💧  SORT • POUR • SOLVE", 16, NAVY, true)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(objective_label, 18, 130, 354, 30)
	canvas.add_child(objective_label)

	gameplay_stage = PanelContainer.new()
	gameplay_stage.name = "GameplayStage"
	gameplay_stage.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.90, 0.99, 1.0, 0.38), 20, Color(0.55, 0.91, 1.0, 0.80), 1))
	RefCanvas.set_rect(gameplay_stage, 18, 170, 354, 420)
	gameplay_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(gameplay_stage)

	board = GridContainer.new()
	board.name = "WaterBoard"
	board.columns = 5
	board.add_theme_constant_override("h_separation", 11)
	board.add_theme_constant_override("v_separation", 14)
	RefCanvas.set_rect(board, 38, 202.7, 294, 251)
	canvas.add_child(board)

	status_label = _make_label("READY", 12, NAVY, true)
	RefCanvas.set_rect(status_label, 18, 597, 354, 20)
	canvas.add_child(status_label)
	hint_label = _make_label("", 12, ORANGE, true)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	RefCanvas.set_rect(hint_label, 120, 597, 252, 20)
	canvas.add_child(hint_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.add_theme_constant_override("separation", 14)
	RefCanvas.set_rect(actions, 22, 628, 346, 60)
	canvas.add_child(actions)

	var undo := _action_button("↶  UNDO", BLUE)
	undo.name = "WaterUndoAction"
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _action_button("💡  HINT", ORANGE)
	hint.name = "WaterHintAction"
	# HintManager is the single owner of hint cost/reward handling.
	actions.add_child(hint)

	title_label = _make_label("",20,OFF_WHITE,true)
	title_label.name = "WaterLevelTitle"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(title_label,116,20,158,28)
	canvas.add_child(title_label)

func _action_button(text_value: String, fill: Color) -> Button:
	var button := RefCanvas.button(text_value, 12, OFF_WHITE, fill, 16, fill.lightened(0.30), 1)
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
	board.position = Vector2(195.0 - content_w * 0.5, 170.0 + (420.0 - content_h) * 0.5)

func apply_theme_mode(_dark: bool) -> void:
	# Production Figma gameplay is intentionally bright; Settings owns the
	# explicit dark variant. Keep gameplay geometry/colors faithful here.
	pass
