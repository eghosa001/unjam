extends Button

const CAPACITY := 4
const PALETTE := [
	Color("6c35bd"), Color("19a9e8"), Color("f4cf25"), Color("20c8b2"),
	Color("e65b72"), Color("f19b2c"), Color("ef7bb0"), Color("2d60c8"),
	Color("43a047"), Color("8d6e63"), Color("9ccc2e"), Color("455a64")
]

var layers: Array = []
var is_selected := false
var tube_index := 0
var pulse := 0.0
var invalid_flash := 0.0
var success_flash := 0.0

func configure(values: Array, selected: bool, index: int) -> void:
	layers = values.duplicate()
	is_selected = selected
	tube_index = index
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	button_down.connect(_press)
	button_up.connect(_release)
	pivot_offset = size * 0.5

func _press() -> void:
	var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)

func _release() -> void:
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.13)

func play_invalid() -> void:
	invalid_flash = 1.0
	var original := position
	var t := create_tween()
	for dx in [7.0, -7.0, 5.0, -5.0, 0.0]:
		t.tween_property(self, "position", original + Vector2(dx, 0), 0.04)

func play_success() -> void:
	success_flash = 1.0
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.08, 0.97), 0.07)
	t.tween_property(self, "scale", Vector2.ONE, 0.14)

func _process(delta: float) -> void:
	pulse += delta
	invalid_flash = maxf(0.0, invalid_flash - delta * 3.8)
	success_flash = maxf(0.0, success_flash - delta * 2.8)
	if is_selected or invalid_flash > 0.0 or success_flash > 0.0:
		queue_redraw()

func _draw() -> void:
	var lift := -13.0 if is_selected else 0.0
	var outer := Rect2(Vector2(size.x * 0.18, 13.0 + lift), Vector2(size.x * 0.64, size.y - 42.0))
	var neck_h := outer.size.y * 0.10
	var body := Rect2(outer.position + Vector2(0, neck_h * 0.40), Vector2(outer.size.x, outer.size.y - neck_h * 0.40))
	var inner_top := maxf(14.0, neck_h * 1.10)
	var inner := Rect2(body.position + Vector2(7, inner_top), body.size - Vector2(14, inner_top + 10.0))
	var radius := minf(18.0, body.size.x * 0.30)

	# Soft shadow keeps the glass readable over the illustrated background.
	_draw_glass_shape(Rect2(body.position + Vector2(0, 8), body.size), Color(0, 0, 0, 0.20), Color.TRANSPARENT, radius, 0.0)

	var outline := Color(1, 1, 1, 0.82)
	if is_selected:
		outline = Color("fff3b4")
	if invalid_flash > 0.0:
		outline = Color("ff4d67")
	if success_flash > 0.0:
		outline = Color("7ff0b0")
	_draw_glass_shape(body, Color(1, 1, 1, 0.045), outline, radius, 3.0)

	# Four crisp liquid layers, similar to the visual rhythm in the reference.
	var slot_h := inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		if slot >= layers.size():
			continue
		var color_index := clampi(int(layers[slot]), 0, PALETTE.size() - 1)
		var liquid: Color = PALETTE[color_index]
		var y := inner.end.y - slot_h * float(slot + 1)
		var r := Rect2(Vector2(inner.position.x, y + 1.0), Vector2(inner.size.x, slot_h + 1.0))
		var liquid_base := liquid.darkened(0.10)
		if slot == 0:
			var style := StyleBoxFlat.new()
			style.bg_color = liquid_base
			style.corner_radius_bottom_left = int(radius * 0.52)
			style.corner_radius_bottom_right = int(radius * 0.52)
			draw_style_box(style, r)
		else:
			draw_rect(r, liquid_base, true)
		# Upper light field + bright meniscus gives each liquid band volume without
		# inserting an artificial vertical reflection line through the bottle.
		var light_band := Rect2(r.position + Vector2(2, 2), Vector2(maxf(2.0, r.size.x - 4), maxf(3.0, r.size.y * 0.42)))
		draw_rect(light_band, Color(liquid.lightened(0.20), 0.46), true)
		draw_line(Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2), liquid.lightened(0.40), 2.2, true)

	# Thick glass lip, base refraction and small curved glints. Avoid long vertical
	# wall strokes—the user-visible bottle should read as glass, not as lined plastic.
	var mouth_width := body.size.x * 0.48
	var mouth_y := body.position.y - maxf(12.0, body.size.y * 0.125) * 0.38 + 1.5
	draw_line(Vector2(body.get_center().x - mouth_width * 0.5 - 3.0, mouth_y), Vector2(body.get_center().x + mouth_width * 0.5 + 3.0, mouth_y), outline, 4.5, true)
	draw_line(Vector2(body.get_center().x - mouth_width * 0.38, mouth_y - 1.0), Vector2(body.get_center().x + mouth_width * 0.20, mouth_y - 1.0), Color(1,1,1,0.48), 1.5, true)
	draw_arc(body.get_center() + Vector2(-body.size.x * 0.16, -body.size.y * 0.30), body.size.x * 0.19, -2.65, -1.05, 16, Color(1,1,1,0.38), 2.6, true)
	draw_arc(Vector2(body.get_center().x, body.end.y - radius * 0.72), body.size.x * 0.31, 0.10, PI - 0.10, 22, Color(0.86,0.98,1.0,0.34), 2.2, true)
	draw_circle(body.position + Vector2(body.size.x * 0.30, body.size.y * 0.18), maxf(1.8, body.size.x * 0.045), Color(1,1,1,0.44))

	if is_selected:
		var a := 0.35 + 0.12 * sin(pulse * 5.0)
		draw_arc(body.get_center(), body.size.x * 0.68, 0, TAU, 42, Color(1.0, 0.88, 0.35, a), 4.0, true)

