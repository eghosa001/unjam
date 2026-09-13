extends RefCounted
class_name CampaignGenerator

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIRS: Array[String] = ["up", "right", "down", "left"]
const RHYTHM: Array[String] = ["easy", "medium", "medium", "easy", "hard"]

static func generate(level_number: int) -> Dictionary:
	var world: int = int((level_number - 1) / 100) + 1
	var phase: int = ((world - 1) % 6) + 1
	# Rotate mechanics inside each world too, so the first 100 levels do not
	# repeat the same simple corridor puzzle.
	if world == 1:
		phase = ((level_number - 1) % 6) + 1
	var campaign_tier: int = _campaign_tier(level_number)
	var rhythm_label: String = RHYTHM[(level_number - 1) % RHYTHM.size()]
	var milestone: String = ""
	if level_number % 100 == 0:
		milestone = "world_finale"
		rhythm_label = "boss"
	elif level_number % 10 == 0:
		milestone = "milestone"
		rhythm_label = "hard"

	var difficulty_score: int = _difficulty_score(campaign_tier, rhythm_label, milestone)
	# The opening levels previously stayed on a sparse 5x5 board. Start with a
	# more interesting 6x6 space, then expand naturally later.
	var size: int = clampi(6 + int(difficulty_score / 5), 6, 8)
	var center: Vector2i = Vector2i(int(size / 2), int(size / 2))
	var rescue_id: String = RESCUES[(level_number - 1) % RESCUES.size()]
	var pieces: Array[Dictionary] = []
	var filler_count: int = clampi(5 + difficulty_score, 6, 18)

	# Three permanent blockers frame the rescue. The left lane remains the
	# authored solution corridor, while the rest of the board carries decoys and
	# secondary mechanics so the route has to be read rather than guessed.
	pieces.append(_piece(center.x, center.y - 1, "blocker", "up"))
	pieces.append(_piece(center.x, center.y + 1, "blocker", "down"))
	pieces.append(_piece(center.x + 1, center.y, "blocker", "right"))

	match phase:
		1:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			pieces.append(_piece(0, 0, "rotate", "right"))
			_add_fillers(pieces, size, center, level_number, filler_count)
		2:
			var gate: Dictionary = _piece(center.x - 1, center.y, "gate", "left")
			gate["key_id"] = "amber_%d" % world
			pieces.append(gate)
			var key: Dictionary = _piece(0, 0, "key", "up")
			key["key_id"] = gate["key_id"]
			pieces.append(key)
			pieces.append(_piece(size - 1, size - 1, "rotate", "left"))
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		3:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			pieces.append(_piece(0, size - 1, "rotate", "left"))
			pieces.append(_piece(size - 1, 0, "rotate", "right"))
			if level_number >= 8:
				_add_bonus_special(pieces, size, center, level_number + 3, "bomb")
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		4:
			pieces.append(_piece(center.x - 1, center.y, "blocker", "left"))
			pieces.append(_piece(center.x - 2, center.y, "bomb", "left"))
			_add_bonus_special(pieces, size, center, level_number + 9, "rotate")
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		5:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			var a: Dictionary = _piece(0, 0, "linked", "up")
			a["link_id"] = "violet_%d" % world
			pieces.append(a)
			var b: Dictionary = _piece(size - 1, size - 1, "linked", "down")
			b["link_id"] = a["link_id"]
			pieces.append(b)
			_add_bonus_special(pieces, size, center, level_number + 13, "rotate")
			_add_fillers(pieces, size, center, level_number, filler_count + 2)
		_:
			var gate2: Dictionary = _piece(center.x - 1, center.y, "gate", "left")
			gate2["key_id"] = "chaos_%d" % world
			pieces.append(gate2)
			var key2: Dictionary = _piece(0, 0, "key", "up")
			key2["key_id"] = gate2["key_id"]
			pieces.append(key2)
			pieces.append(_piece(size - 1, 0, "rotate", "right"))
			pieces.append(_piece(0, size - 1, "bomb", "left"))
			var c: Dictionary = _piece(size - 1, size - 1, "linked", "down")
			c["link_id"] = "chaos_pair_%d" % world
			pieces.append(c)
			var d: Dictionary = _piece(size - 2, size - 1, "linked", "down")
			d["link_id"] = c["link_id"]
			pieces.append(d)
			_add_fillers(pieces, size, center, level_number, filler_count + 2)

	if milestone == "milestone" and difficulty_score >= 5:
		_add_bonus_special(pieces, size, center, level_number, "rotate")
	elif milestone == "world_finale":
		_add_bonus_special(pieces, size, center, level_number + 17, "rotate")
		_add_bonus_special(pieces, size, center, level_number + 31, "bomb")

	return {
		"id": level_number,
		"width": size,
		"height": size,
		"world": world,
		"phase": phase,
		"campaign_tier": campaign_tier,
		"difficulty": rhythm_label,
		"difficulty_score": difficulty_score,
		"milestone": milestone,
		"par_moves": clampi(4 + int(difficulty_score * 0.9), 5, 20),
		"rescue_id": rescue_id,
		"rescue": [center.x, center.y],
		"pieces": pieces
	}

static func _campaign_tier(level_number: int) -> int:
	if level_number <= 100: return 0
	if level_number <= 500: return 1
	if level_number <= 1500: return 2
	if level_number <= 3000: return 3
	if level_number <= 5000: return 4
	if level_number <= 7500: return 5
	return 6

static func _difficulty_score(campaign_tier: int, rhythm_label: String, milestone: String) -> int:
	var rhythm_bonus: int = 0
	match rhythm_label:
		"easy": rhythm_bonus = 0
		"medium": rhythm_bonus = 2
		"hard": rhythm_bonus = 4
		"boss": rhythm_bonus = 6
		_: rhythm_bonus = 1
	var score: int = 2 + campaign_tier * 2 + rhythm_bonus
	if milestone == "milestone": score += 1
	elif milestone == "world_finale": score += 2
	return clampi(score, 2, 20)

static func _piece(x: int, y: int, type: String, direction: String) -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}

static func _is_solution_corridor(pos: Vector2i, center: Vector2i) -> bool:
	return pos.y == center.y and pos.x < center.x

static func _add_fillers(pieces: Array[Dictionary], size: int, center: Vector2i, seed_value: int, amount: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 + seed_value * 7919
	var attempts: int = 0
	while amount > 0 and attempts < 900:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _is_solution_corridor(pos, center) or _occupied(pieces, pos):
			continue
		var direction: String = DIRS[rng.randi_range(0, DIRS.size() - 1)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		pieces.append(_piece(pos.x, pos.y, "normal", direction))
		amount -= 1

static func _add_bonus_special(pieces: Array[Dictionary], size: int, center: Vector2i, seed_value: int, type: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001 + seed_value * 3571
	for i in range(100):
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _is_solution_corridor(pos, center) or _occupied(pieces, pos):
			continue
		var direction: String = DIRS[rng.randi_range(0, DIRS.size() - 1)]
		if pos.x == 0: direction = "left"
		elif pos.x == size - 1: direction = "right"
		elif pos.y == 0: direction = "up"
		elif pos.y == size - 1: direction = "down"
		pieces.append(_piece(pos.x, pos.y, type, direction))
		return

static func _occupied(pieces: Array[Dictionary], pos: Vector2i) -> bool:
	for p in pieces:
		if int(p.get("x", -99)) == pos.x and int(p.get("y", -99)) == pos.y:
			return true
	return false
