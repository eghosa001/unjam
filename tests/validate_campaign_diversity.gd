extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")
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
	var water_profile_signatures := {}
	var water_hard_colors := 0
	# Scan all 10,000 progression profiles cheaply. Board construction itself is
	# sampled below; constructive solvability has its own focused regression.
	for n in range(1, MAX_LEVEL + 1):
		water.level_number = n
		var cfg: Dictionary = water.level_config()
		var colors := int(cfg.get("colors", 0))
		var empties := int(cfg.get("empty_bottles", 0))
		var par := int(cfg.get("par", 0))
		var target := int(cfg.get("target_difficulty", 0))
		if colors < 3 or colors > 12:
			errors.append("Water %d colors outside 3..12" % n)
		if empties < 1 or empties > 2:
			errors.append("Water %d empty-bottle count outside 1..2" % n)
		if par <= 0 or target < 0 or target > 100:
			errors.append("Water %d invalid progression target" % n)
		if n >= 5000 and colors >= 10:
			water_hard_colors += 1
		if n % 10 == 0:
			water_profile_signatures["%d:%d:%d:%d:%s" % [colors, empties, par, target, water.difficulty()]] = true

	var sample_levels: Array[int] = [1,2,3,4,5,6,7,8,9,10,25,50,100,250,500,750,1000,1500,2500,5000,7500,9000,9500,9900,10000]
	var water_board_signatures := {}
	for n in sample_levels:
		water.level_number = n
		var cfg: Dictionary = water.level_config()
		var colors := int(cfg.get("colors", 0))
		var empties := int(cfg.get("empty_bottles", 0))
		var tubes: Array = water.generate_tubes(n, colors)
		var counts := {}
		if tubes.size() != colors + empties:
			errors.append("Water %d tube count: expected %d, got %d" % [n, colors + empties, tubes.size()])
		var actual_empties := 0
		for tube in tubes:
			if tube.is_empty():
				actual_empties += 1
			if tube.size() > 4:
				errors.append("Water %d capacity" % n)
			for color in tube:
				counts[color] = int(counts.get(color, 0)) + 1
		if actual_empties != empties:
			errors.append("Water %d empty-bottle mismatch" % n)
		for color in range(colors):
			if int(counts.get(color, 0)) != 4:
				errors.append("Water %d distribution" % n)
		water_board_signatures[_water_signature(tubes)] = true
	if water_profile_signatures.size() < 100:
		errors.append("Water progression profile diversity too low: %d signatures" % water_profile_signatures.size())
	if water_board_signatures.size() < int(sample_levels.size() * 0.70):
		errors.append("Water sampled structural diversity too low: %d/%d signatures" % [water_board_signatures.size(), sample_levels.size()])
	if water_hard_colors < 4500:
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
	for n in range(1, MAX_LEVEL + 1):
		if not levels.has_level(n):
			errors.append("Rescue %d missing" % n)
			continue
		if n % 20 != 0 and n not in [1, 2, 3, 4, 5, 10, 25, 50, 75, 100, 10000]:
			continue
		var level: Dictionary = CampaignGeneratorScript.generate(n)
		var board_width := int(level.get("width", 0))
		if board_width < 7 or board_width > 8:
			errors.append("Rescue %d invalid board size" % n)
		var occupied := {}
		for raw in level.get("pieces", []):
			if not raw is Dictionary:
				continue
			var key := "%d:%d" % [int(raw.get("x", -1)), int(raw.get("y", -1))]
			if occupied.has(key):
				errors.append("Rescue %d duplicate piece at %s" % [n, key])
			occupied[key] = true
		rescue_signatures[_rescue_signature(level)] = true
	if rescue_signatures.size() < 400:
		errors.append("Rescue structural diversity too low: %d signatures" % rescue_signatures.size())
	if multi.world_for_level(MAX_LEVEL) != 100:
		errors.append("Level %d world mismatch" % MAX_LEVEL)

	if not errors.is_empty():
		for e in errors.slice(0, 50):
			push_error(e)
		push_error("30,000-configuration campaign validation failed: %d errors" % errors.size())
		quit(1)
		return
	print("Validated 30,000 campaign configurations for distribution, goals, progression and structural diversity.")
	quit(0)

func _water_signature(tubes: Array) -> String:
	var parts: PackedStringArray = []
	for tube in tubes:
		if not tube is Array or tube.is_empty():
			continue
		var local: PackedStringArray = []
		for value in tube:
			local.append(str(int(value)))
		parts.append(",".join(local))
	return "|".join(parts)

func _rescue_signature(level: Dictionary) -> String:
	var parts: PackedStringArray = [str(level.get("width", 0)), str(level.get("phase", 0)), str(level.get("target_exit", ""))]
	for raw in level.get("pieces", []):
		if raw is Dictionary:
			parts.append("%s:%d:%d:%s" % [String(raw.get("type", "")), int(raw.get("x", -1)), int(raw.get("y", -1)), String(raw.get("direction", ""))])
	return "|".join(parts)
