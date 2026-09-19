class_name Unjam3DBackdrop
extends Control

# Persistent code-rendered UNJAM world.  The launcher stays asset-light and
# responsive, but the composition now follows a premium casual-game scene:
# cinematic sky, floating islands, cliff terraces, bridge, waterfalls, glossy
# river depth and foreground foliage.  No UI is baked into this layer.
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
	_draw_sun_and_clouds(w, h)
	_draw_far_mountains(w, h)
	_draw_floating_islands(w, h)
	_draw_bridge_and_cliffs(w, h)
	_draw_waterfalls(w, h)
	_draw_river(w, h)
	_draw_shoreline_details(w, h)
	_draw_foreground_frame(w, h)
	_draw_world_sparkles(w, h)
	if dark_mode:
		# Preserve the same geometry at night.  A cool translucent veil shifts
		# the palette without flattening the highlights or accent reflections.
		draw_rect(Rect2(0, 0, w, h), Color(0.015, 0.035, 0.095, 0.52))
		draw_rect(Rect2(0, 0, w, h * 0.58), Color(0.035, 0.075, 0.17, 0.16))
		draw_circle(Vector2(w * 0.82, h * 0.10), w * 0.10, Color(accent, 0.06))

func _draw_sky(w: float, h: float) -> void:
	var bands := 72
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var y := h * 0.56 * t
		var band_h := h * 0.56 / float(bands) + 2.0
		var upper := Color("24aef5")
		var lower := Color("e7fbff")
		var c := upper.lerp(lower, pow(t, 0.82))
		if t > 0.72:
			c = c.lerp(Color("c7f3ff"), (t - 0.72) / 0.28 * 0.32)
		draw_rect(Rect2(0, y, w, band_h), c)
	# Warm horizon band gives the waterfall valley a luminous focal plane.
	for i in range(12):
		var t := float(i) / 11.0
		draw_rect(
			Rect2(0, h * (0.34 + t * 0.019), w, h * 0.025),
			Color(1.0, 0.96, 0.74, 0.018 + (1.0 - t) * 0.018)
		)

func _draw_sun_and_clouds(w: float, h: float) -> void:
	var sun := Vector2(w * 0.83, h * 0.105)
	for i in range(10, 0, -1):
		var t := float(i) / 10.0
		var radius := w * (0.045 + t * 0.105)
		draw_circle(sun, radius, Color(1.0, 0.86, 0.42, 0.010 + (1.0 - t) * 0.022))
	for angle in [-0.58, -0.31, -0.08, 0.18, 0.43]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(
			sun + dir * w * 0.06,
			sun + dir * w * 0.20,
			Color(1.0, 0.92, 0.66, 0.12),
			maxf(2.0, w * 0.004),
			true
		)
	draw_circle(sun, w * 0.040, Color("fff0a0"))
	draw_circle(sun - Vector2(w * 0.010, w * 0.011), w * 0.017, Color(1, 1, 1, 0.66))

	_draw_cloud(Vector2(w * 0.13, h * 0.125), w * 0.060, 0.90)
	_draw_cloud(Vector2(w * 0.47, h * 0.205), w * 0.044, 0.56)
	_draw_cloud(Vector2(w * 0.72, h * 0.185), w * 0.038, 0.42)
	_draw_cloud(Vector2(w * 0.93, h * 0.20), w * 0.052, 0.68)

