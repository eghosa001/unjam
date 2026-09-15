extends RefCounted
class_name CampaignGenerator

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIR_NAMES: Array[String] = ["up", "right", "down", "left"]
const DIR_VECTORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func generate(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, 10000)
	if n <= 12:
		return _generate_onboarding(n)
	var world := int((n - 1) / 100) + 1
	var tier := _campaign_tier(n)
	var difficulty := _rhythm_for_level(n, tier)
	var milestone := ""
	if n % 100 == 0:
		milestone = "world_finale"
		difficulty = "boss"
	elif n % 10 == 0:
		milestone = "milestone"
		difficulty = "hard"
	var difficulty_score := _difficulty_score(tier, difficulty, milestone)
	var size := 7 if difficulty_score < 11 else 8
	var rescue_id := RESCUES[(n * 7 + world) % RESCUES.size()]
	var target_dir_index := posmod(n * 5 + world * 3, 4)
	var target_dir := DIR_VECTORS[target_dir_index]
	var target_name := DIR_NAMES[target_dir_index]
	# Bias the rescue away from its intended exit. This guarantees a meaningful
	# authored lane: 4 required blockers on 7x7 and 5 on 8x8 boards.
	var center := _rescue_position_for_exit(size, target_dir_index)
	var phase := posmod(n - 1, 6) + 1
	var pieces: Array[Dictionary] = []

	for i in range(4):
		if i == target_dir_index:
			continue
		var sealed := center + DIR_VECTORS[i]
		pieces.append(_piece(sealed.x, sealed.y, "blocker", DIR_NAMES[i]))

	var target_cells := _ray_cells(center, target_dir, size)
	var required_moves := 0
	match phase:
		1:
			required_moves += _add_manual_lane(pieces, target_cells, target_name, n)
		2:
			required_moves += _add_gate_lane(pieces, target_cells, target_name, world, n, size, center, target_dir)
		3:
			required_moves += _add_manual_lane(pieces, target_cells, target_name, n)
			_add_safe_special(pieces, size, center, target_dir, n + 17, "rotate")
			if difficulty_score >= 9:
				_add_safe_special(pieces, size, center, target_dir, n + 29, "linked")
		4:
			required_moves += _add_manual_lane(pieces, target_cells, target_name, n)
			_add_safe_special(pieces, size, center, target_dir, n + 41, "bomb")
		5:
			required_moves += _add_manual_lane(pieces, target_cells, target_name, n)
			_add_link_pair(pieces, size, center, target_dir, n + 53)
		_:
			required_moves += _add_double_gate_lane(pieces, target_cells, target_name, world, n, size, center, target_dir)
			_add_link_pair(pieces, size, center, target_dir, n + 71)

	if milestone == "world_finale" and phase != 6:
		var extra_id := "boss_%d" % n
		if _convert_lane_piece_to_gate(pieces, target_cells, extra_id):
			if _add_required_edge_special(pieces, size, center, target_dir, n + 503, "key", extra_id):
				required_moves += 1

	var filler_count := clampi(5 + difficulty_score + int(world / 20), 7, 24)
	_add_fillers(pieces, size, center, target_dir, n, filler_count)
	if milestone == "milestone":
		_add_safe_special(pieces, size, center, target_dir, n + 101, "rotate")
	elif milestone == "world_finale":
		_add_safe_special(pieces, size, center, target_dir, n + 149, "bomb")

	return {
		"id": n,
		"width": size,
		"height": size,
		"world": world,
		"phase": phase,
		"campaign_tier": tier,
		"difficulty": difficulty,
		"difficulty_score": difficulty_score,
		"milestone": milestone,
		"target_exit": target_name,
		"estimated_required_moves": required_moves,
		"par_moves": clampi(required_moves + 2 + int(difficulty_score / 5), 7, 24),
		"rescue_id": rescue_id,
		"rescue": [center.x, center.y],
		"pieces": pieces
	}

