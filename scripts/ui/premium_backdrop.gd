extends Control
class_name PremiumBackdrop

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var base_color := Color("08111f")
var accent_color := Color("2dd4b6")
var motif := 0
var t := 0.0
var _materials = MATERIALS_SCRIPT.new()

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
	var reduced := MotionSystem.reduced()
	if reduced:
		t = 0.0
	set_process(not reduced)
	queue_redraw()

func _process(delta: float) -> void:
	if MotionSystem.reduced():
		return
	t += delta
	queue_redraw()

func decorative_particle_count_for(quality_scale: float, reduced_motion: bool) -> int:
	return _materials.particle_budget(20, quality_scale, reduced_motion)

func _quality_scale() -> float:
	var visuals := get_node_or_null("/root/PremiumVisuals")
	if visuals == null:
		return 1.0
	var value = visuals.get("quality_scale")
	return clampf(float(value) if value != null else 1.0, 0.45, 1.0)

func _draw() -> void:
	var light_mode := base_color.get_luminance() > 0.58
	var quality := _quality_scale()
	var reduced_motion := MotionSystem.reduced()
	var stage_base := base_color.lerp(Color("ffffff"), 0.08) if light_mode else base_color.lerp(Color("121d30"), 0.22)
	var stage := _materials.vertical_shade(stage_base, 0.16 if light_mode else 0.28)
	var depth_target := accent_color.lightened(0.76) if light_mode else accent_color.darkened(0.68)
	var depth := stage.lerp(depth_target, 0.08 if light_mode else 0.10)
	draw_rect(Rect2(Vector2.ZERO, size), stage, true)
	draw_rect(Rect2(Vector2(0, size.y * 0.34), Vector2(size.x, size.y * 0.66)), Color(depth, 0.76 if light_mode else 0.72), true)

	# Large low-contrast light fields create depth without looking illustrated.
	# In reduced-motion mode the same fields remain, but at deterministic static
	# positions so visual hierarchy is preserved without ambient movement.
	var motion_t := 0.0 if reduced_motion else t
	var c1 := Vector2(size.x * 0.16 + sin(motion_t * 0.12) * 30.0, size.y * 0.18)
	var c2 := Vector2(size.x * 0.86 + cos(motion_t * 0.10) * 36.0, size.y * 0.52)
	var c3 := Vector2(size.x * 0.48, size.y * 0.92 + sin(motion_t * 0.08) * 22.0)
	var glow_scale := 0.040 if light_mode else 0.075
	_draw_glow(c1, minf(size.x, size.y) * 0.40, Color(accent_color, glow_scale), quality, reduced_motion)
	_draw_glow(c2, minf(size.x, size.y) * 0.34, Color(accent_color.lightened(0.18), glow_scale * 0.65), quality, reduced_motion)
	_draw_glow(c3, minf(size.x, size.y) * 0.46, Color(accent_color.darkened(0.12), glow_scale * 0.55), quality, reduced_motion)

	# Slow dust adds life but scales down with device quality and accessibility.
	var dust_count := decorative_particle_count_for(quality, reduced_motion)
	for i in range(dust_count):
		var x := fposmod(float(i * 149 + motif * 53) + sin(motion_t * 0.21 + i) * 18.0, maxf(1.0, size.x))
		var y := fposmod(float(i * 223 + 91) - motion_t * (2.5 + float(i % 3)), maxf(1.0, size.y))
		var alpha := (0.026 if light_mode else 0.05) + float(i % 4) * (0.006 if light_mode else 0.012)
		var dust := Color(0.18, 0.28, 0.42, alpha) if light_mode else Color(0.82, 0.92, 1.0, alpha)
		draw_circle(Vector2(x, y), 1.4 + float(i % 3) * 0.55, dust)

	# Horizon bands give tall phone layouts structure.
	for i in range(4):
		var yy := size.y * (0.24 + float(i) * 0.18)
		draw_line(Vector2(size.x * 0.08, yy), Vector2(size.x * 0.92, yy), Color(accent_color, 0.022 if light_mode else 0.028), 1.0, true)

	# Vignette changes with appearance mode: dark screens deepen, light screens frame.
	var edge := maxf(48.0, size.x * 0.075)
	var edge_color := Color(0.12, 0.20, 0.30, 0.045) if light_mode else Color(0, 0, 0, 0.13)
	var bottom_color := Color(0.12, 0.20, 0.30, 0.055) if light_mode else Color(0, 0, 0, 0.16)
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(size.x - edge, 0), Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(0, size.y - edge), Vector2(size.x, edge)), bottom_color, true)

func _draw_glow(center: Vector2, radius: float, color: Color, quality: float, reduced_motion: bool) -> void:
	var passes := _materials.glow_passes(quality, reduced_motion)
	for i in range(passes, 0, -1):
		var ratio := float(i) / float(maxi(1, passes))
		var alpha := color.a * (0.10 + (1.0 - ratio) * 0.16)
		draw_circle(center, radius * ratio, Color(color.r, color.g, color.b, alpha))
