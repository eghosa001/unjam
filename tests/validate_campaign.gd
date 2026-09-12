extends SceneTree

const VALID_TYPES := ["normal", "rotate", "key", "gate", "bomb", "linked", "blocker"]
const VALID_DIRECTIONS := ["up", "down", "left", "right"]

func _init() -> void:
	var errors: Array[String] = []
	for level_number in range(1, LevelManager.get_level_count() + 1):
		var level := LevelManager.load_level(level_number)
		validate(level_number, level, errors)
	if not errors.is_empty():
		for e in errors: printerr(e)
		printerr("Campaign validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Validated all %d campaign levels." % LevelManager.get_level_count())
	quit(0)

func validate(level_number: int, level: Dictionary, errors: Array[String]) -> void:
	if level.is_empty():
		errors.append("Level %d is empty" % level_number)
		return
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	if width < 3 or height < 3 or width > 8 or height > 8:
		errors.append("Level %d has invalid dimensions %dx%d" % [level_number, width, height])
		return
	var rescue_data: Array = level.get("rescue", [])
	if rescue_data.size() != 2:
		errors.append("Level %d has invalid rescue data" % level_number)
		return
	var rescue := Vector2i(int(rescue_data[0]), int(rescue_data[1]))
	if not inside(rescue, width, height):
		errors.append("Level %d rescue is outside board" % level_number)
	var occupied := {}
	var movable := 0
	var key_ids := {}
	var gate_ids := {}
	for raw in level.get("pieces", []):
		if not raw is Dictionary:
			errors.append("Level %d has malformed piece" % level_number)
			continue
		var p: Dictionary = raw
		var pos := Vector2i(int(p.get("x", -1)), int(p.get("y", -1)))
		if not inside(pos, width, height):
			errors.append("Level %d piece outside board at %s" % [level_number, pos])
			continue
		if pos == rescue:
			errors.append("Level %d piece overlaps rescue" % level_number)
		if occupied.has(pos):
			errors.append("Level %d duplicate position %s" % [level_number, pos])
		occupied[pos] = true
		var type := String(p.get("type", "normal"))
		if type not in VALID_TYPES:
			errors.append("Level %d unknown type %s" % [level_number, type])
		if type not in ["gate", "blocker"]:
			movable += 1
			if String(p.get("direction", "")) not in VALID_DIRECTIONS:
				errors.append("Level %d invalid direction" % level_number)
		if type == "key": key_ids[String(p.get("key_id", "default"))] = true
		if type == "gate": gate_ids[String(p.get("key_id", "default"))] = true
	if movable == 0:
		errors.append("Level %d has no movable pieces" % level_number)
	for gate_id in gate_ids:
		if not key_ids.has(gate_id):
			errors.append("Level %d gate '%s' has no matching key" % [level_number, gate_id])

func inside(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height