static func _generate_onboarding(n: int) -> Dictionary:
	# Levels 1–12 stay mechanically simple: no gates, bombs or filler maze.
	# Level 10 retains milestone metadata for the campaign cadence while using
	# the same readable teaching geometry as its neighbours.
	var size := 5 if n <= 4 else 6
	var center := Vector2i(int(size / 2), int(size / 2))
	var target_dir_index := posmod(n - 1, 4)
	var target_dir := DIR_VECTORS[target_dir_index]
	var target_name := DIR_NAMES[target_dir_index]
	var pieces: Array[Dictionary] = []
	for i in range(4):
		if i == target_dir_index:
			continue
		var sealed := center + DIR_VECTORS[i]
		pieces.append(_piece(sealed.x, sealed.y, "blocker", DIR_NAMES[i]))
	var lane := _ray_cells(center, target_dir, size)
	var needed := 1 if n <= 3 else (2 if n <= 8 else mini(3, lane.size()))
	for i in range(mini(needed, lane.size())):
		var pos := lane[i]
		pieces.append(_piece(pos.x, pos.y, "normal", _perpendicular_direction(target_name, n + i)))
	var milestone := "milestone" if n % 10 == 0 else ""
	var difficulty := "hard" if milestone != "" else "easy"
	var difficulty_score := 11 if milestone != "" else 3 + int(n / 3)
	return {
		"id": n, "width": size, "height": size, "world": 1, "phase": 1,
		"campaign_tier": 0, "difficulty": difficulty, "difficulty_label": difficulty, "difficulty_score": difficulty_score,
		"milestone": milestone, "target_exit": target_name, "estimated_required_moves": needed,
		"par_moves": needed + 2, "rescue_id": RESCUES[(n * 7 + 1) % RESCUES.size()],
		"rescue": [center.x, center.y], "pieces": pieces
	}

static func _rescue_position_for_exit(size: int, target_dir_index: int) -> Vector2i:
	var mid := int(size / 2)
	var near_side := 2
	var far_side := size - 3
	match target_dir_index:
		0: return Vector2i(mid, far_side)
		1: return Vector2i(near_side, mid)
		2: return Vector2i(mid, near_side)
		_: return Vector2i(far_side, mid)

static func _rhythm_for_level(level_number: int, tier: int) -> String:
	var local := posmod(level_number - 1, 32)
	if tier == 0:
		if level_number <= 5:
			return "medium"
		return "easy" if local in [7, 15, 23, 31] else ("hard" if local >= 20 and local % 3 != 0 else "medium")
	if tier <= 2:
		return "easy" if local in [15, 31] else ("hard" if local % 3 != 0 else "medium")
	return "medium" if local in [7, 15, 23, 31] else "hard"

static func _campaign_tier(level_number: int) -> int:
	if level_number <= 100: return 0
	if level_number <= 500: return 1
	if level_number <= 1500: return 2
	if level_number <= 3000: return 3
	if level_number <= 5000: return 4
	if level_number <= 7500: return 5
	return 6

static func _difficulty_score(tier: int, difficulty: String, milestone: String) -> int:
	var rhythm_bonus := 0
	match difficulty:
		"easy": rhythm_bonus = 0
		"medium": rhythm_bonus = 3
		"hard": rhythm_bonus = 6
		"boss": rhythm_bonus = 9
		_: rhythm_bonus = 2
	var score := 3 + tier * 2 + rhythm_bonus
	if milestone == "milestone": score += 2
	elif milestone == "world_finale": score += 4
	return clampi(score, 3, 24)

