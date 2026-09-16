extends "res://scripts/ui/block_piece_button.gd"
class_name SmoothBlockPieceButton

const SmoothDragPreview = preload("res://scripts/ui/smooth_block_drag_preview.gd")

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
	# Prefer the centroid-aligned drop, then nearby cells. This gives touch users
	# a forgiving magnetic landing zone without permitting illegal placements.
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
	# Follow the finger continuously. Only the footprint snaps to cells; the
	# piece itself no longer jumps from one board centroid to the next.
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
