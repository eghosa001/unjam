class_name Unjam3DBackdrop
extends Control

var accent: Color = Unjam3DTheme.GREEN
var dark_mode := false

func configure(value: Color, use_dark_mode: bool = false) -> void:
	accent = value
	dark_mode = use_dark_mode
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

	_draw_sky(w, h)
	_draw_distant_world(w, h)
	_draw_water_world(w, h)
	_draw_foreground(w, h)
	if dark_mode:
		# Keep the same cheerful geometry while shifting the environment into a
		# night palette. Accent colors remain visible through the translucent veil.
		draw_rect(Rect2(0, 0, w, h), Color(0.015, 0.045, 0.105, 0.58))
		draw_rect(Rect2(0, 0, w, h * 0.42), Color(0.055, 0.075, 0.18, 0.18))

func _draw_sky(w: float, h: float) -> void:
	# More bands than before keeps the large mobile background smooth without a shader.
	var bands := 36
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var y := h * t
		var band_h := h / float(bands) + 2.0
		var sky_color := Color("31b5ff").lerp(Color("eafcff"), pow(t, 0.86))
		draw_rect(Rect2(0, y, w, band_h), sky_color)

	# Warm sun bloom gives the same cheerful fantasy-game lighting as the reference.
	var sun := Vector2(w * 0.77, h * 0.105)
	for i in range(5, 0, -1):
		var radius := w * (0.034 + float(i) * 0.018)
		draw_circle(sun, radius, Color(1.0, 0.91, 0.52, 0.018 + float(6 - i) * 0.012))
	draw_circle(sun, w * 0.038, Color("fff0a3"))
	draw_circle(sun - Vector2(w * 0.010, w * 0.010), w * 0.017, Color(1, 1, 1, 0.52))

	_draw_cloud(Vector2(w * 0.14, h * 0.13), w * 0.060, 0.78)
	_draw_cloud(Vector2(w * 0.52, h * 0.205), w * 0.044, 0.52)
	_draw_cloud(Vector2(w * 0.86, h * 0.19), w * 0.055, 0.66)

	# Tiny atmospheric sparkles; deterministic so screenshots are stable.
	for p in [Vector2(0.23,0.09), Vector2(0.36,0.18), Vector2(0.65,0.12), Vector2(0.91,0.29), Vector2(0.08,0.27)]:
		var point := Vector2(w * p.x, h * p.y)
		draw_circle(point, maxf(2.0, w * 0.0035), Color(1,1,1,0.68))
		draw_line(point - Vector2(w * 0.008, 0), point + Vector2(w * 0.008, 0), Color(1,1,1,0.30), 2.0)

func _draw_distant_world(w: float, h: float) -> void:
	# Blue atmospheric mountain layer.
	var distant := PackedVector2Array([
		Vector2(0, h * 0.42), Vector2(w * 0.11, h * 0.31), Vector2(w * 0.20, h * 0.36),
		Vector2(w * 0.34, h * 0.24), Vector2(w * 0.46, h * 0.39), Vector2(w * 0.61, h * 0.27),
		Vector2(w * 0.73, h * 0.38), Vector2(w * 0.87, h * 0.25), Vector2(w, h * 0.34),
		Vector2(w, h * 0.62), Vector2(0, h * 0.62)
	])
	draw_colored_polygon(distant, Color("75c6cf"))
	var distant_light := PackedVector2Array([
		Vector2(w * 0.10, h * 0.34), Vector2(w * 0.34, h * 0.24), Vector2(w * 0.27, h * 0.43),
		Vector2(w * 0.60, h * 0.27), Vector2(w * 0.52, h * 0.45), Vector2(w * 0.87, h * 0.25),
		Vector2(w * 0.81, h * 0.45)
	])
	draw_polyline(distant_light, Color(0.85, 1.0, 0.95, 0.28), maxf(2.0, w * 0.004), true)

	# Near cliffs use light caps plus darker rock faces for an extruded 3D look.
	var cliff_face := PackedVector2Array([
		Vector2(0, h * 0.58), Vector2(w * 0.12, h * 0.46), Vector2(w * 0.28, h * 0.55),
		Vector2(w * 0.43, h * 0.42), Vector2(w * 0.60, h * 0.57), Vector2(w * 0.76, h * 0.43),
		Vector2(w, h * 0.51), Vector2(w, h * 0.72), Vector2(0, h * 0.72)
	])
	draw_colored_polygon(cliff_face, Color("2c805f"))
	var grass_cap := PackedVector2Array([
		Vector2(0, h * 0.535), Vector2(w * 0.12, h * 0.415), Vector2(w * 0.28, h * 0.505),
		Vector2(w * 0.43, h * 0.372), Vector2(w * 0.60, h * 0.518), Vector2(w * 0.76, h * 0.385),
		Vector2(w, h * 0.465), Vector2(w, h * 0.525), Vector2(w * 0.76, h * 0.455),
		Vector2(w * 0.60, h * 0.588), Vector2(w * 0.43, h * 0.455), Vector2(w * 0.28, h * 0.575),
		Vector2(w * 0.12, h * 0.485), Vector2(0, h * 0.605)
	])
	draw_colored_polygon(grass_cap, Color("61cd65"))
	draw_polyline(grass_cap, Color("b4f57c"), maxf(2.0, w * 0.004), true)

	# Floating islands provide foreground depth without covering the UI center.
	_draw_floating_island(Vector2(w * 0.12, h * 0.39), w * 0.070)
	_draw_floating_island(Vector2(w * 0.90, h * 0.365), w * 0.062)

	# Rock ledges and trees around the horizon.
	for item in [Vector2(0.08,0.48), Vector2(0.19,0.45), Vector2(0.82,0.43), Vector2(0.94,0.48)]:
		_draw_rock(Vector2(w * item.x, h * item.y), w * 0.033)
	for item in [Vector2(0.06,0.40), Vector2(0.18,0.37), Vector2(0.84,0.35), Vector2(0.95,0.40)]:
		_draw_tree(Vector2(w * item.x, h * item.y), w * 0.028)

