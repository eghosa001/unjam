class_name FigmaReferenceCanvas
extends Control

# Exact coordinate space used by the audited Production frames in Figma.
const REFERENCE_SIZE := Vector2(390.0, 844.0)

var extra_scale := 1.0

# Screen navigation rebuilds many Figma-authored controls. Re-generating the
# same 96x96 gradient images on every tap was expensive enough to be visible as
# navigation hitching on device. Cache immutable StyleBoxTexture instances by
# their authored visual parameters so later screen builds reuse GPU-ready data.
static var _rounded_gradient_cache: Dictionary = {}
static var _rounded_gradient3_cache: Dictionary = {}
static var _horizontal_gradient_cache: Dictionary = {}

static func _style_cache_key(kind: String, colors: Array[Color], radius: float, border_color: Color, border_width: float, midpoint: float = -1.0) -> String:
	var parts := PackedStringArray([kind])
	for color in colors:
		parts.append(color.to_html(true))
	parts.append("%.3f" % radius)
	parts.append(border_color.to_html(true))
	parts.append("%.3f" % border_width)
	if midpoint >= 0.0:
		parts.append("%.3f" % midpoint)
	return "|".join(parts)

func _ready() -> void:
	set_meta("unjam_figma_reference_root", true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = REFERENCE_SIZE
	custom_minimum_size = REFERENCE_SIZE
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_reference_canvas):
		viewport.size_changed.connect(_fit_reference_canvas)
	call_deferred("_fit_reference_canvas")

func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_fit_reference_canvas):
		viewport.size_changed.disconnect(_fit_reference_canvas)

func _fit_reference_canvas() -> void:
	if not is_inside_tree():
		return
	var available := get_viewport_rect().size
	var parent_control := get_parent() as Control
	if parent_control != null and parent_control.size.x > 1.0 and parent_control.size.y > 1.0:
		# DeviceFit may already have inset the owning top-level surface for a
		# notch/cutout. Fit inside that actual parent instead of applying a
		# second full-viewport assumption that would shift the reference frame.
		available = parent_control.size
	var factor := minf(available.x / REFERENCE_SIZE.x, available.y / REFERENCE_SIZE.y) * extra_scale
	scale = Vector2.ONE * factor
	position = (available - REFERENCE_SIZE * factor) * 0.5
	size = REFERENCE_SIZE

static func solid_box(color: Color, radius: float = 0.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	if border_width > 0.0:
		var w := int(ceil(border_width))
		style.border_width_left = w
		style.border_width_right = w
		style.border_width_top = w
		style.border_width_bottom = w
		style.border_color = border_color
	# Figma geometry is authoritative. Borders are visual only and must never
	# enlarge PanelContainer/Button minimum sizes beyond the audited rectangle.
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 0.0)
	return style

