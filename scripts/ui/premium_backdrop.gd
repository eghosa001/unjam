extends Control
class_name PremiumBackdrop

var base_color := Color("dff4ff")
var accent_color := Color("2dd4b6")
var motif := 0
var t := 0.0

const WASHES := [
	Color("ff7a8a"), Color("42b5ff"), Color("ffd166"), Color("42d6a4"),
	Color("9b7bff"), Color("ff9d57"), Color("39d7cf"), Color("f472b6")
]

func configure(base: Color, accent: Color, motif_index: int) -> void:
	# Existing scenes pass very dark colours. Lift them into a bright, playful
	# palette here so every game benefits without losing its own accent identity.
	base_color = base.lerp(Color("eef8ff"), 0.78)
	accent_color = accent.lerp(Color.WHITE, 0.08)
	motif = motif_index
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var top := base_color.lightened(0.08)
	var bottom := base_color.lerp(accent_color.lightened(0.25), 0.30)
	var bands := 12
	for i in range(bands):
		var f := float(i) / float(max(1, bands - 1))
		var y := size.y * f
		var c := top.lerp(bottom, f)
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, size.y / bands + 2)), c, true)

	# Large translucent colour washes keep the screen lively without using a
	# literal illustration as the background.
	for i in range(6):
		var wash: Color = WASHES[posmod(i + motif, WASHES.size())]
		var px := fmod(120.0 + i * 215.0 + sin(t * 0.16 + i * 1.2) * 55.0, max(1.0, size.x + 180.0)) - 90.0
		var py := 160.0 + float(i % 3) * (size.y * 0.30) + cos(t * 0.13 + i) * 36.0
		var radius := 150.0 + float((i * 41) % 95)
		draw_circle(Vector2(px, py), radius, Color(wash, 0.075))

	for i in range(18):
		var x := fmod(float(i * 113 + motif * 31), max(1.0, size.x))
		var y := fmod(float(i * 181 + 70) + t * (4.0 + float(i % 3)), max(1.0, size.y))
		var dot: Color = WASHES[posmod(i + motif, WASHES.size())]
		draw_circle(Vector2(x, y), 3.0 + float(i % 3), Color(dot, 0.18))

	match motif % 6:
		0: _draw_garden()
		1: _draw_locks()
		2: _draw_circuit()
		3: _draw_lab()
		4: _draw_links()
		_: _draw_cosmic()

func _motif_color(alpha: float) -> Color:
	return Color(accent_color.darkened(0.18), alpha)

func _draw_garden() -> void:
	for i in range(6):
		var x := 70.0 + i * 190.0
		var y := size.y - 130.0 + sin(t * 0.5 + i) * 6.0
		draw_circle(Vector2(x, y), 72.0, _motif_color(0.09))
		draw_line(Vector2(x, y), Vector2(x, y + 90), _motif_color(0.08), 12.0, true)

func _draw_locks() -> void:
	for i in range(5):
		var center := Vector2(140 + i * 210, 360 + (i % 2) * 420)
		draw_arc(center + Vector2(0,-35), 55.0, PI, TAU, 26, _motif_color(0.10), 12.0, true)
		draw_rect(Rect2(center + Vector2(-62,-35), Vector2(124,120)), _motif_color(0.055), true)

func _draw_circuit() -> void:
	for i in range(9):
		var y := 180.0 + i * 170.0
		draw_line(Vector2(0,y), Vector2(size.x,y + sin(t*0.25+i)*45.0), _motif_color(0.08), 3.0, true)
		for x in range(120, 1080, 240):
			draw_circle(Vector2(x,y), 8.0, _motif_color(0.14))

func _draw_lab() -> void:
	for i in range(7):
		var x := 100.0 + i*160.0
		var y := 310.0 + (i%3)*430.0
		draw_circle(Vector2(x,y), 46.0, _motif_color(0.07))
		draw_arc(Vector2(x,y), 70.0 + 8.0*sin(t+i), 0, TAU, 32, _motif_color(0.09), 2.0, true)

func _draw_links() -> void:
	for i in range(6):
		var y := 260.0 + i*250.0
		var x := 130.0 + float(i%2)*390.0
		draw_arc(Vector2(x,y), 58.0, 0, TAU, 28, _motif_color(0.10), 8.0, true)
		draw_arc(Vector2(x+90,y), 58.0, 0, TAU, 28, _motif_color(0.10), 8.0, true)

func _draw_cosmic() -> void:
	for i in range(28):
		var x := fmod(float(i*97 + 37), max(1.0,size.x))
		var y := fmod(float(i*173 + 89) + t*(3.0 + float(i%4)), max(1.0,size.y))
		var r := 1.8 + float(i%3)
		var star := WASHES[posmod(i + motif, WASHES.size())]
		draw_circle(Vector2(x,y), r, Color(star, 0.22))
