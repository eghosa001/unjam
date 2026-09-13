extends Button
class_name BlockPieceButton

var shape: Array = []
var selected := false
var used := false
var accent := Color("8b7cf6")
var hover := false

func configure(value: Array, is_selected: bool, color := Color("8b7cf6")) -> void:
	shape = value.duplicate(true)
	selected = is_selected
	used = shape.is_empty()
	accent = color
	text = "USED" if used else ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_style()
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(func(): scale = Vector2(0.97, 0.97))
	button_up.connect(func(): scale = Vector2.ONE)
	resized.connect(queue_redraw)

func _set_hover(value: bool) -> void:
	hover = value
	_update_style()
	queue_redraw()

func _update_style() -> void:
	var bg := Color("342b68") if selected else Color("17233d")
	var border := Color("67e8cf") if selected else Color(0.7, 0.74, 1.0, 0.32 if hover else 0.18)
	add_theme_stylebox_override("normal", _style(bg, border, 3 if selected else 2))
	add_theme_stylebox_override("hover", _style(bg.lightened(0.06), border.lightened(0.15), 3 if selected else 2))
	add_theme_stylebox_override("pressed", _style(Color("2f2861"), Color.WHITE, 2))
	add_theme_stylebox_override("disabled", _style(Color("111a2c"), Color(0.4, 0.45, 0.55, 0.18), 1))
	add_theme_color_override("font_color", Color("9aa5b8"))
	add_theme_color_override("font_disabled_color", Color("68758a"))
	add_theme_font_size_override("font_size", 16)

func _draw() -> void:
	if used or shape.is_empty() or size.x <= 1.0 or size.y <= 1.0:
		return
	var points: Array[Vector2i] = []
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			points.append(point)
	if points.is_empty():
		return
	var max_x := 0
	var max_y := 0
	for point in points:
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	var cell := minf(34.0, minf((size.x - 44.0) / float(max_x + 1), (size.y - 36.0) / float(max_y + 1)))
	cell = maxf(10.0, cell)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(2, 2), Vector2(cell - 4, cell - 4))
		draw_style_box(_style(accent, accent.lightened(0.28), 1, 7), rect)
		draw_line(rect.position + Vector2(5, 5), Vector2(rect.end.x - 5, rect.position.y + 5), accent.lightened(0.32), 2.0, true)

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(raw)
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		var cleaned := String(raw).replace("(", "").replace(")", "").replace("Vector2i", "").strip_edges()
		var parts := cleaned.split(",")
		if parts.size() >= 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)

func _style(background: Color, border: Color, width: int, radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.border_color = border
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 4)
	return style
