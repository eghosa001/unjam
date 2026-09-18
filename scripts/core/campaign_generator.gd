extends RefCounted
class_name CampaignGenerator

const Progression = preload("res://scripts/core/rescue_rush_progression.gd")
const Solver = preload("res://scripts/core/puzzle_solver.gd")

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIR_NAMES: Array[String] = ["up", "right", "down", "left"]
const DIR_VECTORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func generate(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, Progression.TOTAL_LEVELS)
	var profile: Dictionary = Progression.profile(n)
	for attempt in range(6):
		var candidate := _build_candidate(profile, n * 104729 + attempt * 7919)
		var solution: Array[int] = Solver.find_solution(candidate, [], 6000)
		if not solution.is_empty():
			candidate["solver_verified"] = true
			candidate["generation_attempt"] = attempt + 1
			candidate["optimal_moves"] = solution.size()
			candidate["estimated_required_moves"] = solution.size()
			candidate["par_moves"] = solution.size() + 2
			if String(candidate.get("objective", "")) == Progression.OBJECTIVE_PERFECT_RESCUE:
				candidate["action_budget"] = maxi(solution.size(), int(candidate.get("action_budget", solution.size())))
			candidate["structural_signature"] = Progression.canonical_signature(candidate)
			return candidate
	var fallback := _build_fallback(profile)
	fallback["solver_verified"] = Solver.has_solution(fallback, 6000)
	fallback["generation_attempt"] = 0
	fallback["structural_signature"] = Progression.canonical_signature(fallback)
	return fallback

static func _build_candidate(profile: Dictionary, seed_value: int) -> Dictionary:
	var n := int(profile.get("level", 1))
	var size := int(profile.get("board_size", 7))
	var world := int(profile.get("world", 1))
	var target_index := posmod(n * 5 + world * 3, 4)
	var target_dir := DIR_VECTORS[target_index]
	var target_name := DIR_NAMES[target_index]
	var rescue_pos := _rescue_position(size, target_index, n)
	var pieces: Array[Dictionary] = []
	var movable_order: Array[int] = []

	# Three sealed sides make the authored exit lane meaningful without hiding
	# information. These blockers never move and remain visually explicit.
	for i in range(4):
		if i == target_index:
			continue
		var sealed := rescue_pos + DIR_VECTORS[i]
		if _inside(sealed, size):
			pieces.append(_piece(sealed.x, sealed.y, "blocker", DIR_NAMES[i]))

	var mechanics: Array = profile.get("mechanics", []).duplicate()
	var objective := String(profile.get("objective", Progression.OBJECTIVE_RESCUE_ROUTE))
	if objective in [Progression.OBJECTIVE_KEY_RESCUE, Progression.OBJECTIVE_GATE_RUN] and "gate" not in mechanics:
		_mechanic_required(mechanics, "gate")
	if objective == Progression.OBJECTIVE_BOMB_ROUTE and "bomb" not in mechanics:
		_mechanic_required(mechanics, "bomb")
	if objective == Progression.OBJECTIVE_CHAIN_RESCUE and "linked" not in mechanics:
		_mechanic_required(mechanics, "linked")
	var lane := _ray_cells(rescue_pos, target_dir, size)
	var gate_ids: Array[String] = []
	var gate_slots := 0
	if "gate" in mechanics:
		gate_slots = 2 if int(profile.get("difficulty_target", 0)) >= 88 and lane.size() >= 3 else 1
	gate_slots = mini(gate_slots, lane.size())
	for i in range(lane.size()):
		var pos: Vector2i = lane[i]
		if i < gate_slots:
			var gate_id := "gate_%d_%d" % [n, i]
			gate_ids.append(gate_id)
			var gate := _piece(pos.x, pos.y, "gate", target_name)
			gate["key_id"] = gate_id
			pieces.append(gate)
		else:
			var index := pieces.size()
			pieces.append(_piece(pos.x, pos.y, "normal", _perpendicular_direction(target_name, seed_value + i)))
			movable_order.append(index)

	# Required special actions are added through the same reverse-safe placement
	# path as normal arrows. Later insertions may block earlier arrows, but every
	# inserted arrow has a clear route when it is added; reversing insertion order
	# therefore supplies a deterministic candidate solution.
	for gate_id in gate_ids:
		var key_index := _add_reverse_piece(pieces, size, rescue_pos, seed_value + 301 + movable_order.size() * 17, "key", {"key_id": gate_id})
		if key_index >= 0:
			movable_order.append(key_index)

	if "rotate" in mechanics:
		var rotate_index := _add_reverse_piece(pieces, size, rescue_pos, seed_value + 401, "rotate", {})
		if rotate_index >= 0:
			movable_order.append(rotate_index)

	if "linked" in mechanics:
		var link_id := "link_%d" % n
		for k in range(2):
			var link_index := _add_reverse_piece(pieces, size, rescue_pos, seed_value + 503 + k * 43, "linked", {"link_id": link_id})
			if link_index >= 0:
				movable_order.append(link_index)

	if "bomb" in mechanics:
		var bomb_index := _add_reverse_piece(pieces, size, rescue_pos, seed_value + 607, "bomb", {})
		if bomb_index >= 0:
			movable_order.append(bomb_index)

	var target_objects := int(profile.get("piece_target", 18))
	var filler_seed := seed_value + 701
	var guard := 0
	while pieces.size() < target_objects and guard < 180:
		guard += 1
		var index := _add_reverse_piece(pieces, size, rescue_pos, filler_seed + guard * 97, "normal", {})
		if index < 0:
			break
		movable_order.append(index)

	var known_solution: Array[int] = movable_order.duplicate()
	known_solution.reverse()
	var level := _base_level(profile, size, world, target_name, rescue_pos, pieces, known_solution)
	level["generation_seed"] = seed_value
	level["actual_piece_count"] = pieces.size()
	level["initial_frontier"] = _initial_frontier(level)
	level["dependency_depth"] = _dependency_depth(level)
	level["false_clear_candidates"] = _false_clear_candidates(level)
	level["estimated_required_moves"] = known_solution.size()
	level["par_moves"] = maxi(3, mini(known_solution.size(), int(profile.get("action_budget", known_solution.size()))))
	level["action_budget"] = maxi(int(profile.get("action_budget", level["par_moves"])), int(level["par_moves"]))
	return level

