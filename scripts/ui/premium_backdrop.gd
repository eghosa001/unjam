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
	add_to_group("reduced_motion_aware")
	apply_motion_preference()

func apply_motion_preference() -> void:
	var reduced := bool(SaveManager.data.get("reduced_motion", false))
	if reduced:
		t = 0.0
	set_process(not reduced)
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var light_mode := base_color.get_luminance() > 0.58
	var stage := base_color.lerp(Color("ffffff"), 0.10) if light_mode else base_color.lerp(Color("121827"), 0.18)
	var depth_target := accent_color.lightened(0.76) if light_mode else accent_color.darkened(0.68)
	var depth := stage.lerp(depth_target, 0.10 if light_mode else 0.12)
	draw_rect(Rect2(Vector2.ZERO, size), stage, true)
	draw_rect(Rect2(Vector2(0, size.y * 0.34), Vector2(size.x, size.y * 0.66)), Color(depth, 0.76 if light_mode else 0.72), true)

	# Large low-contrast light fields create depth without looking illustrated.
	var c1 := Vector2(size.x * 0.16 + sin(t * 0.12) * 30.0, size.y * 0.18)
	var c2 := Vector2(size.x * 0.86 + cos(t * 0.10) * 36.0, size.y * 0.52)
	var c3 := Vector2(size.x * 0.48, size.y * 0.92 + sin(t * 0.08) * 22.0)
	var glow_scale := 0.042 if light_mode else 0.080
	_draw_glow(c1, minf(size.x, size.y) * 0.40, Color(accent_color, glow_scale))
	_draw_glow(c2, minf(size.x, size.y) * 0.34, Color(accent_color.lightened(0.18), glow_scale * 0.65))
	_draw_glow(c3, minf(size.x, size.y) * 0.46, Color(accent_color.darkened(0.12), glow_scale * 0.55))

	# Slow dust adds life but stays quiet enough for puzzle readability.
	for i in range(16):
		var x := fposmod(float(i * 149 + motif * 53) + sin(t * 0.21 + i) * 18.0, maxf(1.0, size.x))
		var y := fposmod(float(i * 223 + 91) - t * (2.5 + float(i % 3)), maxf(1.0, size.y))
		var alpha := (0.026 if light_mode else 0.05) + float(i % 4) * (0.006 if light_mode else 0.012)
		var dust := Color(0.18, 0.28, 0.42, alpha) if light_mode else Color(0.82, 0.92, 1.0, alpha)
		draw_circle(Vector2(x, y), 1.4 + float(i % 3) * 0.55, dust)

	# Horizon bands give tall phone layouts structure.
	for i in range(4):
		var yy := size.y * (0.24 + float(i) * 0.18)
		draw_line(Vector2(size.x * 0.08, yy), Vector2(size.x * 0.92, yy), Color(accent_color, 0.022 if light_mode else 0.028), 1.0, true)

	# Vignette changes with appearance mode: dark screens deepen, light screens frame.
	var edge := maxf(44.0, size.x * 0.065)
	var edge_color := Color(0.12, 0.20, 0.30, 0.045) if light_mode else Color(0, 0, 0, 0.13)
	var bottom_color := Color(0.12, 0.20, 0.30, 0.055) if light_mode else Color(0, 0, 0, 0.16)
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(size.x - edge, 0), Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(0, size.y - edge), Vector2(size.x, edge)), bottom_color, true)

func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	for i in range(7, 0, -1):
		var ratio := float(i) / 7.0
		var alpha := color.a * (0.10 + (1.0 - ratio) * 0.16)
		draw_circle(center, radius * ratio, Color(color.r, color.g, color.b, alpha))
