extends "res://scripts/ui/block_piece_button.gd"
class_name SmoothBlockPieceButton

const SmoothDragPreview = preload("res://scripts/ui/smooth_block_drag_preview.gd")

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
	if has_node("/root/FeedbackManager"):
		FeedbackManager.tap()

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

func _candidate_origin_for_probe(game: Node, probe_cell: Vector2i) -> Vector2i:
	if probe_cell.x < 0:
		return Vector2i(-1, -1)
	var centroid := _shape_centroid_grid()
	var anchor := probe_cell - Vector2i(int(round(centroid.x)), int(round(centroid.y)))
	var offsets := [
		Vector2i.ZERO,
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)
	]
	for offset in offsets:
		var candidate: Vector2i = anchor + offset
		if bool(game.call("can_place", shape, candidate)):
			return candidate
	return anchor

func _best_origin(game: Node, screen_position: Vector2) -> Vector2i:
	var lifted_probe := _origin_for_screen_position(game, screen_position, true)
	var lifted := _candidate_origin_for_probe(game, lifted_probe)
	if lifted.x >= 0 and bool(game.call("can_place", shape, lifted)):
		return lifted
	var direct_probe := _origin_for_screen_position(game, screen_position, false)
	var direct := _candidate_origin_for_probe(game, direct_probe)
	if direct.x >= 0 and bool(game.call("can_place", shape, direct)):
		return direct
	if lifted_probe.x >= 0:
		return lifted
	return direct

func _show_touch_preview(screen_position: Vector2) -> void:
	var game := _game()
	if game == null:
		return
	if touch_preview == null or not is_instance_valid(touch_preview):
		_clear_single_touch_preview()
		touch_preview = SmoothDragPreview.new()
		touch_preview.configure(shape, accent)
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
	preview.configure(shape, accent)
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
		valid = origin.x >= 0 and bool(game.call("can_place", shape, origin))
	if touch_preview.has_method("set_drag_target"):
		touch_preview.call("set_drag_target", desired, valid)
	else:
		touch_preview.position = desired

func _finish_touch_drag(screen_position: Vector2) -> void:
	var game := _game()
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
		if touch_preview != null and is_instance_valid(touch_preview) and touch_preview.has_method("set_drag_scale"):
			touch_preview.call("set_drag_scale", Vector2(0.92, 0.92))
		_hide_touch_preview(false)
		_end_drag_feedback(false)
