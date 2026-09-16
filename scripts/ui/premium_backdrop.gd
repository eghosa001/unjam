extends Control
class_name PremiumBackdrop

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var base_color := Color("63d9ff")
var accent_color := Color("19dba9")
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

func _motion_service() -> Node:
	return get_node_or_null("/root/MotionSystem")

func _reduced_motion() -> bool:
	var motion := _motion_service()
	if motion != null and motion.has_method("reduced"):
		return bool(motion.call("reduced"))
	return false

func apply_motion_preference() -> void:
	var reduced := _reduced_motion()
	if reduced:
		t = 0.0
	set_process(not reduced)
	queue_redraw()

func _process(delta: float) -> void:
	if _reduced_motion():
		return
	t += delta
	queue_redraw()

func decorative_particle_count_for(quality_scale: float, reduced_motion: bool) -> int:
	return _materials.particle_budget(24, quality_scale, reduced_motion)

func _quality_scale() -> float:
	var visuals := get_node_or_null("/root/PremiumVisuals")
	if visuals == null:
		return 1.0
	var value = visuals.get("quality_scale")
	return clampf(float(value) if value != null else 1.0, 0.45, 1.0)

func _draw() -> void:
	var quality := _quality_scale()
	var reduced_motion := _reduced_motion()
	var motion_t := 0.0 if reduced_motion else t
	var light_mode := base_color.get_luminance() > 0.58
	var sky_top := base_color.lerp(Color.WHITE, 0.58 if light_mode else 0.28)
	var sky_bottom := accent_color.lerp(Color("2a7dff"), 0.34).lightened(0.12 if light_mode else 0.04)
	var horizon_glow := Color("fff3a6")
	for band in range(18):
		var ratio := float(band) / 17.0
		var y0 := size.y * ratio
		var y1 := size.y * float(band + 1) / 18.0
		var band_color := sky_top.lerp(sky_bottom, ratio)
		draw_rect(Rect2(Vector2(0, y0), Vector2(size.x, y1 - y0 + 1.0)), band_color, true)

	_draw_glow(Vector2(size.x * 0.52, size.y * 0.28), minf(size.x, size.y) * 0.56, Color(horizon_glow, 0.22), quality, reduced_motion)
	_draw_glow(Vector2(size.x * 0.12, size.y * 0.72), minf(size.x, size.y) * 0.38, Color("70ffd2", 0.18), quality, reduced_motion)
	_draw_glow(Vector2(size.x * 0.88, size.y * 0.64), minf(size.x, size.y) * 0.42, Color("ff8be8", 0.15), quality, reduced_motion)

	var decorative_orbs: Array = [
		[Vector2(0.04, 0.13), 84.0, Color("8aff83")],
		[Vector2(0.95, 0.18), 102.0, Color("ff7ac8")],
		[Vector2(0.08, 0.88), 116.0, Color("ffd45b")],
		[Vector2(0.92, 0.91), 90.0, Color("9f7cff")]
	]
	for i in range(decorative_orbs.size()):
		var item: Array = decorative_orbs[i]
		var pos_ratio: Vector2 = item[0]
		var wobble := Vector2.ZERO if reduced_motion else Vector2(sin(motion_t * 0.22 + i) * 12.0, cos(motion_t * 0.18 + i) * 9.0)
		var center := Vector2(size.x * pos_ratio.x, size.y * pos_ratio.y) + wobble
		var radius := float(item[1])
		var color: Color = item[2]
		draw_circle(center, radius, Color(color, 0.15))
		draw_circle(center - Vector2(radius * 0.22, radius * 0.22), radius * 0.46, Color(1, 1, 1, 0.10))

	for i in range(5):
		var x := size.x * (0.10 + float(i) * 0.22)
		var y := size.y * (0.12 + float(i % 2) * 0.06)
		var drift := 0.0 if reduced_motion else sin(motion_t * 0.12 + i) * 16.0
		draw_circle(Vector2(x + drift, y), 34.0, Color(1, 1, 1, 0.17))
		draw_circle(Vector2(x + 30 + drift, y + 8), 26.0, Color(1, 1, 1, 0.13))
		draw_circle(Vector2(x - 28 + drift, y + 10), 23.0, Color(1, 1, 1, 0.12))

	var dust_count := decorative_particle_count_for(quality, reduced_motion)
	var sparkle_palette: Array[Color] = [Color("ffffff"), Color("fff273"), Color("ff85ce"), Color("7effe0")]
	for i in range(dust_count):
		var x := fposmod(float(i * 149 + motif * 53) + sin(motion_t * 0.21 + i) * 18.0, maxf(1.0, size.x))
		var y := fposmod(float(i * 223 + 91) - motion_t * (2.5 + float(i % 3)), maxf(1.0, size.y))
		var sparkle: Color = sparkle_palette[i % sparkle_palette.size()]
		draw_circle(Vector2(x, y), 1.8 + float(i % 3) * 0.75, Color(sparkle, 0.22 + float(i % 3) * 0.05))

	var ground_y := size.y * 0.88
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(size.x, size.y - ground_y)), Color("0c9d78", 0.46), true)
	for i in range(14):
		var gx := size.x * float(i) / 13.0
		var gy := ground_y - 10.0 - float((i * 17) % 36)
		var leaf := Color("3ae276") if i % 2 == 0 else Color("84f06d")
		draw_circle(Vector2(gx, gy), 22.0 + float(i % 3) * 8.0, Color(leaf, 0.48))

	# Vignette changes with appearance mode: bright screens get a soft cyan frame,
	# while darker screens get a deeper edge that preserves readability.
	var edge := maxf(40.0, size.x * 0.055)
	var edge_color := Color(0.05, 0.30, 0.48, 0.055) if light_mode else Color(0.0, 0.04, 0.13, 0.16)
	var bottom_color := Color(0.03, 0.30, 0.22, 0.07) if light_mode else Color(0.0, 0.03, 0.10, 0.18)
	draw_rect(Rect2(Vector2.ZERO, Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(size.x - edge, 0), Vector2(edge, size.y)), edge_color, true)
	draw_rect(Rect2(Vector2(0, size.y - edge), Vector2(size.x, edge)), bottom_color, true)

func _draw_glow(center: Vector2, radius: float, color: Color, quality: float, reduced_motion: bool) -> void:
	var passes := _materials.glow_passes(quality, reduced_motion)
	for i in range(passes, 0, -1):
		var ratio := float(i) / float(maxi(1, passes))
		var alpha := color.a * (0.10 + (1.0 - ratio) * 0.16)
		draw_circle(center, radius * ratio, Color(color.r, color.g, color.b, alpha))
