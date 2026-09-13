extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("7c5cff")
var cell_index := 0
var hover := false
var drag_valid := false

func configure(is_occupied: bool, is_preview: bool = false, color: Color = Color("7c5cff"), index: int = 0) -> void:
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
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _hover(value: bool) -> void:
	hover = value
	queue_redraw()

func _press() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or String(data.get("kind", "")) != "block_piece":
		drag_valid = false
		queue_redraw()
		return false
	var host := _find_game_host()
	if host == null:
		drag_valid = false
		return false
	var shape: Array = data.get("shape", [])
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	drag_valid = bool(host.call("can_place", shape, origin))
	queue_redraw()
	return drag_valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	drag_valid = false
	queue_redraw()
	if not data is Dictionary:
		return
	var host := _find_game_host()
	if host == null:
		return
	var piece_index := int(data.get("piece_index", -1))
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	if piece_index < 0:
		return
	host.call("select_piece", piece_index)
	host.call("place_selected", origin)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_valid = false
		queue_redraw()

func _find_game_host() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("can_place") and node.has_method("place_selected") and node.has_method("select_piece"):
			return node
		node = node.get_parent()
	return null

func _draw() -> void:
	var pad := 5.0
	var rect := Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	var shadow := Rect2(rect.position + Vector2(0, 5), rect.size)
	_draw_box(shadow, Color(0.24, 0.18, 0.36, 0.14), 18)
	var base := Color("f8fbff")
	if hover and not occupied:
		base = Color("eef8ff")
	_draw_box(rect, base, 18)
	var border := Color(accent, 0.34) if preview else Color("94a3b8").lerp(accent, 0.20)
	if drag_valid:
		border = Color("10b981")
	_draw_border(rect, border, 18, 4 if drag_valid else (3 if preview else 2))

	if occupied or preview or drag_valid:
		var inset := rect.grow(-8)
		var fill := Color("34d399") if drag_valid and not occupied else Color(accent, 0.43 if preview else 0.98)
		if drag_valid and not occupied:
			fill.a = 0.28
		_draw_box(inset, fill, 14)
		var top_glow := fill.lightened(0.30)
		draw_line(inset.position + Vector2(8, 8), Vector2(inset.end.x - 8, inset.position.y + 8), Color(top_glow, 0.9), 4.0, true)
		if occupied:
			draw_line(Vector2(inset.position.x + 9, inset.end.y - 8), Vector2(inset.end.x - 9, inset.end.y - 8), accent.darkened(0.22), 4.0, true)
			var shine := Rect2(inset.position + Vector2(10, 14), Vector2(6, maxf(6.0, inset.size.y - 30)))
			draw_rect(shine, Color(1, 1, 1, 0.18), true)

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
