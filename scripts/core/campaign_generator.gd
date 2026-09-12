extends RefCounted
class_name CampaignGenerator

const RESCUES: Array[String] = ["chick", "puppy", "kitten", "robot", "slime", "panda", "fox", "alien"]
const DIRS: Array[String] = ["up", "right", "down", "left"]

static func generate(level_number: int) -> Dictionary:
	var world: int = int((level_number - 1) / 10) + 1
	var size: int = 5 if world <= 3 else 6
	var center := Vector2i(int(size / 2), int(size / 2))
	var rescue_id: String = RESCUES[(level_number - 1) % RESCUES.size()]
	var pieces: Array[Dictionary] = []
	pieces.append(_piece(center.x, center.y - 1, "blocker", "up"))
	pieces.append(_piece(center.x, center.y + 1, "blocker", "down"))
	pieces.append(_piece(center.x + 1, center.y, "blocker", "right"))

	match world:
		1:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			_add_fillers(pieces, size, center, level_number, 3)
		2:
			var gate: Dictionary = _piece(center.x - 1, center.y, "gate", "left")
			gate["key_id"] = "amber"
			pieces.append(gate)
			var key: Dictionary = _piece(0, 0, "key", "up")
			key["key_id"] = "amber"
			pieces.append(key)
			_add_fillers(pieces, size, center, level_number, 4)
		3:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			pieces.append(_piece(0, size - 1, "rotate", "left"))
			_add_fillers(pieces, size, center, level_number, 5)
		4:
			pieces.append(_piece(center.x - 1, center.y, "blocker", "left"))
			pieces.append(_piece(center.x - 2, center.y, "bomb", "left"))
			_add_fillers(pieces, size, center, level_number, 5)
		5:
			pieces.append(_piece(center.x - 1, center.y, "normal", "left"))
			var a: Dictionary = _piece(0, 0, "linked", "up")
			a["link_id"] = "violet"
			pieces.append(a)
			var b: Dictionary = _piece(size - 1, size - 1, "linked", "down")
			b["link_id"] = "violet"
			pieces.append(b)
			_add_fillers(pieces, size, center, level_number, 5)
		_:
			var gate2: Dictionary = _piece(center.x - 1, center.y, "gate", "left")
			gate2["key_id"] = "final"
			pieces.append(gate2)
			var key2: Dictionary = _piece(0, 0, "key", "up")
			key2["key_id"] = "final"
			pieces.append(key2)
			pieces.append(_piece(size - 1, 0, "rotate", "right"))
			pieces.append(_piece(0, size - 1, "bomb", "left"))
			var c: Dictionary = _piece(size - 1, size - 1, "linked", "down")
			c["link_id"] = "final_pair"
			pieces.append(c)
			var d: Dictionary = _piece(size - 2, size - 1, "linked", "down")
			d["link_id"] = "final_pair"
			pieces.append(d)
			_add_fillers(pieces, size, center, level_number, 6)

	return {
		"id": level_number,
		"width": size,
		"height": size,
		"world": world,
		"par_moves": 2 + world,
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
	while amount > 0 and attempts < 100:
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
