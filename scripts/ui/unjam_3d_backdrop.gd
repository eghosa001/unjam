class_name Unjam3DBackdrop
extends Control

var accent: Color = Unjam3DTheme.GREEN

func configure(value: Color) -> void:
	accent = value
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0 or h <= 1.0:
		return

	# Bright sky gradient built from inexpensive bands.
	var bands := 20
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var y := h * t
		var bh := h / float(bands) + 2.0
		draw_rect(Rect2(0, y, w, bh), Unjam3DTheme.SKY_TOP.lerp(Unjam3DTheme.SKY_BOTTOM, t))

	# Soft clouds.
	for cloud in [Vector2(w * 0.14, h * 0.15), Vector2(w * 0.78, h * 0.12), Vector2(w * 0.52, h * 0.27)]:
		draw_circle(cloud, w * 0.07, Color(1, 1, 1, 0.72))
		draw_circle(cloud + Vector2(w * 0.055, h * 0.012), w * 0.052, Color(1, 1, 1, 0.65))
		draw_circle(cloud - Vector2(w * 0.05, -h * 0.008), w * 0.046, Color(1, 1, 1, 0.62))

	# Distant fantasy cliffs.
	var cliff := PackedVector2Array([
		Vector2(0, h * 0.40), Vector2(w * 0.13, h * 0.28), Vector2(w * 0.28, h * 0.43),
		Vector2(w * 0.43, h * 0.31), Vector2(w * 0.62, h * 0.45), Vector2(w * 0.82, h * 0.29),
		Vector2(w, h * 0.38), Vector2(w, h * 0.70), Vector2(0, h * 0.70)
	])
	draw_colored_polygon(cliff, Color("8bd4d2"))
	var near_cliff := PackedVector2Array([
		Vector2(0, h * 0.56), Vector2(w * 0.18, h * 0.46), Vector2(w * 0.33, h * 0.58),
		Vector2(w * 0.53, h * 0.44), Vector2(w * 0.72, h * 0.57), Vector2(w, h * 0.47),
		Vector2(w, h), Vector2(0, h)
	])
	draw_colored_polygon(near_cliff, Color("45aa79"))

	# Waterfalls and river glow.
	for x in [w * 0.21, w * 0.50, w * 0.77]:
		draw_rect(Rect2(x - w * 0.025, h * 0.43, w * 0.05, h * 0.27), Color("dffcff"))
		draw_rect(Rect2(x - w * 0.012, h * 0.43, w * 0.024, h * 0.27), Color("7fe9ff"))
		draw_circle(Vector2(x, h * 0.70), w * 0.055, Color(0.55, 0.95, 1.0, 0.50))
	draw_rect(Rect2(0, h * 0.67, w, h * 0.33), Color("1fb8d8"))
	for i in range(6):
		var yy := h * (0.72 + i * 0.045)
		draw_line(Vector2(0, yy), Vector2(w, yy - h * 0.012), Color(0.75, 0.98, 1.0, 0.18), 3.0)

	# Layered foliage around the edges so the center remains readable.
	for side in [0, 1]:
		var sx := w * 0.03 if side == 0 else w * 0.97
		for i in range(10):
			var y := h * (0.08 + i * 0.09)
			var r := w * (0.025 + float(i % 3) * 0.005)
			draw_circle(Vector2(sx, y), r * 1.25, Color("176f43"))
			draw_circle(Vector2(sx + (-r * 0.45 if side == 0 else r * 0.45), y - r * 0.18), r, Color("31b85f"))
			draw_circle(Vector2(sx + (r * 0.30 if side == 0 else -r * 0.30), y + r * 0.22), r * 0.72, Color("82e15d"))

	# Flowers and accent sparkles.
	for p in [Vector2(w * 0.10, h * 0.78), Vector2(w * 0.18, h * 0.88), Vector2(w * 0.84, h * 0.82), Vector2(w * 0.91, h * 0.72)]:
		draw_circle(p, w * 0.012, Color("ff4ca5"))
		draw_circle(p + Vector2(w * 0.014, 0), w * 0.010, Color("ffd83d"))
		draw_circle(p + Vector2(w * 0.006, -w * 0.012), w * 0.009, accent.lightened(0.25))