func _draw_water_world(w: float, h: float) -> void:
	# Three waterfalls with a shaded edge and luminous center.
	for x in [w * 0.215, w * 0.505, w * 0.785]:
		var fall_top := h * 0.445
		var fall_height := h * 0.265
		draw_rect(Rect2(x - w * 0.031, fall_top, w * 0.062, fall_height), Color("4bbdd0"))
		draw_rect(Rect2(x - w * 0.022, fall_top, w * 0.044, fall_height), Color("b8f9ff"))
		draw_rect(Rect2(x - w * 0.008, fall_top, w * 0.016, fall_height), Color(1, 1, 1, 0.76))
		for splash_x in [-0.025, 0.0, 0.025]:
			draw_circle(Vector2(x + w * splash_x, fall_top + fall_height), w * 0.023, Color(0.75, 0.98, 1.0, 0.44))

	# River gradient and perspective streaks.
	var water_top := h * 0.675
	for i in range(12):
		var t := float(i) / 11.0
		var yy := water_top + (h - water_top) * t
		var band_h := (h - water_top) / 11.0 + 2.0
		draw_rect(Rect2(0, yy, w, band_h), Color("20bddc").lerp(Color("087fbb"), t * 0.82))
	for i in range(8):
		var yy := h * (0.71 + float(i) * 0.036)
		var inset := w * (0.03 + float(i) * 0.018)
		draw_line(Vector2(inset, yy), Vector2(w - inset, yy - h * 0.010), Color(0.80, 1.0, 1.0, 0.18), maxf(2.0, w * 0.003))

	# Stepping stones pull the eye toward the central play area.
	for i in range(5):
		var t := float(i) / 4.0
		var p := Vector2(w * (0.37 + t * 0.26), h * (0.78 + t * 0.042))
		var r := w * (0.035 - t * 0.007)
		draw_circle(p + Vector2(0, r * 0.30), r, Color(0.02,0.20,0.28,0.22))
		draw_circle(p, r, Color("9aa899"))
		draw_circle(p - Vector2(r * 0.20, r * 0.20), r * 0.70, Color("cbd6b8"))

