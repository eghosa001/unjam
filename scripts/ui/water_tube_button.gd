extends Button
class_name WaterTubeButton

const CAPACITY := 4
const PALETTE := [
	# High-separation palette: red, royal blue, yellow, emerald, violet, orange,
	# cyan and magenta. Adjacent colours differ strongly in both hue and value.
	Color("ff355d"), Color("2478ff"), Color("ffd42a"), Color("19c56f"),
	Color("8b4dff"), Color("ff7a00"), Color("00cfe8"), Color("ff3db8")
]

var layers: Array = []
var is_selected := false
var tube_index := 0
var hover_amount := 0.0
var pulse_time := 0.0
var slosh_amount := 0.0
var target_rotation := 0.0
var press_amount := 0.0
var invalid_amount := 0.0
var success_amount := 0.0
var landing_amount := 0.0
var bubble_phase := 0.0

func configure(values: Array, selected: bool, index: int) -> void:
	layers = values.duplicate()
	is_selected = selected
	tube_index = index
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_selected:
		target_rotation = deg_to_rad(-8.0 if index % 2 == 0 else 8.0)
		slosh_amount = 1.0
	else:
		target_rotation = 0.0
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _press() -> void:
	press_amount = 1.0
	slosh_amount = 1.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.07)

func _release() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)

func _set_hover(value: bool) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.12)
	if value:
		slosh_amount = maxf(slosh_amount, 0.50)

func play_invalid() -> void:
	invalid_amount = 1.0
	var original := position
	var tween := create_tween()
	for dx in [8.0, -8.0, 6.0, -6.0, 0.0]:
		tween.tween_property(self, "position", original + Vector2(dx, 0), 0.045)

func play_success() -> void:
	success_amount = 1.0
	landing_amount = 1.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.10, 0.96), 0.08)
	tween.tween_property(self, "scale", Vector2(0.98, 1.07), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16)

