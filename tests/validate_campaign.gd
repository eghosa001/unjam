extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")
const PuzzleSolverScript = preload("res://scripts/core/puzzle_solver.gd")
const LEVEL_DIR := "res://data/levels/"
const CAMPAIGN_LEVELS := 10000
const VALID_TYPES: Array[String] = ["normal", "rotate", "key", "gate", "bomb", "linked", "blocker"]
const VALID_DIRECTIONS: Array[String] = ["up", "down", "left", "right"]
const VALID_DIFFICULTIES: Array[String] = ["easy", "medium", "hard", "boss"]

func _init() -> void:
	var errors: Array[String] = []
	var early_score_total := 0
	var late_score_total := 0
	for level_number in range(1, CAMPAIGN_LEVELS + 1):
		var level: Dictionary = load_level_for_test(level_number)
		validate(level_number, level, errors)
		validate_difficulty(level_number, level, errors)
		if level_number <= 500:
			early_score_total += int(level.get("difficulty_score", 0))
		elif level_number > 9500:
			late_score_total += int(level.get("difficulty_score", 0))
		if errors.size() < 100 and not PuzzleSolverScript.has_solution(level, 2000):
			errors.append("Level %d has no verified solution" % level_number)
		if errors.size() >= 100:
			break
		if level_number % 1000 == 0:
			print("Rescue campaign solvability: %d/%d" % [level_number, CAMPAIGN_LEVELS])
	if late_score_total <= early_score_total:
		errors.append("Late campaign difficulty does not exceed opening campaign")
	if not errors.is_empty():
		for e in errors:
			printerr(e)
		printerr("Campaign validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Validated all %d campaign levels: structure, progressive difficulty and solvability." % CAMPAIGN_LEVELS)
	quit(0)

func load_level_for_test(level_number: int) -> Dictionary:
	# Production LevelManager intentionally uses the generator for all campaign
	# levels. Keep validation on that same source of truth.
	return CampaignGeneratorScript.generate(level_number)

func validate_difficulty(level_number: int, level: Dictionary, errors: Array[String]) -> void:
	var difficulty := String(level.get("difficulty", ""))
	if difficulty not in VALID_DIFFICULTIES:
		errors.append("Level %d invalid difficulty label" % level_number)
	var expected_milestone := ""
	if level_number % 100 == 0:
		expected_milestone = "world_finale"
		if difficulty != "boss": errors.append("Level %d finale is not boss difficulty" % level_number)
	elif level_number % 10 == 0:
		expected_milestone = "milestone"
		if difficulty != "hard": errors.append("Level %d milestone is not hard difficulty" % level_number)
	if String(level.get("milestone", "")) != expected_milestone:
		errors.append("Level %d milestone mismatch" % level_number)
	var score := int(level.get("difficulty_score", 0))
	if score < 3 or score > 24:
		errors.append("Level %d invalid difficulty score" % level_number)

func validate(level_number: int, level: Dictionary, errors: Array[String]) -> void:
	if level.is_empty():
		errors.append("Level %d is empty" % level_number)
		return
	var width := int(level.get("width", 0))
	var height := int(level.get("height", 0))
	if width < 3 or height < 3 or width > 8 or height > 8:
		errors.append("Level %d has invalid dimensions" % level_number)
		return
	var rescue_data: Array = level.get("rescue", [])
	if rescue_data.size() != 2:
		errors.append("Level %d has invalid rescue data" % level_number)
		return
	var rescue := Vector2i(int(rescue_data[0]), int(rescue_data[1]))
	if not inside(rescue, width, height):
		errors.append("Level %d rescue outside board" % level_number)
	var occupied := {}
	var movable := 0
	var key_ids := {}
	var gate_ids := {}
	for raw in level.get("pieces", []):
		if not raw is Dictionary:
			errors.append("Level %d malformed piece" % level_number)
			continue
		var p: Dictionary = raw
		var pos := Vector2i(int(p.get("x", -1)), int(p.get("y", -1)))
		if not inside(pos, width, height):
			errors.append("Level %d piece outside board" % level_number)
			continue
		if pos == rescue:
			errors.append("Level %d piece overlaps rescue" % level_number)
		if occupied.has(pos):
			errors.append("Level %d duplicate position" % level_number)
		occupied[pos] = true
		var type := String(p.get("type", "normal"))
		if type not in VALID_TYPES:
			errors.append("Level %d unknown type" % level_number)
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
			errors.append("Level %d gate has no matching key" % level_number)

func inside(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height