static func _base_level(profile: Dictionary, size: int, world: int, target_name: String, rescue_pos: Vector2i, pieces: Array[Dictionary], known_solution: Array[int]) -> Dictionary:
	var score := int(profile.get("difficulty_target", 10))
	var role := String(profile.get("level_role", "progression"))
	return {
		"id": int(profile.get("level", 1)),
		"width": size,
		"height": size,
		"world": world,
		"phase": int((int(profile.get("local_level", 1)) - 1) / 25) + 1,
		"campaign_tier": int((int(profile.get("level", 1)) - 1) / 1000),
		"difficulty": _legacy_difficulty(score, role),
		"difficulty_label": String(profile.get("difficulty_label", "medium")),
		"difficulty_score": score,
		"difficulty_target": score,
		"level_role": role,
		"milestone": String(profile.get("milestone", "")),
		"target_exit": target_name,
		"objective": String(profile.get("objective", Progression.OBJECTIVE_RESCUE_ROUTE)),
		"mistake_limit": int(profile.get("mistake_limit", 3)),
		"required_chain": int(profile.get("required_chain", 3)),
		"frontier_target": [int(profile.get("frontier_min", 2)), int(profile.get("frontier_max", 5))],
		"dependency_target": int(profile.get("dependency_target", 4)),
		"mechanics": profile.get("mechanics", []).duplicate(),
		"rescue_id": RESCUES[(int(profile.get("level", 1)) * 7 + world) % RESCUES.size()],
		"rescue": [rescue_pos.x, rescue_pos.y],
		"pieces": pieces,
		"known_solution": known_solution,
	}

static func _build_fallback(profile: Dictionary) -> Dictionary:
	var n := int(profile.get("level", 1))
	var size := int(profile.get("board_size", 7))
	var world := int(profile.get("world", 1))
	var target_index := posmod(n + world, 4)
	var target_dir := DIR_VECTORS[target_index]
	var target_name := DIR_NAMES[target_index]
	var rescue_pos := _rescue_position(size, target_index, n)
	var pieces: Array[Dictionary] = []
	var movable: Array[int] = []
	for i in range(4):
		if i == target_index:
			continue
		var sealed := rescue_pos + DIR_VECTORS[i]
		if _inside(sealed, size):
			pieces.append(_piece(sealed.x, sealed.y, "blocker", DIR_NAMES[i]))
	for i in range(_ray_cells(rescue_pos, target_dir, size).size()):
		var pos: Vector2i = _ray_cells(rescue_pos, target_dir, size)[i]
		var index := pieces.size()
		pieces.append(_piece(pos.x, pos.y, "normal", _perpendicular_direction(target_name, n + i)))
		movable.append(index)
	var known_solution: Array[int] = movable.duplicate()
	known_solution.reverse()
	var level := _base_level(profile, size, world, target_name, rescue_pos, pieces, known_solution)
	level["actual_piece_count"] = pieces.size()
	level["initial_frontier"] = _initial_frontier(level)
	level["dependency_depth"] = _dependency_depth(level)
	level["false_clear_candidates"] = _false_clear_candidates(level)
	level["estimated_required_moves"] = known_solution.size()
	level["par_moves"] = maxi(3, known_solution.size())
	level["action_budget"] = maxi(int(profile.get("action_budget", known_solution.size())), known_solution.size())
	return level

