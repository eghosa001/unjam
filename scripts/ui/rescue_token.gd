extends Control
class_name RescueToken

var rescue_id := "chick"
var accent := Color("ffd166")
var t := 0.0

func configure(id: String, color: Color = Color("ffd166")) -> void:
	rescue_id = id
	accent = color
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5 + Vector2(0, sin(t * 2.4) * 2.5)
	var r: float = minf(size.x, size.y) * 0.28
	draw_circle(center + Vector2(0, 8), r * 1.22, Color(accent, 0.16))
	draw_circle(center, r, accent)
	draw_circle(center - Vector2(r * 0.32, r * 0.08), r * 0.09, Color("152039"))
	draw_circle(center + Vector2(r * 0.32, -r * 0.08), r * 0.09, Color("152039"))
	draw_circle(center - Vector2(r * 0.35, r * 0.12), r * 0.026, Color.WHITE)
	draw_circle(center + Vector2(r * 0.29, -r * 0.12), r * 0.026, Color.WHITE)
	match rescue_id:
		"puppy": _draw_ears(center, r, Color("b8794c"))
		"kitten": _draw_cat_ears(center, r)
		"robot": _draw_robot(center, r)
		"slime": _draw_slime(center, r)
		"panda": _draw_panda(center, r)
		"fox": _draw_fox(center, r)
		"alien": _draw_alien(center, r)
		_: _draw_chick(center, r)
	_draw_smile(center, r)

func _draw_smile(center: Vector2, r: float) -> void:
	draw_arc(center + Vector2(0, r * 0.14), r * 0.24, 0.25, PI - 0.25, 16, Color("152039"), 3.2, true)

func _draw_ears(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center + Vector2(-r * 0.82, -r * 0.42), r * 0.35, color)
	draw_circle(center + Vector2(r * 0.82, -r * 0.42), r * 0.35, color)

func _draw_cat_ears(center: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		var p := PackedVector2Array([center + Vector2(side * r * 0.76, -r * 0.62), center + Vector2(side * r * 0.34, -r * 1.12), center + Vector2(side * r * 0.08, -r * 0.56)])
		draw_colored_polygon(p, accent.darkened(0.08))

func _draw_robot(center: Vector2, r: float) -> void:
	draw_line(center + Vector2(0, -r), center + Vector2(0, -r * 1.3), Color.WHITE, 4.0, true)
	draw_circle(center + Vector2(0, -r * 1.36), r * 0.09, Color("ff6b7a"))
	draw_rect(Rect2(center - Vector2(r * 0.6, r * 0.42), Vector2(r * 1.2, r * 0.84)), Color(accent, 0.18), false, 3.0)

func _draw_slime(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.6, r * 0.52), r * 0.28, accent)
	draw_circle(center + Vector2(r * 0.6, r * 0.52), r * 0.28, accent)

func _draw_panda(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.72, -r * 0.58), r * 0.28, Color("172033"))
	draw_circle(center + Vector2(r * 0.72, -r * 0.58), r * 0.28, Color("172033"))

func _draw_fox(center: Vector2, r: float) -> void:
	for side in [-1.0, 1.0]:
		var p := PackedVector2Array([center + Vector2(side * r * 0.72, -r * 0.52), center + Vector2(side * r * 0.48, -r * 1.15), center + Vector2(side * r * 0.10, -r * 0.62)])
		draw_colored_polygon(p, Color("f28c4b"))

func _draw_alien(center: Vector2, r: float) -> void:
	draw_arc(center, r * 0.86, 0, TAU, 28, Color("8af0c8"), 4.0, true)
	draw_line(center + Vector2(-r * 0.22, -r * 0.94), center + Vector2(-r * 0.38, -r * 1.22), Color("8af0c8"), 3.0, true)
	draw_line(center + Vector2(r * 0.22, -r * 0.94), center + Vector2(r * 0.38, -r * 1.22), Color("8af0c8"), 3.0, true)

func _draw_chick(center: Vector2, r: float) -> void:
	var beak := PackedVector2Array([center + Vector2(-r * 0.16, r * 0.10), center + Vector2(r * 0.16, r * 0.10), center + Vector2(0, r * 0.34)])
	draw_colored_polygon(beak, Color("ff9f43"))
