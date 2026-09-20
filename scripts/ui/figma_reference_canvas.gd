class_name FigmaReferenceCanvas
extends Control

# Exact coordinate space used by the audited Production frames in Figma.
const REFERENCE_SIZE := Vector2(390.0, 844.0)

var extra_scale := 1.0

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
	var factor := minf(available.x / REFERENCE_SIZE.x, available.y / REFERENCE_SIZE.y) * extra_scale
	scale = Vector2.ONE * factor
	position = (available - REFERENCE_SIZE * factor) * 0.5
	size = REFERENCE_SIZE

func ref_rect(node: Control, x: float, y: float, width: float, height: float) -> Control:
	node.position = Vector2(x, y)
	node.size = Vector2(width, height)
	node.custom_minimum_size = Vector2(width, height)
	return node

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
	return style

static func rounded_gradient(top: Color, bottom: Color, radius: float = 16.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxTexture:
	var image_size := 96
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	var r := clampf(radius / 24.0 * 22.0, 0.0, 44.0)
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
	return style

static func vertical_gradient(top: Color, bottom: Color, radius: float = 0.0, border_color: Color = Color.TRANSPARENT, border_width: float = 0.0) -> StyleBoxTexture:
	return rounded_gradient(top, bottom, radius, border_color, border_width)

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
	result.add_theme_color_override("font_color", text_color)
	result.add_theme_color_override("font_hover_color", text_color)
	result.add_theme_color_override("font_pressed_color", text_color)
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
