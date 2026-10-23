extends SceneTree
# Exact pixel-for-pixel guard for the premium 160px nine-slice rasterizer.
# The reference below is the pre-optimization shipping pixel loop. Regressions
# must not trade glossy rendering quality for CPU startup performance.
const REF = preload("res://scripts/ui/figma_reference_canvas.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cases := [
		[Color("#4a326b"),Color("#6e4c95"),Color("#a07bc6"),34.0,Color("#7f60a7"),1.0,0.22],
		[Color("#a9c4b9"),Color("#789477"),Color("#365648"),34.0,Color("#aebeb4"),1.0,0.34],
		[Color("#493754"),Color("#3d2b49"),Color("#302139"),16.0,Color(0.72,0.52,1.0,0.18),1.0,0.12],
		[Color("#302047"),Color("#241735"),Color("#181023"),0.0,Color.TRANSPARENT,0.0,0.20],
	]
	for i in range(cases.size()):
		var args: Array = cases[i]
		var start := Time.get_ticks_usec()
		var actual_style := REF.rounded_gradient3(args[0],args[1],args[2],args[3],args[4],args[5],args[6])
		var optimized_us := Time.get_ticks_usec() - start
		var expected_start := Time.get_ticks_usec()
		var original_image := _reference_gradient3(args[0],args[1],args[2],args[3],args[4],args[5],args[6])
		var original_us := Time.get_ticks_usec() - expected_start
		var actual_image := actual_style.texture.get_image()
		if actual_image.get_width() != 160 or actual_image.get_height() != 160:
			push_error("Wrong texture dimensions");quit(1);return
		var changed := 0
		for y in range(160):
			for x in range(160):
				if actual_image.get_pixel(x,y).to_rgba32() != original_image.get_pixel(x,y).to_rgba32():
					changed += 1
		print("GRADIENT3_PIXEL_GUARD case=%d optimized_us=%d reference_us=%d different_pixels=%d" % [i,optimized_us,original_us,changed])
		if changed > 0:
			push_error("Visual material pixels changed in case %d" % i)
			quit(1)
			return
	print("GRADIENT3_PIXEL_IDENTITY_OK four color/radius/midpoint cases")
	quit(0)

static func _reference_gradient3(top: Color, middle: Color, bottom: Color, radius: float = 16.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0, midpoint: float = 0.55) -> Image:
	# 160px source material prevents visible stepping/banding after the authored
	# 390x844 surface is scaled to high-density Android viewports.
	var image_size := 160
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	var r := clampf(radius / 24.0 * (float(image_size) * 22.0 / 96.0), 0.0, float(image_size) * 44.0 / 96.0)
	var bw := maxf(0.0, border_width / 4.0 * 4.0)
	var split := clampf(midpoint, 0.08, 0.92)
	for y in range(image_size):
		var fy := float(y) / float(image_size - 1)
		var fill := top.lerp(middle, fy / split) if fy <= split else middle.lerp(bottom, (fy - split) / (1.0 - split))
		for x in range(image_size):
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var dx := maxf(maxf(r - px, 0.0), px - (float(image_size) - r))
			var dy := maxf(maxf(r - py, 0.0), py - (float(image_size) - r))
			if dx * dx + dy * dy > r * r:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if bw > 0.0:
				var inner_r := maxf(0.0, r - bw)
				var idx := maxf(maxf(inner_r - px, 0.0), px - (float(image_size) - inner_r))
				var idy := maxf(maxf(inner_r - py, 0.0), py - (float(image_size) - inner_r))
				var in_inner := idx * idx + idy * idy <= inner_r * inner_r and px >= bw and py >= bw and px <= image_size - bw and py <= image_size - bw
				if not in_inner:
					image.set_pixel(x, y, border_color)
					continue
			# Glossy-flat casual-game lacquer: one controlled top rolloff, one
			# narrow highlight band and a soft key-light. No asymmetric sidewall
			# shading is allowed here; cards should look coated, not extruded.
			var pixel_fill := fill
			var fx := float(x) / float(image_size - 1)
			var center_boost := 1.0 - minf(1.0, absf(fx - 0.5) * 1.7)
			if fy < 0.36:
				var sheen := (1.0 - fy / 0.36) * (0.080 + center_boost * 0.055)
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), sheen)
			if fy >= 0.11 and fy <= 0.20:
				var band := 1.0 - absf(fy - 0.155) / 0.045
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), maxf(0.0, band) * (0.040 + center_boost * 0.025))
			if py <= bw + 2.0:
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), 0.17)
			if fy > 0.86:
				var lower_rolloff := ((fy - 0.86) / 0.14) * 0.070
				pixel_fill = pixel_fill.lerp(Color(0, 0, 0, pixel_fill.a), lower_rolloff)
			# Glossy-flat edge discipline: both side edges receive the same barely
			# visible falloff. This preserves silhouette definition without faking
			# a raised right wall or a directional 3D bevel.
			var edge_distance := minf(fx, 1.0 - fx)
			if edge_distance < 0.055:
				var edge_falloff := (0.055 - edge_distance) / 0.055
				pixel_fill = pixel_fill.lerp(Color(0, 0, 0, pixel_fill.a), edge_falloff * 0.018)
			# Localized key-light hotspot keeps the surface lively while remaining
			# subordinate to the authored game artwork.
			var hotspot_distance := Vector2((fx - 0.34) / 0.50, (fy - 0.12) / 0.28).length()
			var hotspot := clampf(1.0 - hotspot_distance, 0.0, 1.0)
			if hotspot > 0.0:
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), hotspot * 0.052)
			image.set_pixel(x, y, pixel_fill)
	return image

