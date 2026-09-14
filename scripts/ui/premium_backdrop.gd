extends Control
class_name PremiumBackdrop

var base_color := Color("08111f")
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
	# Premium puzzle games benefit from calm, high-contrast stages. Keep the
	# background atmospheric and let the interactive pieces own the colour.
	var deep := base_color.lerp(Color("040812"), 0.50)
	var mid := deep.lerp(accent_color.darkened(0.68), 0.16)
	draw_rect(Rect2(Vector2.ZERO, size), deep, true)
	draw_rect(Rect2(Vector2(0, size.y * 0.35), Vector2(size.x, size.y * 0.65)), Color(mid, 0.72), true)

	# Soft light fields: large, slow and low-opacity instead of decorative motifs.
	var c1 := Vector2(size.x * 0.16 + sin(t * 0.12) * 30.0, size.y * 0.18)
	var c2 := Vector2(size.x * 0.86 + cos(t * 0.10) * 36.0, size.y * 0.52)
	var c3 := Vector2(size.x * 0.48, size.y * 0.92 + sin(t * 0.08) * 22.0)
	_draw_glow(c1, minf(size.x, size.y) * 0.40, Color(accent_color, 0.10))
	_draw_glow(c2, minf(size.x, size.y) * 0.34, Color(accent_color.lightened(0.18), 0.065))
	_draw_glow(c3, minf(size.x, size.y) * 0.46, Color(accent_color.darkened(0.12), 0.055))

	# Subtle moving dust gives life without making the screen look illustrated.
	for i in range(20):
		var x := fposmod(float(i * 149 + motif * 53) + sin(t * 0.21 + i) * 18.0, maxf(1.0, size.x))
		var y := fposmod(float(i * 223 + 91) - t * (2.5 + float(i % 3)), maxf(1.0, size.y))
		var alpha := 0.05 + float(i % 4) * 0.012
		draw_circle(Vector2(x, y), 1.4 + float(i % 3) * 0.55, Color(0.82, 0.92, 1.0, alpha))

	# Thin horizon bands create depth and polish, especially on tall phones.
	for i in range(4):
		var yy := size.y * (0.24 + float(i) * 0.18)
		draw_line(Vector2(size.x * 0.08, yy), Vector2(size.x * 0.92, yy), Color(accent_color, 0.028), 1.0, true)

	# Edge vignette using translucent strips so content remains readable.
	var edge := maxf(48.0, size.x * 0.075)
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge, size.y)), Color(0, 0, 0, 0.13), true)
	draw_rect(Rect2(Vector2(size.x - edge, 0), Vector2(edge, size.y)), Color(0, 0, 0, 0.13), true)
	draw_rect(Rect2(Vector2(0, size.y - edge), Vector2(size.x, edge)), Color(0, 0, 0, 0.16), true)

func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	for i in range(7, 0, -1):
		var ratio := float(i) / 7.0
		var alpha := color.a * (0.10 + (1.0 - ratio) * 0.16)
		draw_circle(center, radius * ratio, Color(color.r, color.g, color.b, alpha))