func _process(delta: float) -> void:
	pulse_time += delta
	bubble_phase += delta
	press_amount = maxf(0.0, press_amount - delta * 5.0)
	invalid_amount = maxf(0.0, invalid_amount - delta * 3.6)
	success_amount = maxf(0.0, success_amount - delta * 2.4)
	landing_amount = maxf(0.0, landing_amount - delta * 2.8)
	rotation = lerpf(rotation, target_rotation, minf(1.0, delta * 12.0))
	if is_selected:
		var wobble := sin(pulse_time * 4.2) * deg_to_rad(1.8)
		rotation = lerpf(rotation, target_rotation + wobble, minf(1.0, delta * 7.0))
		slosh_amount = maxf(slosh_amount, 0.78)
	else:
		slosh_amount = maxf(0.0, slosh_amount - delta * 2.1)
	if hover_amount > 0.001 or is_selected or slosh_amount > 0.001 or invalid_amount > 0.001 or success_amount > 0.001 or landing_amount > 0.001 or layers.is_empty():
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(12, 14), size - Vector2(24, 34))
	var selected_bob: float = sin(pulse_time * 4.4) * 3.5 if is_selected else 0.0
	var lift: float = (-18.0 + selected_bob) if is_selected else -5.0 * hover_amount
	var body: Rect2 = Rect2(rect.position + Vector2(0, lift), rect.size)
	var shadow: Rect2 = Rect2(body.position + Vector2(0, 17), body.size)

	# Premium glass silhouette: translucent shell + darker inner cavity instead of a flat white bottle.
	_draw_round_rect(shadow, Color(0.01, 0.025, 0.06, 0.34), 34.0)
	_draw_round_rect_border(body, Color(0.66, 0.87, 1.0, 0.13), Color(0.82, 0.94, 1.0, 0.76), 34.0, 4)
	var cavity := Rect2(body.position + Vector2(12, 27), body.size - Vector2(24, 53))
	_draw_round_rect_border(cavity, Color(0.025, 0.075, 0.14, 0.34), Color(0.78, 0.92, 1.0, 0.16), 24.0, 2)

	var inner: Rect2 = Rect2(cavity.position + Vector2(5, 12), cavity.size - Vector2(10, 24))
	var slot_h: float = inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var y: float = inner.end.y - slot_h * float(slot + 1)
		var wave := sin(pulse_time * 8.0 + float(slot) * 1.7) * 4.0 * slosh_amount
		var slot_rect: Rect2 = Rect2(Vector2(inner.position.x, y + 1 + wave * 0.20), Vector2(inner.size.x, slot_h - 2))
		if slot < layers.size():
			var color_index: int = clampi(int(layers[slot]), 0, PALETTE.size() - 1)
			var liquid: Color = PALETTE[color_index] as Color
			_draw_round_rect(slot_rect, Color(liquid, 0.96), 8.0 if slot == 0 else 4.0)
			var surface_y: float = slot_rect.position.y + 4.0 + wave
			draw_line(Vector2(slot_rect.position.x + 6, surface_y), Vector2(slot_rect.end.x - 6, surface_y - wave * 0.45), liquid.lightened(0.36), 4.0, true)
			# A tiny shape marker provides an accessibility cue in addition to colour.
			# It is deliberately subtle so the tubes still look like liquid rather
			# than labelled containers.
			var marker_center := Vector2(slot_rect.end.x - 16, slot_rect.get_center().y)
			match color_index % 4:
				0: draw_circle(marker_center, 4.0, Color(1, 1, 1, 0.62))
				1: draw_line(marker_center - Vector2(5, 0), marker_center + Vector2(5, 0), Color(1, 1, 1, 0.62), 3.0, true)
				2: draw_rect(Rect2(marker_center - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 1, 0.55), true)
				_: draw_line(marker_center - Vector2(4, 4), marker_center + Vector2(4, 4), Color(1, 1, 1, 0.62), 3.0, true)
		else:
			# Empty capacity is glass, not opaque grey fill.
			draw_line(Vector2(slot_rect.position.x + 7, slot_rect.end.y - 2), Vector2(slot_rect.end.x - 7, slot_rect.end.y - 2), Color(0.72, 0.88, 1.0, 0.07), 1.5, true)

	var rim_color: Color = Color("16b8a6") if is_selected else Color("9ccdea").lerp(Color("5da9ff"), hover_amount * 0.55)
	if invalid_amount > 0.0:
		rim_color = Color("ef476f")
	if success_amount > 0.0:
		rim_color = Color("22c55e")

	# Glass lip/base plus the translucent rounded body define the bottle. Avoid
	# vertical wall strokes inside the silhouette; they read as artificial lines.
	var lip_center := Vector2(body.get_center().x, body.position.y + 12)
	draw_arc(lip_center, body.size.x * 0.39, PI, TAU, 36, Color(rim_color, 0.90), 5.5, true)
	draw_arc(lip_center + Vector2(0, 3), body.size.x * 0.32, PI, TAU, 30, Color(0.92, 0.98, 1.0, 0.40), 2.5, true)
	draw_arc(Vector2(body.get_center().x, body.end.y - 31), body.size.x * 0.39, 0, PI, 36, Color(rim_color, 0.88), 4.5, true)
	draw_arc(Vector2(body.get_center().x, body.end.y - 35), body.size.x * 0.31, 0, PI, 30, Color(0.84, 0.95, 1.0, 0.30), 2.0, true)

	# Keep the bottle readable through its lip, walls and base only. A vertical
	# interior reflection reads as an artificial divider once the tube is empty.

	if layers.is_empty():
		var empty_pulse := 0.5 + 0.5 * sin(bubble_phase * 2.3 + float(tube_index))
		var empty_center := cavity.get_center() + Vector2(0, 14)
		draw_arc(empty_center, minf(cavity.size.x, cavity.size.y) * 0.13, 0, TAU, 32, Color("9ccdea", 0.13 + empty_pulse * 0.07), 2.0, true)
		draw_circle(empty_center + Vector2(-10, -7), 3.2, Color(1, 1, 1, 0.16 + empty_pulse * 0.08))
		draw_circle(empty_center + Vector2(9, 8), 2.2, Color(1, 1, 1, 0.12 + empty_pulse * 0.06))

	if is_selected:
		var glow_alpha: float = 0.34 + sin(pulse_time * 4.4) * 0.10
		draw_arc(body.get_center(), body.size.x * 0.57, 0, TAU, 48, Color(0.08, 0.72, 0.65, glow_alpha), 5.0, true)
		var dir := -1.0 if target_rotation < 0.0 else 1.0
		var lip := Vector2(body.get_center().x + dir * body.size.x * 0.38, body.position.y + 14.0)
		for i in range(5):
			var phase := fmod(pulse_time * 2.9 + float(i) * 0.19, 1.0)
			var p := lip + Vector2(dir * phase * 28.0, phase * 48.0 + phase * phase * 18.0)
			draw_circle(p, 3.0 + float(i % 2), Color("39d7cf", 0.82 * (1.0 - phase)))
		if not layers.is_empty():
			var liquid_index := clampi(int(layers.back()), 0, PALETTE.size() - 1)
			var stream_color: Color = PALETTE[liquid_index]
			var stream_phase := 0.5 + 0.5 * sin(pulse_time * 6.0)
			draw_line(lip, lip + Vector2(dir * (22.0 + stream_phase * 8.0), 34.0), Color(stream_color, 0.42), 7.0, true)

	if landing_amount > 0.001:
		var land_center := Vector2(body.get_center().x, cavity.position.y + 34)
		var spread := (1.0 - landing_amount) * 26.0
		draw_arc(land_center, 14.0 + spread, 0.15, PI - 0.15, 28, Color("ffffff", landing_amount * 0.52), 3.0, true)
		for i in range(4):
			var a := -2.55 + float(i) * 1.7
			var dp := land_center + Vector2(cos(a), sin(a)) * (18.0 + spread * 0.55)
			draw_circle(dp, 2.5 + float(i % 2), Color("67e8cf", landing_amount * 0.72))

	var number_pos: Vector2 = Vector2(body.get_center().x, body.end.y + 20)
	draw_string(ThemeDB.fallback_font, number_pos - Vector2(7, 0), str(tube_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c6d7ea"))

func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)

func _draw_round_rect_border(rect: Rect2, color: Color, border: Color, radius: float, width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = border
	draw_style_box(style, rect)
