extends SceneTree

const LEVEL_DIR := "res://data/levels/"
const VALID_TYPES := ["normal", "rotate", "key", "gate", "bomb", "linked", "blocker"]
const VALID_DIRECTIONS := ["up", "down", "left", "right"]

func _init() -> void:
	var errors: Array[String] = []
	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		printerr("Could not open level directory")
		quit(1)
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()

	for file in files:
		validate_level(file, errors)

	if files.is_empty():
		errors.append("No levels found")

	if not errors.is_empty():
		for error in errors:
			printerr(error)
		printerr("Level validation failed: %d issue(s)" % errors.size())
		quit(1)
		return

	print("Validated %d levels successfully." % files.size())
	quit(0)

func validate_level(file_name: String, errors: Array[String]) -> void:
	var path := LEVEL_DIR + file_name
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		errors.append("%s: cannot read file" % file_name)
		return
	var parsed = JSON.parse_string(handle.get_as_text())
	if not parsed is Dictionary:
		errors.append("%s: root must be an object" % file_name)
		return
	var level: Dictionary = parsed
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	if width < 3 or height < 3:
		errors.append("%s: board must be at least 3x3" % file_name)
		return

	var rescue: Array = level.get("rescue", [])
	if rescue.size() != 2:
		errors.append("%s: rescue must contain [x,y]" % file_name)
		return
	var rescue_pos := Vector2i(int(rescue[0]), int(rescue[1]))
	if not inside(rescue_pos, width, height):
		errors.append("%s: rescue is outside the board" % file_name)

	var occupied := {}
	for raw in level.get("pieces", []):
		if not raw is Dictionary:
			errors.append("%s: piece entry is not an object" % file_name)
			continue
		var piece: Dictionary = raw
		var pos := Vector2i(int(piece.get("x", -1)), int(piece.get("y", -1)))
		if not inside(pos, width, height):
			errors.append("%s: piece outside board at %s" % [file_name, pos])
			continue
		if pos == rescue_pos:
			errors.append("%s: piece overlaps rescue at %s" % [file_name, pos])
		if occupied.has(pos):
			errors.append("%s: duplicate piece position %s" % [file_name, pos])
		occupied[pos] = true
		var type := String(piece.get("type", "normal"))
		if type not in VALID_TYPES:
			errors.append("%s: unknown piece type '%s'" % [file_name, type])
		if type not in ["gate", "blocker"]:
			var direction := String(piece.get("direction", ""))
			if direction not in VALID_DIRECTIONS:
				errors.append("%s: invalid direction '%s'" % [file_name, direction])

func inside(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height
