extends "res://scripts/game/water_sort_ultra_motion.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const SKY_TOP := Color("#6f98ad")
const SKY_MID := Color("#a9c4ce")
const SKY_BOTTOM := Color("#e7e8df")
const NAVY := Color(0.03, 0.23, 0.47)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const BLUE := Color(0.03, 0.43, 0.78)
const ORANGE := Color(1.0, 0.55, 0.12)
const GUIDANCE_ORANGE := Color("#8a3b00")

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
	call_deferred("apply_theme_mode", _shell_dark_mode())

func _build_figma_water(canvas: Control) -> void:
	var sky := PanelContainer.new()
	sky.name = "WaterScenicSky"
	sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(SKY_TOP, SKY_MID, SKY_BOTTOM, 34, Color("#b8d1e0"), 1, 0.58))
	RefCanvas.set_rect(sky, 0, 0, 390, 844)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sky)
	var ground := PanelContainer.new()
	ground.name = "WaterScenicGround"
	ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#5b98a5"), Color("#3c788a"), Color("#28596d"), 0, Color.TRANSPARENT, 0, 0.28))
	RefCanvas.set_rect(ground, 0, 93, 390, 410)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ground)
	var platform := Polygon2D.new()
	platform.name = "WaterPerspectivePlatform"
	platform.polygon = PackedVector2Array([Vector2(34, 500), Vector2(356, 500), Vector2(330, 190), Vector2(60, 190)])
	platform.color = Color(0.52,0.72,0.76,0.42)
	canvas.add_child(platform)

	RefCanvas.add_shadow(canvas, Rect2(15,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var back := RefCanvas.premium_button("←", 22, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1.4)
	back.name = "WaterBackAction"
	back.tooltip_text = "Back to levels"
	RefCanvas.set_rect(back, 15, 15, 54, 54)
	back.pressed.connect(_quit)
	canvas.add_child(back)
	RefCanvas.add_shadow(canvas, Rect2(319,15,54,54), 16, Color(0.02,0.10,0.18,0.22), 4, Vector2(0,4))
	var retry := RefCanvas.premium_button("↻", 23, NAVY, Color(0.96, 0.99, 1.0, 0.98), 16, Color(0.57, 0.84, 1.0, 0.52), 1.4)
	retry.name = "WaterRetryAction"
	retry.tooltip_text = "Restart level"
	RefCanvas.set_rect(retry, 319, 15, 54, 54)
	retry.pressed.connect(restart_level)
	canvas.add_child(retry)

	_add_water_identity_emblem(canvas)

	var info := PanelContainer.new()
	info.name = "WaterInfo"
	RefCanvas.add_shadow(canvas, Rect2(17,79,354,42), 14, Color(0.02,0.10,0.18,0.22), 5, Vector2(0,4))
	info.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#315d72"), Color("#274f64"), Color("#1f4053"), 14, Color(0.47,0.72,0.82,0.36), 1.1,0.24))
	RefCanvas.set_rect(info, 17, 79, 354, 42)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(info)
	meta_label = _make_label("", 14, Color(0.92, 0.98, 1.0), true)
	meta_label.clip_text = true
	meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	RefCanvas.set_rect(meta_label, 37, 91, 170, 20)
	canvas.add_child(meta_label)
	move_label = _make_label("", 14, OFF_WHITE, true)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	move_label.clip_text = true
	move_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	RefCanvas.set_rect(move_label, 208, 91, 145, 20)
	canvas.add_child(move_label)

	var objective := PanelContainer.new()
	objective.name = "WaterObjective"
	RefCanvas.add_shadow(canvas, Rect2(17,129,354,30), 12, Color(0.02,0.10,0.18,0.14), 3, Vector2(0,3))
	objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#fffdf7"), Color("#faf8f1"), Color("#efeee8"), 12, Color(0.48,0.72,0.82,0.32), 1.0,0.22))
	RefCanvas.set_rect(objective, 17, 129, 354, 30)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective)
	var objective_label := _make_label("WIN • ONE COLOUR PER FULL TUBE", 15, NAVY, true)
	objective_label.name = "WaterObjectiveLabel"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.tooltip_text = "Win when every non-empty tube is full and contains only one colour."
	RefCanvas.set_rect(objective_label, 52, 129, 286, 30)
	canvas.add_child(objective_label)
	_add_water_drop_icon(canvas)

	gameplay_stage = PanelContainer.new()
	gameplay_stage.name = "GameplayStage"
	RefCanvas.add_shadow(canvas, Rect2(17,169,354,450), 20, Color(0.01,0.12,0.23,0.18), 8, Vector2(0,7))
	# Premium glass needs contrast. Keep the overall Water screen bright, but give
	# the playfield a deep ocean-glass surface so crystal edges and liquid volume
	# remain readable even with many bottles at late levels.
	gameplay_stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#173d67"), Color("#0b3158"), Color("#061f3c"), 20, Color(0.52, 0.90, 1.0, 0.72), 1.5))
	RefCanvas.set_rect(gameplay_stage, 17, 169, 354, 450)
	gameplay_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(gameplay_stage)

	board = GridContainer.new()
	board.name = "WaterBoard"
	board.columns = 5
	board.add_theme_constant_override("h_separation", 11)
	board.add_theme_constant_override("v_separation", 14)
	RefCanvas.set_rect(board, 37, 201.73, 294, 251)
	canvas.add_child(board)

	# Keep status and guidance on independent rows. Sharing one y-band looked
	# compact at READY but longer recovery/assist messages could collide with
	# "Best move..." guidance on phone screens.
	status_label = _make_label("", 15, NAVY, true)
	status_label.name = "WaterStatusText"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	RefCanvas.set_rect(status_label, 17, 626, 354, 22)
	canvas.add_child(status_label)
	hint_label = _make_label("", 15, GUIDANCE_ORANGE, true)
	hint_label.name = "WaterGuidanceText"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.clip_text = true
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	RefCanvas.set_rect(hint_label, 17, 652, 354, 22)
	canvas.add_child(hint_label)

	var actions := HBoxContainer.new()
	actions.name = "CompactGameActions"
	actions.add_theme_constant_override("separation", 14)
	RefCanvas.set_rect(actions, 21, 686, 346, 60)
	canvas.add_child(actions)

	var undo := _action_button("↶  UNDO", BLUE)
	undo.name = "WaterUndoAction"
	undo.pressed.connect(undo_move)
	actions.add_child(undo)
	var hint := _action_button("HINT", BLUE)
	hint.name = "WaterHintAction"
	# HintManager is the single owner of hint cost/reward handling.
	actions.add_child(hint)
	_add_water_bulb_icon(hint)

	title_label = _make_label("",21,OFF_WHITE,true)
	title_label.name = "WaterLevelTitle"
	RefCanvas.style_display_title(title_label, Color("#38d5ff"), Color("#063770"), 2)
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

func _action_button(text_value: String, _fill: Color) -> Button:
	var fill := Color("#315d72")
	var border := Color(0.48,0.78,0.88,0.44)
	var button := RefCanvas.premium_button(text_value,15,OFF_WHITE,fill,16,border,1.1)
	button.custom_minimum_size = Vector2(166,60)
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
		move_label.text = "MOVES %d • 3★≤%d" % [moves, par_moves]

func _apply_tube_layout() -> void:
	if board == null or not is_instance_valid(board):
		return
	var count := tubes.size()
	if count <= 0:
		return

	# The audited stage is 354×450. Fit every production configuration (up to
	# 14 generated tubes, plus the optional assist tube) inside it instead of
	# letting a third row overlap the move/status/action layers below.
	var columns := count if count <= 5 else (3 if count <= 6 else (4 if count <= 8 else (5 if count <= 10 else (4 if count <= 12 else 5))))
	var rows := int(ceil(float(count) / float(columns)))
	var stage_width := 326.0
	var stage_height := 420.0
	var h_gap := 12.0 if columns <= 4 else (8.0 if rows == 1 else 9.0)
	var v_gap := 14.0 if rows <= 2 else 10.0
	# Premium water-sort bottles should read as substantial vessels, not needles.
	var ratio := 3.8 if rows == 1 else (2.55 if rows == 2 else 2.30)
	var preferred_width := 60.0 if rows == 1 else (70.0 if rows == 2 else 58.0)
	var width_limit := floorf((stage_width - h_gap * float(maxi(columns - 1, 0))) / float(columns))
	var row_height_limit := floorf((stage_height - v_gap * float(maxi(rows - 1, 0))) / float(rows))
	var height_width_limit := row_height_limit / ratio
	var tube_width := clampf(minf(preferred_width, minf(width_limit, height_width_limit)), 38.0, preferred_width)
	var tube_size := Vector2(tube_width, tube_width * ratio)

	board.columns = columns
	board.add_theme_constant_override("h_separation", int(h_gap))
	board.add_theme_constant_override("v_separation", int(v_gap))
	for child in board.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = tube_size
	var content_w := tube_size.x * columns + h_gap * float(maxi(columns - 1, 0))
	var content_h := tube_size.y * rows + v_gap * float(maxi(rows - 1, 0))
	board.size = Vector2(content_w, content_h)
	board.custom_minimum_size = Vector2(content_w, content_h)
	board.position = Vector2(194.0 - content_w * 0.5, 169.0 + (450.0 - content_h) * 0.5)

func _shell_dark_mode() -> bool:
	var main := get_tree().current_scene
	var shell := main.get_node_or_null("UXShell") if main != null else null
	return shell != null and String(shell.get("theme_mode")) == "dark"

func _style_water_button(button: Button, dark: bool, accent: Color = BLUE) -> void:
	if button == null or not is_instance_valid(button):
		return
	var fill := Color("#172a36") if dark else Color(0.96, 0.99, 1.0, 0.98)
	var text := Color("#eaf7ff") if dark else NAVY
	var border := Color(accent, 0.72 if dark else 0.52)
	button.add_theme_stylebox_override("normal", RefCanvas.rounded_gradient3(fill.lightened(0.08 if dark else 0.02), fill, fill.darkened(0.12 if dark else 0.05), 16, border, 1.4))
	button.add_theme_stylebox_override("hover", RefCanvas.rounded_gradient3(fill.lightened(0.14), fill.lightened(0.04), fill.darkened(0.08), 16, border.lightened(0.10), 1.4))
	button.add_theme_stylebox_override("pressed", RefCanvas.rounded_gradient3(fill, fill.darkened(0.08), fill.darkened(0.18), 16, border, 1.4))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(key, text)

func _style_water_action(button: Button, dark: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	var fill := Color("#172a36") if dark else Color("#315d72")
	var border := Color(0.31,0.78,0.92,0.62 if dark else 0.44)
	button.add_theme_stylebox_override("normal", RefCanvas.rounded_gradient3(fill.lightened(0.08), fill, fill.darkened(0.12), 16, border, 1.1))
	button.add_theme_stylebox_override("hover", RefCanvas.rounded_gradient3(fill.lightened(0.14), fill.lightened(0.04), fill.darkened(0.08), 16, border.lightened(0.10), 1.1))
	button.add_theme_stylebox_override("pressed", RefCanvas.rounded_gradient3(fill, fill.darkened(0.08), fill.darkened(0.18), 16, border, 1.1))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(key, OFF_WHITE)

func apply_theme_mode(dark: bool) -> void:
	var viewport_bg := find_child("WaterFigmaViewportBackground", true, false) as ColorRect
	if viewport_bg != null:
		viewport_bg.color = Color("#0d1820") if dark else Color(0.04, 0.39, 0.67)
	var sky := find_child("WaterScenicSky", true, false) as PanelContainer
	if sky != null:
		sky.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#17242d") if dark else SKY_TOP,
			Color("#20323c") if dark else SKY_MID,
			Color("#293d46") if dark else SKY_BOTTOM,
			34, Color("#466372") if dark else Color("#b8d1e0"), 1, 0.58
		))
	var ground := find_child("WaterScenicGround", true, false) as PanelContainer
	if ground != null:
		ground.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#18313a") if dark else Color("#5b98a5"),
			Color("#122833") if dark else Color("#3c788a"),
			Color("#0c1d27") if dark else Color("#28596d"),
			0, Color.TRANSPARENT, 0, 0.28
		))
	var platform := find_child("WaterPerspectivePlatform", true, false) as Polygon2D
	if platform != null:
		platform.color = Color(0.16,0.29,0.34,0.52) if dark else Color(0.52,0.72,0.76,0.42)
	var info := find_child("WaterInfo", true, false) as PanelContainer
	if info != null:
		info.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#1c3542") if dark else Color("#315d72"),
			Color("#172e3a") if dark else Color("#274f64"),
			Color("#10232d") if dark else Color("#1f4053"),
			14, Color(0.47,0.72,0.82,0.46), 1.1, 0.24
		))
	var objective := find_child("WaterObjective", true, false) as PanelContainer
	if objective != null:
		objective.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#20313a") if dark else Color("#fffdf7"),
			Color("#1a2932") if dark else Color("#faf8f1"),
			Color("#14222a") if dark else Color("#efeee8"),
			12, Color(0.48,0.72,0.82,0.48 if dark else 0.32), 1.0, 0.22
		))
	var objective_label := find_child("WaterObjectiveLabel", true, false) as Label
	if objective_label != null:
		objective_label.add_theme_color_override("font_color", Color("#dff7ff") if dark else NAVY)
	if gameplay_stage != null:
		gameplay_stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#102d4a") if dark else Color("#173d67"),
			Color("#092640") if dark else Color("#0b3158"),
			Color("#041827") if dark else Color("#061f3c"),
			20, Color(0.52,0.90,1.0,0.72), 1.5
		))
	if status_label != null:
		status_label.add_theme_color_override("font_color", Color("#e8f5ff") if dark else NAVY)
	if hint_label != null:
		hint_label.add_theme_color_override("font_color", Color("#ffd47a") if dark else GUIDANCE_ORANGE)
	_style_water_button(find_child("WaterBackAction", true, false) as Button, dark)
	_style_water_button(find_child("WaterRetryAction", true, false) as Button, dark)
	_style_water_action(find_child("WaterUndoAction", true, false) as Button, dark)
	_style_water_action(find_child("WaterHintAction", true, false) as Button, dark)
	var frame := find_child("WaterFrameBorder", true, false) as PanelContainer
	if frame != null:
		frame.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color.TRANSPARENT, 34, Color("#4f6e7d") if dark else Color("#b8d1e0"), 1))