static func rounded_gradient(top: Color, bottom: Color, radius: float = 16.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxTexture:
	var cache_key := _style_cache_key("rounded2", [top, bottom], radius, border_color, border_width)
	if _rounded_gradient_cache.has(cache_key):
		return _rounded_gradient_cache[cache_key] as StyleBoxTexture
	var image_size := 64
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	var r := clampf(radius / 24.0 * (float(image_size) * 22.0 / 96.0), 0.0, float(image_size) * 44.0 / 96.0)
	var bw := maxf(0.0, border_width / 4.0 * 4.0)
	for y in range(image_size):
		var fy := float(y) / float(image_size - 1)
		var fill := top.lerp(bottom, fy)
		for x in range(image_size):
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var dx := maxf(maxf(r - px, 0.0), px - (float(image_size) - r))
			var dy := maxf(maxf(r - py, 0.0), py - (float(image_size) - r))
			var outside := dx * dx + dy * dy > r * r
			if outside:
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
			image.set_pixel(x, y, fill)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var margin := maxi(8, int(ceil(r + bw + 2.0)))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		# Nine-slice texture margins define rendering, not layout padding.
		style.set_content_margin(side, 0.0)
	_rounded_gradient_cache[cache_key] = style
	return style

static func rounded_gradient3(top: Color, middle: Color, bottom: Color, radius: float = 16.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0, midpoint: float = 0.55) -> StyleBoxTexture:
	var cache_key := _style_cache_key("rounded3", [top, middle, bottom], radius, border_color, border_width, midpoint)
	if _rounded_gradient3_cache.has(cache_key):
		return _rounded_gradient3_cache[cache_key] as StyleBoxTexture
	var image_size := 64
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
			# Premium casual-game gloss: a broad curved specular rolloff across the
			# upper third, a crisp inner rim, and a restrained lower shade. It is
			# baked once into the cached nine-slice, so there is no per-frame shader.
			var pixel_fill := fill
			var fx := float(x) / float(image_size - 1)
			var center_boost := 1.0 - minf(1.0, absf(fx - 0.5) * 1.7)
			if fy < 0.42:
				var sheen := (1.0 - fy / 0.42) * (0.17 + center_boost * 0.14)
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), sheen)
			# A second, narrow specular band makes large cards read like lacquered
			# casual-game surfaces rather than simple vertical gradients.
			if fy >= 0.10 and fy <= 0.22:
				var band := 1.0 - absf(fy - 0.16) / 0.06
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), maxf(0.0, band) * (0.07 + center_boost * 0.05))
			if py <= bw + 3.0:
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), 0.30)
			if fy > 0.82:
				var lower_rolloff := ((fy - 0.82) / 0.18) * 0.14
				pixel_fill = pixel_fill.lerp(Color(0, 0, 0, pixel_fill.a), lower_rolloff)
			# Premium 3D bevel side: a brighter top/left rim and darker right/bottom
			# side profile makes the nine-slice read as a physical raised object.
			if fx < 0.10:
				pixel_fill = pixel_fill.lerp(Color(1, 1, 1, pixel_fill.a), (0.10 - fx) * 0.55)
			if fx > 0.88:
				pixel_fill = pixel_fill.lerp(Color(0, 0, 0, pixel_fill.a), (fx - 0.88) * 0.72)
			if fy > 0.90:
				pixel_fill = pixel_fill.lerp(Color(0, 0, 0, pixel_fill.a), (fy - 0.90) * 0.92)
			image.set_pixel(x, y, pixel_fill)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var margin := maxi(8, int(ceil(r + bw + 2.0)))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, 0.0)
	_rounded_gradient3_cache[cache_key] = style
	return style

