extends Button
class_name PremiumPieceButton

var piece_type := "normal"
var direction := "right"
var accent := Color("4a8bd8")
var glow := Color("8fc5ff")
var active_piece := true
var phase := 0.0

func configure(type_value: String, direction_value: String, base_color: Color) -> void:
	piece_type = type_value
	direction = direction_value
	accent = base_color
	glow = base_color.lightened(0.30)
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	var center := size * 0.5
	var pulse := 0.5 + 0.5 * sin(phase * 2.2)
	_draw_shell(r, center, pulse)
	match piece_type:
		"rotate": _draw_rotate(center)
		"key": _draw_key(center)
		"gate": _draw_gate(center)
		"bomb": _draw_bomb(center)
		"linked": _draw_linked(center)
		"blocker": _draw_blocker(center)
		_: _draw_arrow(center, direction, min(size.x, size.y) * 0.23)

func _draw_shell(rect: Rect2, center: Vector2, pulse: float) -> void:
	var radius := min(rect.size.x, rect.size.y) * 0.22
	draw_style_box(_rounded(Color(accent, 0.96), radius, Color(glow, 0.65), 2), rect)
	var inner := rect.grow(-7)
	draw_style_box(_rounded(Color(accent.darkened(0.14), 0.62), radius * 0.75, Color.WHITE, 0), inner)
	var shine := Rect2(inner.position + Vector2(8, 7), Vector2(inner.size.x - 16, max(5.0, inner.size.y * 0.12)))
	draw_rect(shine, Color(1, 1, 1, 0.10 + pulse * 0.05), true)
	draw_circle(center + Vector2(0, rect.size.y * 0.34), rect.size.x * 0.23, Color(0, 0, 0, 0.10))

func _rounded(color: Color, radius: float, border: Color, border_width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = int(radius)
	s.corner_radius_top_right = int(radius)
	s.corner_radius_bottom_left = int(radius)
	s.corner_radius_bottom_right = int(radius)
	if border_width > 0:
		s.border_width_left = border_width
		s.border_width_right = border_width
		s.border_width_top = border_width
		s.border_width_bottom = border_width
		s.border_color = border
	return s

func _draw_arrow(center: Vector2, dir: String, scale_value: float) -> void:
	var v := _dir_vec(dir)
	var n := Vector2(-v.y, v.x)
	var tip := center + v * scale_value
	var tail := center - v * scale_value * 0.75
	var neck := center + v * scale_value * 0.15
	var half := scale_value * 0.24
	var wing := scale_value * 0.52
	var points := PackedVector2Array([
		tail + n * half,
		neck + n * half,
		neck + n * wing,
		tip,
		neck - n * wing,
		neck - n * half,
		tail - n * half
	])
	draw_polygon(points, PackedColorArray([Color.WHITE]))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1,1,1,0.25), 2.0, true)

func _draw_rotate(center: Vector2) -> void:
	var radius := min(size.x, size.y) * 0.20
	draw_arc(center, radius, -2.6, 1.9, 26, Color.WHITE, 7.0, true)
	var tip := center + Vector2(cos(1.9), sin(1.9)) * radius
	var tangent := Vector2(-sin(1.9), cos(1.9))
	var p := PackedVector2Array([tip, tip - tangent * 13 - (tip-center).normalized()*9, tip - tangent * 13 + (tip-center).normalized()*9])
	draw_polygon(p, PackedColorArray([Color.WHITE]))
	_draw_arrow(center + Vector2(0, 6), direction, radius * 0.65)

func _draw_key(center: Vector2) -> void:
	var r := min(size.x, size.y) * 0.12
	draw_circle(center - Vector2(r * 0.75, 0), r, Color.WHITE)
	draw_circle(center - Vector2(r * 0.75, 0), r * 0.48, accent.darkened(0.2))
	draw_line(center, center + Vector2(r * 1.45, 0), Color.WHITE, 8.0, true)
	draw_line(center + Vector2(r * 0.75, 0), center + Vector2(r * 0.75, r * 0.55), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(r * 1.18, 0), center + Vector2(r * 1.18, r * 0.42), Color.WHITE, 7.0, true)

func _draw_gate(center: Vector2) -> void:
	var w := min(size.x, size.y) * 0.40
	var h := w * 0.82
	for offset in [-0.34, 0.0, 0.34]:
		draw_line(center + Vector2(w*offset, -h*0.45), center + Vector2(w*offset, h*0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w*0.5, -h*0.45), center + Vector2(w*0.5, -h*0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w*0.5, h*0.45), center + Vector2(w*0.5, h*0.45), Color.WHITE, 7.0, true)

func _draw_bomb(center: Vector2) -> void:
	var r := min(size.x, size.y) * 0.18
	draw_circle(center + Vector2(0, 5), r, Color.WHITE)
	draw_line(center + Vector2(r*0.38, -r*0.75), center + Vector2(r*0.82, -r*1.3), Color.WHITE, 6.0, true)
	draw_circle(center + Vector2(r*0.95, -r*1.45), r*0.18, glow)

func _draw_linked(center: Vector2) -> void:
	var r := min(size.x, size.y) * 0.13
	draw_arc(center - Vector2(r*0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_arc(center + Vector2(r*0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_line(center - Vector2(r*0.15, 0), center + Vector2(r*0.15, 0), Color.WHITE, 7.0, true)

func _draw_blocker(center: Vector2) -> void:
	var w := min(size.x, size.y) * 0.42
	var rect := Rect2(center - Vector2(w,w)*0.5, Vector2(w,w))
	draw_style_box(_rounded(Color("303746"), w*0.18, Color("697386"), 2), rect)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			draw_circle(center + Vector2(sx,sy)*w*0.28, w*0.045, Color("b5c0d0"))

func _dir_vec(dir: String) -> Vector2:
	match dir:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT
