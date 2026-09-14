class_name GameShowcaseArt
extends Control

var game_id := "rescue_rush"
var accent := Color("2dd4b6")
var phase := 0.0
var dark_mode := true

func configure(id: String, color: Color, dark: bool) -> void:
	game_id = id
	accent = color
	dark_mode = dark
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	_draw_stage()
	match game_id:
		"water_sort": _draw_water_sort()
		"block_puzzle": _draw_block_puzzle()
		_: _draw_rescue_rush()

func _bg() -> Color:
	return Color("07101d") if dark_mode else Color("f3f7fb")

func _draw_stage() -> void:
	var c := size * 0.5
	for i in range(5, 0, -1):
		var r := minf(size.x, size.y) * (0.24 + float(i) * 0.045)
		draw_circle(c + Vector2(sin(phase * 0.5) * 8.0, cos(phase * 0.4) * 6.0), r, Color(accent, 0.012 + float(6 - i) * 0.006))
	# premium ground shadow
	draw_set_transform(c + Vector2(0, size.y * 0.32), 0.0, Vector2(1.0, 0.23))
	draw_circle(Vector2.ZERO, minf(size.x, 520.0) * 0.40, Color(0, 0, 0, 0.24))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _panel(rect: Rect2, color: Color, radius: int = 20, border: Color = Color.TRANSPARENT, border_width: int = 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if border_width > 0:
		s.border_width_left = border_width
		s.border_width_right = border_width
		s.border_width_top = border_width
		s.border_width_bottom = border_width
		s.border_color = border
	draw_style_box(s, rect)

func _draw_rescue_rush() -> void:
	var c := size * 0.5 + Vector2(0, 6)
	var bob := sin(phase * 2.0) * 5.0
	var rescue := c + Vector2(0, bob)
	# central rescue token with soft halo
	for i in range(4, 0, -1):
		draw_circle(rescue, 66.0 + float(i) * 16.0, Color("ffd166", 0.016 * float(i)))
	draw_circle(rescue + Vector2(0, 9), 62, Color(0, 0, 0, 0.24))
	draw_circle(rescue, 58, Color("ffd166"))
	draw_circle(rescue + Vector2(-18, -7), 6, Color("111827"))
	draw_circle(rescue + Vector2(18, -7), 6, Color("111827"))
	draw_arc(rescue + Vector2(0, 13), 19, 0.18, PI - 0.18, 24, Color("111827"), 4.5, true)

	var dirs: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for i in range(4):
		var d := dirs[i]
		var travel := 152.0 + sin(phase * 1.8 + float(i) * 0.9) * 9.0
		var p := c + d * travel
		var block := Rect2(p - Vector2(58, 42), Vector2(116, 84))
		_panel(block.translated(Vector2(0, 8)), Color(0, 0, 0, 0.24), 20)
		_panel(block, Color(accent.darkened(0.34), 0.96), 20, Color(accent.lightened(0.28), 0.80), 2)
		_panel(block.grow(-7), Color(accent, 0.12), 15)
		var n := Vector2(-d.y, d.x)
		var tip := p + d * 28.0
		var tail := p - d * 20.0
		var points := PackedVector2Array([
			tail + n * 8, tip - d * 13 + n * 8, tip - d * 13 + n * 18,
			tip + d * 10, tip - d * 13 - n * 18, tip - d * 13 - n * 8, tail - n * 8
		])
		draw_polygon(points, PackedColorArray([Color("f8fbff")]))
		# motion trail implies the actual tap-away gameplay
		for j in range(3):
			var start := p - d * (58.0 + float(j) * 18.0)
			draw_line(start - n * 9, start + n * 9, Color(accent, 0.16 - float(j) * 0.035), 3.5, true)

func _draw_water_sort() -> void:
	var c := size * 0.5 + Vector2(0, 14)
	var colors: Array[Color] = [Color("ff5f7a"), Color("ffd166"), Color("5da9ff"), Color("45d6a4"), Color("9b6cff")]
	for i in range(5):
		var x := c.x - 220.0 + float(i) * 110.0
		var lift := -14.0 if i == 1 else 0.0
		var tilt := deg_to_rad(-10.0) if i == 1 else 0.0
		draw_set_transform(Vector2(x, c.y + lift), tilt, Vector2.ONE)
		var body := Rect2(Vector2(-35, -104), Vector2(70, 208))
		_panel(body.translated(Vector2(0, 9)), Color(0, 0, 0, 0.24), 28)
		_panel(body, Color(0.72, 0.90, 1.0, 0.07), 28, Color(0.78, 0.93, 1.0, 0.65), 3)
		var inner := body.grow(-10)
		inner.position.y += 18
		inner.size.y -= 24
		for layer in range(4):
			var col := colors[(i + layer) % colors.size()]
			var h := inner.size.y / 4.0
			var y := inner.end.y - h * float(layer + 1)
			var wave := sin(phase * 5.0 + float(i + layer)) * 2.0
			var r := Rect2(Vector2(inner.position.x, y + wave * 0.15), Vector2(inner.size.x, h + 1))
			_panel(r, Color(col, 0.95), 5)
			draw_line(Vector2(r.position.x + 5, r.position.y + 4 + wave), Vector2(r.end.x - 5, r.position.y + 4 - wave), col.lightened(0.34), 2.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# one deliberate animated pour, not a permanent laser-like line
	var pulse := 0.5 + 0.5 * sin(phase * 3.0)
	var source := Vector2(c.x - 110, c.y - 100)
	var target := Vector2(c.x + 2, c.y - 75)
	var mid := (source + target) * 0.5 + Vector2(0, -28)
	draw_polyline(PackedVector2Array([source, mid, target]), Color(colors[2], 0.36 + pulse * 0.36), 7.0, true)
	for j in range(3):
		var p := target + Vector2(float(j - 1) * 9.0, 9.0 + pulse * float(j) * 3.0)
		draw_circle(p, 3.0 + float(j), Color(colors[2], 0.58))

func _draw_block_puzzle() -> void:
	var c := size * 0.5
	var cell := 43.0
	var origin := c - Vector2(cell * 4.0, cell * 4.0)
	var board_rect := Rect2(origin - Vector2(16, 16), Vector2(cell * 8.0 + 27, cell * 8.0 + 27))
	_panel(board_rect.translated(Vector2(0, 10)), Color(0, 0, 0, 0.26), 28)
	_panel(board_rect, Color("0b1530"), 28, Color(accent, 0.34), 2)
	for y in range(8):
		for x in range(8):
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(cell - 5, cell - 5))
			var filled := ((x * 3 + y * 5) % 9 in [0, 1, 4]) and not (x in [3, 4] and y in [3, 4])
			_panel(rect, Color("111d38"), 10, Color("26385a"), 1)
			if filled:
				_panel(rect.grow(-3).translated(Vector2(0, 3)), Color(0, 0, 0, 0.20), 8)
				_panel(rect.grow(-3), accent.lerp(Color("5da9ff"), float((x + y) % 3) * 0.12), 8)
				draw_line(rect.position + Vector2(7, 7), Vector2(rect.end.x - 7, rect.position.y + 7), Color(1, 1, 1, 0.28), 2.5, true)
	# floating piece follows the finger target then settles toward the board
	var settle := 0.5 + 0.5 * sin(phase * 1.9)
	var hover := origin + Vector2(2.7 * cell, 1.0 * cell) + Vector2(0, -28.0 + settle * 10.0)
	for raw in [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(2,1)]:
		var r := Rect2(hover + raw * cell, Vector2(cell - 5, cell - 5))
		_panel(r.grow(5), Color(accent, 0.10), 11)
		_panel(r, accent.lightened(0.05), 9)
		draw_line(r.position + Vector2(6, 6), Vector2(r.end.x - 6, r.position.y + 6), Color(1, 1, 1, 0.32), 2.5, true)
	# completion sweep hints at the high-reward line-clear moment
	var sweep := fposmod(phase * 95.0, cell * 8.0)
	draw_rect(Rect2(Vector2(origin.x, origin.y + sweep), Vector2(cell * 8.0 - 5, 4)), Color("67e8cf", 0.24), true)
