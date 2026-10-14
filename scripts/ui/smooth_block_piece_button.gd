extends "res://scripts/ui/block_piece_button.gd"
class_name SmoothBlockPieceButton

const SmoothDragPreview = preload("res://scripts/ui/smooth_block_drag_preview.gd")
const MagneticTarget = preload("res://scripts/ui/block_magnetic_target.gd")
const MIN_ACTUAL_DRAG_PX := 13.0
var _last_magnet := Vector2i(-1,-1)
var _down_pointer := Vector2.ZERO
var _drag_distance := 0.0
# Only the few cells in a *changed* target footprint need highlighting.
# Raw pointer input can arrive >100x/s, often within the same 8x8 cell.
var _last_footprint_origin := Vector2i(-1,-1)
var _last_footprint_valid := false

func _clear_touch_footprint() -> void:
	if _last_footprint_origin.x < 0:
		return
	_last_footprint_origin = Vector2i(-1,-1)
	_last_footprint_valid = false
	super._clear_touch_footprint()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var pointer: Vector2 = get_global_transform_with_canvas() * event.position
		if event.pressed:
			_down_pointer = pointer
			_drag_distance = 0.0
			_last_magnet = Vector2i(-1,-1)
		else:
			_drag_distance = maxf(_drag_distance,pointer.distance_to(_down_pointer))
	elif event is InputEventScreenDrag:
		var pointer: Vector2 = get_global_transform_with_canvas() * event.position
		_drag_distance = maxf(_drag_distance,pointer.distance_to(_down_pointer))
	super._gui_input(event)

func _update_touch_footprint(screen_position: Vector2) -> void:
	if _drag_distance < MIN_ACTUAL_DRAG_PX:
		_clear_touch_footprint()
		return
	var game := _game()
	if game == null:
		_clear_touch_footprint()
		return
	# Reuse the preview's cached magnetic target; avoid waking all 64 board
	# cells on every sub-cell finger movement at 60/120Hz.
	var origin := _last_magnet
	if origin.x < 0:
		origin = _best_origin(game,screen_position)
	var valid := origin.x >= 0 and bool(game.call("can_place",shape,origin))
	if origin == _last_footprint_origin and valid == _last_footprint_valid:
		return
	_last_footprint_origin = origin
	_last_footprint_valid = valid
	super._update_touch_footprint(screen_position)


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
	var chosen: Vector2i = MagneticTarget.choose(game,shape,screen_position,_last_magnet,TOUCH_LIFT)
	_last_magnet = chosen
	return chosen

func _show_touch_preview(screen_position: Vector2) -> void:
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
	var local_point := parent_control.get_global_transform_with_canvas().affine_inverse() * screen_position
	var desired := local_point - Vector2(touch_preview.size.x * 0.5, touch_preview.size.y * 0.5 + TOUCH_LIFT)
	var game := _game()
	var valid := false
	if game != null:
		var origin := _best_origin(game, screen_position)
		valid = _drag_distance >= MIN_ACTUAL_DRAG_PX and origin.x >= 0 and bool(game.call("can_place", shape, origin))
		if valid:
			# Match the ghost to the *actual* legal cells highlighted beneath it.
			# The same centroid calculation is used on pointer release; no
			# unexpected teleport occurs between hover and committed placement.
			desired = _preview_position_for_origin(game, origin)
	if touch_preview.has_method("set_drag_target"):
		touch_preview.call("set_drag_target", desired, valid)
	else:
		touch_preview.position = desired

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
	_last_magnet = Vector2i(-1,-1)
	_drag_distance = 0.0
	_clear_touch_footprint()
	super.dispose_visuals()