func _draw_glass_shape(rect: Rect2, fill: Color, border: Color, radius: float, border_width: float) -> void:
	# Premium bottle silhouette: a genuinely narrow neck, sloped shoulders and a
	# rounded crystal body. This stays in the authoritative CanvasItem renderer so
	# interaction remains cheap while the bottle reads as glass rather than a tube.
	var neck_width := rect.size.x * 0.48
	var neck_height := maxf(12.0, rect.size.y * 0.125)
	var neck := Rect2(
		Vector2(rect.get_center().x - neck_width * 0.5, rect.position.y - neck_height * 0.38),
		Vector2(neck_width, neck_height)
	)
	var body_top := rect.position.y + neck_height * 0.72
	var body := Rect2(Vector2(rect.position.x, body_top), Vector2(rect.size.x, rect.end.y - body_top))
	var shoulder_y := body.position.y + maxf(3.0, radius * 0.20)
	var shoulder := PackedVector2Array([
		Vector2(neck.position.x, neck.end.y - 1.0),
		Vector2(neck.end.x, neck.end.y - 1.0),
		Vector2(body.end.x - radius * 0.18, shoulder_y),
		Vector2(body.position.x + radius * 0.18, shoulder_y),
	])

	# Shoulder bridge is drawn first so neck/body seams disappear into one glass
	# silhouette instead of looking like two stacked rounded rectangles.
	draw_colored_polygon(shoulder, fill)

	var body_style := StyleBoxFlat.new()
	body_style.bg_color = fill
	body_style.corner_radius_top_left = int(radius * 0.26)
	body_style.corner_radius_top_right = int(radius * 0.26)
	body_style.corner_radius_bottom_left = int(radius)
	body_style.corner_radius_bottom_right = int(radius)
	var neck_style := StyleBoxFlat.new()
	neck_style.bg_color = fill
	neck_style.corner_radius_top_left = 4
	neck_style.corner_radius_top_right = 4
	neck_style.corner_radius_bottom_left = 2
	neck_style.corner_radius_bottom_right = 2

	if border_width > 0.0:
		var bw := maxi(1, int(border_width))
		# Do not draw horizontal borders at the shoulder seam; use explicit sloped
		# shoulder edges so the bottle keeps a continuous crystal outline.
		body_style.border_width_left = bw
		body_style.border_width_right = bw
		body_style.border_width_bottom = bw
		body_style.border_width_top = 0
		body_style.border_color = border
		neck_style.border_width_left = bw
		neck_style.border_width_right = bw
		neck_style.border_width_top = bw
		neck_style.border_width_bottom = 0
		neck_style.border_color = border

	draw_style_box(body_style, body)
	draw_style_box(neck_style, neck)

	if border_width > 0.0:
		var shoulder_width := maxf(1.5, border_width)
		draw_line(Vector2(neck.position.x, neck.end.y - 1.0), Vector2(body.position.x + radius * 0.18, shoulder_y), border, shoulder_width, true)
		draw_line(Vector2(neck.end.x, neck.end.y - 1.0), Vector2(body.end.x - radius * 0.18, shoulder_y), border, shoulder_width, true)

	# Local refraction follows the curved body rather than a long vertical white
	# stripe, preserving the clean glass look requested for Water Sort.
	if fill.a > 0.0:
		draw_arc(Vector2(body.get_center().x, body.end.y - radius * 0.70), body.size.x * 0.30, 0.08, PI - 0.08, 20, Color(0.62,0.92,1.0,minf(fill.a * 2.2,0.18)), 2.0, true)
		draw_arc(Vector2(body.position.x + radius * 0.58, body.position.y + radius * 0.72), radius * 0.42, -2.75, -1.22, 12, Color(1,1,1,minf(fill.a * 3.2,0.22)), 1.8, true)
		draw_circle(Vector2(body.position.x + body.size.x * 0.30, body.position.y + body.size.y * 0.17), maxf(1.4, body.size.x * 0.030), Color(1,1,1,minf(fill.a * 4.0,0.26)))
