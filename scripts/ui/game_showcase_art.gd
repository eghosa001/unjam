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
	match game_id:
		"water_sort": _draw_water_sort()
		"block_puzzle": _draw_block_puzzle()
		_: _draw_rescue_rush()

func _bg() -> Color:
	return Color("0b1322") if dark_mode else Color("f6f9fd")

func _draw_rescue_rush() -> void:
	var c := size * 0.5
	var bob := sin(phase * 2.2) * 7.0
	for ring in range(4, 0, -1):
		draw_circle(c + Vector2(0, bob), 80.0 + ring * 22.0, Color(accent, 0.025 * ring))
	# rescue character
	draw_circle(c + Vector2(0, 8 + bob), 64, Color("ffd166"))
	draw_circle(c + Vector2(-22, -2 + bob), 8, Color("16213a"))
	draw_circle(c + Vector2(22, -2 + bob), 8, Color("16213a"))
	draw_arc(c + Vector2(0, 24 + bob), 22, 0.15, PI - 0.15, 24, Color("16213a"), 5)
	# blockers/arrows around character
	var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for i in range(4):
		var d: Vector2 = dirs[i]
		var p := c + d * (150 + sin(phase * 1.8 + i) * 8)
		var rect := Rect2(p - Vector2(52, 38), Vector2(104, 76))
		draw_rect(rect, Color(accent, 0.18 + i * 0.03), true)
		draw_rect(rect.grow(-4), Color(_bg(), 0.92), true)
		var tip := p + d * 28
		var side := Vector2(-d.y, d.x) * 16
		draw_colored_polygon(PackedVector2Array([tip + d * 14, tip - d * 10 + side, tip - d * 10 - side]), accent)
	# motion trail
	for j in range(5):
		var alpha := 0.16 - j * 0.025
		draw_line(c + Vector2(-250 + j*22, 190), c + Vector2(-170 + j*22, 190), Color(accent, alpha), 8)

func _draw_water_sort() -> void:
	var c := size * 0.5
	var colors := [Color("ff6b7a"), Color("ffd166"), Color("5da9ff"), Color("67e8cf")]
	for i in range(5):
		var x := c.x - 220 + i * 110
		var y := c.y + sin(phase * 1.8 + i * 0.7) * 8
		var tube := Rect2(Vector2(x - 34, y - 105), Vector2(68, 210))
		draw_rect(tube, Color(1,1,1,0.08), true)
		draw_rect(Rect2(tube.position + Vector2(7, 10), tube.size - Vector2(14, 18)), Color(_bg(), 0.82), true)
		for layer in range(4):
			var liquid_y := y + 76 - layer * 38
			var col := colors[(i + layer) % colors.size()]
			var wave := sin(phase * 3.0 + i + layer) * 2.5
			draw_rect(Rect2(Vector2(x - 26, liquid_y - 28 + wave), Vector2(52, 32)), Color(col, 0.92), true)
	# pouring stream
	var sx := c.x - 110.0
	var tx := c.x + 110.0
	var stream_y := c.y - 150.0 + sin(phase * 2.8) * 6.0
	draw_line(Vector2(sx, stream_y), Vector2(tx, stream_y + 28), Color(colors[2], 0.92), 12)
	draw_circle(Vector2(tx, stream_y + 28), 10 + sin(phase * 4.0) * 2, colors[2])

func _draw_block_puzzle() -> void:
	var c := size * 0.5
	var origin := c - Vector2(180, 180)
	var cell := 44.0
	for y in range(8):
		for x in range(8):
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(cell - 5, cell - 5))
			var filled := ((x + y * 3) % 7 in [0,1,3]) and not (x in [3,4] and y in [3,4])
			var col := Color(accent, 0.75) if filled else Color(1,1,1,0.05)
			draw_rect(rect, col, true)
	# hovering piece above board
	var hover := origin + Vector2(3.0 * cell, 1.3 * cell) + Vector2(0, sin(phase * 2.1) * 10)
	for p in [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(2,1)]:
		var r := Rect2(hover + p * cell, Vector2(cell - 5, cell - 5))
		draw_rect(r.grow(6), Color(accent, 0.08), true)
		draw_rect(r, accent.lightened(0.08), true)
	# clear sweep
	var sweep_x := origin.x + fposmod(phase * 110.0, 8.0 * cell)
	draw_rect(Rect2(Vector2(sweep_x, origin.y), Vector2(18, 8 * cell)), Color("67e8cf", 0.16), true)
