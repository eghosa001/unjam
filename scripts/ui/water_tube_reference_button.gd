extends Button

const CAPACITY := 4
const PALETTE := [
	Color("6c35bd"), Color("19a9e8"), Color("f4cf25"), Color("20c8b2"),
	Color("e65b72"), Color("f19b2c"), Color("ef7bb0"), Color("2d60c8")
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
	if MotionSystem.reduced():
		return
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(0.95, 0.95), MotionSystem.duration(&"micro"))

func _release() -> void:
	if MotionSystem.reduced():
		scale = Vector2.ONE
		return
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.04, 1.04), MotionSystem.duration(&"micro"))
	t.tween_property(self, "scale", Vector2.ONE, MotionSystem.duration(&"settle"))

func play_invalid() -> void:
	invalid_flash = 1.0
	if MotionSystem.reduced():
		queue_redraw()
		return
	var original := position
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for dx in [7.0, -7.0, 5.0, -5.0, 0.0]:
		t.tween_property(self, "position", original + Vector2(dx, 0), MotionSystem.duration(&"micro") * 0.58)

func play_success() -> void:
	success_flash = 1.0
	if MotionSystem.reduced():
		queue_redraw()
		return
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.08, 0.97), MotionSystem.duration(&"micro"))
	t.tween_property(self, "scale", Vector2.ONE, MotionSystem.duration(&"settle"))

func _process(delta: float) -> void:
	if not MotionSystem.reduced():
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
	var inner := Rect2(body.position + Vector2(7, 10), body.size - Vector2(14, 20))
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
		if slot == 0:
			var style := StyleBoxFlat.new()
			style.bg_color = liquid
			style.corner_radius_bottom_left = int(radius * 0.52)
			style.corner_radius_bottom_right = int(radius * 0.52)
			draw_style_box(style, r)
		else:
			draw_rect(r, liquid, true)
		# Bright top meniscus.
		draw_line(Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2), liquid.lightened(0.28), 2.0, true)

	# Tube lip and simple glass highlights.
	var lip_y := body.position.y + 3.0
	draw_line(Vector2(body.position.x - 3, lip_y), Vector2(body.end.x + 3, lip_y), outline, 4.0, true)
	draw_line(Vector2(body.position.x + 9, body.position.y + 18), Vector2(body.position.x + 9, body.end.y - 24), Color(1, 1, 1, 0.28), 3.0, true)
	draw_line(Vector2(body.end.x - 7, body.position.y + 23), Vector2(body.end.x - 7, body.size.y * 0.38 + body.position.y), Color(1, 1, 1, 0.13), 2.0, true)

	if is_selected:
		var a := 0.35 if MotionSystem.reduced() else 0.35 + 0.12 * sin(pulse * 5.0)
		draw_arc(body.get_center(), body.size.x * 0.68, 0, TAU, 42, Color(1.0, 0.88, 0.35, a), 4.0, true)

func _draw_glass_shape(rect: Rect2, fill: Color, border: Color, radius: float, border_width: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	if border_width > 0.0:
		var bw := int(border_width)
		style.border_width_left = bw
		style.border_width_right = bw
		style.border_width_top = bw
		style.border_width_bottom = bw
		style.border_color = border
	draw_style_box(style, rect)