static func _mechanic_required(mechanics: Array, mechanic: String) -> void:
	if mechanic in mechanics:
		return
	if mechanics.size() >= 3:
		var replace_index := mechanics.find("rotate")
		if replace_index < 0:
			replace_index = 0
		mechanics[replace_index] = mechanic
	else:
		mechanics.append(mechanic)

static func _add_reverse_piece(pieces: Array[Dictionary], size: int, rescue_pos: Vector2i, seed_value: int, type: String, metadata: Dictionary) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var best_score := -100000
	var best: Array[Dictionary] = []
	for y in range(size):
		for x in range(size):
			var pos := Vector2i(x, y)
			if pos == rescue_pos or _occupied(pieces, pos):
				continue
			for direction_index in range(4):
				var direction := DIR_VECTORS[direction_index]
				if not _candidate_path_clear(pos, direction, pieces, rescue_pos, size):
					continue
				var impact := _blocking_impact(pos, pieces, rescue_pos, size)
				var route_length := _route_length(pos, direction, size)
				var edge_distance := mini(mini(x, size - 1 - x), mini(y, size - 1 - y))
				var score := impact * 100 + route_length * 4 + edge_distance * 3 + rng.randi_range(0, 7)
				if score > best_score:
					best_score = score
					best = [{"pos": pos, "direction": DIR_NAMES[direction_index]}]
				elif score == best_score:
					best.append({"pos": pos, "direction": DIR_NAMES[direction_index]})
	if best.is_empty():
		return -1
	var chosen: Dictionary = best[rng.randi_range(0, best.size() - 1)]
	var pos: Vector2i = chosen["pos"]
	var piece := _piece(pos.x, pos.y, type, String(chosen["direction"]))
	for key in metadata.keys():
		piece[key] = metadata[key]
	var index := pieces.size()
	pieces.append(piece)
	return index

static func _candidate_path_clear(pos: Vector2i, direction: Vector2i, pieces: Array[Dictionary], rescue_pos: Vector2i, size: int) -> bool:
	var cursor := pos + direction
	while _inside(cursor, size):
		if cursor == rescue_pos or _occupied(pieces, cursor):
			return false
		cursor += direction
	return true

static func _blocking_impact(candidate: Vector2i, pieces: Array[Dictionary], rescue_pos: Vector2i, size: int) -> int:
	var impact := 0
	for piece in pieces:
		var type := String(piece.get("type", "normal"))
		if type in ["blocker", "gate"]:
			continue
		var cursor := _piece_pos(piece) + _dir_vector(String(piece.get("direction", "right")))
		while _inside(cursor, size):
			if cursor == rescue_pos:
				break
			if cursor == candidate:
				impact += 1
				break
			if _occupied(pieces, cursor):
				break
			cursor += _dir_vector(String(piece.get("direction", "right")))
	return impact

static func _route_length(pos: Vector2i, direction: Vector2i, size: int) -> int:
	var count := 0
	var cursor := pos + direction
	while _inside(cursor, size):
		count += 1
		cursor += direction
	return count

static func _initial_frontier(level: Dictionary) -> int:
	var pieces: Array = level.get("pieces", [])
	var rescue_raw: Array = level.get("rescue", [])
	if rescue_raw.size() != 2:
		return 0
	var rescue_pos := Vector2i(int(rescue_raw[0]), int(rescue_raw[1]))
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	var count := 0
	for i in range(pieces.size()):
		if _piece_path_clear(pieces, i, rescue_pos, width, height):
			count += 1
	return count

static func _dependency_depth(level: Dictionary) -> int:
	var pieces: Array = level.get("pieces", [])
	var rescue_raw: Array = level.get("rescue", [])
	if rescue_raw.size() != 2:
		return 0
	var rescue_pos := Vector2i(int(rescue_raw[0]), int(rescue_raw[1]))
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	var memo: Dictionary = {}
	var visiting: Dictionary = {}
	var best := 0
	for i in range(pieces.size()):
		best = maxi(best, _depth_from(i, pieces, rescue_pos, width, height, memo, visiting))
	return best

