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
	button_down.connect(func(): scale = Vector2(0.96, 0.96))
	button_up.connect(func(): scale = Vector2.ONE)
	pivot_offset = size * 0.5

func _set_hover(value: bool) -> void:
	var tween := create_tween()
	tween.tween_property(self, "hover_amount", 1.0 if value else 0.0, 0.12)
	tween.tween_callback(queue_redraw)

func _process(_delta: float) -> void:
	if hover_amount > 0.001 or is_selected:
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(17, 20), size - Vector2(34, 42))
	var lift: float = -8.0 if is_selected else -2.0 * hover_amount
	var body: Rect2 = Rect2(rect.position + Vector2(0, lift), rect.size)
	var shadow: Rect2 = Rect2(body.position + Vector2(0, 12), body.size)
	_draw_round_rect(shadow, Color(0, 0, 0, 0.28), 30.0)
	_draw_round_rect(body, Color(0.035, 0.075, 0.14, 0.96), 30.0)

	var rim_color: Color = Color("67e8cf") if is_selected else Color(0.65, 0.77, 0.92, 0.45 + hover_amount * 0.25)
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.position.y + 6), body.size.x * 0.40, PI, TAU, 30, rim_color, 5.0, true)
	draw_line(body.position + Vector2(8, 18), body.position + Vector2(8, body.size.y - 28), rim_color, 4.0, true)
	draw_line(Vector2(body.end.x - 8, body.position.y + 18), Vector2(body.end.x - 8, body.end.y - 28), rim_color, 4.0, true)
	draw_arc(Vector2(body.position.x + body.size.x * 0.5, body.end.y - 30), body.size.x * 0.40, 0, PI, 30, rim_color, 4.0, true)

	var inner: Rect2 = Rect2(body.position + Vector2(14, 30), body.size - Vector2(28, 58))
	var slot_h: float = inner.size.y / float(CAPACITY)
	for slot in range(CAPACITY):
		var y: float = inner.end.y - slot_h * float(slot + 1)
		var slot_rect: Rect2 = Rect2(Vector2(inner.position.x, y + 2), Vector2(inner.size.x, slot_h - 4))
		if slot < layers.size():
			var color_index: int = clampi(int(layers[slot]), 0, PALETTE.size() - 1)
			var liquid: Color = PALETTE[color_index]
			draw_rect(slot_rect, Color(liquid, 0.92), true)
			draw_line(slot_rect.position + Vector2(8, 5), Vector2(slot_rect.end.x - 8, slot_rect.position.y + 5), liquid.lightened(0.22), 3.0, true)
		else:
			draw_rect(slot_rect, Color(1, 1, 1, 0.018), true)

	if is_selected:
		draw_arc(body.get_center(), body.size.x * 0.56, 0, TAU, 44, Color("67e8cf"), 3.0, true)
	var number_pos: Vector2 = Vector2(body.get_center().x, body.end.y + 20)
	draw_string(ThemeDB.fallback_font, number_pos - Vector2(7, 0), str(tube_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.84, 0.95, 0.8))

func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	draw_style_box(style, rect)
