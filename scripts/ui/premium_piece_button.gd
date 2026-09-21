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
	glow = base_color.lightened(0.36)
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
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.10)

func _press() -> void:
	press_amount = 1.0
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.05)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.07, 1.07), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.13)

func _process(delta: float) -> void:
	phase += delta
	press_amount = maxf(0.0, press_amount - delta * 4.5)
	var hover_scale := 1.0 + hover_amount * 0.035
	scale = scale.lerp(Vector2(hover_scale, hover_scale), minf(1.0, delta * 9.0))
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(3, 3), size - Vector2(6, 8))
	var center := rect.get_center()
	var pulse := 0.5 + 0.5 * sin(phase * 3.2)
	_draw_motion_trail(center, pulse)
	_draw_shell(rect, center, pulse)
	match piece_type:
		"rotate": _draw_rotate(center)
		"key": _draw_key(center)
		"gate": _draw_gate(center)
		"bomb": _draw_bomb(center)
		"linked": _draw_linked(center)
		"blocker": _draw_blocker(center)
		_: _draw_arrow(center, direction, minf(rect.size.x, rect.size.y) * 0.34)

func _draw_motion_trail(center: Vector2, pulse: float) -> void:
	if piece_type in ["blocker", "gate"] or MotionSystem.reduced():
		return
	var v := _dir_vec(direction)
	var n := Vector2(-v.y, v.x)
	for i in range(2):
		var offset := 22.0 + float(i) * 16.0 + pulse * 3.0
		var alpha := (0.11 - float(i) * 0.035) * (0.6 + hover_amount * 0.4)
		var a := center - v * offset
		draw_line(a - n * 10.0, a + n * 10.0, Color(glow, alpha), 4.0 - float(i), true)

func _draw_shell(rect: Rect2, center: Vector2, pulse: float) -> void:
	var radius := minf(rect.size.x, rect.size.y) * 0.22
	# A visible lower sidewall and contact shadow give the tile physical thickness
	# before the glossy front face is drawn on top.
	var shadow_rect := Rect2(rect.position + Vector2(0, 9), rect.size)
	draw_style_box(_rounded(Color(0.01, 0.05, 0.10, 0.38), radius, Color.TRANSPARENT, 0), shadow_rect)
	var side_rect := Rect2(rect.position + Vector2(0, 6), rect.size)
	draw_style_box(_rounded(accent.darkened(0.34), radius, accent.darkened(0.48), 2), side_rect)
	var edge := glow.lightened(0.12)
	draw_style_box(_rounded(accent, radius, edge, 3), rect)
	# Bright top bevel and darker bottom rolloff create clear material separation.
	var top_face := PackedVector2Array([
		rect.position + Vector2(radius * 0.42, 4),
		rect.position + Vector2(rect.size.x - radius * 0.42, 4),
		rect.position + Vector2(rect.size.x - radius * 0.70, 11),
		rect.position + Vector2(radius * 0.70, 11)
	])
	draw_colored_polygon(top_face, Color(accent.lightened(0.34), 0.54))
	var lower := Rect2(Vector2(rect.position.x + 5, rect.end.y - rect.size.y * 0.18), Vector2(rect.size.x - 10, rect.size.y * 0.13))
	draw_style_box(_rounded(Color(accent.darkened(0.30), 0.76), radius * 0.46, Color.TRANSPARENT, 0), lower)
	# Localized lacquer highlight rather than a flat white stripe.
	var gloss_rect := Rect2(rect.position + Vector2(10, 9), Vector2(rect.size.x * 0.48, maxf(8.0, rect.size.y * 0.15)))
	draw_style_box(_rounded(Color(1, 1, 1, 0.28 + pulse * 0.035), radius * 0.42, Color.TRANSPARENT, 0), gloss_rect)
	draw_circle(rect.position + Vector2(rect.size.x * 0.24, rect.size.y * 0.28), maxf(2.0, rect.size.x * 0.035), Color(1,1,1,0.46))
	if hover_amount > 0.01:
		draw_arc(center, rect.size.x * 0.55, 0, TAU, 36, Color(glow, 0.18 + pulse * 0.10), 4.0, true)

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
	var breathing := 1.0 + sin(phase * 4.0) * 0.025
	var tip := center + v * scale_value * breathing
	var tail := center - v * scale_value * 0.72
	var neck := center + v * scale_value * 0.13
	var half := scale_value * 0.23
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
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0, 4))
	draw_polygon(shadow, PackedColorArray([Color(0.02, 0.16, 0.25, 0.28)]))
	draw_polygon(points, PackedColorArray([Color.WHITE]))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.88, 0.98, 1.0, 0.90), 2.0, true)

