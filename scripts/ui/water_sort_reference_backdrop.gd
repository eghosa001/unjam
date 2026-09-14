extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	# Warm illustrated dusk gradient.
	for i in range(36):
		var t := float(i) / 35.0
		var c := Color("ff9a32").lerp(Color("b64d2f"), t)
		draw_rect(Rect2(0.0, h * t, w, h / 35.0 + 3.0), c, true)
	# Glowing moon and atmospheric halo.
	var moon := Vector2(w * 0.52, h * 0.20)
	var r := minf(w, h) * 0.145
	for i in range(7, 0, -1):
		draw_circle(moon, r + float(i) * 13.0, Color(1.0, 0.80, 0.35, 0.018 * float(8 - i)))
	draw_circle(moon, r, Color("ffe8a6"))
	draw_circle(moon + Vector2(-r * 0.28, -r * 0.18), r * 0.12, Color(0.75, 0.48, 0.20, 0.16))
	draw_circle(moon + Vector2(r * 0.24, r * 0.17), r * 0.08, Color(0.75, 0.48, 0.20, 0.13))
	# Distant rolling ground.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.68), Vector2(w * 0.15, h * 0.61), Vector2(w * 0.30, h * 0.66),
		Vector2(w * 0.47, h * 0.60), Vector2(w * 0.66, h * 0.65), Vector2(w * 0.82, h * 0.58),
		Vector2(w, h * 0.64), Vector2(w, h), Vector2(0, h)
	]), Color("392225"))
	draw_rect(Rect2(0, h * 0.80, w, h * 0.20), Color("171415"), true)
	_draw_tree(Vector2(w * 0.07, h * 0.82), h * 0.26)
	_draw_tree(Vector2(w * 0.94, h * 0.82), h * 0.29)
	_draw_house(Vector2(w * 0.80, h * 0.79), Vector2(w * 0.18, h * 0.15))
	_draw_lantern(Vector2(w * 0.10, h * 0.90), minf(w, h) * 0.055)
	_draw_lantern(Vector2(w * 0.91, h * 0.91), minf(w, h) * 0.044)
	_draw_flying_shape(Vector2(w * 0.23, h * 0.12), 19.0)
	_draw_flying_shape(Vector2(w * 0.31, h * 0.16), 13.0)
	_draw_flying_shape(Vector2(w * 0.74, h * 0.13), 15.0)

func _draw_tree(base: Vector2, height: float) -> void:
	var c := Color("171313")
	var trunk := height * 0.07
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-trunk, 0), base + Vector2(trunk, 0),
		base + Vector2(trunk * 0.34, -height), base + Vector2(-trunk * 0.38, -height)
	]), c)
	var top := base + Vector2(0, -height * 0.82)
	for k in range(7):
		var p := top + Vector2(0, float(k) * height * 0.085)
		var spread := height * (0.11 + float(k) * 0.017)
		draw_line(p, p + Vector2(-spread, -height * 0.10), c, maxf(4.0, height * 0.022), true)
		draw_line(p, p + Vector2(spread, -height * 0.13), c, maxf(4.0, height * 0.022), true)

func _draw_house(pos: Vector2, s: Vector2) -> void:
	var c := Color("111113")
	draw_rect(Rect2(pos.x - s.x * 0.50, pos.y - s.y * 0.55, s.x, s.y * 0.55), c, true)
	for tower in [-0.38, 0.0, 0.38]:
		var tx := pos.x + s.x * float(tower)
		var tw := s.x * (0.22 if float(tower) != 0.0 else 0.28)
		var th := s.y * (0.68 if float(tower) != 0.0 else 0.88)
		draw_rect(Rect2(tx - tw * 0.5, pos.y - th, tw, th), c, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - tw * 0.66, pos.y - th), Vector2(tx + tw * 0.66, pos.y - th), Vector2(tx, pos.y - th - s.y * 0.16)
		]), c)
		draw_rect(Rect2(tx - 6, pos.y - th * 0.48, 12, 22), Color("ffb02e"), true)

func _draw_lantern(center: Vector2, radius: float) -> void:
	for i in range(4, 0, -1):
		draw_circle(center, radius + float(i) * 7.0, Color(1.0, 0.47, 0.06, 0.025 * float(5 - i)))
	draw_circle(center, radius, Color("d96c12"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius * 0.46, -radius * 0.14), center + Vector2(-radius * 0.17, -radius * 0.31), center + Vector2(-radius * 0.23, radius * 0.02)
	]), Color("1b1712"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(radius * 0.46, -radius * 0.14), center + Vector2(radius * 0.17, -radius * 0.31), center + Vector2(radius * 0.23, radius * 0.02)
	]), Color("1b1712"))
	draw_arc(center + Vector2(0, radius * 0.10), radius * 0.42, 0.25, PI - 0.25, 18, Color("1b1712"), 5.0, true)

func _draw_flying_shape(center: Vector2, span: float) -> void:
	var c := Color("141214")
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-span, 0), center + Vector2(-span * 0.45, -span * 0.32), center,
		center + Vector2(span * 0.45, -span * 0.32), center + Vector2(span, 0),
		center + Vector2(span * 0.45, span * 0.16), center, center + Vector2(-span * 0.45, span * 0.16)
	]), c)