func _draw_far_mountains(w: float, h: float) -> void:
	var back := PackedVector2Array([
		Vector2(0, h * 0.39), Vector2(w * 0.10, h * 0.30), Vector2(w * 0.19, h * 0.36),
		Vector2(w * 0.31, h * 0.245), Vector2(w * 0.43, h * 0.37), Vector2(w * 0.54, h * 0.27),
		Vector2(w * 0.64, h * 0.38), Vector2(w * 0.76, h * 0.255), Vector2(w * 0.88, h * 0.35),
		Vector2(w, h * 0.27), Vector2(w, h * 0.53), Vector2(0, h * 0.53)
	])
	draw_colored_polygon(back, Color("80c9d0"))
	var middle := PackedVector2Array([
		Vector2(0, h * 0.44), Vector2(w * 0.13, h * 0.34), Vector2(w * 0.24, h * 0.43),
		Vector2(w * 0.39, h * 0.31), Vector2(w * 0.50, h * 0.44), Vector2(w * 0.66, h * 0.325),
		Vector2(w * 0.79, h * 0.44), Vector2(w * 0.91, h * 0.34), Vector2(w, h * 0.41),
		Vector2(w, h * 0.58), Vector2(0, h * 0.58)
	])
	draw_colored_polygon(middle, Color("58a98c"))
	var ridge := PackedVector2Array([
		Vector2(0, h * 0.455), Vector2(w * 0.13, h * 0.355), Vector2(w * 0.24, h * 0.445),
		Vector2(w * 0.39, h * 0.325), Vector2(w * 0.50, h * 0.455), Vector2(w * 0.66, h * 0.34),
		Vector2(w * 0.79, h * 0.455), Vector2(w * 0.91, h * 0.355), Vector2(w, h * 0.425)
	])
	draw_polyline(ridge, Color(0.83, 1.0, 0.82, 0.42), maxf(2.0, w * 0.005), true)

	# Atmospheric depth separates the distant ridge from the interactive UI.
	for i in range(6):
		var t := float(i) / 5.0
		draw_rect(
			Rect2(0, h * (0.34 + t * 0.035), w, h * 0.09),
			Color(0.90, 0.995, 1.0, 0.038 - t * 0.004)
		)

func _draw_floating_islands(w: float, h: float) -> void:
	_draw_floating_island(Vector2(w * 0.08, h * 0.245), w * 0.075, 0.92)
	_draw_floating_island(Vector2(w * 0.25, h * 0.155), w * 0.048, 0.70)
	_draw_floating_island(Vector2(w * 0.72, h * 0.165), w * 0.045, 0.62)
	_draw_floating_island(Vector2(w * 0.93, h * 0.255), w * 0.070, 0.86)

