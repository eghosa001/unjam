extends Control
class_name BlockDragPreview

var shape: Array = []
var accent := Color("8b7cf6")
var phase := 0.0
var target_position := Vector2.ZERO
var target_scale := Vector2.ONE
var board_valid := true
var has_target := false
var board_cell_size := 0.0

func configure(value: Array, color := Color("8b7cf6"), cell_size_override: float = 0.0) -> void:
	shape = value.duplicate(true)
	accent = color
	board_cell_size = maxf(0.0, cell_size_override)
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
	var cell := _display_cell_size(max_x, max_y)
	var total := Vector2(float(max_x + 1) * cell, float(max_y + 1) * cell)
	var origin := (size - total) * 0.5
	var centroid := Vector2.ZERO
	for point in points:
		centroid += origin + Vector2(point) * cell + Vector2.ONE * cell * 0.5
	return centroid / float(points.size())

func _display_cell_size(max_x: int, max_y: int) -> float:
	var fit := minf(88.0, minf(292.0 / float(max_x + 1), 292.0 / float(max_y + 1)))
	if board_cell_size <= 0.0:
		return fit
	# Match the live board cell so the dragged piece does not appear to become a
	# second, larger copy when it crosses from the tray onto a compact board.
	return clampf(minf(board_cell_size, fit), 24.0, 108.0)

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
	_draw_extruded_cube(rect, color, pulse)

func _draw_extruded_cube(rect: Rect2, color: Color, pulse: float) -> void:
	var depth := clampf(rect.size.x * 0.12, 3.0, 10.0)
	var front := Rect2(rect.position + Vector2(0.0, depth), rect.size - Vector2(depth, depth))
	# A narrow contact shadow reads as depth without looking like a second brick.
	var shadow := Rect2(
		Vector2(front.position.x + 4.0, front.end.y + 2.0),
		Vector2(maxf(2.0, front.size.x - 8.0), maxf(3.0, depth * 0.70))
	)
	draw_style_box(_style(Color(0.01, 0.02, 0.08, 0.38), 8), shadow)

	var top_face := PackedVector2Array([
		front.position,
		front.position + Vector2(depth, -depth),
		Vector2(front.end.x + depth, front.position.y - depth),
		Vector2(front.end.x, front.position.y)
	])
	var right_face := PackedVector2Array([
		Vector2(front.end.x, front.position.y),
		Vector2(front.end.x + depth, front.position.y - depth),
		Vector2(front.end.x + depth, front.end.y - depth),
		Vector2(front.end.x, front.end.y)
	])
	var invalid_tint := Color("ff6f8e")
	var face_color := color if board_valid else color.lerp(invalid_tint, 0.42)
	draw_colored_polygon(top_face, face_color.lightened(0.40))
	draw_colored_polygon(right_face, face_color.darkened(0.28))

	var style := _style(face_color, 14)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = face_color.lightened(0.36) if board_valid else invalid_tint
	draw_style_box(style, front)
	var inset := front.grow(-4.0)
	draw_style_box(_style(Color(face_color.lightened(0.12), 0.20), 11), inset)

	var top_glow := Color(face_color.lightened(0.58), 0.86 + pulse * 0.10)
	draw_line(front.position + Vector2(10, 9), Vector2(front.end.x - 10, front.position.y + 9), top_glow, 4.5, true)
	draw_line(front.position + Vector2(9, 12), Vector2(front.position.x + 9, front.end.y - 11), Color(face_color.lightened(0.30), 0.70), 2.8, true)
	var shine := Rect2(front.position + Vector2(front.size.x * 0.18, front.size.y * 0.18), Vector2(front.size.x * 0.32, front.size.y * 0.15))
	draw_style_box(_style(Color(1, 1, 1, 0.10 + pulse * 0.08), 9), shine)

	if not board_valid:
		var warning_alpha := 0.30 + pulse * 0.24
		draw_arc(front.get_center(), front.size.x * 0.62, 0.0, TAU, 30, Color(invalid_tint, warning_alpha), 4.0, true)

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
