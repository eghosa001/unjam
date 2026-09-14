extends Button
class_name BlockPieceButton

const DragPreview = preload("res://scripts/ui/block_drag_preview.gd")

var shape: Array = []
var selected := false
var used := false
var accent := Color("4f7cff")
var hover := false
var piece_index := -1
var touch_drag_started := false
var dragging := false
var phase := 0.0
var target_scale := Vector2.ONE

func configure(value: Array, is_selected: bool, color := Color("4f7cff"), index: int = -1) -> void:
	shape = value.duplicate(true)
	selected = is_selected
	used = shape.is_empty()
	accent = color
	piece_index = index
	text = ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_DRAG if not used else Control.CURSOR_ARROW
	target_scale = Vector2(1.08, 1.08) if selected else Vector2.ONE
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
	var hover_scale := 1.045 if hover and not selected else 1.0
	var desired := target_scale * hover_scale
	scale = scale.lerp(desired, minf(1.0, delta * 13.0))
	rotation = lerpf(rotation, 0.0, minf(1.0, delta * 14.0))
	if selected or hover:
		queue_redraw()

func _press() -> void:
	if used: return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.12, 0.06)

func _release() -> void:
	if dragging: return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 0.98, 0.045)
	tween.tween_property(self, "scale", target_scale, 0.12)

func _drag_payload() -> Dictionary:
	var drag_piece_index := piece_index if piece_index >= 0 else get_index()
	return {"kind": "block_piece", "piece_index": drag_piece_index, "shape": shape.duplicate(true)}

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(250, 250)
	wrapper.size = Vector2(250, 250)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.position = Vector2(-125, -215)
	var preview := DragPreview.new()
	preview.position = Vector2(10, 8)
	preview.configure(shape, accent)
	wrapper.add_child(preview)
	return wrapper

func _begin_drag_feedback() -> void:
	dragging = true
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.90, 0.90), 0.07)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.24), 0.07)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if used or shape.is_empty(): return null
	_begin_drag_feedback()
	set_drag_preview(_make_drag_preview())
	return _drag_payload()

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty(): return
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
		tween.tween_property(self, "modulate", Color.WHITE, 0.07)
		tween.parallel().tween_property(self, "scale", target_scale * 1.08, 0.09)
		tween.tween_property(self, "scale", target_scale, 0.15)

func _set_hover(value: bool) -> void:
	hover = value
	queue_redraw()

func _update_style() -> void:
	var transparent := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", transparent)
	add_theme_stylebox_override("hover", transparent)
	add_theme_stylebox_override("pressed", transparent)
	add_theme_stylebox_override("disabled", transparent)

func _draw() -> void:
	if used or shape.is_empty() or size.x <= 1.0 or size.y <= 1.0: return
	var points: Array[Vector2i] = []
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			points.append(point)
	if points.is_empty(): return
	var max_x := 0
	var max_y := 0
	for point in points:
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	var cell := minf(42.0, minf((size.x - 26.0) / float(max_x + 1), (size.y - 20.0) / float(max_y + 1)))
	cell = maxf(12.0, cell)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(1.5, 1.5), Vector2(cell - 3, cell - 3))
		_draw_block(rect, accent)
	if selected:
		var pulse := 0.55 + 0.45 * sin(phase * 7.0)
		draw_arc(size * 0.5, maxf(total.x, total.y) * 0.58, 0.0, TAU, 32, Color(accent.lightened(0.38), 0.18 + pulse * 0.16), 3.0, true)

func _draw_block(rect: Rect2, fill: Color) -> void:
	var dark := fill.darkened(0.28)
	draw_style_box(_style(dark, Color.TRANSPARENT, 0, 3), Rect2(rect.position + Vector2(0, 4), rect.size))
	draw_style_box(_style(fill, fill.lightened(0.22), 1, 3), rect)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.end.x - 4, rect.position.y + 4), Color(fill.lightened(0.50), 0.98), 2.2, true)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.position.x + 4, rect.end.y - 4), Color(fill.lightened(0.30), 0.80), 1.5, true)
	draw_line(Vector2(rect.position.x + 4, rect.end.y - 4), rect.end - Vector2(4, 4), Color(dark, 0.95), 2.2, true)
	draw_line(Vector2(rect.end.x - 4, rect.position.y + 4), rect.end - Vector2(4, 4), Color(dark, 0.82), 1.5, true)

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i: return raw
	if raw is Vector2: return Vector2i(raw)
	if raw is Dictionary: return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2: return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		var cleaned := String(raw).replace("(", "").replace(")", "").replace("Vector2i", "").strip_edges()
		var parts := cleaned.split(",")
		if parts.size() >= 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)

func _style(background: Color, border: Color, width: int, radius: int = 3) -> StyleBoxFlat:
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
	return style
