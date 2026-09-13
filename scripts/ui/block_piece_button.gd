extends Button
class_name BlockPieceButton

const DragPreview = preload("res://scripts/ui/block_drag_preview.gd")

var shape: Array = []
var selected := false
var used := false
var accent := Color("7c5cff")
var hover := false
var piece_index := -1
var touch_drag_started := false
var dragging := false
var phase := 0.0
var target_scale := Vector2.ONE
var target_rotation := 0.0

func configure(value: Array, is_selected: bool, color := Color("7c5cff"), index: int = -1) -> void:
	shape = value.duplicate(true)
	selected = is_selected
	used = shape.is_empty()
	accent = color
	piece_index = index
	text = "USED" if used else ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	mouse_default_cursor_shape = Control.CURSOR_DRAG if not used else Control.CURSOR_ARROW
	target_scale = Vector2(1.07, 1.07) if selected else Vector2.ONE
	target_rotation = deg_to_rad(-1.8 if selected else 0.0)
	_update_style()
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	set_process(true)

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	phase += delta
	if dragging:
		queue_redraw()
		return
	var hover_scale := 1.04 if hover and not selected else 1.0
	var desired := target_scale * hover_scale
	scale = scale.lerp(desired, minf(1.0, delta * 11.0))
	var wobble := sin(phase * 3.4) * deg_to_rad(0.65) if selected else 0.0
	rotation = lerpf(rotation, target_rotation + wobble, minf(1.0, delta * 9.0))
	if selected or hover:
		queue_redraw()

func _press() -> void:
	if used:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.12, 0.08)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(-3.0), 0.08)

func _release() -> void:
	if dragging:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.04, 0.07)
	tween.tween_property(self, "scale", target_scale, 0.16)
	tween.parallel().tween_property(self, "rotation", target_rotation, 0.16)

func _drag_payload() -> Dictionary:
	var drag_piece_index := piece_index if piece_index >= 0 else get_index()
	return {"kind": "block_piece", "piece_index": drag_piece_index, "shape": shape.duplicate(true)}

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(250, 250)
	wrapper.size = Vector2(250, 250)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Lift the actual shape well above the finger, like the reference trailer.
	wrapper.position = Vector2(-125, -225)
	var preview := DragPreview.new()
	preview.position = Vector2(10, 8)
	preview.configure(shape, accent)
	wrapper.add_child(preview)
	return wrapper

func _begin_drag_feedback() -> void:
	dragging = true
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.88, 0.88), 0.08)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.32), 0.08)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if used or shape.is_empty():
		return null
	_begin_drag_feedback()
	set_drag_preview(_make_drag_preview())
	return _drag_payload()

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_drag_started = false
		else:
			touch_drag_started = false
	elif event is InputEventScreenDrag and not touch_drag_started:
		touch_drag_started = true
		_begin_drag_feedback()
		force_drag(_drag_payload(), _make_drag_preview())
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and dragging:
		dragging = false
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate", Color.WHITE, 0.08)
		tween.parallel().tween_property(self, "scale", target_scale * 1.12, 0.10)
		tween.tween_property(self, "scale", target_scale, 0.18)
		tween.parallel().tween_property(self, "rotation", target_rotation, 0.18)

func _set_hover(value: bool) -> void:
	hover = value
	_update_style()
	queue_redraw()

func _update_style() -> void:
	var bg := Color("e9e5ff") if selected else Color("f8f5ff")
	var border := Color("12b8a6") if selected else Color(accent, 0.72 if hover else 0.38)
	add_theme_stylebox_override("normal", _style(bg, border, 4 if selected else 2))
	add_theme_stylebox_override("hover", _style(Color("ffffff"), border.lightened(0.10), 3))
	add_theme_stylebox_override("pressed", _style(Color("e0d9ff"), Color("12b8a6"), 4))
	add_theme_stylebox_override("disabled", _style(Color("e9edf4"), Color(0.35, 0.4, 0.5, 0.18), 1))
	add_theme_color_override("font_color", Color("334155"))
	add_theme_color_override("font_disabled_color", Color("64748b"))
	add_theme_font_size_override("font_size", 16)

func _draw() -> void:
	if used or shape.is_empty() or size.x <= 1.0 or size.y <= 1.0:
		return
	var points: Array[Vector2i] = []
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			points.append(point)
	if points.is_empty():
		return
	var max_x := 0
	var max_y := 0
	for point in points:
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	var cell := minf(36.0, minf((size.x - 44.0) / float(max_x + 1), (size.y - 36.0) / float(max_y + 1)))
	cell = maxf(10.0, cell)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	var pulse := 0.5 + 0.5 * sin(phase * 4.2)
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(2, 2), Vector2(cell - 4, cell - 4))
		var shadow := Rect2(rect.position + Vector2(0, 4), rect.size)
		draw_style_box(_style(Color(0.06, 0.05, 0.16, 0.18), Color.TRANSPARENT, 0, 8), shadow)
		draw_style_box(_style(accent, accent.lightened(0.24), 1, 8), rect)
		draw_line(rect.position + Vector2(5, 5), Vector2(rect.end.x - 5, rect.position.y + 5), accent.lightened(0.40), 2.5, true)
		if selected:
			draw_arc(rect.get_center(), rect.size.x * 0.58, 0, TAU, 24, Color("34d399", 0.20 + pulse * 0.12), 2.5, true)

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(raw)
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		var cleaned := String(raw).replace("(", "").replace(")", "").replace("Vector2i", "").strip_edges()
		var parts := cleaned.split(",")
		if parts.size() >= 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)

func _style(background: Color, border: Color, width: int, radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = border
	style.shadow_color = Color(0.10, 0.08, 0.22, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style