func _draw_bridge_and_cliffs(w: float, h: float) -> void:
	# Layered cliff band.  Shadow face, stone shelf and grass cap create real
	# foreground/midground separation instead of a single flat green polygon.
	var shadow_face := PackedVector2Array([
		Vector2(0, h * 0.535), Vector2(w * 0.10, h * 0.47), Vector2(w * 0.22, h * 0.505),
		Vector2(w * 0.34, h * 0.43), Vector2(w * 0.48, h * 0.515), Vector2(w * 0.61, h * 0.445),
		Vector2(w * 0.74, h * 0.515), Vector2(w * 0.86, h * 0.45), Vector2(w, h * 0.50),
		Vector2(w, h * 0.66), Vector2(0, h * 0.66)
	])
	draw_colored_polygon(shadow_face, Color("416b66"))
	var stone_shelf := PackedVector2Array([
		Vector2(0, h * 0.50), Vector2(w * 0.10, h * 0.435), Vector2(w * 0.22, h * 0.47),
		Vector2(w * 0.34, h * 0.395), Vector2(w * 0.48, h * 0.48), Vector2(w * 0.61, h * 0.41),
		Vector2(w * 0.74, h * 0.48), Vector2(w * 0.86, h * 0.415), Vector2(w, h * 0.465),
		Vector2(w, h * 0.54), Vector2(w * 0.86, h * 0.485), Vector2(w * 0.74, h * 0.55),
		Vector2(w * 0.61, h * 0.48), Vector2(w * 0.48, h * 0.55), Vector2(w * 0.34, h * 0.465),
		Vector2(w * 0.22, h * 0.54), Vector2(w * 0.10, h * 0.505), Vector2(0, h * 0.57)
	])
	draw_colored_polygon(stone_shelf, Color("8da89b"))
	var grass := PackedVector2Array([
		Vector2(0, h * 0.485), Vector2(w * 0.10, h * 0.42), Vector2(w * 0.22, h * 0.455),
		Vector2(w * 0.34, h * 0.38), Vector2(w * 0.48, h * 0.465), Vector2(w * 0.61, h * 0.395),
		Vector2(w * 0.74, h * 0.465), Vector2(w * 0.86, h * 0.40), Vector2(w, h * 0.45),
		Vector2(w, h * 0.482), Vector2(w * 0.86, h * 0.442), Vector2(w * 0.74, h * 0.505),
		Vector2(w * 0.61, h * 0.438), Vector2(w * 0.48, h * 0.505), Vector2(w * 0.34, h * 0.425),
		Vector2(w * 0.22, h * 0.50), Vector2(w * 0.10, h * 0.465), Vector2(0, h * 0.525)
	])
	draw_colored_polygon(grass, Color("54c85e"))
	draw_polyline(grass + PackedVector2Array([grass[0]]), Color("b6f878"), maxf(2.0, w * 0.0045), true)

	# Stone bridge appears to the right of the hero focal area, matching the
	# aspirational world art while keeping the centre calm for readable UI.
	var deck_y := h * 0.405
	draw_line(Vector2(w * 0.57, deck_y), Vector2(w * 0.91, deck_y - h * 0.018), Color("6f7d79"), w * 0.033, true)
	draw_line(Vector2(w * 0.57, deck_y - h * 0.008), Vector2(w * 0.91, deck_y - h * 0.026), Color("c7d5c4"), w * 0.010, true)
	for x in [0.62, 0.72, 0.82, 0.90]:
		var cx := w * x
		var top := deck_y - h * (0.004 + (x - 0.62) * 0.04)
		draw_line(Vector2(cx, top), Vector2(cx, h * 0.505), Color("657673"), w * 0.024, true)
		draw_line(Vector2(cx - w * 0.006, top), Vector2(cx - w * 0.006, h * 0.49), Color("aabcae"), w * 0.007, true)
	for x in [0.67, 0.77, 0.87]:
		var center := Vector2(w * x, h * 0.465)
		draw_arc(center, w * 0.048, PI, TAU, 24, Color("c6d4c4"), w * 0.011, true)

	# Sparse rounded trees on the horizon.  Different scales prevent stamped repetition.
	for item in [
		Vector3(0.07, 0.425, 0.021), Vector3(0.17, 0.405, 0.027), Vector3(0.29, 0.415, 0.019),
		Vector3(0.44, 0.425, 0.024), Vector3(0.56, 0.405, 0.018), Vector3(0.78, 0.395, 0.021),
		Vector3(0.94, 0.425, 0.028)
	]:
		_draw_tree(Vector2(w * item.x, h * item.y), w * item.z, 0.92)

func _draw_waterfalls(w: float, h: float) -> void:
	var falls := [
		Vector3(0.155, 0.455, 0.055),
		Vector3(0.405, 0.455, 0.072),
		Vector3(0.665, 0.465, 0.060),
		Vector3(0.885, 0.445, 0.045)
	]
	for fall in falls:
		var x := w * fall.x
		var width := w * fall.z
		var top := h * fall.y
		var bottom := h * 0.665
		# Dark cyan edge, pale body and white center make the water read as
		# translucent volume instead of a flat rectangle.
		draw_rect(Rect2(x - width * 0.52, top, width * 1.04, bottom - top), Color("179dbc"))
		draw_rect(Rect2(x - width * 0.42, top, width * 0.84, bottom - top), Color("70dff0"))
		draw_rect(Rect2(x - width * 0.22, top, width * 0.44, bottom - top), Color("c9fbff"))
		draw_rect(Rect2(x - width * 0.07, top, width * 0.14, bottom - top), Color(1, 1, 1, 0.82))
		for n in range(5):
			var sx := x + width * (-0.38 + float(n) * 0.19)
			draw_circle(Vector2(sx, bottom), width * (0.18 + float(n % 2) * 0.03), Color(0.84, 1.0, 1.0, 0.36))
		draw_line(Vector2(x - width * 0.40, top + h * 0.018), Vector2(x - width * 0.20, bottom - h * 0.025), Color(1,1,1,0.24), maxf(1.5, w * 0.0025), true)

