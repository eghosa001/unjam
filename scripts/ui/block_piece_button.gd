extends Button
class_name BlockPieceButton

var shape: Array = []
var selected := false
var used := false
var accent := Color("8b7cf6")
var hover := false

func configure(value: Array, is_selected: bool, color := Color("8b7cf6")) -> void:
	shape = value.duplicate()
	selected = is_selected
	used = shape.is_empty()
	accent = color
	text = "USED" if used else ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_style()
	call_deferred("_render_shape")

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(func(): scale = Vector2(0.97, 0.97))
	button_up.connect(func(): scale = Vector2.ONE)
	resized.connect(_render_shape)

func _set_hover(value: bool) -> void:
	hover = value
	_update_style()

func _update_style() -> void:
	var normal := _style(Color("342b68") if selected else Color("17233d"), Color("67e8cf") if selected else Color(0.7, 0.74, 1.0, 0.32 if hover else 0.18), 3 if selected else 2)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", _style(Color("28365a"), Color("67e8cf"), 2))
	add_theme_stylebox_override("pressed", _style(Color("2f2861"), Color.WHITE, 2))
	add_theme_stylebox_override("disabled", _style(Color("111a2c"), Color(0.4, 0.45, 0.55, 0.18), 1))
	add_theme_color_override("font_color", Color("9aa5b8"))
	add_theme_color_override("font_disabled_color", Color("68758a"))
	add_theme_font_size_override("font_size", 16)

func _render_shape() -> void:
	for child in get_children():
		if child.has_meta("piece_cell"):
			child.queue_free()
	if used or shape.is_empty():
		return
	var max_x := 0
	var max_y := 0
	for point in shape:
		max_x = maxi(max_x, int(point.x))
		max_y = maxi(max_y, int(point.y))
	var cell := minf(34.0, minf((size.x - 44.0) / float(max_x + 1), (size.y - 36.0) / float(max_y + 1)))
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in shape:
		var block := Panel.new()
		block.set_meta("piece_cell", true)
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block.position = origin + Vector2(int(point.x), int(point.y)) * cell + Vector2(2, 2)
		block.size = Vector2(cell - 4, cell - 4)
		block.add_theme_stylebox_override("panel", _style(accent, accent.lightened(0.28), 1, 7))
		add_child(block)

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
