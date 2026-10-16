extends RefCounted
class_name BlockMagneticTarget

# All distances are expressed in live board cells, not fixed screen pixels.
# Preview and committed release use the same target calculation.
const CATCH_RADIUS := 1.22
const HOLD_RADIUS := 1.38
const STICKINESS := 0.23
const BLOCKED_INTENT_RADIUS := 0.32
const NO_TARGET := Vector2i(-1, -1)

static func _screen_center(cell: Control) -> Vector2:
	# Unlike get_global_rect(), this includes the canvas transform used by
	# responsive/embedded game boards on real Android displays.
	return cell.get_global_transform_with_canvas() * (cell.size * 0.5)

static func geometry(game: Node) -> Dictionary:
	var cells: Array = game.get("cell_buttons")
	if cells.size() < 64:
		return {}
	var cell0 := cells[0] as Control
	var cell1 := cells[1] as Control
	var cell8 := cells[8] as Control
	if cell0 == null or cell1 == null or cell8 == null:
		return {}
	if not is_instance_valid(cell0) or not is_instance_valid(cell1) or not is_instance_valid(cell8):
		return {}
	var first := _screen_center(cell0)
	var step := Vector2(_screen_center(cell1).x - first.x, _screen_center(cell8).y - first.y)
	if step.x <= 1.0 or step.y <= 1.0:
		return {}
	return {"first": first, "step": step}

static func lift_distance(game: Node) -> float:
	var geo := geometry(game)
	if geo.is_empty():
		return 132.0
	# A smaller board-relative lift keeps the finger below the block without
	# making the player aim several hidden rows away from its footprint.
	var step: Vector2 = geo["step"]
	return clampf(step.y * 2.35, 74.0, 114.0)

static func _centroid(shape: Array) -> Vector2:
	if shape.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for cell in shape:
		total += Vector2(cell)
	return total / float(shape.size())

static func _near_board(point: Vector2, geo: Dictionary) -> bool:
	if geo.is_empty():
		return false
	var first: Vector2 = geo["first"]
	var step: Vector2 = geo["step"]
	var edge := step * 0.85
	return Rect2(first - edge, Vector2(step.x * 7.0, step.y * 7.0) + 2.0 * edge).has_point(point)

static func _raw_origin(shape: Array, point: Vector2, geo: Dictionary) -> Vector2:
	var first: Vector2 = geo["first"]
	var step: Vector2 = geo["step"]
	return Vector2((point.x - first.x) / step.x, (point.y - first.y) / step.y) - _centroid(shape)

static func preview_origin(game: Node, shape: Array, finger: Vector2, lift: float) -> Vector2i:
	var geo := geometry(game)
	if geo.is_empty() or shape.is_empty():
		return NO_TARGET
	var target_point := finger - Vector2(0.0, lift)
	if not _near_board(target_point, geo):
		return NO_TARGET
	var raw := _raw_origin(shape, target_point, geo)
	return Vector2i(roundi(raw.x), roundi(raw.y))

static func _closest(game: Node, shape: Array, point: Vector2, geo: Dictionary, held: Vector2i) -> Vector2i:
	if not _near_board(point, geo):
		return NO_TARGET
	var raw := _raw_origin(shape, point, geo)
	var rounded := Vector2i(roundi(raw.x), roundi(raw.y))
	# A nearly centered intentional aim at a blocked tile must show an invalid
	# position. Near its edge, magnetic assistance may offer a neighbouring fit.
	if (raw - Vector2(rounded)).length() <= BLOCKED_INTENT_RADIUS:
		if not bool(game.call("can_place", shape, rounded)):
			return NO_TARGET
	var nearest := NO_TARGET
	var best_distance := CATCH_RADIUS
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var candidate := rounded + Vector2i(dx, dy)
			var distance := (raw - Vector2(candidate)).length()
			if distance > best_distance:
				continue
			if not bool(game.call("can_place", shape, candidate)):
				continue
			nearest = candidate
			best_distance = distance
	# Sub-cell aim correction is forgiving. Holding remains stable across
	# touchscreen jitter, but the pointer cannot teleport to distant legal tiles.
	if held.x >= 0 and bool(game.call("can_place", shape, held)):
		var held_distance := (raw - Vector2(held)).length()
		if held_distance <= HOLD_RADIUS and (nearest == NO_TARGET or held_distance <= best_distance + STICKINESS):
			nearest = held
	return nearest

static func choose(game: Node, shape: Array, finger: Vector2, held: Vector2i, lift: float) -> Vector2i:
	var geo := geometry(game)
	if geo.is_empty() or shape.is_empty():
		return NO_TARGET
	var floating_point := finger - Vector2(0.0, lift)
	# The floating block, not the occluding fingertip, owns the drop position.
	# Never switch to a different row under the finger as it leaves the board.
	return _closest(game, shape, floating_point, geo, held)
