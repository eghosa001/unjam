extends Button
class_name WaterTubeButton

const CAPACITY := 4
const PALETTE := [
	Color("ff6b7a"), Color("5da9ff"), Color("ffd166"), Color("57d69a"),
	Color("c074ff"), Color("ff9d57"), Color("67e8cf"), Color("f472b6")
]

var layers: Array = []
var is_selected := false
var tube_index := 0
var hover_amount := 0.0
var pulse_time := 0.0

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
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _press() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.965, 0.965), 0.07)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16)

func _set_hover(value: bool) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.12)

func _process(delta: float) -> void:
	pulse_time += delta
	if hover_amount > 0.001 or is_selected:
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(14, 18), size - Vector2(28, 40))
	var selected_bob := sin(pulse_time * 4.0) * 2.0 if is_selected else 0.0
	var lift := (-11.0 + selected_bob) if is_selected else -3.0 * hover_amount
	var body := Rect2(rect.position + Vector2(0, lift), rect.size)
	var shadow := Rect2(body.position + Vector2(0, 13), body.size)
	_draw_round_rect(shadow, Color(0, 0, 0, 0.32), 31.0)
	_draw_round_rect(body, Color(0.028, 0.066, 0.13, 0.98), 31.0)

	var inner := Rect2(body.position + Vector2(14, 31), body.size - Vector2(28, 61))
	var slot_h := inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var y := inner.end.y - slot_h * float(slot + 1)
		var slot_rect := Rect2(Vector2(inner.position.x, y + 1), Vector2(inner.size.x, slot_h - 2))
		if slot < layers.size():
			var color_index := clampi(int(layers[slot]), 0, PALETTE.size() - 1)
			var liquid := PALETTE[color_index]
			draw_rect(slot_rect, Color(liquid, 0.96), true)
			var surface_y := slot_rect.position.y + 4
			draw_line(Vector2(slot_rect.position.x + 5, surface_y), Vector2(slot_rect.end.x - 5, surface_y), liquid.lightened(0.3), 4.0, true)
			var shine := Rect2(slot_rect.position + Vector2(8, 10), Vector2(maxf(4.0, slot_rect.size.x * 0.10), maxf(5.0, slot_rect.size.y - 18)))
			draw_rect(shine, Color(1, 1, 1, 0.10), true)
		else:
			draw_rect(slot_rect, Color(1, 1, 1, 0.014), true)

	var rim_color := Color("67e8cf") if is_selected else Color(0.67, 0.79, 0.94, 0.48 + hover_amount * 0.24)
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.position.y + 7), body.size.x * 0.40, PI, TAU, 32, rim_color, 5.0, true)
	draw_line(body.position + Vector2(8, 19), body.position + Vector2(8, body.size.y - 29), rim_color, 4.0, true)
	draw_line(Vector2(body.end.x - 8, body.position.y + 19), Vector2(body.end.x - 8, body.end.y - 29), rim_color, 4.0, true)
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.end.y - 30), body.size.x * 0.40, 0, PI, 32, rim_color, 4.0, true)

	var glass_shine := Rect2(body.position + Vector2(18, 34), Vector2(8, body.size.y - 78))
	draw_rect(glass_shine, Color(1, 1, 1, 0.10), true)
	if is_selected:
		var glow_alpha := 0.32 + sin(pulse_time * 4.0) * 0.08
		draw_arc(body.get_center(), body.size.x * 0.56, 0, TAU, 48, Color(0.40, 0.91, 0.81, glow_alpha), 4.0, true)
	var number_pos := Vector2(body.get_center().x, body.end.y + 20)
	draw_string(ThemeDB.fallback_font, number_pos - Vector2(7, 0), str(tube_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.84, 0.95, 0.82))

func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)
