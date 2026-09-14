extends Button
class_name BlockCellButton

var occupied := false
var preview := false
var accent := Color("7c5cff")
var cell_index := 0
var hover := false
var drag_valid := false
var drag_rejected := false
var footprint_active := false
var footprint_valid := false
var clear_echo := 0.0
var impact_glow := 0.0
var phase := 0.0

func configure(is_occupied: bool, is_preview: bool = false, color: Color = Color("7c5cff"), index: int = 0) -> void:
	var was_occupied := occupied
	occupied = is_occupied
	preview = is_preview
	accent = color
	cell_index = index
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if is_inside_tree():
		if not was_occupied and occupied:
			call_deferred("_animate_fill")
		elif was_occupied and not occupied:
			call_deferred("_animate_clear")
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	impact_glow = maxf(0.0, impact_glow - delta * 4.8)
	if clear_echo > 0.0:
		clear_echo = maxf(0.0, clear_echo - delta * 3.5)
	if hover or drag_valid or drag_rejected or footprint_active or impact_glow > 0.0 or clear_echo > 0.0:
		queue_redraw()

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _hover(value: bool) -> void:
	hover = value
	if not value:
		drag_rejected = false
	queue_redraw()

func _press() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.055, 1.055), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.13)

func _animate_fill() -> void:
	if not is_instance_valid(self):
		return
	impact_glow = 1.0
	pivot_offset = size * 0.5
	scale = Vector2(0.72, 0.72)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.09, 1.09), 0.11)
	tween.tween_property(self, "scale", Vector2.ONE, 0.13)

func _animate_clear() -> void:
	if not is_instance_valid(self):
		return
	clear_echo = 1.0
	impact_glow = 1.0
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.14, 1.14), 0.06)
	tween.tween_property(self, "scale", Vector2(0.20, 0.20), 0.14)
	tween.tween_property(self, "scale", Vector2.ONE, 0.07)

func set_drag_footprint(active: bool, valid: bool = false) -> void:
	footprint_active = active
	footprint_valid = valid
	queue_redraw()

func _clear_host_footprint(host: Node) -> void:
	if host == null:
		return
	var buttons = host.get("cell_buttons")
	if buttons is Array:
		for raw in buttons:
			if raw is BlockCellButton:
				(raw as BlockCellButton).set_drag_footprint(false, false)

func _apply_host_footprint(host: Node, shape: Array, origin: Vector2i, valid: bool) -> void:
	_clear_host_footprint(host)
	if host == null:
		return
	var buttons = host.get("cell_buttons")
	if not buttons is Array:
		return
	for raw_point in shape:
		var point := _as_point(raw_point)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			continue
		var index := y * 8 + x
		if index >= 0 and index < buttons.size() and buttons[index] is BlockCellButton:
			(buttons[index] as BlockCellButton).set_drag_footprint(true, valid)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or String(data.get("kind", "")) != "block_piece":
		drag_valid = false
		drag_rejected = false
		queue_redraw()
		return false
	var host := _find_game_host()
	if host == null:
		drag_rejected = true
		return false
	var shape: Array = data.get("shape", [])
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	var valid := bool(host.call("can_place", shape, origin))
	drag_valid = valid
	drag_rejected = not valid
	_apply_host_footprint(host, shape, origin, valid)
	queue_redraw()
	return valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var host := _find_game_host()
	_clear_host_footprint(host)
	drag_valid = false
	drag_rejected = false
	queue_redraw()
	if not data is Dictionary or host == null:
		return
	var piece_index := int(data.get("piece_index", -1))
	var origin := Vector2i(cell_index % 8, int(cell_index / 8))
	if piece_index < 0:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.13, 1.13), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)
	host.call("select_piece", piece_index)
	host.call("place_selected", origin)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var host := _find_game_host()
		_clear_host_footprint(host)
		drag_valid = false
		drag_rejected = false
		queue_redraw()

func _find_game_host() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("can_place") and node.has_method("place_selected") and node.has_method("select_piece"):
			return node
		node = node.get_parent()
	return null

func _draw() -> void:
	var pad := 4.0
	var rect := Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	var shadow := rect.translated(Vector2(0, 5))
	_draw_box(shadow, Color(0, 0, 0, 0.24), 17)
	var base := Color("101a32")
	if hover and not occupied:
		base = Color("152342")
	_draw_box(rect, base, 17)

	var pulse := 0.5 + 0.5 * sin(phase * 5.0)
	var border := Color("2d405f")
	if preview:
		border = Color(accent, 0.72)
	if footprint_active:
		border = Color("34d399") if footprint_valid else Color("ef476f")
	elif drag_valid:
		border = Color("34d399")
	elif drag_rejected:
		border = Color("ef476f")
	_draw_border(rect, Color(border, 0.70 + pulse * 0.08), 17, 2 if not footprint_active else 3)

	# fine inner bevel keeps empty cells dimensional without turning the board into a checkerboard.
	draw_line(rect.position + Vector2(8, 8), Vector2(rect.end.x - 8, rect.position.y + 8), Color(1, 1, 1, 0.035), 2.0, true)

	var show_block := occupied or preview or footprint_active or drag_valid or drag_rejected or clear_echo > 0.001
	if show_block:
		var inset := rect.grow(-7)
		var fill := accent
		if clear_echo > 0.001 and not occupied:
			fill = Color(accent.lightened(0.32), clear_echo)
		elif preview:
			fill = Color(accent, 0.45)
		elif footprint_active and not occupied:
			fill = Color("34d399", 0.34 + pulse * 0.08) if footprint_valid else Color("ef476f", 0.24)
		elif drag_valid and not occupied:
			fill = Color("34d399", 0.32)
		elif drag_rejected and not occupied:
			fill = Color("ef476f", 0.22)
		_draw_box(inset.translated(Vector2(0, 4)), Color(0, 0, 0, 0.25), 12)
		_draw_box(inset, fill, 12)
		draw_line(inset.position + Vector2(7, 7), Vector2(inset.end.x - 7, inset.position.y + 7), Color(fill.lightened(0.40), 0.78), 3.0, true)
		draw_line(Vector2(inset.position.x + 7, inset.end.y - 7), Vector2(inset.end.x - 7, inset.end.y - 7), Color(fill.darkened(0.40), 0.52), 3.0, true)
		if footprint_active and footprint_valid and not occupied:
			draw_circle(inset.get_center(), 5.5 + pulse * 1.8, Color("ffffff", 0.72))
		elif footprint_active and not footprint_valid:
			draw_line(inset.position + Vector2(14, 14), inset.end - Vector2(14, 14), Color("ffffff", 0.72), 4.0, true)
			draw_line(Vector2(inset.end.x - 14, inset.position.y + 14), Vector2(inset.position.x + 14, inset.end.y - 14), Color("ffffff", 0.72), 4.0, true)

	if impact_glow > 0.001:
		_draw_border(rect.grow(4.0 + impact_glow * 3.0), Color(accent.lightened(0.40), impact_glow * 0.55), 20, 3)

func _as_point(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Vector2:
		return Vector2i(raw)
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

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
