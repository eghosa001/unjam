extends RefCounted
class_name PuzzleSolver

const DIRS := {
	"up": Vector2i.UP,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
	"right": Vector2i.RIGHT
}

static func _empty_int_path() -> Array[int]:
	var empty: Array[int] = []
	return empty

static func find_solution(level: Dictionary, source_pieces: Array = [], max_states: int = 4000) -> Array[int]:
	var width: int = int(level.get("width", 0))
	var height: int = int(level.get("height", 0))
	var rescue_raw: Array = level.get("rescue", [])
	if width <= 0 or height <= 0 or rescue_raw.size() != 2:
		return _empty_int_path()
	var rescue: Vector2i = Vector2i(int(rescue_raw[0]), int(rescue_raw[1]))
	var initial: Array = []
	var raw_pieces: Array = source_pieces if not source_pieces.is_empty() else level.get("pieces", [])
	for raw in raw_pieces:
		if raw is Dictionary:
			var p: Dictionary = raw.duplicate(true)
			p["active"] = bool(p.get("active", true))
			initial.append(p)
	if _goal_satisfied(level, initial, rescue, width, height, 0):
		return _empty_int_path()
	# Generated campaign boards carry a reverse-construction proof. Simulate it
	# first; this both verifies generation and keeps hints instant on dense boards.
	var known: Array[int] = _find_known_solution(level, initial, rescue, width, height)
	if not known.is_empty():
		return known
	# Generated campaign boards also contain an authored rescue lane. Try that
	# deterministic route first so Hint stays instant on dense boss levels instead
	# of exploring thousands of irrelevant filler-piece permutations. Every step is
	# simulated with the same special/cascade rules as gameplay; BFS remains the
	# fallback for custom/daily boards or when the authored route is unavailable.
	var authored: Array[int] = _find_authored_solution(level, initial, rescue, width, height)
	if not authored.is_empty():
		return authored
	var queue_states: Array = [initial]
	var queue_paths: Array = [[]]
	var head: int = 0
	var visited: Dictionary = {_state_key(initial): true}
	while head < queue_states.size() and visited.size() <= max_states:
		var pieces: Array = queue_states[head]
		var path: Array = queue_paths[head]
		head += 1
		for i in _ordered_legal_moves(level, pieces, rescue, width, height):
			var next: Array = _apply_move(pieces, i, rescue, width, height)
			var next_path: Array = path.duplicate()
			next_path.append(i)
			if _goal_satisfied(level, next, rescue, width, height, next_path.size()):
				var result: Array[int] = []
				for step in next_path:
					result.append(int(step))
				return result
			var key: String = _state_key(next)
			if not visited.has(key):
				visited[key] = true
				queue_states.append(next)
				queue_paths.append(next_path)
	return _empty_int_path()

static func _find_known_solution(level: Dictionary, source: Array, rescue: Vector2i, width: int, height: int) -> Array[int]:
	var raw: Variant = level.get("known_solution", [])
	if not raw is Array or (raw as Array).is_empty():
		return _empty_int_path()
	var pieces: Array = source.duplicate(true)
	var pending: Array[int] = []
	for raw_index in raw:
		var index := int(raw_index)
		if index < 0 or index >= pieces.size():
			return _empty_int_path()
		pending.append(index)
	var path: Array[int] = []
	# Reverse construction provides a dependency proof, but late-game special
	# mechanics can temporarily make the next authored index illegal. Keep the
	# proof bounded and deterministic: choose the earliest currently legal proof
	# move, then restart the scan. This is O(n²) for <=54 pieces and avoids the
	# exponential BFS fallback while still simulating every move before accepting
	# the proof as solved.
	while not pending.is_empty():
		var progressed := false
		for pending_position in range(pending.size()):
			var index := pending[pending_position]
			if not bool(pieces[index].get("active", true)):
				pending.remove_at(pending_position)
				progressed = true
				break
			if not _path_clear(pieces, index, rescue, width, height):
				continue
			pieces = _apply_move(pieces, index, rescue, width, height)
			path.append(index)
			pending.remove_at(pending_position)
			progressed = true
			if _goal_satisfied(level, pieces, rescue, width, height, path.size()):
				return path
			break
		if not progressed:
			break
	if _goal_satisfied(level, pieces, rescue, width, height, path.size()):
		return path
	return _empty_int_path()

