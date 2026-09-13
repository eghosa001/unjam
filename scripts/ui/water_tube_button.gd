extends Button
class_name WaterTubeButton

const CAPACITY := 4
const PALETTE := [
	Color("ff5f7a"), Color("3fa9f5"), Color("ffd166"), Color("45d6a4"),
	Color("9b6cff"), Color("ff9d57"), Color("39d7cf"), Color("f472b6")
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
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)

func _process(delta: float) -> void:
	pulse_time += delta
	press_amount = maxf(0.0, press_amount - delta * 5.0)
	invalid_amount = maxf(0.0, invalid_amount - delta * 3.6)
	success_amount = maxf(0.0, success_amount - delta * 2.4)
	rotation = lerpf(rotation, target_rotation, minf(1.0, delta * 12.0))
	if is_selected:
		var wobble := sin(pulse_time * 4.2) * deg_to_rad(1.8)
		rotation = lerpf(rotation, target_rotation + wobble, minf(1.0, delta * 7.0))
		slosh_amount = maxf(slosh_amount, 0.78)
	else:
		slosh_amount = maxf(0.0, slosh_amount - delta * 2.1)
	if hover_amount > 0.001 or is_selected or slosh_amount > 0.001 or invalid_amount > 0.001 or success_amount > 0.001:
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(14, 18), size - Vector2(28, 40))
	var selected_bob: float = sin(pulse_time * 4.4) * 3.5 if is_selected else 0.0
	var lift: float = (-18.0 + selected_bob) if is_selected else -5.0 * hover_amount
	var body: Rect2 = Rect2(rect.position + Vector2(0, lift), rect.size)
	var shadow: Rect2 = Rect2(body.position + Vector2(0, 16), body.size)
	_draw_round_rect(shadow, Color(0.03, 0.06, 0.12, 0.28), 31.0)
	_draw_round_rect(body, Color("fbfdff"), 31.0)

	var inner: Rect2 = Rect2(body.position + Vector2(14, 31), body.size - Vector2(28, 61))
	var slot_h: float = inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var y: float = inner.end.y - slot_h * float(slot + 1)
		var wave := sin(pulse_time * 8.0 + float(slot) * 1.7) * 4.0 * slosh_amount
		var slot_rect: Rect2 = Rect2(Vector2(inner.position.x, y + 1 + wave * 0.20), Vector2(inner.size.x, slot_h - 2))
		if slot < layers.size():
			var color_index: int = clampi(int(layers[slot]), 0, PALETTE.size() - 1)
			var liquid: Color = PALETTE[color_index] as Color
			draw_rect(slot_rect, Color(liquid, 0.98), true)
			var surface_y: float = slot_rect.position.y + 4.0 + wave
			draw_line(Vector2(slot_rect.position.x + 5, surface_y), Vector2(slot_rect.end.x - 5, surface_y - wave * 0.45), liquid.lightened(0.34), 4.0, true)
			var shine: Rect2 = Rect2(slot_rect.position + Vector2(8, 10), Vector2(maxf(4.0, slot_rect.size.x * 0.10), maxf(5.0, slot_rect.size.y - 18)))
			draw_rect(shine, Color(1, 1, 1, 0.20), true)
		else:
			draw_rect(slot_rect, Color("e7eef7"), true)

	var rim_color: Color = Color("16b8a6") if is_selected else Color("64748b").lerp(Color("3fa9f5"), hover_amount * 0.65)
	if invalid_amount > 0.0:
		rim_color = Color("ef476f")
	if success_amount > 0.0:
		rim_color = Color("22c55e")
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.position.y + 7), body.size.x * 0.40, PI, TAU, 32, rim_color, 5.0, true)
	draw_line(body.position + Vector2(8, 19), body.position + Vector2(8, body.size.y - 29), rim_color, 4.0, true)
	draw_line(Vector2(body.end.x - 8, body.position.y + 19), Vector2(body.end.x - 8, body.end.y - 29), rim_color, 4.0, true)
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.end.y - 30), body.size.x * 0.40, 0, PI, 32, rim_color, 4.0, true)

	var glass_shine: Rect2 = Rect2(body.position + Vector2(18, 34), Vector2(8, body.size.y - 78))
	draw_rect(glass_shine, Color(1, 1, 1, 0.32), true)
	if is_selected:
		var glow_alpha: float = 0.34 + sin(pulse_time * 4.4) * 0.10
		draw_arc(body.get_center(), body.size.x * 0.58, 0, TAU, 48, Color(0.08, 0.72, 0.65, glow_alpha), 5.0, true)
		# Continuous pour anticipation: droplets and a short stream show the active direction.
		var dir := -1.0 if target_rotation < 0.0 else 1.0
		var lip := Vector2(body.get_center().x + dir * body.size.x * 0.38, body.position.y + 13.0)
		for i in range(5):
			var phase := fmod(pulse_time * 2.9 + float(i) * 0.19, 1.0)
			var p := lip + Vector2(dir * phase * 28.0, phase * 48.0 + phase * phase * 18.0)
			draw_circle(p, 3.0 + float(i % 2), Color("39d7cf", 0.82 * (1.0 - phase)))
		if not layers.is_empty():
			var liquid_index := clampi(int(layers.back()), 0, PALETTE.size() - 1)
			var stream_color: Color = PALETTE[liquid_index]
			var stream_phase := 0.5 + 0.5 * sin(pulse_time * 6.0)
			draw_line(lip, lip + Vector2(dir * (22.0 + stream_phase * 8.0), 34.0), Color(stream_color, 0.42), 7.0, true)
	var number_pos: Vector2 = Vector2(body.get_center().x, body.end.y + 20)
	draw_string(ThemeDB.fallback_font, number_pos - Vector2(7, 0), str(tube_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("334155"))

func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)
