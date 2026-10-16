extends "res://scripts/ui/block_piece_button.gd"
class_name SmoothBlockPieceButton

const SmoothDragPreview = preload("res://scripts/ui/smooth_block_drag_preview.gd")
const MagneticTarget = preload("res://scripts/ui/block_magnetic_target.gd")
const MIN_ACTUAL_DRAG_PX := 9.0
var _last_magnet := Vector2i(-1,-1)
var _down_pointer := Vector2.ZERO
var _drag_distance := 0.0
var _active_touch_index := -1
var _last_snap_msec := -1000
# Only the few cells in a *changed* target footprint need highlighting.
# Raw pointer input can arrive >100x/s, often within the same 8x8 cell.
var _last_footprint_origin := Vector2i(-1,-1)
var _last_footprint_valid := false

func _clear_touch_footprint() -> void:
	if _last_footprint_origin.x < 0:
		return
	var game := _game()
	if game != null:
		_set_footprint(game, _last_footprint_origin, false, false)
	_last_footprint_origin = Vector2i(-1,-1)
	_last_footprint_valid = false

func _set_footprint(game: Node, origin: Vector2i, active: bool, valid: bool) -> void:
	var cells := _cell_buttons(game)
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
				cell.call("set_drag_footprint", active, valid, accent)

func _ready() -> void:
	super._ready()
	# Listen globally only while this particular finger owns a tray piece.
	# Godot GUI bounds must not interrupt drags that leave the tray.
	set_process_input(false)

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed or touch_drag_started:
			return
		var game := _game()
		if game == null:
			return
		var owner = game.get("active_touch_piece")
		if owner != null and is_instance_valid(owner) and owner != self:
			return
		_active_touch_index = touch.index
		_down_pointer = get_global_transform_with_canvas() * touch.position
		_drag_distance = 0.0
		_last_magnet = Vector2i(-1, -1)
		_last_snap_msec = -1000
		touch_drag_started = true
		game.call("register_touch_drag", self)
		set_process_input(true)
		accept_event()
		return
	# Keep Godot's native mouse and keyboard drag path unaffected.
	super._gui_input(event)

func _input(event: InputEvent) -> void:
	if not touch_drag_started:
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _active_touch_index:
			return
		_drag_distance = maxf(_drag_distance, drag.position.distance_to(_down_pointer))
		if _drag_distance >= MIN_ACTUAL_DRAG_PX:
			_begin_drag_feedback()
			# One target calculation per pointer update. Ghost, board footprint
			# and release all read the same captured viewport coordinates.
			_show_touch_preview(drag.position)
			_update_touch_footprint(drag.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index != _active_touch_index or touch.pressed:
			return
		var tap := _drag_distance < MIN_ACTUAL_DRAG_PX and touch.position.distance_to(_down_pointer) < MIN_ACTUAL_DRAG_PX
		_drag_distance = maxf(_drag_distance, touch.position.distance_to(_down_pointer))
		# Release input ownership before committing: placement can synchronously
		# replace the tray slot, and a later stray finger cannot claim it.
		touch_drag_started = false
		_active_touch_index = -1
		set_process_input(false)
		if touch.canceled:
			dispose_visuals()
		else:
			_finish_touch_drag(touch.position)
			if tap and not used and not shape.is_empty():
				var game := _game()
				if game != null and game.has_method("select_piece"):
					game.call("select_piece", piece_index)
		get_viewport().set_input_as_handled()

func _update_touch_footprint(screen_position: Vector2) -> void:
	if _drag_distance < MIN_ACTUAL_DRAG_PX:
		_clear_touch_footprint()
		return
	var game := _game()
	if game == null:
		_clear_touch_footprint()
		return
	# An illegal aim appears red in its actual cell footprint. Only a legal
	# magnetized position is highlighted green and accepted on release.
	var origin := _last_magnet
	if origin.x < 0:
		origin = MagneticTarget.preview_origin(game, shape, screen_position, MagneticTarget.lift_distance(game))
	var valid := origin.x >= 0 and bool(game.call("can_place", shape, origin))
	if origin == _last_footprint_origin and valid == _last_footprint_valid:
		return
	_clear_touch_footprint()
	_last_footprint_origin = origin
	_last_footprint_valid = valid
	if origin.x >= 0:
		_set_footprint(game, origin, true, valid)

func _clear_single_touch_preview() -> void:
	if touch_preview != null and is_instance_valid(touch_preview):
		# Detach immediately. queue_free() alone leaves the old ghost drawable until
		# frame end and a replacement can briefly produce a duplicate brick.
		var parent := touch_preview.get_parent()
		if parent != null:
			parent.remove_child(touch_preview)
		touch_preview.queue_free()
	touch_preview = null

func _begin_drag_feedback() -> void:
	# Tap-select should not hide the tray piece or flash a floating duplicate.
	if touch_drag_started and _drag_distance < MIN_ACTUAL_DRAG_PX:
		return
	if dragging:
		return
	dragging = true
	_sync_processing()
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.84, 0.84), 0.07)
	var feedback := get_node_or_null("/root/FeedbackManager")
	if feedback != null and feedback.has_method("tap"):
		feedback.call("tap")