func _draw_foreground(w: float, h: float) -> void:
	# Darker foreground foliage makes the center feel brighter and deeper.
	for side in [0, 1]:
		var direction := -1.0 if side == 0 else 1.0
		var sx := w * (0.015 if side == 0 else 0.985)
		for i in range(12):
			var y := h * (0.07 + float(i) * 0.078)
			var r := w * (0.025 + float(i % 4) * 0.004)
			draw_circle(Vector2(sx, y) + Vector2(direction * r * 0.25, r * 0.24), r * 1.40, Color("0d633d"))
			draw_circle(Vector2(sx, y), r * 1.12, Color("1f9b50"))
			draw_circle(Vector2(sx - direction * r * 0.45, y - r * 0.28), r * 0.78, Color("67d35d"))
			draw_circle(Vector2(sx - direction * r * 0.62, y - r * 0.52), r * 0.35, Color("b4ed65"))

	# Flowers, mushrooms and gem-like accent specks around the safe margins.
	var flower_points := [Vector2(0.075,0.78), Vector2(0.14,0.88), Vector2(0.20,0.76), Vector2(0.81,0.87), Vector2(0.88,0.78), Vector2(0.94,0.90)]
	for p in flower_points:
		var center := Vector2(w * p.x, h * p.y)
		_draw_flower(center, w * 0.010)
	for p in [Vector2(0.10,0.68), Vector2(0.91,0.67), Vector2(0.16,0.94), Vector2(0.84,0.95)]:
		var center := Vector2(w * p.x, h * p.y)
		draw_circle(center + Vector2(0, w * 0.010), w * 0.009, Color("fff5da"))
		draw_circle(center, w * 0.016, accent.lightened(0.20))
		draw_arc(center, w * 0.016, PI, TAU, 16, Color.WHITE, maxf(1.5, w * 0.002), true)

func _draw_cloud(center: Vector2, radius: float, alpha: float) -> void:
	var shadow := Color(0.18, 0.55, 0.72, alpha * 0.16)
	draw_circle(center + Vector2(radius * 0.10, radius * 0.28), radius * 1.06, shadow)
	draw_circle(center, radius, Color(1,1,1,alpha))
	draw_circle(center + Vector2(radius * 0.78, radius * 0.18), radius * 0.72, Color(1,1,1,alpha * 0.92))
	draw_circle(center - Vector2(radius * 0.72, -radius * 0.14), radius * 0.63, Color(1,1,1,alpha * 0.88))
	draw_circle(center + Vector2(radius * 0.14, -radius * 0.46), radius * 0.72, Color(1,1,1,alpha * 0.92))
	draw_circle(center - Vector2(radius * 0.24, radius * 0.30), radius * 0.34, Color(1,1,1,alpha * 0.40))

func _draw_floating_island(center: Vector2, radius: float) -> void:
	var underside := PackedVector2Array([
		center + Vector2(-radius, 0), center + Vector2(radius, 0),
		center + Vector2(radius * 0.55, radius * 0.70), center + Vector2(0, radius * 1.55),
		center + Vector2(-radius * 0.55, radius * 0.70)
	])
	draw_colored_polygon(underside, Color("55635c"))
	var top := PackedVector2Array([
		center + Vector2(-radius, 0), center + Vector2(-radius * 0.62, -radius * 0.35),
		center + Vector2(0, -radius * 0.52), center + Vector2(radius * 0.70, -radius * 0.28),
		center + Vector2(radius, 0), center + Vector2(0, radius * 0.24)
	])
	draw_colored_polygon(top, Color("66d363"))
	draw_polyline(top + PackedVector2Array([top[0]]), Color("b4f57c"), maxf(1.5, radius * 0.055), true)
	_draw_tree(center - Vector2(0, radius * 0.50), radius * 0.28)

func _draw_tree(base: Vector2, scale_value: float) -> void:
	draw_line(base + Vector2(0, scale_value * 1.4), base - Vector2(0, scale_value * 1.3), Color("75472d"), scale_value * 0.30, true)
	draw_circle(base - Vector2(0, scale_value * 1.6), scale_value * 0.92, Color("177c45"))
	draw_circle(base - Vector2(scale_value * 0.55, scale_value * 1.35), scale_value * 0.72, Color("2daf51"))
	draw_circle(base + Vector2(scale_value * 0.50, -scale_value * 1.42), scale_value * 0.68, Color("55cb59"))
	draw_circle(base - Vector2(scale_value * 0.28, scale_value * 1.95), scale_value * 0.58, Color("8ee55f"))

func _draw_rock(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius, radius * 0.46), center + Vector2(-radius * 0.72, -radius * 0.38),
		center + Vector2(-radius * 0.10, -radius), center + Vector2(radius * 0.72, -radius * 0.50),
		center + Vector2(radius, radius * 0.44), center + Vector2(0, radius * 0.82)
	])
	draw_colored_polygon(points, Color("657c78"))
	draw_polyline(PackedVector2Array([points[1], points[2], points[3]]), Color("a7c4ad"), maxf(1.0, radius * 0.12), true)

func _draw_flower(center: Vector2, radius: float) -> void:
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_circle(center + direction * radius * 0.90, radius * 0.72, Color("ff59ac"))
	draw_circle(center, radius * 0.66, Color("ffd83d"))
	draw_circle(center - Vector2(radius * 0.18, radius * 0.18), radius * 0.20, Color.WHITE)
