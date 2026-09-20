extends Button
class_name BlockPieceButton

const DragPreview = preload("res://scripts/ui/block_drag_preview.gd")
const TOUCH_LIFT := 132.0
const TOUCH_SNAP_RADIUS := 112.0

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
	# A tray slot can be reconfigured during refill/shuffle/placement. Any touch
	# ghost belongs to the old visual and must be removed before the new brick is
	# drawn, otherwise both remain visible for a frame and look duplicated.
	if touch_drag_started or (touch_preview != null and is_instance_valid(touch_preview)):
		dispose_visuals()
	shape = _sanitize_shape(value)
	selected = is_selected
	used = shape.is_empty()
	accent = color
	piece_index = index
	text = ""
	focus_mode = Control.FOCUS_NONE
	disabled = used
	flat = true
	clip_contents = false
	mouse_default_cursor_shape = Control.CURSOR_DRAG if not used else Control.CURSOR_ARROW
	target_scale = Vector2(1.08, 1.08) if selected else Vector2.ONE
	_update_style()
	queue_redraw()
	if is_inside_tree():
		_sync_processing()

func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	button_down.connect(_press)
	button_up.connect(_release)
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	set_process(false)
	_sync_processing()

func _sync_processing() -> void:
	set_process(selected or hover or dragging)

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	phase += delta
	if dragging:
		queue_redraw()
		return
	var hover_scale := 1.05 if hover and not selected else 1.0
	var desired := target_scale * hover_scale
	scale = scale.lerp(desired, minf(1.0, delta * 13.0))
	rotation = lerpf(rotation, 0.0, minf(1.0, delta * 14.0))
	if selected or hover:
		queue_redraw()

func _press() -> void:
	if used:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.16, 0.06)

func _release() -> void:
	if dragging:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 0.98, 0.045)
	tween.tween_property(self, "scale", target_scale, 0.12)

func _drag_payload() -> Dictionary:
	var drag_piece_index := piece_index if piece_index >= 0 else get_index()
	return {"kind": "block_piece", "piece_index": drag_piece_index, "shape": shape.duplicate(true), "accent": accent}

func _board_cell_visual_size(game: Node) -> float:
	if game == null:
		return 0.0
	var cells := _cell_buttons(game)
	if cells.is_empty():
		return 0.0
	var first := cells[0] as Control
	if first == null or not is_instance_valid(first):
		return 0.0
	return minf(first.size.x, first.size.y)

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(380, 380)
	wrapper.size = Vector2(380, 380)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.position = Vector2(-190, -315)
	var preview := DragPreview.new()
	preview.position = Vector2(10, 10)
	preview.configure(shape, accent, _board_cell_visual_size(_game()))
	wrapper.add_child(preview)
	return wrapper

func _begin_drag_feedback() -> void:
	if dragging:
		return
	dragging = true
	_sync_processing()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.84, 0.84), 0.07)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.06), 0.07)
	var feedback := get_node_or_null("/root/FeedbackManager")
	if feedback != null and feedback.has_method("tap"):
		feedback.call("tap")

