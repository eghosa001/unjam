extends RefCounted
class_name ProceduralMaterials

# Lightweight material helpers for GL Compatibility. These deliberately avoid
# shader-only effects so low/mid-range Android devices keep the same visual
# language as high-end phones.

func vertical_shade(base: Color, vertical_t: float) -> Color:
	var t := clampf(vertical_t, 0.0, 1.0)
	var top := base.lightened(0.21)
	var bottom := base.darkened(0.24)
	return top.lerp(bottom, t)

func bevel_light(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.34 * strength, 0.10, 0.48)
	var result := base.lightened(amount)
	result.a = base.a
	return result

func bevel_dark(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.30 * strength, 0.10, 0.44)
	var result := base.darkened(amount)
	result.a = base.a
	return result

func depth_tone(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.50 * strength, 0.24, 0.64)
	var result := base.darkened(amount)
	result.a = base.a
	return result

func extrusion_offset(quality_scale: float = 1.0, reduce_motion: bool = false) -> Vector2:
	var quality := clampf(quality_scale, 0.35, 1.0)
	# Strong enough to remain visible after the 1080x1920 scene is scaled to a
	# phone, while still being a cheap layered-2D effect rather than true 3D.
	var depth := lerpf(3.8, 9.0, quality)
	if reduce_motion:
		depth = minf(depth, 4.0)
	return Vector2(depth * 0.30, depth)

func depth_layers_for(quality_scale: float = 1.0, reduce_motion: bool = false) -> int:
	if reduce_motion:
		return 2
	var quality := clampf(quality_scale, 0.35, 1.0)
	if quality < 0.55:
		return 2
	if quality < 0.82:
		return 3
	return 4

func contact_shadow(alpha: float = 0.24) -> Color:
	return Color(0.005, 0.012, 0.025, clampf(alpha, 0.0, 0.60))

func glass_highlight(base: Color = Color.WHITE, alpha: float = 0.30) -> Color:
	var highlight := base.lightened(0.34)
	highlight.a = clampf(alpha, 0.0, 0.76)
	return highlight

func specular(base: Color, alpha: float = 0.26) -> Color:
	var highlight := base.lightened(0.54)
	highlight.a = clampf(alpha, 0.0, 0.68)
	return highlight

func particle_budget(base_count: int, quality_scale: float, reduce_motion: bool) -> int:
	var scale := clampf(quality_scale, 0.35, 1.0)
	if reduce_motion:
		scale = minf(scale, 0.28)
	return maxi(0, int(round(float(maxi(0, base_count)) * scale)))

func glow_passes(quality_scale: float, reduce_motion: bool) -> int:
	if reduce_motion:
		return 3
	if quality_scale < 0.70:
		return 4
	return 7