static func _star_points(center: Vector2, outer_radius: float, inner_radius: float, point_count: int = 5) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(point_count * 2):
		var radius := outer_radius if i % 2 == 0 else inner_radius
		var angle := -PI / 2.0 + float(i) * PI / float(point_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

static func _regular_points(center: Vector2, radius: float, point_count: int, rotation: float = -PI / 2.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(point_count):
		var angle := rotation + TAU * float(i) / float(point_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

static func add_collectible_star(parent: Node, center: Vector2, outer_radius: float, earned: bool = true, node_name: String = "CollectibleStar3D") -> Polygon2D:
	var inner_radius := outer_radius * 0.48
	var side := Polygon2D.new()
	side.name = "%sSide" % node_name
	side.polygon = _star_points(center + Vector2(0, maxf(2.0, outer_radius * 0.14)), outer_radius, inner_radius)
	side.color = Color("#8f4d00") if earned else Color("#516474")
	parent.add_child(side)
	var star := Polygon2D.new()
	star.name = node_name
	star.polygon = _star_points(center, outer_radius, inner_radius)
	star.color = Color("#ffc928") if earned else Color("#8faabc")
	parent.add_child(star)
	var highlight := Polygon2D.new()
	highlight.name = "%sHighlight" % node_name
	highlight.polygon = _star_points(center + Vector2(-outer_radius * 0.08, -outer_radius * 0.10), outer_radius * 0.56, inner_radius * 0.56)
	highlight.color = Color(1.0, 0.97, 0.62, 0.58) if earned else Color(0.88, 0.95, 1.0, 0.28)
	parent.add_child(highlight)
	return star

static func add_collectible_gem(parent: Node, center: Vector2, radius: float, node_name: String = "CollectibleGem3D") -> Polygon2D:
	var side := Polygon2D.new()
	side.name = "%sSide" % node_name
	side.polygon = _regular_points(center + Vector2(0, maxf(2.0, radius * 0.18)), radius, 6, PI / 6.0)
	side.color = Color("#1747a8")
	parent.add_child(side)
	var gem := Polygon2D.new()
	gem.name = node_name
	gem.polygon = _regular_points(center, radius, 6, PI / 6.0)
	gem.color = Color("#34d9ff")
	parent.add_child(gem)
	var facet := Polygon2D.new()
	facet.name = "%sFacet" % node_name
	facet.polygon = PackedVector2Array([
		center + Vector2(-radius * 0.58, -radius * 0.18),
		center + Vector2(0, -radius * 0.86),
		center + Vector2(radius * 0.12, -radius * 0.08),
		center + Vector2(-radius * 0.08, radius * 0.18)
	])
	facet.color = Color(0.88, 1.0, 1.0, 0.70)
	parent.add_child(facet)
	return gem

static func add_scene_backdrop_layers(parent: Control, accent: Color, dark: bool, prefix: String = "Surface") -> void:
	# Static geometry mirrors the approved Figma key-light/accent-light composition
	# without per-frame shaders, preserving low-end Android performance.
	var key_light := PanelContainer.new()
	key_light.name = "%sKeyLight" % prefix
	key_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_light.add_theme_stylebox_override("panel", solid_box(Color(1, 1, 1, 0.16 if not dark else 0.09), 110))
	set_rect(key_light, -55, -72, 270, 220)
	parent.add_child(key_light)

	var accent_glow := PanelContainer.new()
	accent_glow.name = "%sAccentGlow" % prefix
	accent_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_glow.add_theme_stylebox_override("panel", solid_box(Color(accent.r, accent.g, accent.b, 0.12 if not dark else 0.08), 120))
	set_rect(accent_glow, 230, 575, 250, 230)
	parent.add_child(accent_glow)

	var sweep := Polygon2D.new()
	sweep.name = "%sLightSweep" % prefix
	sweep.polygon = PackedVector2Array([Vector2(-45,118),Vector2(435,22),Vector2(435,118),Vector2(-45,226)])
	sweep.color = Color(1,1,1,0.095 if not dark else 0.055)
	parent.add_child(sweep)

	var vignette := Polygon2D.new()
	vignette.name = "%sBottomVignette" % prefix
	vignette.polygon = PackedVector2Array([Vector2(-30,692),Vector2(430,604),Vector2(430,844),Vector2(-30,844)])
	vignette.color = Color(0.005,0.015,0.06,0.28 if not dark else 0.42)
	parent.add_child(vignette)

	for i in range(4):
		var vein := Line2D.new()
		vein.name = "%sMaterialVein%d" % [prefix, i]
		vein.width = 1.0
		vein.antialiased = true
		vein.default_color = Color(0.84,0.95,1.0,0.055 if not dark else 0.035) if i % 2 == 0 else Color(0.02,0.07,0.18,0.055)
		var start := Vector2(18.0 + float(i) * 82.0, 260.0 + float(i) * 116.0)
		var length := 120.0 + float(i) * 18.0
		var angle := deg_to_rad(-8.0 if i % 2 == 0 else 11.0)
		vein.points = PackedVector2Array([start, start + Vector2(cos(angle), sin(angle)) * length])
		parent.add_child(vein)

static func style_display_title(label_node: Label, fill: Color, outline_color: Color = Color("#071d55"), outline_size: int = 2) -> void:
	label_node.add_theme_color_override("font_color", fill)
	label_node.add_theme_color_override("font_outline_color", outline_color)
	label_node.add_theme_constant_override("outline_size", outline_size)
	label_node.add_theme_color_override("font_shadow_color", Color(0.01,0.03,0.12,0.72))
	label_node.add_theme_constant_override("shadow_offset_x", 0)
	label_node.add_theme_constant_override("shadow_offset_y", 4)
	label_node.add_theme_constant_override("shadow_outline_size", 2)

static func horizontal_gradient(left: Color, right: Color, radius: float = 0.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxTexture:
	var cache_key := _style_cache_key("horizontal", [left, right], radius, border_color, border_width)
	if _horizontal_gradient_cache.has(cache_key):
		return _horizontal_gradient_cache[cache_key] as StyleBoxTexture
	var image_size := 64
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	var r := clampf(radius / 24.0 * (float(image_size) * 22.0 / 96.0), 0.0, float(image_size) * 44.0 / 96.0)
	var bw := maxf(0.0, border_width)
	for y in range(image_size):
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
			var fx := float(x) / float(image_size - 1)
			image.set_pixel(x, y, left.lerp(right, fx))
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var margin := maxi(8, int(ceil(r + bw + 2.0)))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, 0.0)
	_horizontal_gradient_cache[cache_key] = style
	return style

static func vertical_gradient(top: Color, bottom: Color, radius: float = 0.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxTexture:
	return rounded_gradient(top, bottom, radius, border_color, border_width)

static func shadow_box(radius: float, shadow_color: Color = Color(0.02, 0.10, 0.20, 0.20), shadow_size: int = 6, shadow_offset: Vector2 = Vector2(0, 4)) -> StyleBoxFlat:
	var style := solid_box(Color(0, 0, 0, 0.001), radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = shadow_offset
	return style

static func add_shadow(parent: Control, rect: Rect2, radius: float, shadow_color: Color = Color(0.02, 0.10, 0.20, 0.20), shadow_size: int = 6, shadow_offset: Vector2 = Vector2(0, 4)) -> PanelContainer:
	var shadow := PanelContainer.new()
	shadow.name = "FigmaShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", shadow_box(radius, shadow_color, shadow_size, shadow_offset))
	set_rect(shadow, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	parent.add_child(shadow)
	return shadow

static func contrast_ratio(a: Color, b: Color) -> float:
	var la := a.srgb_to_linear().get_luminance()
	var lb := b.srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func accessible_text_color(preferred: Color, fill: Color, minimum_ratio: float = 4.5) -> Color:
	if contrast_ratio(preferred, fill) >= minimum_ratio:
		return preferred
	var dark_candidate := Color("#071d55")
	var light_candidate := Color("#fffef8")
	return dark_candidate if contrast_ratio(dark_candidate, fill) >= contrast_ratio(light_candidate, fill) else light_candidate

static func premium_button(text_value: String, font_size: int, text_color: Color, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> Button:
	var result := Button.new()
	result.set_meta("unjam_figma_exact_geometry", true)
	result.text = text_value
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", Unjam3DTheme.readable_font())
	result.add_theme_font_size_override("font_size", font_size)
	var resolved_text := accessible_text_color(text_color, fill)
	result.add_theme_color_override("font_color", resolved_text)
	result.add_theme_color_override("font_hover_color", resolved_text)
	result.add_theme_color_override("font_pressed_color", resolved_text)

	# StyleBoxTexture's nine-slice margins contribute to Button minimum size.
	# Drawing the gradient in a geometry-neutral child preserves the exact Figma
	# rectangle (including compact authored controls) without giving up the 3D finish.
	var top := fill.lightened(0.18)
	var bottom := fill.darkened(0.18)
	var gradient := rounded_gradient3(top, fill, bottom, radius, border, border_width)
	var backdrop := FigmaButtonBackdrop.new()
	backdrop.name = "FigmaButtonGradient"
	backdrop.configure(gradient)
	result.add_child(backdrop)

	var clear := solid_box(Color.TRANSPARENT, 0)
	var hover_overlay := solid_box(Color(1,1,1,0.055), radius)
	var pressed_overlay := solid_box(Color(0,0,0,0.075), radius)
	var disabled_overlay := solid_box(Color(0.10,0.13,0.16,0.16), radius)
	result.add_theme_stylebox_override("normal", clear)
	result.add_theme_stylebox_override("hover", hover_overlay)
	result.add_theme_stylebox_override("pressed", pressed_overlay)
	result.add_theme_stylebox_override("focus", clear)
	result.add_theme_stylebox_override("disabled", disabled_overlay)
	var disabled_text := Color(resolved_text.r, resolved_text.g, resolved_text.b, 0.72)
	result.add_theme_color_override("font_disabled_color", disabled_text)
	result.button_down.connect(func() -> void:
		if result.disabled:
			return
		var motion := result.get_node_or_null("/root/MotionSystem")
		if motion != null and motion.has_method("press"):
			motion.call("press", result, 0.78)
	)
	return result

static func label(text_value: String, font_size: int, color: Color, bold := false) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_override("font", Unjam3DTheme.readable_font())
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if bold:
		result.add_theme_constant_override("outline_size", 0)
	return result

static func button(text_value: String, font_size: int, text_color: Color, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> Button:
	var result := Button.new()
	result.text = text_value
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", Unjam3DTheme.readable_font())
	result.add_theme_font_size_override("font_size", font_size)
	var resolved_text := accessible_text_color(text_color, fill)
	result.add_theme_color_override("font_color", resolved_text)
	result.add_theme_color_override("font_hover_color", resolved_text)
	result.add_theme_color_override("font_pressed_color", resolved_text)
	var normal := solid_box(fill, radius, border, border_width)
	var hover := solid_box(fill.lightened(0.055), radius, border.lightened(0.06), border_width)
	var pressed := solid_box(fill.darkened(0.075), radius, border, border_width)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("focus", normal)
	return result

static func panel(fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_width: float = 0.0) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", solid_box(fill, radius, border, border_width))
	return result

static func set_rect(node: Control, x: float, y: float, width: float, height: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(width, height)
	node.custom_minimum_size = Vector2(width, height)

static func add_gloss(parent: Control, rect: Rect2, color: Color = Color(1, 1, 1, 0.16), radius: float = 0.0) -> ColorRect:
	var gloss := ColorRect.new()
	gloss.name = "FigmaGloss"
	gloss.color = color
	gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gloss.position = rect.position
	gloss.size = rect.size
	gloss.custom_minimum_size = rect.size
	parent.add_child(gloss)
	return gloss
