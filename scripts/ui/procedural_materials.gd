extends RefCounted
class_name ProceduralMaterials

# Lightweight material helpers for GL Compatibility. These deliberately avoid
# shader-only effects so low/mid-range Android devices keep the same visual
# language as high-end phones.

func vertical_shade(base: Color, vertical_t: float) -> Color:
	var t := clampf(vertical_t, 0.0, 1.0)
	var top := base.lightened(0.17)
	var bottom := base.darkened(0.19)
	return top.lerp(bottom, t)

func bevel_light(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.28 * strength, 0.08, 0.42)
	var result := base.lightened(amount)
	result.a = base.a
	return result

func bevel_dark(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.24 * strength, 0.08, 0.38)
	var result := base.darkened(amount)
	result.a = base.a
	return result

func depth_tone(base: Color, strength: float = 1.0) -> Color:
	var amount := clampf(0.43 * strength, 0.20, 0.58)
	var result := base.darkened(amount)
	result.a = base.a
	return result

func extrusion_offset(quality_scale: float = 1.0, reduce_motion: bool = false) -> Vector2:
	var quality := clampf(quality_scale, 0.35, 1.0)
	var depth := lerpf(3.0, 7.0, quality)
	if reduce_motion:
		depth = minf(depth, 3.5)
	return Vector2(depth * 0.22, depth)

func depth_layers_for(quality_scale: float = 1.0, reduce_motion: bool = false) -> int:
	if reduce_motion:
		return 2
	var quality := clampf(quality_scale, 0.35, 1.0)
	if quality < 0.55:
		return 2
	if quality < 0.82:
		return 3
	return 4

func contact_shadow(alpha: float = 0.22) -> Color:
	return Color(0.01, 0.02, 0.04, clampf(alpha, 0.0, 0.55))

func glass_highlight(base: Color = Color.WHITE, alpha: float = 0.30) -> Color:
	var highlight := base.lightened(0.28)
	highlight.a = clampf(alpha, 0.0, 0.72)
	return highlight

func specular(base: Color, alpha: float = 0.26) -> Color:
	var highlight := base.lightened(0.48)
	highlight.a = clampf(alpha, 0.0, 0.64)
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