func _draw_river(w: float, h: float) -> void:
	var water_top := h * 0.61
	var bands := 32
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var y := water_top + (h - water_top) * t
		var bh := (h - water_top) / float(bands) + 2.0
		var c := Color("36d6e7").lerp(Color("0879bb"), pow(t, 0.82))
		c = c.lerp(accent, 0.045)
		draw_rect(Rect2(0, y, w, bh), c)

	# Horizon glow and deep side vignette add depth without darkening the centre.
	draw_rect(Rect2(0, water_top, w, h * 0.018), Color(0.85, 1.0, 1.0, 0.42))
	for i in range(13):
		var t := float(i) / 12.0
		var yy := h * (0.665 + t * 0.025)
		var inset := w * (0.025 + t * 0.030)
		draw_line(Vector2(inset, yy), Vector2(w - inset, yy - h * 0.006), Color(0.86, 1.0, 1.0, 0.16), maxf(1.5, w * 0.0025), true)

	# Long glossy reflection lanes point toward the centre focal area.
	for lane in [
		Vector3(0.16, 0.70, 0.060), Vector3(0.39, 0.76, 0.085),
		Vector3(0.61, 0.72, 0.070), Vector3(0.82, 0.80, 0.055)
	]:
		var center := Vector2(w * lane.x, h * lane.y)
		var half_len := w * lane.z
		draw_line(center - Vector2(half_len, 0), center + Vector2(half_len, 0), Color(0.94, 1.0, 1.0, 0.30), maxf(2.0, w * 0.004), true)
		draw_line(center - Vector2(half_len * 0.52, h * 0.007), center + Vector2(half_len * 0.52, -h * 0.007), Color(1,1,1,0.22), maxf(1.5, w * 0.0025), true)

	# Perspective stepping stones with underwater shadows and highlights.
	var stones := [
		Vector3(0.52, 0.735, 0.050), Vector3(0.49, 0.785, 0.046),
		Vector3(0.47, 0.835, 0.041), Vector3(0.45, 0.882, 0.035)
	]
	for stone in stones:
		var p := Vector2(w * stone.x, h * stone.y)
		var r := w * stone.z
		draw_circle(p + Vector2(r * 0.10, r * 0.36), r * 1.12, Color(0.01, 0.18, 0.28, 0.23))
		draw_circle(p, r, Color("819990"))
		draw_circle(p - Vector2(r * 0.18, r * 0.22), r * 0.76, Color("c8d6c0"))
		draw_arc(p - Vector2(r * 0.10, r * 0.13), r * 0.72, 3.4, 5.55, 20, Color(1,1,1,0.28), maxf(1.0, r * 0.10), true)
		for ring in range(2):
			draw_arc(p + Vector2(0, r * 0.45), r * (1.25 + ring * 0.28), 0.10, PI - 0.10, 24, Color(0.78, 1.0, 1.0, 0.14), maxf(1.0, w * 0.0018), true)

func _draw_shoreline_details(w: float, h: float) -> void:
	# Rocky banks make the river feel physically contained.
	var left_bank := PackedVector2Array([
		Vector2(0, h * 0.59), Vector2(w * 0.17, h * 0.62), Vector2(w * 0.21, h * 0.70),
		Vector2(w * 0.15, h * 0.79), Vector2(0, h * 0.84)
	])
	var right_bank := PackedVector2Array([
		Vector2(w, h * 0.59), Vector2(w * 0.83, h * 0.62), Vector2(w * 0.79, h * 0.70),
		Vector2(w * 0.85, h * 0.79), Vector2(w, h * 0.84)
	])
	draw_colored_polygon(left_bank, Color("758f7c"))
	draw_colored_polygon(right_bank, Color("758f7c"))
	var left_grass := PackedVector2Array([
		Vector2(0, h * 0.575), Vector2(w * 0.18, h * 0.61), Vector2(w * 0.20, h * 0.645),
		Vector2(w * 0.15, h * 0.675), Vector2(0, h * 0.65)
	])
	var right_grass := PackedVector2Array([
		Vector2(w, h * 0.575), Vector2(w * 0.82, h * 0.61), Vector2(w * 0.80, h * 0.645),
		Vector2(w * 0.85, h * 0.675), Vector2(w, h * 0.65)
	])
	draw_colored_polygon(left_grass, Color("55cc59"))
	draw_colored_polygon(right_grass, Color("55cc59"))
	draw_polyline(left_grass, Color("a8f16a"), maxf(2.0, w * 0.004), true)
	draw_polyline(right_grass, Color("a8f16a"), maxf(2.0, w * 0.004), true)

	for item in [
		Vector3(0.055, 0.62, 0.030), Vector3(0.13, 0.66, 0.022),
		Vector3(0.87, 0.655, 0.024), Vector3(0.95, 0.615, 0.032)
	]:
		_draw_tree(Vector2(w * item.x, h * item.y), w * item.z, 1.0)

	# Lily pads and flowers bring the glossy water closer to the approved target.
	for item in [Vector2(0.12,0.78), Vector2(0.24,0.90), Vector2(0.76,0.86), Vector2(0.89,0.76)]:
		var p := Vector2(w * item.x, h * item.y)
		var r := w * 0.024
		draw_circle(p + Vector2(0, r * 0.16), r, Color(0.02,0.24,0.24,0.22))
		draw_circle(p, r, Color("43b750"))
		draw_line(p, p + Vector2(r * 0.95, -r * 0.15), Color("0a8542"), maxf(1.0, r * 0.08), true)
		if item.x in [0.24, 0.76]:
			_draw_flower(p - Vector2(0, r * 0.20), r * 0.32)