static func _find_authored_solution(level: Dictionary, source: Array, rescue: Vector2i, width: int, height: int) -> Array[int]:
	var target_direction: Vector2i = DIRS.get(String(level.get("target_exit", "")), Vector2i.ZERO)
	if target_direction == Vector2i.ZERO:
		return _empty_int_path()
	var pieces: Array = source.duplicate(true)
	var path: Array[int] = []
	var guard := maxi(8, pieces.size() * 2)
	for _step in range(guard):
		if _goal_satisfied(level, pieces, rescue, width, height, path.size()):
			return path
		var chosen := -1
		# Required keys are authored on safe edge paths; taking them first opens
		# any gate deliberately placed in the target rescue lane.
		for i in range(pieces.size()):
			if _path_clear(pieces, i, rescue, width, height) and String(pieces[i].get("type", "normal")) == "key":
				chosen = i
				break
		if chosen < 0:
			for i in range(pieces.size()):
				if not _path_clear(pieces, i, rescue, width, height):
					continue
				if _on_ray(_piece_pos(pieces[i]), rescue, target_direction, width, height):
					chosen = i
					break
		if chosen < 0:
			return _empty_int_path()
		pieces = _apply_move(pieces, chosen, rescue, width, height)
		path.append(chosen)
	if _goal_satisfied(level, pieces, rescue, width, height, path.size()):
		return path
	return _empty_int_path()

static func _ordered_legal_moves(level: Dictionary, pieces: Array, rescue: Vector2i, width: int, height: int) -> Array[int]:
	var keys: Array[int] = []
	var lane: Array[int] = []
	var specials: Array[int] = []
	var others: Array[int] = []
	var target_direction: Vector2i = DIRS.get(String(level.get("target_exit", "")), Vector2i.ZERO)
	for i in range(pieces.size()):
		if not _path_clear(pieces, i, rescue, width, height):
			continue
		var piece: Dictionary = pieces[i]
		var type := String(piece.get("type", "normal"))
		if type == "key":
			keys.append(i)
		elif target_direction != Vector2i.ZERO and _on_ray(_piece_pos(piece), rescue, target_direction, width, height):
			lane.append(i)
		elif type in ["rotate", "linked", "bomb"]:
			specials.append(i)
		else:
			others.append(i)
	var ordered: Array[int] = []
	ordered.append_array(keys)
	ordered.append_array(lane)
	ordered.append_array(specials)
	ordered.append_array(others)
	return ordered

static func _on_ray(pos: Vector2i, origin: Vector2i, direction: Vector2i, width: int, height: int) -> bool:
	var cursor := origin + direction
	while _inside(cursor, width, height):
		if cursor == pos:
			return true
		cursor += direction
	return false

static func has_solution(level: Dictionary, max_states: int = 4000) -> bool:
	var rescue_raw: Array = level.get("rescue", [])
	if rescue_raw.size() != 2:
		return false
	var pieces: Array = level.get("pieces", [])
	var rescue: Vector2i = Vector2i(int(rescue_raw[0]), int(rescue_raw[1]))
	if _goal_satisfied(level, pieces, rescue, int(level.get("width", 0)), int(level.get("height", 0)), 0):
		return true
	return not find_solution(level, [], max_states).is_empty()

static func first_solution_move(level: Dictionary, source_pieces: Array, max_states: int = 4000) -> int:
	var solution: Array[int] = find_solution(level, source_pieces, max_states)
	return -1 if solution.is_empty() else int(solution[0])

static func _apply_move(source: Array, index: int, rescue: Vector2i, width: int, height: int) -> Array:
	var pieces: Array = source.duplicate(true)
	if index < 0 or index >= pieces.size():
		return pieces
	_escape_once(pieces, index, rescue, width, height)
	return pieces

static func _resolve_cascades(pieces: Array, previous_legal: Dictionary, rescue: Vector2i, width: int, height: int) -> void:
	var baseline: Dictionary = previous_legal.duplicate()
	var guard: int = 0
	var max_steps: int = maxi(8, pieces.size() * 2)
	while guard < max_steps:
		guard += 1
		var newly_opened: Array[int] = []
		for i in range(pieces.size()):
			if not bool(pieces[i].get("active", true)):
				continue
			if _path_clear(pieces, i, rescue, width, height) and not bool(baseline.get(i, false)):
				newly_opened.append(i)
		if newly_opened.is_empty():
			return
		var before_batch: Dictionary = _legal_map(pieces, rescue, width, height)
		for index in newly_opened:
			if index >= 0 and index < pieces.size() and bool(pieces[index].get("active", true)) and _path_clear(pieces, index, rescue, width, height):
				_escape_once(pieces, index, rescue, width, height)
		baseline = before_batch

static func _legal_map(pieces: Array, rescue: Vector2i, width: int, height: int) -> Dictionary:
	var result: Dictionary = {}
	for i in range(pieces.size()):
		result[i] = _path_clear(pieces, i, rescue, width, height)
	return result

static func _escape_once(pieces: Array, index: int, rescue: Vector2i, width: int, height: int) -> void:
	if index < 0 or index >= pieces.size() or not bool(pieces[index].get("active", true)):
		return
	var piece: Dictionary = pieces[index]
	pieces[index]["active"] = false
	var type: String = String(piece.get("type", "normal"))
	match type:
		"rotate": _rotate_neighbors(pieces, _piece_pos(piece))
		"key": _open_gates(pieces, String(piece.get("key_id", "default")))
		"bomb": _explode(pieces, _piece_pos(piece))
		"linked": _activate_link(pieces, String(piece.get("link_id", "")), index, rescue, width, height)

