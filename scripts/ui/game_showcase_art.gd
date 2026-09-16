class_name GameShowcaseArt
extends Control

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var game_id := "rescue_rush"
var accent := Color("2dd4b6")
var phase := 0.0
var dark_mode := true
var _materials = MATERIALS_SCRIPT.new()

func configure(id: String, color: Color, dark: bool) -> void:
	game_id = id
	accent = color
	dark_mode = dark
	queue_redraw()

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("reduced_motion_aware")
	apply_motion_preference()

func apply_motion_preference() -> void:
	var reduced := MotionSystem.reduced()
	if reduced:
		phase = 0.0
	set_process(not reduced)
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var scale_factor := clampf(minf(size.x / 700.0, size.y / 520.0), 0.72, 1.65)
	draw_set_transform(size * 0.5, 0.0, Vector2.ONE * scale_factor)
	match game_id:
		"water_sort": _draw_water_sort()
		"block_puzzle": _draw_block_puzzle()
		_: _draw_rescue_rush()

func _draw_rescue_rush() -> void:
	var c := Vector2(0, 6)
	var pulse := 0.5 if MotionSystem.reduced() else 0.5 + 0.5 * sin(phase * 2.4)
	for i in range(4, 0, -1):
		draw_circle(c, 62.0 + float(i) * 34.0, Color(accent, 0.018 * float(i)))
	var rescue_y := 0.0 if MotionSystem.reduced() else sin(phase * 2.1) * 6.0
	var rescue_center := c + Vector2(0, rescue_y)
	var rescue_depth := _materials.extrusion_offset(0.85, MotionSystem.reduced())
	draw_circle(rescue_center + rescue_depth, 64, _materials.depth_tone(Color("ffd166")))
	draw_circle(rescue_center, 62, Color("ffd166"))
	draw_arc(rescue_center, 60, PI + 0.25, TAU - 0.25, 32, _materials.bevel_light(Color("ffd166")), 3.0, true)
	draw_circle(c + Vector2(-18, -7 + rescue_y), 6, Color("152033"))
	draw_circle(c + Vector2(18, -7 + rescue_y), 6, Color("152033"))
	draw_arc(c + Vector2(0, 13 + rescue_y), 19, 0.2, PI - 0.2, 24, Color("152033"), 4.5, true)
	var dirs: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for i in range(dirs.size()):
		var dir := dirs[i]
		var drift := 0.0 if MotionSystem.reduced() else sin(phase * 1.8 + float(i) * 0.8) * 9.0
		var distance := 152.0 + drift
		var center := c + dir * distance
		_draw_arrow_block(center, dir, i, pulse)
	var trail_start := c + Vector2(-250, 188)
	for i in range(6):
		var alpha := 0.20 - float(i) * 0.025
		var y := trail_start.y + float(i % 2) * 10.0
		draw_line(Vector2(trail_start.x + float(i) * 27.0, y), Vector2(trail_start.x + 76 + float(i) * 27.0, y), Color(accent, alpha), 7.0, true)

func _draw_arrow_block(center: Vector2, dir: Vector2, index: int, pulse: float) -> void:
	var rect := Rect2(center - Vector2(52, 39), Vector2(104, 78))
	var base := accent.lightened(float(index) * 0.035)
	var offset := _materials.extrusion_offset(0.90, MotionSystem.reduced())
	var layers := _materials.depth_layers_for(0.90, MotionSystem.reduced())
	for layer in range(layers, 0, -1):
		var factor := float(layer) / float(layers)
		_draw_box(Rect2(rect.position + offset * factor, rect.size), Color(_materials.depth_tone(base), 0.90), 22, Color.TRANSPARENT, 0)
	var shadow := Rect2(rect.position + offset + Vector2(0, 7), rect.size)
	_draw_box(shadow, Color(0, 0, 0, 0.20), 22, Color.TRANSPARENT, 0)
	_draw_box(rect, Color(base, 0.96), 22, Color(_materials.bevel_light(base), 0.66), 2)
	_draw_box(rect.grow(-6), Color(_materials.bevel_dark(base), 0.42), 17, Color.TRANSPARENT, 0)
	draw_line(rect.position + Vector2(19, 8), Vector2(rect.end.x - 19, rect.position.y + 8), Color(_materials.bevel_light(base), 0.62), 3.0, true)
	var n := Vector2(-dir.y, dir.x)
	var tip := center + dir * 27
	var tail := center - dir * 24
	var neck := center + dir * 6
	var points := PackedVector2Array([
		tail + n * 8,
		neck + n * 8,
		neck + n * 18,
		tip,
		neck - n * 18,
		neck - n * 8,
		tail - n * 8
	])
	draw_polygon(points, PackedColorArray([Color.WHITE]))
	draw_arc(center, 48 + pulse * 3.0, 0, TAU, 36, Color(_materials.bevel_light(base), 0.12 + pulse * 0.05), 2.0, true)

func _draw_water_sort() -> void:
	var c := Vector2.ZERO
	var colors: Array[Color] = [Color("ff6680"), Color("ffd166"), Color("5da9ff"), Color("43d6ad"), Color("9b7cff")]
	for i in range(5):
		var x := c.x - 224.0 + float(i) * 112.0
		var bob := 0.0 if MotionSystem.reduced() else sin(phase * 1.5 + float(i) * 0.7) * 5.0
		var y := c.y + 20.0 + bob
		_draw_tube(Vector2(x, y), colors, i)
	if not MotionSystem.reduced():
		var t := fposmod(phase * 0.55, 1.0)
		var from := Vector2(c.x - 112, c.y - 112)
		var to := Vector2(c.x + 112, c.y - 92)
		for i in range(4):
			var tp := maxf(0.0, t - float(i) * 0.045)
			var q := from.lerp(to, tp)
			q.y -= sin(tp * PI) * 62.0
			draw_circle(q, 8.0 - float(i) * 1.25, Color(colors[2], 0.86 - float(i) * 0.16))

func _draw_tube(center: Vector2, colors: Array[Color], index: int) -> void:
	var body := Rect2(center - Vector2(32, 108), Vector2(64, 216))
	var inner := Rect2(body.position + Vector2(8, 18), body.size - Vector2(16, 31))
	var depth := _materials.extrusion_offset(0.72, MotionSystem.reduced())
	_draw_box(Rect2(body.position + depth, body.size), _materials.depth_tone(Color(0.56, 0.84, 1.0, 0.20)), 30, Color.TRANSPARENT, 0)
	var shadow := Rect2(body.position + depth + Vector2(0, 6), body.size)
	_draw_box(shadow, Color(0, 0, 0, 0.18), 30, Color.TRANSPARENT, 0)
	_draw_box(body, Color(0.65, 0.88, 1.0, 0.09), 30, Color(_materials.bevel_light(Color(0.82, 0.95, 1.0, 0.60)), 0.60), 3)
	var slot_h := inner.size.y / 4.0
	for layer in range(4):
		var y := inner.end.y - slot_h * float(layer + 1)
		var r := Rect2(Vector2(inner.position.x + 2, y + 2), Vector2(inner.size.x - 4, slot_h - 3))
		var col := colors[(index + layer) % colors.size()]
		var liquid_depth := Rect2(r.position + Vector2(0, 3), r.size)
		_draw_box(liquid_depth, _materials.depth_tone(col), 6 if layer == 0 else 3, Color.TRANSPARENT, 0)
		_draw_box(r, Color(col, 0.94), 6 if layer == 0 else 3, Color.TRANSPARENT, 0)
		draw_line(Vector2(r.position.x + 5, r.position.y + 4), Vector2(r.end.x - 5, r.position.y + 4), _materials.bevel_light(col), 2.5, true)
	draw_line(body.position + Vector2(18, 30), body.position + Vector2(18, body.size.y - 37), Color(1, 1, 1, 0.24), 4.0, true)

func _draw_block_puzzle() -> void:
	var c := Vector2.ZERO
	var cell := 42.0
	var origin := c - Vector2(cell * 4.0, cell * 4.0) + Vector2(0, 18)
	var filled_positions := {
		Vector2i(0,7): Color("5da9ff"), Vector2i(1,7): Color("5da9ff"), Vector2i(2,7): Color("ff667e"),
		Vector2i(0,6): Color("8b7cf6"), Vector2i(1,6): Color("8b7cf6"), Vector2i(2,6): Color("ff667e"),
		Vector2i(5,7): Color("43d6ad"), Vector2i(6,7): Color("43d6ad"), Vector2i(7,7): Color("5da9ff"),
		Vector2i(5,6): Color("43d6ad"), Vector2i(7,6): Color("5da9ff"), Vector2i(3,5): Color("ffd166")
	}
	for y in range(8):
		for x in range(8):
			var r := Rect2(origin + Vector2(float(x), float(y)) * cell, Vector2(cell - 5, cell - 5))
			var key := Vector2i(x, y)
			if filled_positions.has(key):
				var col: Color = filled_positions[key]
				var depth := _materials.extrusion_offset(0.62, MotionSystem.reduced())
				_draw_box(Rect2(r.position + depth, r.size), _materials.depth_tone(col), 8, Color.TRANSPARENT, 0)
				_draw_box(r, col, 8, _materials.bevel_light(col), 1)
				draw_line(r.position + Vector2(5, 5), Vector2(r.end.x - 5, r.position.y + 5), Color(_materials.bevel_light(col), 0.52), 2.0, true)
			else:
				_draw_box(r, Color("111a31"), 8, Color("34415f"), 1)
	var float_y := 0.0 if MotionSystem.reduced() else sin(phase * 2.1) * 9.0
	var piece_origin := origin + Vector2(3.0 * cell, 1.4 * cell + float_y)
	var shape := [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)]
	for point in shape:
		var r := Rect2(piece_origin + Vector2(point) * cell, Vector2(cell - 5, cell - 5))
		var depth := _materials.extrusion_offset(0.78, MotionSystem.reduced())
		_draw_box(Rect2(r.position + depth, r.size), _materials.depth_tone(accent), 10, Color.TRANSPARENT, 0)
		_draw_box(r.grow(5), Color(accent, 0.10), 10, Color.TRANSPARENT, 0)
		_draw_box(r, accent, 8, _materials.bevel_light(accent), 1)
	if not MotionSystem.reduced():
		var sweep := fposmod(phase * 90.0, cell * 8.0)
		draw_rect(Rect2(Vector2(origin.x + sweep, origin.y), Vector2(12, cell * 8.0 - 5)), Color("67e8cf", 0.09), true)

func _draw_box(rect: Rect2, color: Color, radius: int, border: Color, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border
	draw_style_box(style, rect)