func _get_drag_data(_at_position: Vector2) -> Variant:
	if touch_drag_started:
		return null
	if used or shape.is_empty():
		return null
	_clear_single_touch_preview()
	_begin_drag_feedback()
	set_drag_preview(_make_drag_preview())
	return _drag_payload()

func _shape_centroid_grid() -> Vector2:
	if shape.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	var count := 0
	for raw in shape:
		var point := _as_point(raw)
		if point.x >= 0 and point.y >= 0:
			sum += Vector2(point)
			count += 1
	return sum / float(maxi(count, 1))

func _best_origin(game: Node, screen_position: Vector2) -> Vector2i:
	var previous := _last_magnet
	var chosen: Vector2i = MagneticTarget.choose(game, shape, screen_position, previous, MagneticTarget.lift_distance(game))
	_last_magnet = chosen
	# Physical and visual click when moving from one locked grid cell to
	# another, not on every pointer event; bounded for mobile performance.
	if chosen.x >= 0 and previous.x >= 0 and chosen != previous and _drag_distance >= MIN_ACTUAL_DRAG_PX:
		var now := Time.get_ticks_msec()
		if now - _last_snap_msec >= 105:
			_last_snap_msec = now
			var feedback := get_node_or_null("/root/FeedbackManager")
			if feedback != null and feedback.has_method("snap"):
				feedback.call("snap")
			if touch_preview != null and is_instance_valid(touch_preview):
				touch_preview.set_drag_scale(Vector2(1.025, 1.025))
				var settle := touch_preview.create_tween()
				settle.tween_method(
					func(value: float) -> void: touch_preview.set_drag_scale(Vector2.ONE * value),
					1.025, 1.0, 0.085
				)
	return chosen

func _show_touch_preview(screen_position: Vector2) -> void:
	if touch_drag_started and _drag_distance < MIN_ACTUAL_DRAG_PX:
		return
	var game := _game()
	if game == null:
		return
	if touch_preview == null or not is_instance_valid(touch_preview):
		_clear_single_touch_preview()
		touch_preview = SmoothDragPreview.new()
		touch_preview.configure(shape, accent, _board_cell_visual_size(game))
		touch_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_preview.z_index = 950
		var layer = game.get("effects_layer")
		if layer is Control:
			layer.add_child(touch_preview)
		else:
			game.add_child(touch_preview)
	_update_touch_preview_position(screen_position)

func _board_cell_visual_size(game: Node) -> float:
	var geo := MagneticTarget.geometry(game)
	if geo.is_empty():
		return super._board_cell_visual_size(game)
	var step: Vector2 = geo["step"]
	var layer := game.get("effects_layer") as Control
	if layer == null:
		return minf(step.x, step.y)
	var transform := layer.get_global_transform_with_canvas()
	var x_scale := maxf(0.01, transform.x.length())
	var y_scale := maxf(0.01, transform.y.length())
	return minf(step.x / x_scale, step.y / y_scale)

