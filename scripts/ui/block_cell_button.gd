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
	if impact_glow > 0.0:
		impact_glow = maxf(0.0, impact_glow - delta * 4.8)
	if clear_echo > 0.0:
		queue_redraw()
	if hover or drag_valid or drag_rejected or footprint_active or impact_glow > 0.0:
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
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.055)

func _release() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.075, 1.075), 0.065)
	tween.tween_property(self, "scale", Vector2.ONE, 0.145)

func _animate_fill() -> void:
	if not is_instance_valid(self):
		return
	impact_glow = 1.0
	pivot_offset = size * 0.5
	scale = Vector2(0.66, 0.66)
	rotation = deg_to_rad(-3.5)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.12)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(1.3), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.13)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.13)

func _animate_clear() -> void:
	if not is_instance_valid(self):
		return
	clear_echo = 1.0
	impact_glow = 1.0
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.07)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(4.0 if cell_index % 2 == 0 else -4.0), 0.07)
	tween.tween_property(self, "scale", Vector2(0.18, 0.18), 0.16)
	tween.parallel().tween_property(self, "clear_echo", 0.0, 0.16)
	tween.tween_property(self, "scale", Vector2.ONE, 0.06)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.06)
	tween.finished.connect(queue_redraw)

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
		if point.x < 0 or point.y < 0:
			continue
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
		drag_valid = false
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
	tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.065)
	tween.tween_property(self, "scale", Vector2.ONE, 0.145)
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
	var pad := 5.0
	var rect := Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	var shadow := Rect2(rect.position + Vector2(0, 6), rect.size)
	_draw_box(shadow, Color(0.07, 0.06, 0.16, 0.20), 18)
	var base := Color("f8fbff")
	if hover and not occupied:
		base = Color("edf6ff")
	_draw_box(rect, base, 18)

	var pulse := 0.5 + 0.5 * sin(phase * 6.0)
	var border := Color(accent, 0.34) if preview else Color("64748b").lerp(accent, 0.24)
	if footprint_active:
		border = Color("34d399") if footprint_valid else Color("ef476f")
	elif drag_valid:
		border = Color("34d399")
	elif drag_rejected:
		border = Color("ef476f")
	var width := 2
	if preview: width = 3
	if footprint_active or drag_valid or drag_rejected: width = 4
	_draw_border(rect, Color(border, minf(1.0, border.a + pulse * 0.20)), 18, width)

	var show_block := occupied or preview or footprint_active or drag_valid or drag_rejected or clear_echo > 0.001
	if show_block:
		var inset := rect.grow(-8)
		var fill := Color(accent, 0.98)
		if clear_echo > 0.001 and not occupied:
			fill = Color(accent.lightened(0.30), 0.90 * clear_echo)
		elif preview:
			fill = Color(accent, 0.43)
		elif footprint_active and not occupied:
			fill = Color("34d399", 0.32 + pulse * 0.10) if footprint_valid else Color("ef476f", 0.20 + pulse * 0.07)
		elif drag_valid and not occupied:
			fill = Color("34d399", 0.30 + pulse * 0.08)
		elif drag_rejected and not occupied:
			fill = Color("ef476f", 0.18 + pulse * 0.06)
		_draw_box(inset, fill, 14)
		var top_glow := fill.lightened(0.30)
		draw_line(inset.position + Vector2(8, 8), Vector2(inset.end.x - 8, inset.position.y + 8), Color(top_glow, 0.9), 4.0, true)
		if occupied or clear_echo > 0.001:
			draw_line(Vector2(inset.position.x + 9, inset.end.y - 8), Vector2(inset.end.x - 9, inset.end.y - 8), Color(accent.darkened(0.22), maxf(0.25, clear_echo)), 4.0, true)
			var shine := Rect2(inset.position + Vector2(10, 14), Vector2(6, maxf(6.0, inset.size.y - 30)))
			draw_rect(shine, Color(1, 1, 1, 0.18), true)
		elif footprint_active and footprint_valid:
			draw_circle(inset.get_center(), 7.0 + pulse * 2.5, Color("ffffff", 0.78))
		elif footprint_active and not footprint_valid:
			draw_line(inset.position + Vector2(16, 16), inset.end - Vector2(16, 16), Color("ef476f"), 5.0, true)
			draw_line(Vector2(inset.end.x - 16, inset.position.y + 16), Vector2(inset.position.x + 16, inset.end.y - 16), Color("ef476f"), 5.0, true)

	if impact_glow > 0.001:
		var glow_rect := rect.grow(3.0 + impact_glow * 4.0)
		_draw_border(glow_rect, Color(accent.lightened(0.45), impact_glow * 0.65), 20, 3)

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