static func _path_clear(pieces: Array, index: int, rescue: Vector2i, width: int, height: int) -> bool:
	if index < 0 or index >= pieces.size():
		return false
	var piece: Dictionary = pieces[index]
	if not bool(piece.get("active", true)):
		return false
	var type: String = String(piece.get("type", "normal"))
	if type in ["gate", "blocker"]:
		return false
	var direction: Vector2i = DIRS.get(String(piece.get("direction", "right")), Vector2i.RIGHT)
	var pos: Vector2i = _piece_pos(piece) + direction
	while _inside(pos, width, height):
		if pos == rescue or _piece_at(pieces, pos) >= 0:
			return false
		pos += direction
	return true

static func _rescue_has_exit(pieces: Array, rescue: Vector2i, width: int, height: int) -> bool:
	if width <= 0 or height <= 0:
		return false
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction: Vector2i in directions:
		var pos: Vector2i = rescue + direction
		var blocked: bool = false
		while _inside(pos, width, height):
			if _piece_at(pieces, pos) >= 0:
				blocked = true
				break
			pos += direction
		if not blocked:
			return true
	return false

static func _goal_satisfied(level: Dictionary, pieces: Array, rescue: Vector2i, width: int, height: int, steps: int = -1) -> bool:
	if not _rescue_has_exit(pieces, rescue, width, height):
		return false
	var objective := String(level.get("objective", "rescue_route"))
	match objective:
		"full_escape":
			for piece in pieces:
				if bool(piece.get("active", true)) and String(piece.get("type", "normal")) not in ["blocker", "gate"]:
					return false
			return true
		"key_rescue":
			for piece in pieces:
				if bool(piece.get("active", true)) and String(piece.get("type", "normal")) == "key":
					return false
			return true
		"gate_run":
			for piece in pieces:
				if bool(piece.get("active", true)) and String(piece.get("type", "normal")) == "gate":
					return false
			return true
		"bomb_route":
			for piece in pieces:
				if bool(piece.get("active", true)) and String(piece.get("type", "normal")) == "bomb":
					return false
			return true
		"chain_rescue":
			for piece in pieces:
				if bool(piece.get("active", true)) and String(piece.get("type", "normal")) == "linked":
					return false
			return true
		"perfect_rescue":
			return steps < 0 or steps <= int(level.get("action_budget", 999999))
		_:
			return true

static func _rotate_neighbors(pieces: Array, center: Vector2i) -> void:
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for direction: Vector2i in directions:
		var idx: int = _piece_at(pieces, center + direction)
		if idx < 0:
			continue
		var type: String = String(pieces[idx].get("type", "normal"))
		if type not in ["blocker", "gate"]:
			pieces[idx]["direction"] = _rotate_direction(String(pieces[idx].get("direction", "right")))

static func _open_gates(pieces: Array, key_id: String) -> void:
	for i in range(pieces.size()):
		if bool(pieces[i].get("active", true)) and String(pieces[i].get("type", "")) == "gate" and String(pieces[i].get("key_id", "default")) == key_id:
			pieces[i]["active"] = false

static func _explode(pieces: Array, center: Vector2i) -> void:
	for y in range(center.y - 1, center.y + 2):
		for x in range(center.x - 1, center.x + 2):
			var idx: int = _piece_at(pieces, Vector2i(x, y))
			if idx >= 0 and String(pieces[idx].get("type", "")) not in ["gate", "blocker"]:
				pieces[idx]["active"] = false

static func _activate_link(pieces: Array, link_id: String, source_index: int, rescue: Vector2i, width: int, height: int) -> void:
	if link_id.is_empty():
		return
	for i in range(pieces.size()):
		if i == source_index or not bool(pieces[i].get("active", true)):
			continue
		if String(pieces[i].get("type", "")) == "linked" and String(pieces[i].get("link_id", "")) == link_id:
			if _path_clear(pieces, i, rescue, width, height):
				pieces[i]["active"] = false
			else:
				pieces[i]["direction"] = _rotate_direction(String(pieces[i].get("direction", "right")))

static func _rotate_direction(direction: String) -> String:
	match direction:
		"up": return "right"
		"right": return "down"
		"down": return "left"
		_: return "up"

static func _piece_at(pieces: Array, pos: Vector2i) -> int:
	for i in range(pieces.size()):
		var p: Dictionary = pieces[i]
		if bool(p.get("active", true)) and _piece_pos(p) == pos:
			return i
	return -1

static func _piece_pos(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1)))

static func _inside(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

static func _state_key(pieces: Array) -> String:
	var parts: PackedStringArray = []
	for p in pieces:
		parts.append("%d:%s" % [1 if bool(p.get("active", true)) else 0, String(p.get("direction", ""))])
	return "|".join(parts)
