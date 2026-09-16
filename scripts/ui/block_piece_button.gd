extends Button
class_name BlockPieceButton

const DragPreview = preload("res://scripts/ui/block_drag_preview.gd")
const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")
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
var _materials = MATERIALS_SCRIPT.new()

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
	if not MotionSystem.reduced():
		phase += delta
	if dragging:
		queue_redraw()
		return
	var hover_scale := 1.05 if hover and not selected and not MotionSystem.reduced() else 1.0
	var desired := target_scale * hover_scale
	scale = scale.lerp(desired, minf(1.0, delta * 13.0))
	rotation = lerpf(rotation, 0.0, minf(1.0, delta * 14.0))
	if selected or hover:
		queue_redraw()

func _press() -> void:
	if used or MotionSystem.reduced():
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 1.16, MotionSystem.duration(&"micro"))

func _release() -> void:
	if dragging:
		return
	if MotionSystem.reduced():
		scale = target_scale
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale * 0.98, MotionSystem.duration(&"micro") * 0.65)
	tween.tween_property(self, "scale", target_scale, MotionSystem.duration(&"settle"))

func _drag_payload() -> Dictionary:
	var drag_piece_index := piece_index if piece_index >= 0 else get_index()
	return {"kind": "block_piece", "piece_index": drag_piece_index, "shape": shape.duplicate(true), "accent": accent}

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(380, 380)
	wrapper.size = Vector2(380, 380)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.position = Vector2(-190, -315)
	var preview := DragPreview.new()
	preview.position = Vector2(10, 10)
	preview.configure(shape, accent)
	wrapper.add_child(preview)
	return wrapper

func _begin_drag_feedback() -> void:
	if dragging:
		return
	dragging = true
	if MotionSystem.reduced():
		scale = Vector2(0.94, 0.94)
		modulate = Color(1, 1, 1, 0.10)
	else:
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(0.84, 0.84), MotionSystem.duration(&"micro"))
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0.06), MotionSystem.duration(&"micro"))
	if has_node("/root/FeedbackManager"):
		FeedbackManager.tap()

func _show_touch_preview(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	if touch_preview == null or not is_instance_valid(touch_preview):
		touch_preview = DragPreview.new()
		touch_preview.configure(shape, accent)
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
	if immediate or MotionSystem.reduced():
		touch_preview.queue_free()
	else:
		var preview := touch_preview
		var tween := preview.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(preview, "scale", preview.scale * 0.82, MotionSystem.duration(&"micro"))
		tween.parallel().tween_property(preview, "modulate:a", 0.0, MotionSystem.duration(&"press"))
		tween.finished.connect(preview.queue_free)
	touch_preview = null

func _end_drag_feedback(hide_preview := true) -> void:
	if hide_preview:
		_hide_touch_preview()
	if not dragging:
		return
	dragging = false
	if MotionSystem.reduced():
		modulate = Color.WHITE
		scale = target_scale
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, MotionSystem.duration(&"micro"))
	tween.parallel().tween_property(self, "scale", target_scale * 1.10, MotionSystem.duration(&"press"))
	tween.tween_property(self, "scale", target_scale, MotionSystem.duration(&"settle"))

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
		_hide_touch_preview()
		_end_drag_feedback(false)

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
	var cell := minf(74.0, minf((size.x - 24.0) / float(max_x + 1), (size.y - 18.0) / float(max_y + 1)))
	cell = maxf(14.0, cell)
	var total := Vector2((max_x + 1) * cell, (max_y + 1) * cell)
	var origin := (size - total) * 0.5
	for point in points:
		var rect := Rect2(origin + Vector2(point) * cell + Vector2(2, 2), Vector2(cell - 4, cell - 4))
		_draw_block(rect, accent)
	if selected:
		var pulse := 0.55 if MotionSystem.reduced() else 0.55 + 0.45 * sin(phase * 7.0)
		draw_arc(size * 0.5, maxf(total.x, total.y) * 0.60, 0.0, TAU, 32, Color(_materials.bevel_light(accent), 0.20 + pulse * 0.18), 3.0, true)

func _draw_block(rect: Rect2, fill: Color) -> void:
	var reduced := MotionSystem.reduced()
	var depth_offset := _materials.extrusion_offset(0.88, reduced)
	var layers := _materials.depth_layers_for(0.88, reduced)
	var depth: Color = _materials.depth_tone(fill)
	for layer in range(layers, 0, -1):
		var factor := float(layer) / float(layers)
		draw_style_box(_style(Color(depth, fill.a * (0.84 + factor * 0.10)), Color.TRANSPARENT, 0, 6), Rect2(rect.position + depth_offset * factor, rect.size))
	var light: Color = _materials.bevel_light(fill)
	var dark: Color = _materials.bevel_dark(fill)
	draw_style_box(_style(fill, light, 2, 6), rect)
	draw_line(rect.position + Vector2(6, 5), Vector2(rect.end.x - 6, rect.position.y + 5), Color(light, minf(0.98, fill.a)), 3.0, true)
	draw_line(rect.position + Vector2(5, 7), Vector2(rect.position.x + 5, rect.end.y - 7), Color(light, fill.a * 0.80), 2.0, true)
	draw_line(Vector2(rect.position.x + 6, rect.end.y - 5), rect.end - Vector2(6, 5), Color(dark, fill.a * 0.95), 3.0, true)
	draw_line(Vector2(rect.end.x - 5, rect.position.y + 7), rect.end - Vector2(5, 7), Color(dark, fill.a * 0.82), 2.0, true)

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