func _show_touch_preview(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	if touch_preview == null or not is_instance_valid(touch_preview):
		touch_preview = DragPreview.new()
		touch_preview.configure(shape, accent, _board_cell_visual_size(game))
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
	var game := _game()
	var local_point: Vector2 = parent_control.get_global_transform_with_canvas().affine_inverse() * screen_position
	var desired: Vector2 = local_point - Vector2(touch_preview.size.x * 0.5, touch_preview.size.y * 0.5 + TOUCH_LIFT)
	var valid := true
	if game != null:
		var origin := _best_origin(game, screen_position)
		if origin.x >= 0:
			desired = _preview_position_for_origin(game, origin)
			valid = bool(game.call("can_place", shape, origin))
		else:
			valid = false
	if touch_preview.has_method("set_drag_target"):
		touch_preview.call("set_drag_target", desired, valid)
	else:
		touch_preview.position = desired

func _hide_touch_preview(immediate := true) -> void:
	if touch_preview == null or not is_instance_valid(touch_preview):
		touch_preview = null
		return
	var preview := touch_preview
	touch_preview = null
	if immediate:
		# Floating previews live in the game effects layer, not under the tray button.
		# Detach synchronously so a tray refresh can never leave one drawable frame
		# of the old piece behind beside the newly rendered piece.
		var parent := preview.get_parent()
		if parent != null:
			parent.remove_child(preview)
		preview.queue_free()
	else:
		var tween := preview.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(preview, "scale", preview.scale * 0.82, 0.08)
		tween.parallel().tween_property(preview, "modulate:a", 0.0, 0.10)
		tween.finished.connect(preview.queue_free)

func _end_drag_feedback(hide_preview := true) -> void:
	if hide_preview:
		_hide_touch_preview()
	if not dragging:
		return
	dragging = false
	_sync_processing()
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.07)
	tween.parallel().tween_property(self, "scale", target_scale * 1.10, 0.09)
	tween.tween_property(self, "scale", target_scale, 0.15)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if used or shape.is_empty():
		return null
	_begin_drag_feedback()
	set_drag_preview(_make_drag_preview())
	return _drag_payload()

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty():
		return
	# Control._gui_input receives touch coordinates in this button's LOCAL space.
	# Convert them back to canvas/screen space before driving the floating preview
	# and board hit-testing; using the local values made the ghost jump offscreen.
	if event is InputEventScreenTouch:
		var screen_position: Vector2 = get_global_transform_with_canvas() * event.position
		if event.pressed:
			touch_drag_started = true
			_begin_drag_feedback()
			var game := _game()
			if game != null and game.has_method("register_touch_drag"):
				game.call("register_touch_drag", self)
			_show_touch_preview(screen_position)
			_update_touch_footprint(screen_position)
			accept_event()
		else:
			if touch_drag_started:
				_finish_touch_drag(screen_position)
				touch_drag_started = false
				accept_event()
			else:
				touch_drag_started = false
	elif event is InputEventScreenDrag:
		var screen_position: Vector2 = get_global_transform_with_canvas() * event.position
		if not touch_drag_started:
			touch_drag_started = true
			_begin_drag_feedback()
			var game := _game()
			if game != null and game.has_method("register_touch_drag"):
				game.call("register_touch_drag", self)
		_show_touch_preview(screen_position)
		_update_touch_preview_position(screen_position)
		_update_touch_footprint(screen_position)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_touch_footprint()
		_hide_touch_preview(true)
		_end_drag_feedback(false)

func dispose_visuals() -> void:
	# Called by the tray owner before a control is replaced/reconfigured. Keep
	# external preview nodes and board-footprint highlights from becoming orphans.
	_clear_touch_footprint()
	var game := _game()
	if game != null and game.has_method("clear_touch_drag"):
		game.call("clear_touch_drag", self)
	touch_drag_started = false
	dragging = false
	_hide_touch_preview(true)
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0

func _exit_tree() -> void:
	# touch_preview is parented to effects_layer, so normal child cleanup would
	# not remove it when this tray button leaves the tree.
	_hide_touch_preview(true)

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
			cell.call("set_drag_footprint", false, false, accent)