func _draw_foreground_frame(w: float, h: float) -> void:
	# Irregular foliage clusters frame the scene rather than repeating evenly down
	# the entire edge.  Large blurred-looking leaves stay away from touch targets.
	var clusters := [
		Vector3(-0.015,0.14,0.050), Vector3(0.018,0.34,0.038), Vector3(-0.010,0.57,0.044),
		Vector3(1.015,0.16,0.047), Vector3(0.985,0.36,0.036), Vector3(1.010,0.58,0.045),
		Vector3(0.04,0.93,0.060), Vector3(0.96,0.94,0.064)
	]
	for item in clusters:
		var base := Vector2(w * item.x, h * item.y)
		var r := w * item.z
		_draw_leaf_cluster(base, r)

	# Warm flowers punctuate the green frame and echo monetization/accent colors.
	for p in [Vector2(0.07,0.74), Vector2(0.16,0.88), Vector2(0.82,0.91), Vector2(0.93,0.77)]:
		_draw_flower(Vector2(w * p.x, h * p.y), w * 0.010)

func _draw_world_sparkles(w: float, h: float) -> void:
	for p in [
		Vector2(0.18,0.12), Vector2(0.34,0.18), Vector2(0.60,0.12), Vector2(0.91,0.29),
		Vector2(0.18,0.72), Vector2(0.34,0.81), Vector2(0.61,0.76), Vector2(0.79,0.84)
	]:
		var center := Vector2(w * p.x, h * p.y)
		var r := maxf(1.8, w * 0.0028)
		draw_circle(center, r, Color(1,1,1,0.72))
		draw_line(center - Vector2(r * 3.2, 0), center + Vector2(r * 3.2, 0), Color(1,1,1,0.28), maxf(1.0, r * 0.55), true)

func _draw_cloud(center: Vector2, radius: float, alpha: float) -> void:
	var shadow := Color(0.10, 0.42, 0.64, alpha * 0.17)
	draw_circle(center + Vector2(radius * 0.12, radius * 0.30), radius * 1.08, shadow)
	draw_circle(center, radius, Color(1,1,1,alpha))
	draw_circle(center + Vector2(radius * 0.78, radius * 0.18), radius * 0.72, Color(1,1,1,alpha * 0.94))
	draw_circle(center - Vector2(radius * 0.72, -radius * 0.14), radius * 0.63, Color(1,1,1,alpha * 0.90))
	draw_circle(center + Vector2(radius * 0.14, -radius * 0.46), radius * 0.74, Color(1,1,1,alpha * 0.95))
	draw_circle(center - Vector2(radius * 0.24, radius * 0.30), radius * 0.35, Color(1,1,1,alpha * 0.48))

