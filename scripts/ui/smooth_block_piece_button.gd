extends "res://scripts/ui/block_piece_button.gd"
class_name SmoothBlockPieceButton

const SmoothDragPreview = preload("res://scripts/ui/smooth_block_drag_preview.gd")

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

func _shape_centroid_grid() -> Vector2:
	if shape.is_empty():
		return Vector2.ZERO
	var centroid := Vector2.ZERO
	for raw in shape:
		centroid += Vector2(_as_point(raw))
	return centroid / float(shape.size())

func _candidate_origins(base: Vector2i) -> Array[Vector2i]:
	return [
		base,
		base + Vector2i.LEFT, base + Vector2i.RIGHT, base + Vector2i.UP, base + Vector2i.DOWN,
		base + Vector2i(-1, -1), base + Vector2i(1, -1), base + Vector2i(-1, 1), base + Vector2i(1, 1),
		base + Vector2i(-2, 0), base + Vector2i(2, 0), base + Vector2i(0, -2), base + Vector2i(0, 2)
	]

func _candidate_centroid_global(game: Node, origin: Vector2i) -> Vector2:
	var cells := _cell_buttons(game)
	var center := Vector2.ZERO
	var count := 0
	for raw in shape:
		var point := _as_point(raw)
		var x := origin.x + point.x
		var y := origin.y + point.y
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			continue
		var index := y * 8 + x
		if index >= 0 and index < cells.size():
			var cell := cells[index] as Control
			if cell != null and is_instance_valid(cell):
				center += cell.get_global_rect().get_center()
				count += 1
	return center / float(count) if count > 0 else Vector2(INF, INF)

func _best_origin(game: Node, screen_position: Vector2) -> Vector2i:
	var cells := _cell_buttons(game)
	if cells.is_empty():
		return Vector2i(-1, -1)
	var probe := screen_position - Vector2(0, TOUCH_LIFT)
	var nearest_index := -1
	var nearest_distance := INF
	for i in range(cells.size()):
		var cell := cells[i] as Control
		if cell == null or not is_instance_valid(cell):
			continue
		var distance := cell.get_global_rect().get_center().distance_squared_to(probe)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	if nearest_index < 0:
		return Vector2i(-1, -1)
	var grid_point := Vector2(float(nearest_index % 8), float(int(nearest_index / 8)))
	var shape_centroid := _shape_centroid_grid()
	var base := Vector2i(roundi(grid_point.x - shape_centroid.x), roundi(grid_point.y - shape_centroid.y))
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for candidate in _candidate_origins(base):
		if not bool(game.call("can_place", shape, candidate)):
			continue
		var centroid_global := _candidate_centroid_global(game, candidate)
		var distance := centroid_global.distance_squared_to(probe)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

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
