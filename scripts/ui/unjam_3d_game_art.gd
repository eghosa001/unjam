class_name Unjam3DGameArt
extends Control

var game_id := "rescue_rush"
var accent := Unjam3DTheme.GREEN

func configure(id: String) -> void:
	game_id = id
	accent = Unjam3DTheme.game_accent(id)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 10.0 or rect.size.y < 10.0:
		return
	draw_style_box(Unjam3DTheme.panel_3d(Unjam3DTheme.game_dark(game_id), 34, accent.lightened(0.35), 3, 12), rect.grow(-4.0))
	match game_id:
		"water_sort": _draw_water()
		"block_puzzle": _draw_blocks()
		_: _draw_rescue()

func _draw_rescue() -> void:
	var w := size.x
	var h := size.y
	var cell := minf(w, h) * 0.18
	var origin := Vector2(w * 0.17, h * 0.18)
	for y in range(3):
		for x in range(4):
			var r := Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell * 0.88, cell * 0.88))
			draw_style_box(Unjam3DTheme.panel_3d(Color("17395f"), 13, Color("2c5d8f"), 2, 3), r)
	_draw_arrow_tile(Rect2(origin + Vector2(cell, 0), Vector2(cell * 0.88, cell * 0.88)), Unjam3DTheme.WATER, Vector2.UP)
	_draw_arrow_tile(Rect2(origin + Vector2(cell * 2.0, cell), Vector2(cell * 0.88, cell * 0.88)), Unjam3DTheme.RED, Vector2.RIGHT)
	_draw_arrow_tile(Rect2(origin + Vector2(cell * 2.0, cell * 2.0), Vector2(cell * 0.88, cell * 0.88)), Unjam3DTheme.GREEN, Vector2.DOWN)
	var face := Vector2(w * 0.51, h * 0.56)
	draw_circle(face + Vector2(0, 7), cell * 0.34, Color(0.05, 0.16, 0.25, 0.35))
	draw_circle(face, cell * 0.34, Unjam3DTheme.GOLD)
	draw_circle(face + Vector2(-cell * 0.10, -cell * 0.05), cell * 0.045, Color("17304a"))
	draw_circle(face + Vector2(cell * 0.10, -cell * 0.05), cell * 0.045, Color("17304a"))
	draw_arc(face + Vector2(0, cell * 0.02), cell * 0.13, 0.2, PI - 0.2, 18, Color("8b3a20"), 4.0)

func _draw_water() -> void:
	var w := size.x
	var h := size.y
	var tube_w := w * 0.16
	var tube_h := h * 0.52
	var xs := [w * 0.25, w * 0.50, w * 0.75]
	var liquid := [Unjam3DTheme.GOLD, Unjam3DTheme.WATER, Unjam3DTheme.PINK]
	for i in range(3):
		var x: float = xs[i]
		var r := Rect2(Vector2(x - tube_w * 0.5, h * 0.26), Vector2(tube_w, tube_h))
		draw_style_box(Unjam3DTheme.panel_3d(Color(0.86, 0.98, 1.0, 0.28), 24, Color(0.9, 1.0, 1.0, 0.95), 3, 7), r)
		var fill := Rect2(r.position + Vector2(7, tube_h * 0.48), Vector2(tube_w - 14, tube_h * 0.48 - 8))
		draw_style_box(Unjam3DTheme.panel_3d(liquid[i], 17, liquid[i].lightened(0.34), 2, 4), fill)
		draw_line(Vector2(r.position.x + 9, r.position.y + 13), Vector2(r.end.x - 9, r.position.y + 13), Color.WHITE, 4.0)
	# Dynamic pouring ribbon.
	draw_line(Vector2(w * 0.28, h * 0.24), Vector2(w * 0.56, h * 0.14), Color("d98cff"), 18.0, true)
	draw_line(Vector2(w * 0.28, h * 0.24), Vector2(w * 0.56, h * 0.14), Color("fff2ff"), 4.0, true)

func _draw_blocks() -> void:
	var w := size.x
	var h := size.y
	var s := minf(w, h) * 0.19
	var points := [
		[Vector2(0.20, 0.30), Unjam3DTheme.GOLD], [Vector2(0.39, 0.30), Unjam3DTheme.ORANGE],
		[Vector2(0.58, 0.30), Unjam3DTheme.PINK], [Vector2(0.29, 0.49), Unjam3DTheme.GREEN],
		[Vector2(0.48, 0.49), Unjam3DTheme.WATER], [Vector2(0.67, 0.49), Unjam3DTheme.PURPLE],
		[Vector2(0.39, 0.68), Unjam3DTheme.GREEN], [Vector2(0.58, 0.68), Unjam3DTheme.PURPLE]
	]
	for item in points:
		var p: Vector2 = item[0]
		var c: Color = item[1]
		var r := Rect2(Vector2(w * p.x - s * 0.5, h * p.y - s * 0.5), Vector2(s, s))
		draw_style_box(Unjam3DTheme.panel_3d(c, 16, c.lightened(0.35), 3, 7), r)
		draw_line(r.position + Vector2(9, 8), Vector2(r.end.x - 9, r.position.y + 8), Color(1, 1, 1, 0.55), 3.0)

func _draw_arrow_tile(rect: Rect2, color: Color, direction: Vector2) -> void:
	draw_style_box(Unjam3DTheme.panel_3d(color, 15, color.lightened(0.34), 3, 6), rect)
	var center := rect.get_center()
	var d := direction.normalized()
	var side := Vector2(-d.y, d.x)
	var length := minf(rect.size.x, rect.size.y) * 0.25
	draw_line(center - d * length * 0.65, center + d * length, Color.WHITE, 8.0, true)
	var tip := center + d * length
	draw_line(tip, tip - d * length * 0.55 + side * length * 0.55, Color.WHITE, 8.0, true)
	draw_line(tip, tip - d * length * 0.55 - side * length * 0.55, Color.WHITE, 8.0, true)
