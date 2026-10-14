extends RefCounted
class_name BlockMagneticTarget

# Distances are measured in actual screen-space grid cells: portable across
# iPhone-size boards, tall Samsung phones, and tablets.
const CATCH_RADIUS := 0.82
const STICKINESS := 0.16
const NO_TARGET := Vector2i(-1,-1)

static func geometry(game: Node) -> Dictionary:
	var cells: Array = game.get("cell_buttons")
	if cells.size() < 64:
		return {}
	var cell0 := cells[0] as Control
	var cell1 := cells[1] as Control
	var cell8 := cells[8] as Control
	if cell0 == null or cell1 == null or cell8 == null:
		return {}
	var first := cell0.get_global_rect().get_center()
	var step := Vector2(cell1.get_global_rect().get_center().x-first.x,cell8.get_global_rect().get_center().y-first.y)
	if step.x <= 1.0 or step.y <= 1.0:
		return {}
	return {"first":first,"step":step}

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
	return Rect2(first-edge,Vector2(step.x*7.0,step.y*7.0)+2.0*edge).has_point(point)

static func _closest(game: Node, shape: Array, point: Vector2, geo: Dictionary, held: Vector2i) -> Vector2i:
	if not _near_board(point,geo):
		return NO_TARGET
	var first: Vector2 = geo["first"]
	var step: Vector2 = geo["step"]
	var center := _centroid(shape)
	var raw := Vector2((point.x-first.x)/step.x-center.x,(point.y-first.y)/step.y-center.y)
	var rounded := Vector2i(roundi(raw.x),roundi(raw.y))
	var nearest := NO_TARGET
	var best_distance := CATCH_RADIUS
	# Small bounded 3x3 search prevents the previous arbitrary first-legal
	# one-cell jump and keeps work constant even on late-game boards.
	for dy in range(-1,2):
		for dx in range(-1,2):
			var candidate := rounded + Vector2i(dx,dy)
			var distance := (raw-Vector2(candidate)).length()
			if distance >= CATCH_RADIUS or distance > best_distance:
				continue
			if not bool(game.call("can_place",shape,candidate)):
				continue
			nearest = candidate
			best_distance = distance
	# Hysteresis makes magnetic holding stable near cell boundaries but cannot
	# override a distinctly closer, intentional new location.
	if held.x >= 0 and bool(game.call("can_place",shape,held)):
		var held_distance := (raw-Vector2(held)).length()
		if held_distance < CATCH_RADIUS and held_distance <= best_distance+STICKINESS:
			nearest = held
	return nearest

static func choose(game: Node, shape: Array, finger: Vector2, held: Vector2i, lift: float) -> Vector2i:
	var geo := geometry(game)
	if geo.is_empty() or shape.is_empty():
		return NO_TARGET
	var floating_point := finger - Vector2(0,lift)
	# If the intended floating footprint is over the board but obstructed,
	# NEVER silently fall back to the finger below (a different row).
	if _near_board(floating_point,geo):
		return _closest(game,shape,floating_point,geo,held)
	# Short direct-touch drag remains supported when the floating ghost has
	# not reached the board. Still bounded to the same small magnetic radius.
	return _closest(game,shape,finger,geo,held)