func _update_touch_footprint(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	var cells := _cell_buttons(game)
	for cell in cells:
		if cell != null and is_instance_valid(cell) and cell.has_method("set_drag_footprint"):
			cell.call("set_drag_footprint", false, false, accent)
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
				cell.call("set_drag_footprint", true, valid, accent)

func _preview_position_for_origin(game: Node, origin: Vector2i) -> Vector2:
	if touch_preview == null or not is_instance_valid(touch_preview):
		return Vector2.ZERO
	var cells := _cell_buttons(game)
	if cells.is_empty():
		return touch_preview.position
	var center := Vector2.ZERO
	var count := 0
	for raw in shape:
		var point := _as_point(raw)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			continue
		var idx := y * 8 + x
		if idx >= 0 and idx < cells.size():
			var cell: Control = cells[idx]
			center += cell.get_global_rect().get_center()
			count += 1
	if count <= 0:
		return touch_preview.position
	center /= float(count)
	var parent_control := touch_preview.get_parent() as Control
	if parent_control == null:
		return touch_preview.position
	var local_center: Vector2 = parent_control.get_global_transform_with_canvas().affine_inverse() * center
	var centroid := touch_preview.size * 0.5
	if touch_preview.has_method("shape_centroid_local"):
		centroid = Vector2(touch_preview.call("shape_centroid_local"))
	return local_center - centroid

func _snap_preview_to_origin(game: Node, origin: Vector2i) -> void:
	if touch_preview == null or not is_instance_valid(touch_preview):
		return
	var desired := _preview_position_for_origin(game, origin)
	if touch_preview.has_method("set_drag_target"):
		touch_preview.call("set_drag_target", desired, true)
	if touch_preview.has_method("set_drag_scale"):
		touch_preview.call("set_drag_scale", Vector2(1.03, 1.03))

func _finish_touch_drag(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		_clear_touch_footprint()
		_hide_touch_preview()
		_end_drag_feedback(false)
		return
	if game.has_method("clear_touch_drag"):
		game.call("clear_touch_drag", self)
	var origin := _best_origin(game, screen_position)
	var valid := origin.x >= 0 and bool(game.call("can_place", shape, origin))
	if valid:
		_snap_preview_to_origin(game, origin)
		game.call("place_piece_from_drag", piece_index if piece_index >= 0 else get_index(), origin)
		_clear_touch_footprint()
		_hide_touch_preview(false)
		_end_drag_feedback(false)
	else:
		_clear_touch_footprint()
		if touch_preview != null and is_instance_valid(touch_preview):
			if touch_preview.has_method("set_drag_scale"):
				touch_preview.call("set_drag_scale", Vector2(0.92, 0.92))
		_hide_touch_preview(false)
		_end_drag_feedback(false)

func _set_hover(value: bool) -> void:
	hover = value
	_sync_processing()
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
	var cell := _tray_cell_size(max_x, max_y)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(2, 2), Vector2(cell - 4, cell - 4))
		_draw_block(rect, accent)
	if selected:
		var pulse := 0.55 + 0.45 * sin(phase * 7.0)
		draw_arc(size * 0.5, maxf(total.x, total.y) * 0.60, 0.0, TAU, 32, Color(accent.lightened(0.38), 0.20 + pulse * 0.18), 3.0, true)

func tray_visual_cell_size() -> float:
	if shape.is_empty():
		return 0.0
	var max_x := 0
	var max_y := 0
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			max_x = maxi(max_x, point.x)
			max_y = maxi(max_y, point.y)
	return _tray_cell_size(max_x, max_y)

func _tray_cell_size(max_x: int, max_y: int) -> float:
	var fit_cell := minf((size.x - 24.0) / float(max_x + 1), (size.y - 18.0) / float(max_y + 1))
	# Keep every tray shape on one visual scale. A single-cell piece should read
	# like one board cell, not inflate to fill the entire tray slot.
	return clampf(minf(30.0, fit_cell), 16.0, 30.0)

func _draw_block(rect: Rect2, fill: Color) -> void:
	# Use real top/right extrusion instead of a second full-size dark rectangle.
	# The old offset shadow could read as a duplicate brick in the piece tray.
	var depth := clampf(rect.size.x * 0.10, 3.0, 7.0)
	var front := Rect2(rect.position + Vector2(0.0, depth), rect.size - Vector2(depth, depth))
	var bottom_shadow := Rect2(
		Vector2(front.position.x + 3.0, front.end.y + 1.0),
		Vector2(maxf(2.0, front.size.x - 4.0), maxf(3.0, depth * 0.65))
	)
	draw_style_box(_style(Color(fill.darkened(0.52), 0.42), Color.TRANSPARENT, 0, 4), bottom_shadow)
	var top_face := PackedVector2Array([
		front.position,
		front.position + Vector2(depth, -depth),
		Vector2(front.end.x + depth, front.position.y - depth),
		Vector2(front.end.x, front.position.y)
	])
	var right_face := PackedVector2Array([
		Vector2(front.end.x, front.position.y),
		Vector2(front.end.x + depth, front.position.y - depth),
		Vector2(front.end.x + depth, front.end.y - depth),
		Vector2(front.end.x, front.end.y)
	])
	draw_colored_polygon(top_face, fill.lightened(0.34))
	draw_colored_polygon(right_face, fill.darkened(0.24))
	draw_style_box(_style(fill, fill.lightened(0.28), 2, 6), front)
	var inner := front.grow(-3.0)
	draw_style_box(_style(Color(fill.lightened(0.10), 0.20), Color(1, 1, 1, 0.08), 1, 4), inner)
	draw_line(front.position + Vector2(6, 5), Vector2(front.end.x - 6, front.position.y + 5), Color(fill.lightened(0.58), 0.96), 2.6, true)
	var gloss_band := Rect2(
		front.position + Vector2(front.size.x * 0.16, front.size.y * 0.18),
		Vector2(front.size.x * 0.46, maxf(3.0, front.size.y * 0.16))
	)
	draw_style_box(_style(Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.06), 1, 5), gloss_band)
	draw_circle(front.position + Vector2(front.size.x * 0.25, front.size.y * 0.30), maxf(1.2, front.size.x * 0.045), Color(1,1,1,0.52))

func _sanitize_shape(value: Array) -> Array:
	var unique := {}
	var points: Array[Vector2i] = []
	var min_x := 999
	var min_y := 999
	for raw in value:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		var key := "%d:%d" % [point.x, point.y]
		if unique.has(key):
			continue
		unique[key] = true
		points.append(point)
		min_x = mini(min_x, point.x)
		min_y = mini(min_y, point.y)
	if points.is_empty():
		return []
	var normalized: Array = []
	for point in points:
		normalized.append(Vector2i(point.x - min_x, point.y - min_y))
	return normalized

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
	if width > 0:
		style.border_width_left = width
		style.border_width_right = width
		style.border_width_top = width
		style.border_width_bottom = width
		style.border_color = border
	return style
