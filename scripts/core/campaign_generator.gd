extends RefCounted
class_name CampaignGenerator

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIR_NAMES: Array[String] = ["up", "right", "down", "left"]
const DIR_VECTORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const RHYTHM: Array[String] = ["medium", "hard", "medium", "hard", "easy", "hard", "medium", "hard"]

static func generate(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, 10000)
	var world := int((n - 1) / 100) + 1
	var campaign_tier := _campaign_tier(n)
	var rhythm_label := _rhythm_for_level(n, campaign_tier)
	var milestone := ""
	if n % 100 == 0:
		milestone = "world_finale"
		rhythm_label = "boss"
	elif n % 10 == 0:
		milestone = "milestone"
		rhythm_label = "hard"
	var difficulty_score := _difficulty_score(campaign_tier, rhythm_label, milestone)
	var size := clampi(6 + int((difficulty_score + 2) / 6), 6, 8)
	var center := Vector2i(int(size / 2), int(size / 2))
	var rescue_id := RESCUES[(n * 7 + world) % RESCUES.size()]
	var target_dir_index := posmod(n * 5 + world * 3, 4)
	var target_dir := DIR_VECTORS[target_dir_index]
	var target_name := DIR_NAMES[target_dir_index]
	var phase := posmod(n - 1, 6) + 1
	var pieces: Array[Dictionary] = []

	# Three rays are permanently sealed. The fourth ray is an authored dependency
	# lane. This removes the old one-tap corridor exploit while keeping every
	# generated puzzle deterministic and guaranteed to have a rescue route.
	for i in range(4):
		if i == target_dir_index:
			continue
		var p := center + DIR_VECTORS[i]
		pieces.append(_piece(p.x, p.y, "blocker", DIR_NAMES[i]))

	var target_cells := _ray_cells(center, target_dir, size)
	var dependency_depth := clampi(1 + int(difficulty_score / 5), 1, 4)
	match phase:
		1:
			_add_escape_chain(pieces, target_cells, target_name)
		2:
			_add_gate_lane(pieces, target_cells, target_name, world, n, size, center, dependency_depth)
		3:
			_add_escape_chain(pieces, target_cells, target_name)
			_add_bonus_special(pieces, size, center, target_dir, n + 17, "rotate")
			if difficulty_score >= 8:
				_add_bonus_special(pieces, size, center, target_dir, n + 29, "linked")
		4:
			_add_bomb_lane(pieces, target_cells, target_name)
			_add_dependency_branch(pieces, size, center, target_dir, n + 41, mini(3, dependency_depth), "rotate", "")
		5:
			_add_escape_chain(pieces, target_cells, target_name)
			_add_link_pair(pieces, size, center, target_dir, n + 53)
			if difficulty_score >= 10:
				_add_dependency_branch(pieces, size, center, target_dir, n + 61, dependency_depth, "rotate", "")
		_:
			_add_gate_lane(pieces, target_cells, target_name, world, n, size, center, dependency_depth)
			_add_link_pair(pieces, size, center, target_dir, n + 71)
			_add_bonus_special(pieces, size, center, target_dir, n + 83, "bomb")

	var filler_count := clampi(4 + difficulty_score + int(world / 16), 6, 24)
	_add_fillers(pieces, size, center, target_dir, n, filler_count)
	if milestone == "milestone":
		_add_bonus_special(pieces, size, center, target_dir, n + 101, "rotate")
	elif milestone == "world_finale":
		_add_dependency_branch(pieces, size, center, target_dir, n + 127, mini(4, dependency_depth + 1), "bomb", "")
		_add_bonus_special(pieces, size, center, target_dir, n + 149, "linked")

	var result := {
		"id": n,
		"width": size,
		"height": size,
		"world": world,
		"phase": phase,
		"campaign_tier": campaign_tier,
		"difficulty": rhythm_label,
		"difficulty_score": difficulty_score,
		"milestone": milestone,
		"target_exit": target_name,
		"par_moves": clampi(target_cells.size() + dependency_depth + 2 + int(difficulty_score / 4), 7, 24),
		"rescue_id": rescue_id,
		"rescue": [center.x, center.y],
		"pieces": pieces
	}
	return result

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

static func _difficulty_score(campaign_tier: int, rhythm_label: String, milestone: String) -> int:
	var rhythm_bonus := 0
	match rhythm_label:
		"easy": rhythm_bonus = 0
		"medium": rhythm_bonus = 3
		"hard": rhythm_bonus = 6
		"boss": rhythm_bonus = 9
		_: rhythm_bonus = 2
	var score := 3 + campaign_tier * 2 + rhythm_bonus
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

static func _add_escape_chain(pieces: Array[Dictionary], cells: Array[Vector2i], direction_name: String) -> void:
	# Every piece points outward. The player must peel the chain from the edge
	# inward before the rescue ray is actually open.
	for p in cells:
		pieces.append(_piece(p.x, p.y, "normal", direction_name))

