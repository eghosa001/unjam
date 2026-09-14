extends SceneTree

const MAX_LEVEL := 10000

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var multi = root.get_node("MultiGameManager")
	var levels = root.get_node("LevelManager")

	var water = (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate()
	root.add_child(water)
	await process_frame
	var water_signatures := {}
	var water_hard_colors := 0
	for n in range(1, MAX_LEVEL + 1):
		water.level_number = n
		var cfg: Dictionary = water.level_config()
		var colors := int(cfg.get("colors", 0))
		var tubes: Array = water.generate_tubes(n, colors)
		var counts := {}
		if tubes.size() != colors + 2: errors.append("Water %d tube count" % n)
		for tube in tubes:
			if tube.size() > 4: errors.append("Water %d capacity" % n)
			for color in tube: counts[color] = int(counts.get(color, 0)) + 1
		for color in range(colors):
			if int(counts.get(color, 0)) != 4: errors.append("Water %d distribution" % n)
		if n >= 5000 and colors >= 7: water_hard_colors += 1
		if n % 25 == 0:
			water_signatures[_water_signature(tubes)] = true
	if water_signatures.size() < 300:
		errors.append("Water structural diversity too low: %d signatures" % water_signatures.size())
	if water_hard_colors < 1500:
		errors.append("Water late campaign is too soft: only %d high-colour levels" % water_hard_colors)
	water.queue_free()
	await process_frame

	var block = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(block)
	await process_frame
	var block_goal_signatures := {}
	for n in range(1, MAX_LEVEL + 1):
		block.level_number = n
		var cfg: Dictionary = block.level_config()
		var target_score := int(cfg.get("target_score", 0))
		var target_lines := int(cfg.get("target_lines", -1))
		var par := int(cfg.get("par", 0))
		# Levels 1-2 deliberately teach placement/scoring before introducing line clears.
		# From level 3 onward every puzzle must include a positive line-clear objective.
		if target_score <= 0 or par <= 0 or target_lines < 0 or (n >= 3 and target_lines <= 0):
			errors.append("Block %d invalid goal" % n)
		if multi.difficulty_for_level(n) not in ["easy", "medium", "hard", "milestone", "boss"]:
			errors.append("Level %d invalid difficulty" % n)
		if n % 20 == 0:
			block_goal_signatures["%d:%d:%d" % [target_score, target_lines, par]] = true
	if block_goal_signatures.size() < 100:
		errors.append("Block campaign goal diversity too low: %d signatures" % block_goal_signatures.size())
	if block.ADVANCED_SHAPES.size() < 25:
		errors.append("Block shape library too small: %d" % block.ADVANCED_SHAPES.size())
	block.queue_free()
	await process_frame

	var rescue_signatures := {}
	var sampled_solutions := 0
	var deep_solutions := 0
	for n in range(1, MAX_LEVEL + 1):
		if not levels.has_level(n):
			errors.append("Rescue %d missing" % n)
			continue
		var level: Dictionary = CampaignGenerator.generate(n)
		if int(level.get("width", 0)) < 6 or int(level.get("width", 0)) > 8:
			errors.append("Rescue %d invalid board size" % n)
		var occupied := {}
		for raw in level.get("pieces", []):
			if not raw is Dictionary: continue
			var key := "%d:%d" % [int(raw.get("x", -1)), int(raw.get("y", -1))]
			if occupied.has(key): errors.append("Rescue %d duplicate piece at %s" % [n, key])
			occupied[key] = true
		if n % 20 == 0:
			rescue_signatures[_rescue_signature(level)] = true
		if n % 100 == 0 or n in [1, 10, 50, 500, 2500, 5000, 7500, 10000]:
			var solution: Array[int] = PuzzleSolver.find_solution(level, [], 20000)
			sampled_solutions += 1
			if solution.is_empty():
				errors.append("Rescue %d has no solver-confirmed solution" % n)
			elif solution.size() >= 4:
				deep_solutions += 1
	if rescue_signatures.size() < 400:
		errors.append("Rescue structural diversity too low: %d signatures" % rescue_signatures.size())
	if sampled_solutions > 0 and deep_solutions < int(sampled_solutions * 0.65):
		errors.append("Rescue campaign too shallow: %d/%d samples reach 4+ moves" % [deep_solutions, sampled_solutions])
	if multi.world_for_level(10000) != 100:
		errors.append("Level 10000 world mismatch")

	if not errors.is_empty():
		for e in errors.slice(0, 50): push_error(e)
		push_error("30,000-level validation failed: %d errors" % errors.size())
		quit(1)
		return
	print("All 10,000 levels validated for each game: 30,000 campaign configurations with diversity/depth gates.")
	quit(0)

func _water_signature(tubes: Array) -> String:
	var parts: PackedStringArray = []
	for tube in tubes:
		if not tube is Array or tube.is_empty(): continue
		var local: PackedStringArray = []
		for value in tube: local.append(str(int(value)))
		parts.append(",".join(local))
	return "|".join(parts)

func _rescue_signature(level: Dictionary) -> String:
	var parts: PackedStringArray = [str(level.get("width", 0)), str(level.get("phase", 0)), str(level.get("target_exit", ""))]
	for raw in level.get("pieces", []):
		if raw is Dictionary:
			parts.append("%s:%d:%d:%s" % [String(raw.get("type", "")), int(raw.get("x", -1)), int(raw.get("y", -1)), String(raw.get("direction", ""))])
	return "|".join(parts)