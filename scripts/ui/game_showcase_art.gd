class_name GameShowcaseArt
extends Control

var game_id := "rescue_rush"
var accent := Color("2dd4b6")
var phase := 0.0

func configure(id: String, color: Color, _dark: bool) -> void:
	game_id = id
	accent = color
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	match game_id:
		"water_sort":
			for i in range(5):
				var x := center.x - 220.0 + float(i) * 110.0
				var y := center.y + sin(phase * 1.6 + float(i)) * 5.0
				draw_rect(Rect2(Vector2(x - 28, y - 96), Vector2(56, 192)), Color(0.8, 0.94, 1.0, 0.14), true)
				draw_rect(Rect2(Vector2(x - 22, y + 15), Vector2(44, 72)), Color(accent.lightened(float(i) * 0.04), 0.9), true)
		"block_puzzle":
			var cell := 40.0
			var origin := center - Vector2(cell * 4.0, cell * 4.0)
			for y in range(8):
				for x in range(8):
					var filled := ((x * 3 + y * 5) % 8) in [0,1,3]
					draw_rect(Rect2(origin + Vector2(float(x), float(y)) * cell, Vector2(cell - 5, cell - 5)), Color(accent, 0.8) if filled else Color(1,1,1,0.05), true)
		_:
			draw_circle(center, 58, Color("ffd166"))
			draw_circle(center + Vector2(-18,-7), 6, Color("111827"))
			draw_circle(center + Vector2(18,-7), 6, Color("111827"))
			for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var pos := center + dir * (150.0 + sin(phase * 1.7) * 7.0)
				draw_rect(Rect2(pos - Vector2(48,34), Vector2(96,68)), Color(accent, 0.28), true)
