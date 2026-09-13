extends Button
class_name PremiumPieceButton

var piece_type := "normal"
var direction := "right"
var accent := Color("4a8bd8")
var glow := Color("8fc5ff")
var active_piece := true
var phase := 0.0
var hover_amount := 0.0
var press_amount := 0.0

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
	mouse_entered.connect(func(): _set_hover(true))
	mouse_exited.connect(func(): _set_hover(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(func(): pivot_offset = size * 0.5)
	pivot_offset = size * 0.5

func _set_hover(value: bool) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.12)

func _press() -> void:
	press_amount = 1.0
	var v := _dir_vec(direction)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + v * 7.0, 0.055)
	tween.parallel().tween_property(self, "scale", Vector2(0.94, 0.94), 0.055)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.07, 1.07), 0.075)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)

func _process(delta: float) -> void:
	phase += delta
	press_amount = maxf(0.0, press_amount - delta * 4.5)
	var hover_scale := 1.025 + hover_amount * 0.025
	scale = scale.lerp(Vector2(hover_scale, hover_scale), minf(1.0, delta * 8.0))
	queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(6, 6), size - Vector2(12, 12))
	var center: Vector2 = size * 0.5
	var pulse: float = 0.5 + 0.5 * sin(phase * 3.0)
	_draw_motion_trail(center, pulse)
	_draw_shell(rect, center, pulse)
	match piece_type:
		"rotate": _draw_rotate(center)
		"key": _draw_key(center)
		"gate": _draw_gate(center)
		"bomb": _draw_bomb(center)
		"linked": _draw_linked(center)
		"blocker": _draw_blocker(center)
		_: _draw_arrow(center, direction, minf(size.x, size.y) * 0.23)

func _draw_motion_trail(center: Vector2, pulse: float) -> void:
	if piece_type == "blocker":
		return
	var v := _dir_vec(direction)
	for i in range(3):
		var offset := 20.0 + float(i) * 13.0 + pulse * 5.0
		var alpha := (0.15 - float(i) * 0.035) * (0.55 + hover_amount * 0.45)
		var a := center - v * offset
		var n := Vector2(-v.y, v.x)
		draw_line(a - n * 11.0, a + n * 11.0, Color(glow, alpha), 4.0 - float(i) * 0.7, true)

func _draw_shell(rect: Rect2, center: Vector2, pulse: float) -> void:
	var radius: float = minf(rect.size.x, rect.size.y) * 0.22
	var glow_alpha := 0.62 + hover_amount * 0.25 + pulse * 0.10
	draw_style_box(_rounded(Color(accent, 0.98), radius, Color(glow, glow_alpha), 2 + int(hover_amount)), rect)
	var inner: Rect2 = rect.grow(-7)
	draw_style_box(_rounded(Color(accent.darkened(0.16), 0.66), radius * 0.75, Color.WHITE, 0), inner)
	var shine: Rect2 = Rect2(inner.position + Vector2(8, 7), Vector2(inner.size.x - 16, maxf(5.0, inner.size.y * 0.12)))
	draw_rect(shine, Color(1, 1, 1, 0.12 + pulse * 0.07), true)
	draw_circle(center + Vector2(0, rect.size.y * 0.34), rect.size.x * 0.23, Color(0, 0, 0, 0.12))
	if hover_amount > 0.01:
		draw_arc(center, rect.size.x * 0.53, 0, TAU, 32, Color(glow, 0.18 + 0.14 * pulse), 3.0, true)

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
	var v: Vector2 = _dir_vec(dir)
	var n: Vector2 = Vector2(-v.y, v.x)
	var breathing := 1.0 + sin(phase * 4.2) * 0.035
	var tip: Vector2 = center + v * scale_value * breathing
	var tail: Vector2 = center - v * scale_value * 0.75
	var neck: Vector2 = center + v * scale_value * 0.15
	var half: float = scale_value * 0.24
	var wing: float = scale_value * 0.52
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
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1,1,1,0.28), 2.0, true)

func _draw_rotate(center: Vector2) -> void:
	var radius: float = minf(size.x, size.y) * 0.20
	draw_arc(center, radius, -2.6, 1.9, 26, Color.WHITE, 7.0, true)
	var tip: Vector2 = center + Vector2(cos(1.9), sin(1.9)) * radius
	var tangent: Vector2 = Vector2(-sin(1.9), cos(1.9))
	var p := PackedVector2Array([tip, tip - tangent * 13 - (tip-center).normalized()*9, tip - tangent * 13 + (tip-center).normalized()*9])
	draw_polygon(p, PackedColorArray([Color.WHITE]))
	_draw_arrow(center + Vector2(0, 6), direction, radius * 0.65)

func _draw_key(center: Vector2) -> void:
	var r: float = minf(size.x, size.y) * 0.12
	draw_circle(center - Vector2(r * 0.75, 0), r, Color.WHITE)
	draw_circle(center - Vector2(r * 0.75, 0), r * 0.48, accent.darkened(0.2))
	draw_line(center, center + Vector2(r * 1.45, 0), Color.WHITE, 8.0, true)
	draw_line(center + Vector2(r * 0.75, 0), center + Vector2(r * 0.75, r * 0.55), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(r * 1.18, 0), center + Vector2(r * 1.18, r * 0.42), Color.WHITE, 7.0, true)

func _draw_gate(center: Vector2) -> void:
	var w: float = minf(size.x, size.y) * 0.40
	var h: float = w * 0.82
	for offset in [-0.34, 0.0, 0.34]:
		draw_line(center + Vector2(w * offset, -h * 0.45), center + Vector2(w * offset, h * 0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w * 0.5, -h * 0.45), center + Vector2(w * 0.5, -h * 0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w * 0.5, h * 0.45), center + Vector2(w * 0.5, h * 0.45), Color.WHITE, 7.0, true)

func _draw_bomb(center: Vector2) -> void:
	var r: float = minf(size.x, size.y) * 0.18
	draw_circle(center + Vector2(0, 5), r, Color.WHITE)
	draw_line(center + Vector2(r * 0.38, -r * 0.75), center + Vector2(r * 0.82, -r * 1.3), Color.WHITE, 6.0, true)
	var spark := 1.0 + sin(phase * 9.0) * 0.22
	draw_circle(center + Vector2(r * 0.95, -r * 1.45), r * 0.18 * spark, glow)

func _draw_linked(center: Vector2) -> void:
	var r: float = minf(size.x, size.y) * 0.13
	draw_arc(center - Vector2(r * 0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_arc(center + Vector2(r * 0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_line(center - Vector2(r * 0.15, 0), center + Vector2(r * 0.15, 0), Color.WHITE, 7.0, true)

func _draw_blocker(center: Vector2) -> void:
	var w: float = minf(size.x, size.y) * 0.42
	var rect := Rect2(center - Vector2(w, w) * 0.5, Vector2(w, w))
	draw_style_box(_rounded(Color("303746"), w * 0.18, Color("697386"), 2), rect)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			draw_circle(center + Vector2(sx, sy) * w * 0.28, w * 0.045, Color("b5c0d0"))

func _dir_vec(dir: String) -> Vector2:
	match dir:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT
