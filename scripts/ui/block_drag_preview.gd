extends Control
class_name BlockDragPreview

var shape: Array = []
var accent := Color("8b7cf6")
var phase := 0.0

func configure(value: Array, color := Color("8b7cf6")) -> void:
	shape = value.duplicate(true)
	accent = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(230, 230)
	size = Vector2(230, 230)
	pivot_offset = size * 0.5
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	var breathe := 1.0 + sin(phase * 5.2) * 0.018
	scale = Vector2(breathe, breathe)
	queue_redraw()

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
	var cell := minf(62.0, minf(190.0 / float(max_x + 1), 190.0 / float(max_y + 1)))
	var total := Vector2(float(max_x + 1) * cell, float(max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(3, 3), Vector2(cell - 6, cell - 6))
		_draw_block(rect, accent)

func _draw_block(rect: Rect2, color: Color) -> void:
	var shadow := rect
	shadow.position += Vector2(0, 9)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.02, 0.02, 0.08, 0.42)
	shadow_style.corner_radius_top_left = 13
	shadow_style.corner_radius_top_right = 13
	shadow_style.corner_radius_bottom_left = 13
	shadow_style.corner_radius_bottom_right = 13
	draw_style_box(shadow_style, shadow)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = color.lightened(0.28)
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(8, 8), Vector2(rect.end.x - 8, rect.position.y + 8), Color(color.lightened(0.45), 0.9), 4.0, true)
	draw_line(Vector2(rect.position.x + 8, rect.end.y - 7), rect.end - Vector2(8, 7), Color(color.darkened(0.24), 0.8), 4.0, true)
	var glow_alpha := 0.16 + (0.5 + 0.5 * sin(phase * 6.0)) * 0.10
	draw_arc(rect.get_center(), rect.size.x * 0.56, 0.0, TAU, 28, Color(color.lightened(0.40), glow_alpha), 3.0, true)

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
