extends Control
class_name BlockDragPreview

var shape: Array = []
var accent := Color("8b7cf6")
var phase := 0.0
var target_position := Vector2.ZERO
var target_scale := Vector2.ONE
var board_valid := true
var has_target := false

func configure(value: Array, color := Color("8b7cf6")) -> void:
	shape = value.duplicate(true)
	accent = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(360, 360)
	size = Vector2(360, 360)
	pivot_offset = size * 0.5
	scale = Vector2(0.78, 0.78)
	target_scale = Vector2(1.16, 1.16)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_drag_target(value: Vector2, valid := true) -> void:
	target_position = value
	board_valid = valid
	if not has_target:
		position = value
		has_target = true
	queue_redraw()

func set_drag_scale(value: Vector2) -> void:
	target_scale = value

func _process(delta: float) -> void:
	phase += delta
	if has_target:
		var delta_to_target: Vector2 = target_position - position
		position = position.lerp(target_position, minf(1.0, delta * 30.0))
		var desired_rotation := clampf(delta_to_target.x * 0.00045, -0.026, 0.026)
		rotation = lerpf(rotation, desired_rotation, minf(1.0, delta * 16.0))
	else:
		rotation = lerpf(rotation, 0.0, minf(1.0, delta * 16.0))
	scale = scale.lerp(target_scale, minf(1.0, delta * 22.0))
	queue_redraw()

func shape_centroid_local() -> Vector2:
	var points: Array[Vector2i] = []
	var max_x := 0
	var max_y := 0
	for raw in shape:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		points.append(point)
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	if points.is_empty():
		return size * 0.5
	var cell := minf(88.0, minf(292.0 / float(max_x + 1), 292.0 / float(max_y + 1)))
	var total := Vector2(float(max_x + 1) * cell, float(max_y + 1) * cell)
	var origin := (size - total) * 0.5
	var centroid := Vector2.ZERO
	for point in points:
		centroid += origin + Vector2(point) * cell + Vector2.ONE * cell * 0.5
	return centroid / float(points.size())

func _draw() -> void:
	if shape.is_empty():
		return
	var points: Array[Vector2i] = []
	var max_x := 0
	var max_y := 0
	for raw in shape:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		points.append(point)
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	if points.is_empty():
		return
	var cell := minf(88.0, minf(292.0 / float(max_x + 1), 292.0 / float(max_y + 1)))
	var total := Vector2(float(max_x + 1) * cell, float(max_y + 1) * cell)
	var origin := (size - total) * 0.5
	var pulse := 0.72 + 0.28 * sin(phase * 7.5)
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(4, 4), Vector2(cell - 8, cell - 8))
		_draw_block(rect, accent, pulse)

func _draw_block(rect: Rect2, color: Color, pulse: float) -> void:
	var shadow := rect
	shadow.position += Vector2(0, 13)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.01, 0.02, 0.08, 0.50)
	shadow_style.corner_radius_top_left = 16
	shadow_style.corner_radius_top_right = 16
	shadow_style.corner_radius_bottom_left = 16
	shadow_style.corner_radius_bottom_right = 16
	draw_style_box(shadow_style, shadow)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = color.lightened(0.34) if board_valid else Color("ff6f8e")
	draw_style_box(style, rect)
	var top_glow := Color(color.lightened(0.58), 0.90 + pulse * 0.08)
	draw_line(rect.position + Vector2(10, 9), Vector2(rect.end.x - 10, rect.position.y + 9), top_glow, 5.0, true)
	draw_line(rect.position + Vector2(9, 11), Vector2(rect.position.x + 9, rect.end.y - 11), Color(color.lightened(0.34), 0.78), 3.0, true)
	draw_line(Vector2(rect.position.x + 10, rect.end.y - 9), rect.end - Vector2(10, 9), Color(color.darkened(0.26), 0.90), 5.0, true)
	var shine := Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.16), Vector2(rect.size.x * 0.34, rect.size.y * 0.16))
	draw_style_box(_style(Color(1, 1, 1, 0.10 + pulse * 0.08), 10), shine)

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(raw)
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