func _draw_floating_island(center: Vector2, radius: float, opacity: float) -> void:
	var shadow_center := center + Vector2(radius * 0.08, radius * 0.20)
	draw_circle(shadow_center, radius * 1.05, Color(0.02,0.20,0.24,0.12 * opacity))
	var underside := PackedVector2Array([
		center + Vector2(-radius, 0), center + Vector2(radius, 0),
		center + Vector2(radius * 0.60, radius * 0.72), center + Vector2(radius * 0.18, radius * 1.34),
		center + Vector2(-radius * 0.12, radius * 1.62), center + Vector2(-radius * 0.55, radius * 0.78)
	])
	draw_colored_polygon(underside, Color(0.31, 0.40, 0.39, opacity))
	var highlight_face := PackedVector2Array([
		center + Vector2(-radius * 0.72, radius * 0.12), center + Vector2(-radius * 0.05, radius * 0.28),
		center + Vector2(-radius * 0.12, radius * 1.25), center + Vector2(-radius * 0.45, radius * 0.72)
	])
	draw_colored_polygon(highlight_face, Color(0.52, 0.61, 0.55, 0.52 * opacity))
	var top := PackedVector2Array([
		center + Vector2(-radius, 0), center + Vector2(-radius * 0.60, -radius * 0.34),
		center + Vector2(0, -radius * 0.50), center + Vector2(radius * 0.72, -radius * 0.28),
		center + Vector2(radius, 0), center + Vector2(0, radius * 0.26)
	])
	draw_colored_polygon(top, Color(0.35, 0.80, 0.36, opacity))
	draw_polyline(top + PackedVector2Array([top[0]]), Color(0.76, 1.0, 0.50, 0.68 * opacity), maxf(1.5, radius * 0.055), true)
	_draw_tree(center - Vector2(radius * 0.15, radius * 0.55), radius * 0.25, opacity)
	# Tiny waterfall hanging from selected islands.
	draw_rect(Rect2(center.x + radius * 0.34, center.y + radius * 0.02, radius * 0.18, radius * 0.66), Color(0.75, 0.98, 1.0, 0.55 * opacity))
	draw_rect(Rect2(center.x + radius * 0.40, center.y + radius * 0.02, radius * 0.06, radius * 0.66), Color(1,1,1,0.54 * opacity))

func _draw_tree(base: Vector2, scale_value: float, opacity: float = 1.0) -> void:
	draw_line(base + Vector2(0, scale_value * 1.4), base - Vector2(0, scale_value * 1.3), Color(0.43,0.25,0.15,opacity), scale_value * 0.28, true)
	draw_circle(base - Vector2(0, scale_value * 1.55), scale_value * 0.96, Color(0.07,0.43,0.23,opacity))
	draw_circle(base - Vector2(scale_value * 0.58, scale_value * 1.34), scale_value * 0.74, Color(0.13,0.66,0.28,opacity))
	draw_circle(base + Vector2(scale_value * 0.52, -scale_value * 1.44), scale_value * 0.70, Color(0.31,0.78,0.31,opacity))
	draw_circle(base - Vector2(scale_value * 0.28, scale_value * 1.94), scale_value * 0.60, Color(0.56,0.90,0.36,opacity))
	draw_circle(base - Vector2(scale_value * 0.48, scale_value * 1.74), scale_value * 0.25, Color(0.80,1.0,0.55,0.60 * opacity))

func _draw_leaf_cluster(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(radius * 0.10, radius * 0.30), radius * 1.20, Color(0.01,0.28,0.18,0.30))
	draw_circle(center, radius, Color("08733b"))
	draw_circle(center + Vector2(radius * 0.58, -radius * 0.12), radius * 0.72, Color("16a747"))
	draw_circle(center - Vector2(radius * 0.48, radius * 0.08), radius * 0.68, Color("29bf4d"))
	draw_circle(center - Vector2(radius * 0.12, radius * 0.58), radius * 0.60, Color("78df53"))
	draw_circle(center - Vector2(radius * 0.35, radius * 0.67), radius * 0.22, Color("b9f06c"))

func _draw_flower(center: Vector2, radius: float) -> void:
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_circle(center + direction * radius * 0.88, radius * 0.70, Color("fffdf2"))
	draw_circle(center, radius * 0.66, Color("ffd83d"))
	draw_circle(center - Vector2(radius * 0.18, radius * 0.18), radius * 0.20, Color.WHITE)