func _preview_position_for_origin(game: Node, origin: Vector2i) -> Vector2:
	if touch_preview == null or not is_instance_valid(touch_preview):
		return Vector2.ZERO
	var geo := MagneticTarget.geometry(game)
	var parent := touch_preview.get_parent() as Control
	if geo.is_empty() or parent == null:
		return touch_preview.position
	var first: Vector2 = geo["first"]
	var step: Vector2 = geo["step"]
	var mean_cell := Vector2(origin) + _shape_centroid_grid()
	var screen_center := first + step * mean_cell
	var local_center := parent.get_global_transform_with_canvas().affine_inverse() * screen_center
	var centroid: Vector2 = touch_preview.call("shape_centroid_local")
	return local_center - centroid

func _make_drag_preview() -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(380, 380)
	wrapper.size = Vector2(380, 380)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.position = Vector2(-190, -315)
	var preview := SmoothDragPreview.new()
	preview.position = Vector2(10, 10)
	preview.configure(shape, accent, _board_cell_visual_size(_game()))
	wrapper.add_child(preview)
	return wrapper

func _update_touch_preview_position(screen_position: Vector2) -> void:
	if touch_preview == null or not is_instance_valid(touch_preview):
		return
	var parent_control := touch_preview.get_parent() as Control
	if parent_control == null:
		return
	var game := _game()
	if game == null:
		return
	var lift := MagneticTarget.lift_distance(game)
	var local_point := parent_control.get_global_transform_with_canvas().affine_inverse() * (screen_position - Vector2(0.0, lift))
	var centroid: Vector2 = touch_preview.call("shape_centroid_local")
	var desired := local_point - centroid
	var origin := _best_origin(game, screen_position)
	var valid := origin.x >= 0 and bool(game.call("can_place", shape, origin))
	if not valid:
		origin = MagneticTarget.preview_origin(game, shape, screen_position, lift)
	if origin.x >= 0:
		desired = _preview_position_for_origin(game, origin)
	# Invalid ghosts and board footprints are red; legal snaps align exactly
	# with the accepted release position, without one-frame teleporting.
	touch_preview.set_drag_target(desired, valid)

func _finish_touch_drag(screen_position: Vector2) -> void:
	var game := _game()
	# Tap-selecting a tray piece must never drop it accidentally.
	if _drag_distance < MIN_ACTUAL_DRAG_PX:
		if game != null and game.has_method("clear_touch_drag"):
			game.call("clear_touch_drag",self)
		_clear_touch_footprint()
		_clear_single_touch_preview()
		_end_drag_feedback(false)
		_last_magnet = Vector2i(-1,-1)
		return
	if game == null:
		_clear_touch_footprint()
		_clear_single_touch_preview()
		_end_drag_feedback(false)
		return
	if game.has_method("clear_touch_drag"):
		game.call("clear_touch_drag", self)
	var origin := _best_origin(game, screen_position)
	var valid := origin.x >= 0 and bool(game.call("can_place", shape, origin))
	if valid:
		_snap_preview_to_origin(game, origin)
		_clear_touch_footprint()
		# The ghost must be gone before the game commits and renders the real board
		# cells; fading it afterwards is what made one placed brick look duplicated.
		_hide_touch_preview(true)
		game.call("place_piece_from_drag", piece_index if piece_index >= 0 else get_index(), origin)
		if is_instance_valid(self) and not is_queued_for_deletion():
			_end_drag_feedback(false)
	else:
		_clear_touch_footprint()
		# Restore the tray piece only after the floating copy is synchronously gone.
		# Fading the preview while revealing the source creates a visible double.
		_clear_single_touch_preview()
		_end_drag_feedback(false)

func dispose_visuals() -> void:
	touch_drag_started = false
	_active_touch_index = -1
	set_process_input(false)
	_last_magnet = Vector2i(-1,-1)
	_drag_distance = 0.0
	_clear_touch_footprint()
	super.dispose_visuals()

