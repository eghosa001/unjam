extends Button
class_name BlockPieceButton

const DragPreview = preload("res://scripts/ui/block_drag_preview.gd")
const TOUCH_LIFT := 96.0
const TOUCH_SNAP_RADIUS := 82.0

var shape: Array = []
var selected := false
var used := false
var accent := Color("4f7cff")
var hover := false
var piece_index := -1
var touch_drag_started := false
var dragging := false
var phase := 0.0
var target_scale := Vector2.ONE
var touch_preview: Control

func configure(value: Array, is_selected: bool, color := Color("4f7cff"), index: int = -1) -> void:
	shape = value.duplicate(true)
	selected = is_selected
	used = shape.is_empty()
	accent = color
	piece_index = index
	text = ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_DRAG if not used else Control.CURSOR_ARROW
	target_scale = Vector2(1.08, 1.08) if selected else Vector2.ONE
	_update_style()
	queue_redraw()

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	set_process(true)

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	phase += delta
	if dragging:
		queue_redraw()
		return
	var hover_scale := 1.045 if hover and not selected else 1.0
	var desired := target_scale * hover_scale
	scale = scale.lerp(desired, minf(1.0, delta * 13.0))
	rotation = lerpf(rotation, 0.0, minf(1.0, delta * 14.0))
	if selected or hover:
		queue_redraw()

func _press() -> void:
	if used:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.12, 0.06)

func _release() -> void:
	if dragging:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 0.98, 0.045)
	tween.tween_property(self, "scale", target_scale, 0.12)

func _drag_payload() -> Dictionary:
	var drag_piece_index := piece_index if piece_index >= 0 else get_index()
	return {"kind": "block_piece", "piece_index": drag_piece_index, "shape": shape.duplicate(true)}

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(250, 250)
	wrapper.size = Vector2(250, 250)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.position = Vector2(-125, -215)
	var preview := DragPreview.new()
	preview.position = Vector2(10, 8)
	preview.configure(shape, accent)
	wrapper.add_child(preview)
	return wrapper

func _begin_drag_feedback() -> void:
	if dragging:
		return
	dragging = true
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.90, 0.90), 0.07)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.24), 0.07)

func _show_touch_preview(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	if touch_preview == null or not is_instance_valid(touch_preview):
		touch_preview = DragPreview.new()
		touch_preview.configure(shape, accent)
		touch_preview.scale = Vector2(1.18, 1.18)
		touch_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_preview.z_index = 950
		var layer = game.get("effects_layer")
		if layer is Control:
			layer.add_child(touch_preview)
		else:
			game.add_child(touch_preview)
	_update_touch_preview_position(screen_position)

func _update_touch_preview_position(screen_position: Vector2) -> void:
	if touch_preview == null or not is_instance_valid(touch_preview):
		return
	var parent_control := touch_preview.get_parent() as Control
	if parent_control == null:
		return
	var local_point: Vector2 = parent_control.get_global_transform_with_canvas().affine_inverse() * screen_position
	# Lift the actual brick above the finger so it remains visible while aiming.
	touch_preview.position = local_point - Vector2(touch_preview.size.x * 0.5, touch_preview.size.y + 8.0)

func _hide_touch_preview() -> void:
	if touch_preview != null and is_instance_valid(touch_preview):
		touch_preview.queue_free()
	touch_preview = null

func _end_drag_feedback() -> void:
	_hide_touch_preview()
	if not dragging:
		return
	dragging = false
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.07)
	tween.parallel().tween_property(self, "scale", target_scale * 1.08, 0.09)
	tween.tween_property(self, "scale", target_scale, 0.15)

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Desktop/mouse path: use Godot's native drag-and-drop lifecycle.
	if used or shape.is_empty():
		return null
	_begin_drag_feedback()
	set_drag_preview(_make_drag_preview())
	return _drag_payload()

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_drag_started = true
			_begin_drag_feedback()
			var game := _game()
			if game != null and game.has_method("register_touch_drag"):
				game.call("register_touch_drag", self)
			_show_touch_preview(event.position)
			_update_touch_footprint(event.position)
			accept_event()
		else:
			if touch_drag_started:
				_finish_touch_drag(event.position)
				touch_drag_started = false
				accept_event()
			else:
				touch_drag_started = false
	elif event is InputEventScreenDrag:
		if not touch_drag_started:
			touch_drag_started = true
			_begin_drag_feedback()
			var game := _game()
			if game != null and game.has_method("register_touch_drag"):
				game.call("register_touch_drag", self)
		_show_touch_preview(event.position)
		_update_touch_preview_position(event.position)
		_update_touch_footprint(event.position)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_touch_footprint()
		_hide_touch_preview()
		_end_drag_feedback()

func _game() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("place_piece_from_drag") and node.has_method("can_place"):
			return node
		node = node.get_parent()
	return null

func _cell_buttons(game: Node) -> Array:
	var value: Variant = game.get("cell_buttons")
	return value if value is Array else []