static func _depth_from(index: int, pieces: Array, rescue_pos: Vector2i, width: int, height: int, memo: Dictionary, visiting: Dictionary) -> int:
	if memo.has(index):
		return int(memo[index])
	if visiting.has(index):
		return 1
	visiting[index] = true
	var piece: Dictionary = pieces[index]
	if String(piece.get("type", "normal")) in ["blocker", "gate"]:
		visiting.erase(index)
		memo[index] = 0
		return 0
	var direction := _dir_vector(String(piece.get("direction", "right")))
	var cursor := _piece_pos(piece) + direction
	var depth := 1
	while cursor.x >= 0 and cursor.y >= 0 and cursor.x < width and cursor.y < height:
		if cursor == rescue_pos:
			break
		var blocker := _piece_index_at(pieces, cursor)
		if blocker >= 0:
			depth = 1 + _depth_from(blocker, pieces, rescue_pos, width, height, memo, visiting)
			break
		cursor += direction
	visiting.erase(index)
	memo[index] = depth
	return depth

static func _false_clear_candidates(level: Dictionary) -> int:
	var pieces: Array = level.get("pieces", [])
	var rescue_raw: Array = level.get("rescue", [])
	if rescue_raw.size() != 2:
		return 0
	var rescue_pos := Vector2i(int(rescue_raw[0]), int(rescue_raw[1]))
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	var count := 0
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		if String(piece.get("type", "normal")) in ["blocker", "gate"]:
			continue
		var direction := _dir_vector(String(piece.get("direction", "right")))
		var cursor := _piece_pos(piece) + direction
		var distance := 0
		while cursor.x >= 0 and cursor.y >= 0 and cursor.x < width and cursor.y < height:
			distance += 1
			if cursor == rescue_pos or _piece_index_at(pieces, cursor) >= 0:
				if distance >= 3:
					count += 1
				break
			cursor += direction
	return count

static func _piece_path_clear(pieces: Array, index: int, rescue_pos: Vector2i, width: int, height: int) -> bool:
	if index < 0 or index >= pieces.size():
		return false
	var piece: Dictionary = pieces[index]
	if String(piece.get("type", "normal")) in ["blocker", "gate"]:
		return false
	var direction := _dir_vector(String(piece.get("direction", "right")))
	var cursor := _piece_pos(piece) + direction
	while cursor.x >= 0 and cursor.y >= 0 and cursor.x < width and cursor.y < height:
		if cursor == rescue_pos or _piece_index_at(pieces, cursor) >= 0:
			return false
		cursor += direction
	return true

static func _piece_index_at(pieces: Array, pos: Vector2i) -> int:
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		if bool(piece.get("active", true)) and _piece_pos(piece) == pos:
			return i
	return -1

static func _rescue_position(size: int, target_index: int, n: int) -> Vector2i:
	var low := 2
	var high := size - 3
	var mid := int((size - 1) / 2)
	var wobble := -1 if posmod(n, 2) == 0 else 0
	match target_index:
		0: return Vector2i(clampi(mid + wobble, 2, size - 3), high)
		1: return Vector2i(low, clampi(mid + wobble, 2, size - 3))
		2: return Vector2i(clampi(mid + wobble, 2, size - 3), low)
		_: return Vector2i(high, clampi(mid + wobble, 2, size - 3))

static func _ray_cells(center: Vector2i, direction: Vector2i, size: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cursor := center + direction
	while _inside(cursor, size):
		out.append(cursor)
		cursor += direction
	return out

static func _perpendicular_direction(target_direction: String, seed_value: int) -> String:
	if target_direction in ["left", "right"]:
		return "up" if seed_value % 2 == 0 else "down"
	return "left" if seed_value % 2 == 0 else "right"

static func _legacy_difficulty(score: int, role: String) -> String:
	if role == "world_boss":
		return "boss"
	if score < 30:
		return "easy"
	if score < 60:
		return "medium"
	return "hard"

static func _piece(x: int, y: int, type: String, direction: String) -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}

static func _piece_pos(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1)))

static func _dir_vector(direction: String) -> Vector2i:
	var index := DIR_NAMES.find(direction)
	return DIR_VECTORS[index] if index >= 0 else Vector2i.RIGHT

static func _occupied(pieces: Array[Dictionary], pos: Vector2i) -> bool:
	for piece in pieces:
		if bool(piece.get("active", true)) and _piece_pos(piece) == pos:
			return true
	return false

static func _inside(pos: Vector2i, size: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size and pos.y < size
