extends RefCounted
class_name CampaignGenerator

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIRS: Array[String] = ["up", "right", "down", "left"]

static func generate(level_number: int) -> Dictionary:
	var world: int = int((level_number - 1) / 100) + 1
	var phase: int = ((world - 1) % 6) + 1
	var tier: int = int((world - 1) / 10)
	var size: int = 5 + min(2, int((world - 1) / 20))
	var center := Vector2i(int(size / 2), int(size / 2))
	var rescue_id: String = RESCUES[(level_number - 1) % RESCUES.size()]
	var pieces: Array[Dictionary] = []
	var filler_count: int = clamp(3 + int(level_number / 250), 3, 12)

	# Three fixed blockers leave one rescue lane that each phase manipulates differently.
	pieces.append(_piece(center.x, center.y - 1, "blocker", "up"))
	pieces.append(_piece(center.x, center.y + 1, "blocker", "down"))
	pieces.append(_piece(center.x + 1, center.y, "blocker", "right"))

	match phase:
		1:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			_add_fillers(pieces, size, center, level_number, filler_count)
		2:
			var gate: Dictionary = _piece(center.x - 1, center.y, "gate", "left")
			gate["key_id"] = "amber_%d" % world
			pieces.append(gate)
			var key: Dictionary = _piece(0, 0, "key", "up")
			key["key_id"] = gate["key_id"]
			pieces.append(key)
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		3:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			pieces.append(_piece(0, size - 1, "rotate", "left"))
			if tier >= 3:
				pieces.append(_piece(size - 1, 0, "rotate", "right"))
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		4:
			pieces.append(_piece(center.x - 1, center.y, "blocker", "left"))
			pieces.append(_piece(center.x - 2, center.y, "bomb", "left"))
			if tier >= 5 and size >= 6:
				pieces.append(_piece(size - 1, size - 1, "bomb", "down"))
			_add_fillers(pieces, size, center, level_number, filler_count + 1)
		5:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			var a: Dictionary = _piece(0, 0, "linked", "up")
			a["link_id"] = "violet_%d" % world
			pieces.append(a)
			var b: Dictionary = _piece(size - 1, size - 1, "linked", "down")
			b["link_id"] = a["link_id"]
			pieces.append(b)
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

	return {
		"id": level_number,
		"width": size,
		"height": size,
		"world": world,
		"phase": phase,
		"difficulty_tier": tier,
		"par_moves": 3 + phase + min(5, tier),
		"rescue_id": rescue_id,
		"rescue": [center.x, center.y],
		"pieces": pieces
	}

static func _piece(x: int, y: int, type: String, direction: String) -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}

static func _add_fillers(pieces: Array[Dictionary], size: int, center: Vector2i, seed_value: int, amount: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 + seed_value * 7919
	var attempts := 0
	while amount > 0 and attempts < 300:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		if pos == center or _occupied(pieces, pos):
			continue
		var direction: String = DIRS[rng.randi_range(0, DIRS.size() - 1)]
		if pos.x == 0:
			direction = "left"
		elif pos.x == size - 1:
			direction = "right"
		elif pos.y == 0:
			direction = "up"
		elif pos.y == size - 1:
			direction = "down"
		pieces.append(_piece(pos.x, pos.y, "normal", direction))
		amount -= 1

static func _occupied(pieces: Array[Dictionary], pos: Vector2i) -> bool:
	for p in pieces:
		if int(p.get("x", -99)) == pos.x and int(p.get("y", -99)) == pos.y:
			return true
	return false
