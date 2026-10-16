extends RefCounted
class_name BlockMagneticTarget

# All distances are expressed in live board cells, not fixed screen pixels.
# Preview and committed release use the same target calculation.
const CATCH_RADIUS := 1.32
const HOLD_RADIUS := 1.38
const STICKINESS := 0.23
const BLOCKED_INTENT_RADIUS := 0.32
const RELEASE_HOLD_RADIUS := 0.80
const NO_TARGET := Vector2i(-1, -1)
const NO_GRAB_ANCHOR := Vector2(-1.0, -1.0)

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

static func lift_distance(game: Node, geo_override: Dictionary = {}) -> float:
	var geo := geo_override if not geo_override.is_empty() else geometry(game)
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

static func _raw_origin(shape: Array, point: Vector2, geo: Dictionary, grab_anchor: Vector2 = NO_GRAB_ANCHOR) -> Vector2:
	var first: Vector2 = geo["first"]
	var step: Vector2 = geo["step"]
	var anchor := grab_anchor if grab_anchor.x >= 0.0 and grab_anchor.y >= 0.0 else _centroid(shape)
	return Vector2((point.x - first.x) / step.x, (point.y - first.y) / step.y) - anchor

static func preview_origin(game: Node, shape: Array, finger: Vector2, lift: float, grab_anchor: Vector2 = NO_GRAB_ANCHOR, geo_override: Dictionary = {}) -> Vector2i:
	var geo := geo_override if not geo_override.is_empty() else geometry(game)
	if geo.is_empty() or shape.is_empty():
		return NO_TARGET
	var target_point := finger - Vector2(0.0, lift)
	if not _near_board(target_point, geo):
		return NO_TARGET
	var raw := _raw_origin(shape, target_point, geo, grab_anchor)
	return Vector2i(roundi(raw.x), roundi(raw.y))

static func _closest(game: Node, shape: Array, point: Vector2, geo: Dictionary, held: Vector2i, grab_anchor: Vector2 = NO_GRAB_ANCHOR) -> Vector2i:
	if not _near_board(point, geo):
		return NO_TARGET
	var raw := _raw_origin(shape, point, geo, grab_anchor)
	var rounded := Vector2i(roundi(raw.x), roundi(raw.y))
	# Check the intended origin once and reuse the answer for both blocked
	# intent and fast nearest-candidate resolution on every touch sample.
	var rounded_valid := bool(game.call("can_place", shape, rounded))
	# A nearly centred aim at an occupied tile still shows red, unless it
	# only trembled a fraction of a cell away from a held green placement.
	if not rounded_valid and (raw - Vector2(rounded)).length() <= BLOCKED_INTENT_RADIUS:
		if held.x >= 0 and (raw - Vector2(held)).length() <= RELEASE_HOLD_RADIUS:
			if bool(game.call("can_place", shape, held)):
				return held
		return NO_TARGET
	var nearest := NO_TARGET
	var best_distance := CATCH_RADIUS
	# Most finger samples are centred on an open cell. The nearest integer
	# origin is mathematically the closest grid target, so validate it first
	# rather than doing 25 full shape-collision checks on every Android drag.
	if rounded_valid:
		nearest = rounded
		best_distance = (raw - Vector2(rounded)).length()
	else:
		# When the pointer is between blocked cells, check only actual nearby
		# origins. Offsets of two cannot fit inside the 1.32-cell catch radius
		# when rounded already lies within half a cell on either axis.
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
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

static func choose(game: Node, shape: Array, finger: Vector2, held: Vector2i, lift: float, grab_anchor: Vector2 = NO_GRAB_ANCHOR, geo_override: Dictionary = {}) -> Vector2i:
	var geo := geo_override if not geo_override.is_empty() else geometry(game)
	if geo.is_empty() or shape.is_empty():
		return NO_TARGET
	var floating_point := finger - Vector2(0.0, lift)
	# The floating block, not the occluding fingertip, owns the drop position.
	# Never switch to a different row under the finger as it leaves the board.
	return _closest(game, shape, floating_point, geo, held, grab_anchor)

static func choose_release(game: Node, shape: Array, finger: Vector2, held: Vector2i, lift: float, grab_anchor: Vector2 = NO_GRAB_ANCHOR) -> Vector2i:
	# A few pixels of finger movement on lift-up must not turn a visibly
	# green, snapped brick into a failed drop. A previous lock is accepted
	# only when the release is still within 0.8 real cells of that lock.
	# This is never a global nearest-legal search or a distant auto-placement.
	var target := choose(game, shape, finger, held, lift, grab_anchor)
	if target.x >= 0:
		return target
	if held.x < 0 or not bool(game.call("can_place", shape, held)):
		return NO_TARGET
	var geo := geometry(game)
	if geo.is_empty():
		return NO_TARGET
	var point := finger - Vector2(0.0, lift)
	if not _near_board(point, geo):
		return NO_TARGET
	var raw := _raw_origin(shape, point, geo, grab_anchor)
	return held if (raw - Vector2(held)).length() <= RELEASE_HOLD_RADIUS else NO_TARGET