static func _add_gate_lane(pieces: Array[Dictionary], cells: Array[Vector2i], direction_name: String, world: int, seed_value: int, size: int, center: Vector2i, dependency_depth: int) -> void:
	if cells.is_empty():
		return
	var gate_id := "gate_%d_%d" % [world, seed_value]
	var first := cells[0]
	var gate := _piece(first.x, first.y, "gate", direction_name)
	gate["key_id"] = gate_id
	pieces.append(gate)
	for i in range(1, cells.size()):
		var p := cells[i]
		pieces.append(_piece(p.x, p.y, "normal", direction_name))
	_add_dependency_branch(pieces, size, center, _dir_vector(direction_name), seed_value + 211, dependency_depth, "key", gate_id)

static func _add_bomb_lane(pieces: Array[Dictionary], cells: Array[Vector2i], direction_name: String) -> void:
	if cells.is_empty():
		return
	var first := cells[0]
	pieces.append(_piece(first.x, first.y, "blocker", direction_name))
	if cells.size() >= 2:
		var bomb := cells[1]
		pieces.append(_piece(bomb.x, bomb.y, "bomb", direction_name))
	for i in range(2, cells.size()):
		var p := cells[i]
		pieces.append(_piece(p.x, p.y, "normal", direction_name))

static func _add_dependency_branch(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, depth: int, special_type: String, link_value: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1889 + seed_value * 3571
	var wanted := clampi(depth, 1, 4)
	for attempt in range(80):
		var dir_index := rng.randi_range(0, 3)
		var direction := DIR_VECTORS[dir_index]
		var direction_name := DIR_NAMES[dir_index]
		var edge_axis := rng.randi_range(0, size - 1)
		var chain: Array[Vector2i] = []
		for step in range(wanted + 1):
			var p := Vector2i.ZERO
			match dir_index:
				0: p = Vector2i(edge_axis, step)
				1: p = Vector2i(size - 1 - step, edge_axis)
				2: p = Vector2i(edge_axis, size - 1 - step)
				_: p = Vector2i(step, edge_axis)
			chain.append(p)
		var valid := true
		for p in chain:
			if p == center or _on_target_ray(p, center, target_dir) or _occupied(pieces, p):
				valid = false
				break
		if not valid:
			continue
		# Edge-most normals leave first, exposing the special piece at the inner end.
		for i in range(wanted):
			var p := chain[i]
			pieces.append(_piece(p.x, p.y, "normal", direction_name))
		var special_pos := chain[wanted]
		var special := _piece(special_pos.x, special_pos.y, special_type, direction_name)
		if special_type == "key": special["key_id"] = link_value
		elif special_type == "linked": special["link_id"] = link_value
		pieces.append(special)
		return

static func _add_link_pair(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int) -> void:
	var id := "link_%d" % seed_value
	_add_dependency_branch(pieces, size, center, target_dir, seed_value, 1, "linked", id)
	_add_dependency_branch(pieces, size, center, target_dir, seed_value + 19, 1, "linked", id)

static func _add_fillers(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, amount: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 + seed_value * 7919
	var remaining := amount
	var attempts := 0
	while remaining > 0 and attempts < 1200:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _on_target_ray(pos, center, target_dir) or _occupied(pieces, pos):
			continue
		var direction := DIR_NAMES[rng.randi_range(0, 3)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		pieces.append(_piece(pos.x, pos.y, "normal", direction))
		remaining -= 1

static func _add_bonus_special(pieces: Array[Dictionary], size: int, center: Vector2i, target_dir: Vector2i, seed_value: int, type: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001 + seed_value * 3571
	for _i in range(120):
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _on_target_ray(pos, center, target_dir) or _occupied(pieces, pos):
			continue
		var direction := DIR_NAMES[rng.randi_range(0, 3)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		var special := _piece(pos.x, pos.y, type, direction)
		if type == "linked": special["link_id"] = "bonus_%d" % seed_value
		pieces.append(special)
		return

static func _piece(x: int, y: int, type: String, direction: String) -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}

static func _dir_vector(direction: String) -> Vector2i:
	var index := DIR_NAMES.find(direction)
	return DIR_VECTORS[index] if index >= 0 else Vector2i.RIGHT

static func _on_target_ray(pos: Vector2i, center: Vector2i, direction: Vector2i) -> bool:
	var p := center + direction
	for _i in range(8):
		if p == pos:
			return true
		p += direction
	return false

static func _occupied(pieces: Array[Dictionary], pos: Vector2i) -> bool:
	for p in pieces:
		if int(p.get("x", -99)) == pos.x and int(p.get("y", -99)) == pos.y:
			return true
	return false

static func _inside(pos: Vector2i, size: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size and pos.y < size
