extends Control
class_name PremiumBackdrop

var base_color := Color("0b1830")
var accent_color := Color("2dd4b6")
var motif := 0
var t := 0.0

func configure(base: Color, accent: Color, motif_index: int) -> void:
	base_color = base
	accent_color = accent
	motif = motif_index
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), base_color, true)
	var bands := 9
	for i in range(bands):
		var f := float(i) / float(max(1, bands - 1))
		var y := size.y * f
		var c := base_color.lerp(accent_color.darkened(0.55), f * 0.42)
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, size.y / bands + 2)), c, true)

	for i in range(8):
		var px := fmod(130.0 + i * 173.0 + sin(t * 0.18 + i) * 45.0, max(1.0, size.x))
		var py := fmod(190.0 + i * 241.0 - t * (7.0 + i), max(1.0, size.y + 240.0)) - 120.0
		var radius := 70.0 + float((i * 29) % 85)
		draw_circle(Vector2(px, py), radius, Color(accent_color, 0.025 + 0.009 * float(i % 3)))

	match motif % 6:
		0: _draw_garden()
		1: _draw_locks()
		2: _draw_circuit()
		3: _draw_lab()
		4: _draw_links()
		_: _draw_cosmic()

func _draw_garden() -> void:
	for i in range(6):
		var x := 70.0 + i * 190.0
		var y := size.y - 130.0 + sin(t * 0.5 + i) * 6.0
		draw_circle(Vector2(x, y), 72.0, Color(accent_color, 0.07))
		draw_line(Vector2(x, y), Vector2(x, y + 90), Color(accent_color.darkened(0.35), 0.08), 12.0, true)

func _draw_locks() -> void:
	for i in range(5):
		var center := Vector2(140 + i * 210, 360 + (i % 2) * 420)
		var r := 55.0
		draw_arc(center + Vector2(0,-35), r, PI, TAU, 26, Color(accent_color, 0.06), 12.0, true)
		draw_rect(Rect2(center + Vector2(-62,-35), Vector2(124,120)), Color(accent_color,0.04), true)

func _draw_circuit() -> void:
	for i in range(9):
		var y := 180.0 + i * 170.0
		draw_line(Vector2(0,y), Vector2(size.x,y + sin(t*0.25+i)*45.0), Color(accent_color,0.035), 3.0, true)
		for x in range(120, 1080, 240):
			draw_circle(Vector2(x,y), 8.0, Color(accent_color,0.08))

func _draw_lab() -> void:
	for i in range(7):
		var x := 100.0 + i*160.0
		var y := 310.0 + (i%3)*430.0
		draw_circle(Vector2(x,y), 46.0, Color(accent_color,0.04))
		draw_arc(Vector2(x,y), 70.0 + 8.0*sin(t+i), 0, TAU, 32, Color(accent_color,0.045), 2.0, true)

func _draw_links() -> void:
	for i in range(6):
		var y := 260.0 + i*250.0
		var x := 130.0 + float(i%2)*390.0
		draw_arc(Vector2(x,y), 58.0, 0, TAU, 28, Color(accent_color,0.055), 8.0, true)
		draw_arc(Vector2(x+90,y), 58.0, 0, TAU, 28, Color(accent_color,0.055), 8.0, true)

func _draw_cosmic() -> void:
	for i in range(28):
		var x := fmod(float(i*97 + 37), max(1.0,size.x))
		var y := fmod(float(i*173 + 89) + t*(3.0 + float(i%4)), max(1.0,size.y))
		var r := 1.8 + float(i%3)
		draw_circle(Vector2(x,y), r, Color(1,1,1,0.10 + 0.04*float(i%2)))