static func _ray_cells(center: Vector2i, direction: Vector2i, size: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var p := center + direction
	while _inside(p, size):
		out.append(p)
		p += direction
	return out

static func _perpendicular_direction(target_direction: String, seed_value: int) -> String:
	if target_direction in ["left", "right"]:
		return "up" if seed_value % 2 == 0 else "down"
	return "left" if seed_value % 2 == 0 else "right"

static func _add_manual_lane(pieces: Array[Dictionary], cells: Array[Vector2i], target_direction: String, seed_value: int) -> int:
	var count := 0
	for i in range(cells.size()):
		var p := cells[i]
		pieces.append(_piece(p.x, p.y, "normal", _perpendicular_direction(target_direction, seed_value + i)))
		count += 1
	return count

static func _add_gate_lane(pieces: Array[Dictionary], cells: Array[Vector2i], target_direction: String, world: int, seed_value: int, size: int, center: Vector2i, target_dir: Vector2i) -> int:
	if cells.is_empty(): return 0
	var gate_id := "gate_%d_%d" % [world, seed_value]
	var first := cells[0]
	var gate := _piece(first.x, first.y, "gate", target_direction)
	gate["key_id"] = gate_id
	pieces.append(gate)
	var count := 1
	for i in range(1, cells.size()):
		var p := cells[i]
		pieces.append(_piece(p.x, p.y, "normal", _perpendicular_direction(target_direction, seed_value + i)))
		count += 1
	if _add_required_edge_special(pieces, size, center, target_dir, seed_value + 211, "key", gate_id):
		count += 1
	return count

static func _add_double_gate_lane(pieces: Array[Dictionary], cells: Array[Vector2i], target_direction: String, world: int, seed_value: int, size: int, center: Vector2i, target_dir: Vector2i) -> int:
	if cells.is_empty(): return 0
	var count := 0
	var gate_slots := mini(2, cells.size())
	for i in range(gate_slots):
		var gate_id := "double_%d_%d_%d" % [world, seed_value, i]
		var p := cells[i]
		var gate := _piece(p.x, p.y, "gate", target_direction)
		gate["key_id"] = gate_id
		pieces.append(gate)
		count += 1
		if _add_required_edge_special(pieces, size, center, target_dir, seed_value + 307 + i * 37, "key", gate_id):
			count += 1
	for i in range(gate_slots, cells.size()):
		var p := cells[i]
		pieces.append(_piece(p.x, p.y, "normal", _perpendicular_direction(target_direction, seed_value + i)))
		count += 1
	return count

static func _convert_lane_piece_to_gate(pieces: Array[Dictionary], cells: Array[Vector2i], gate_id: String) -> bool:
	for cell in cells:
		for i in range(pieces.size()):
			if _piece_pos(pieces[i]) == cell and String(pieces[i].get("type", "")) == "normal":
				pieces[i]["type"] = "gate"
				pieces[i]["key_id"] = gate_id
				return true
	return false

static func _add_required_edge_special(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, special_type: String, link_value: String) -> bool:
	var candidates: Array[Dictionary] = []
	for x in range(size):
		candidates.append({"p": Vector2i(x, 0), "d": "up"})
		candidates.append({"p": Vector2i(x, size - 1), "d": "down"})
	for y in range(1, size - 1):
		candidates.append({"p": Vector2i(0, y), "d": "left"})
		candidates.append({"p": Vector2i(size - 1, y), "d": "right"})
	var start := posmod(seed_value, candidates.size())
	for offset in range(candidates.size()):
		var candidate: Dictionary = candidates[(start + offset) % candidates.size()]
		var pos: Vector2i = candidate["p"]
		if pos == center or _on_target_ray(pos, center, target_dir) or _occupied(pieces, pos): continue
		if _reserved_by_authored_paths(pieces, pos, size): continue
		var special := _piece(pos.x, pos.y, special_type, String(candidate["d"]))
		if special_type == "key": special["key_id"] = link_value
		elif special_type == "linked": special["link_id"] = link_value
		pieces.append(special)
		return true
	return false

static func _add_link_pair(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int) -> void:
	var id := "link_%d" % seed_value
	_add_required_edge_special(pieces, size, center, target_dir, seed_value, "linked", id)
	_add_required_edge_special(pieces, size, center, target_dir, seed_value + 19, "linked", id)

static func _add_fillers(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, amount: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 + seed_value * 7919
	var remaining := amount
	var attempts := 0
	while remaining > 0 and attempts < 1600:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _on_target_ray(pos, center, target_dir) or _occupied(pieces, pos): continue
		if _reserved_by_authored_paths(pieces, pos, size): continue
		var direction := DIR_NAMES[rng.randi_range(0, 3)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		pieces.append(_piece(pos.x, pos.y, "normal", direction))
		remaining -= 1

static func _add_safe_special(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, type: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001 + seed_value * 3571
	for _i in range(160):
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _on_target_ray(pos, center, target_dir) or _occupied(pieces, pos): continue
		if _distance_to_target_ray(pos, center, target_dir, size) <= 1: continue
		if _reserved_by_authored_paths(pieces, pos, size): continue
		var direction := DIR_NAMES[rng.randi_range(0, 3)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		var special := _piece(pos.x, pos.y, type, direction)
		if type == "linked": special["link_id"] = "bonus_%d" % seed_value
		pieces.append(special)
		return

static func _reserved_by_authored_paths(pieces: Array[Dictionary], candidate: Vector2i, size: int) -> bool:
	for piece in pieces:
		var type := String(piece.get("type", "normal"))
		if type in ["gate", "blocker"]: continue
		var p := _piece_pos(piece)
		var direction := _dir_vector(String(piece.get("direction", "right")))
		p += direction
		while _inside(p, size):
			if p == candidate: return true
			p += direction
	return false

static func _distance_to_target_ray(pos: Vector2i, center: Vector2i, direction: Vector2i, size: int) -> int:
	var best := 99
	for p in _ray_cells(center, direction, size):
		best = mini(best, maxi(absi(pos.x - p.x), absi(pos.y - p.y)))
	return best

static func _piece(x: int, y: int, type: String, direction: String) -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}

static func _piece_pos(piece: Dictionary) -> Vector2i:
	return Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1)))

static func _dir_vector(direction: String) -> Vector2i:
	var index := DIR_NAMES.find(direction)
	return DIR_VECTORS[index] if index >= 0 else Vector2i.RIGHT

static func _on_target_ray(pos: Vector2i, center: Vector2i, direction: Vector2i) -> bool:
	var p := center + direction
	for _i in range(8):
		if p == pos: return true
		p += direction
	return false

static func _occupied(pieces: Array[Dictionary], pos: Vector2i) -> bool:
	for p in pieces:
		if _piece_pos(p) == pos: return true
	return false

static func _inside(pos: Vector2i, size: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size and pos.y < size