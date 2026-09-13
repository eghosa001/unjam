extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("8b7cf6")
var cell_index := 0

func configure(is_occupied: bool, is_preview: bool = false, color: Color = Color("8b7cf6"), index: int = 0) -> void:
	occupied = is_occupied
	preview = is_preview
	accent = color
	cell_index = index
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func _ready() -> void:
	button_down.connect(func(): scale = Vector2(0.94, 0.94))
	button_up.connect(func(): scale = Vector2.ONE)
	pivot_offset = size * 0.5

func _draw() -> void:
	var pad: float = 5.0
	var rect: Rect2 = Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	var shadow: Rect2 = Rect2(rect.position + Vector2(0, 5), rect.size)
	_draw_box(shadow, Color(0, 0, 0, 0.22), 18)
	var base: Color = Color(0.055, 0.09, 0.16, 0.98)
	_draw_box(rect, base, 18)
	var border: Color = Color(0.55, 0.64, 0.78, 0.12)
	_draw_border(rect, border, 18, 2)

	if occupied or preview:
		var inset: Rect2 = rect.grow(-8)
		var fill: Color = Color(accent, 0.42 if preview else 0.96)
		_draw_box(inset, fill, 14)
		draw_line(inset.position + Vector2(8, 8), Vector2(inset.end.x - 8, inset.position.y + 8), accent.lightened(0.28), 3.0, true)
		if not preview:
			draw_line(Vector2(inset.position.x + 9, inset.end.y - 8), Vector2(inset.end.x - 9, inset.end.y - 8), accent.darkened(0.28), 3.0, true)

func _draw_box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	draw_style_box(style, rect)

func _draw_border(rect: Rect2, color: Color, radius: int, width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = color
	draw_style_box(style, rect)