func _origin_for_screen_position(game: Node, screen_position: Vector2, lifted: bool) -> Vector2i:
	var cells := _cell_buttons(game)
	if cells.is_empty():
		return Vector2i(-1, -1)
	var probe := screen_position - (Vector2(0, TOUCH_LIFT) if lifted else Vector2.ZERO)
	var best_index := -1
	var best_distance := INF
	for i in range(cells.size()):
		var cell: Control = cells[i]
		if cell == null or not is_instance_valid(cell):
			continue
		var rect := cell.get_global_rect()
		if rect.has_point(probe):
			return Vector2i(i % 8, int(i / 8))
		var d := rect.get_center().distance_squared_to(probe)
		if d < best_distance:
			best_distance = d
			best_index = i
	if best_index >= 0 and sqrt(best_distance) <= TOUCH_SNAP_RADIUS:
		return Vector2i(best_index % 8, int(best_index / 8))
	return Vector2i(-1, -1)

func _best_origin(game: Node, screen_position: Vector2) -> Vector2i:
	# Prefer the lifted mobile preview position used by commercial block puzzles.
	# Fall back to the finger position so synthetic touch and accessibility input
	# remain reliable even when they do not emulate the same drag geometry.
	var lifted := _origin_for_screen_position(game, screen_position, true)
	if lifted.x >= 0 and bool(game.call("can_place", shape, lifted)):
		return lifted
	var direct := _origin_for_screen_position(game, screen_position, false)
	if direct.x >= 0 and bool(game.call("can_place", shape, direct)):
		return direct
	if lifted.x >= 0:
		return lifted
	return direct

func _clear_touch_footprint() -> void:
	var game := _game()
	if game == null:
		return
	for cell in _cell_buttons(game):
		if cell != null and is_instance_valid(cell) and cell.has_method("set_drag_footprint"):
			cell.call("set_drag_footprint", false, false)

func _update_touch_footprint(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	var cells := _cell_buttons(game)
	for cell in cells:
		if cell != null and is_instance_valid(cell) and cell.has_method("set_drag_footprint"):
			cell.call("set_drag_footprint", false, false)
	var origin := _best_origin(game, screen_position)
	if origin.x < 0:
		return
	var valid := bool(game.call("can_place", shape, origin))
	for raw in shape:
		var point := _as_point(raw)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			continue
		var index := y * 8 + x
		if index >= 0 and index < cells.size():
			var cell = cells[index]
			if cell != null and is_instance_valid(cell) and cell.has_method("set_drag_footprint"):
				cell.call("set_drag_footprint", true, valid)

func _finish_touch_drag(screen_position: Vector2) -> void:
	var game := _game()
	_clear_touch_footprint()
	_hide_touch_preview()
	_end_drag_feedback()
	if game == null:
		return
	if game.has_method("clear_touch_drag"):
		game.call("clear_touch_drag", self)
	var origin := _best_origin(game, screen_position)
	if origin.x < 0:
		return
	game.call("place_piece_from_drag", piece_index if piece_index >= 0 else get_index(), origin)

func _set_hover(value: bool) -> void:
	hover = value
	queue_redraw()

func _update_style() -> void:
	var transparent := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", transparent)
	add_theme_stylebox_override("hover", transparent)
	add_theme_stylebox_override("pressed", transparent)
	add_theme_stylebox_override("disabled", transparent)

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
	var cell := minf(42.0, minf((size.x - 26.0) / float(max_x + 1), (size.y - 20.0) / float(max_y + 1)))
	cell = maxf(12.0, cell)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(1.5, 1.5), Vector2(cell - 3, cell - 3))
		_draw_block(rect, accent)
	if selected:
		var pulse := 0.55 + 0.45 * sin(phase * 7.0)
		draw_arc(size * 0.5, maxf(total.x, total.y) * 0.58, 0.0, TAU, 32, Color(accent.lightened(0.38), 0.18 + pulse * 0.16), 3.0, true)

func _draw_block(rect: Rect2, fill: Color) -> void:
	var dark := fill.darkened(0.28)
	draw_style_box(_style(dark, Color.TRANSPARENT, 0, 3), Rect2(rect.position + Vector2(0, 4), rect.size))
	draw_style_box(_style(fill, fill.lightened(0.22), 1, 3), rect)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.end.x - 4, rect.position.y + 4), Color(fill.lightened(0.50), 0.98), 2.2, true)
	draw_line(rect.position + Vector2(4, 4), Vector2(rect.position.x + 4, rect.end.y - 4), Color(fill.lightened(0.30), 0.80), 1.5, true)
	draw_line(Vector2(rect.position.x + 4, rect.end.y - 4), rect.end - Vector2(4, 4), Color(dark, 0.95), 2.2, true)
	draw_line(Vector2(rect.end.x - 4, rect.position.y + 4), rect.end - Vector2(4, 4), Color(dark, 0.82), 1.5, true)

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

func _style(background: Color, border: Color, width: int, radius: int = 3) -> StyleBoxFlat:
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
	return style