func _draw_rotate(center: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.24
	draw_arc(center + Vector2(0, 3), radius, -2.6, 1.9, 26, Color(0.02, 0.15, 0.26, 0.25), 9.0, true)
	draw_arc(center, radius, -2.6, 1.9, 26, Color.WHITE, 7.0, true)
	var tip := center + Vector2(cos(1.9), sin(1.9)) * radius
	var tangent := Vector2(-sin(1.9), cos(1.9))
	var p := PackedVector2Array([tip, tip - tangent * 13 - (tip-center).normalized()*9, tip - tangent * 13 + (tip-center).normalized()*9])
	draw_polygon(p, PackedColorArray([Color.WHITE]))
	_draw_arrow(center + Vector2(0, 6), direction, radius * 0.65)

func _draw_key(center: Vector2) -> void:
	var r := minf(size.x, size.y) * 0.15
	draw_circle(center - Vector2(r * 0.75, -3), r, Color(0.02, 0.15, 0.26, 0.25))
	draw_circle(center - Vector2(r * 0.75, 0), r, Color.WHITE)
	draw_circle(center - Vector2(r * 0.75, 0), r * 0.48, accent.darkened(0.20))
	draw_line(center, center + Vector2(r * 1.45, 0), Color.WHITE, 8.0, true)
	draw_line(center + Vector2(r * 0.75, 0), center + Vector2(r * 0.75, r * 0.55), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(r * 1.18, 0), center + Vector2(r * 1.18, r * 0.42), Color.WHITE, 7.0, true)

func _draw_gate(center: Vector2) -> void:
	var w := minf(size.x, size.y) * 0.54
	var h := w * 0.82
	for offset in [-0.34, 0.0, 0.34]:
		draw_line(center + Vector2(w * offset, -h * 0.45 + 3), center + Vector2(w * offset, h * 0.45 + 3), Color(0.02, 0.15, 0.26, 0.22), 9.0, true)
		draw_line(center + Vector2(w * offset, -h * 0.45), center + Vector2(w * offset, h * 0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w * 0.5, -h * 0.45), center + Vector2(w * 0.5, -h * 0.45), Color.WHITE, 7.0, true)
	draw_line(center + Vector2(-w * 0.5, h * 0.45), center + Vector2(w * 0.5, h * 0.45), Color.WHITE, 7.0, true)

func _draw_bomb(center: Vector2) -> void:
	var r := minf(size.x, size.y) * 0.22
	draw_circle(center + Vector2(0, 8), r, Color(0.02, 0.15, 0.26, 0.22))
	draw_circle(center + Vector2(0, 5), r, Color.WHITE)
	draw_line(center + Vector2(r * 0.38, -r * 0.75), center + Vector2(r * 0.82, -r * 1.3), Color.WHITE, 6.0, true)
	var spark := 1.0 + sin(phase * 9.0) * 0.22
	draw_circle(center + Vector2(r * 0.95, -r * 1.45), r * 0.18 * spark, Unjam3DTheme.GOLD)

func _draw_linked(center: Vector2) -> void:
	var r := minf(size.x, size.y) * 0.16
	draw_arc(center - Vector2(r * 0.85, -3), r, 0, TAU, 28, Color(0.02, 0.15, 0.26, 0.22), 9.0, true)
	draw_arc(center + Vector2(r * 0.85, 3), r, 0, TAU, 28, Color(0.02, 0.15, 0.26, 0.22), 9.0, true)
	draw_arc(center - Vector2(r * 0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_arc(center + Vector2(r * 0.85, 0), r, 0, TAU, 28, Color.WHITE, 7.0, true)
	draw_line(center - Vector2(r * 0.15, 0), center + Vector2(r * 0.15, 0), Color.WHITE, 7.0, true)

func _draw_blocker(center: Vector2) -> void:
	var w := minf(size.x, size.y) * 0.62
	var rect := Rect2(center - Vector2(w, w) * 0.5, Vector2(w, w))
	var shadow := Rect2(rect.position + Vector2(0, 5), rect.size)
	draw_style_box(_rounded(Color("242d38"), w * 0.18, Color("111820"), 2), shadow)
	draw_style_box(_rounded(Color("6a7482"), w * 0.18, Color("d1d7de"), 3), rect)
	var top := Rect2(rect.position + Vector2(6, 5), Vector2(rect.size.x - 12, rect.size.y * 0.18))
	draw_style_box(_rounded(Color(1, 1, 1, 0.20), w * 0.10, Color.TRANSPARENT, 0), top)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			draw_circle(center + Vector2(sx, sy) * w * 0.28, w * 0.055, Color("e7edf3"))
			draw_circle(center + Vector2(sx, sy) * w * 0.28 + Vector2(0, 2), w * 0.025, Color("59626f"))

func _dir_vec(dir: String) -> Vector2:
	match dir:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		_: return Vector2.RIGHT
