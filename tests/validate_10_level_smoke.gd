extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")
const PuzzleSolverScript = preload("res://scripts/core/puzzle_solver.gd")
const LEVEL_LIMIT := 10

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var multi := root.get_node("MultiGameManager")
	var levels := root.get_node("LevelManager")

	var water = (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate()
	root.add_child(water)
	await process_frame
	var block = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(block)
	await process_frame

	for n in range(1, LEVEL_LIMIT + 1):
		if not levels.has_level(n):
			errors.append("Rescue level %d missing" % n)
		else:
			var rescue: Dictionary = CampaignGeneratorScript.generate(n)
			if rescue.is_empty():
				errors.append("Rescue level %d empty" % n)
			elif not PuzzleSolverScript.has_solution(rescue, 2000):
				errors.append("Rescue level %d has no verified solution" % n)

		water.level_number = n
		var water_cfg: Dictionary = water.level_config()
		var colors := int(water_cfg.get("colors", 0))
		var tubes: Array = water.generate_tubes(n, colors)
		if colors < 4 or colors > 8:
			errors.append("Water level %d invalid color count" % n)
		if tubes.size() != colors + 2:
			errors.append("Water level %d invalid tube count" % n)
		var counts := {}
		for tube in tubes:
			if tube.size() > 4:
				errors.append("Water level %d exceeds tube capacity" % n)
			for color in tube:
				counts[color] = int(counts.get(color, 0)) + 1
		for color in range(colors):
			if int(counts.get(color, 0)) != 4:
				errors.append("Water level %d invalid color distribution" % n)

		block.level_number = n
		var block_cfg: Dictionary = block.level_config()
		if int(block_cfg.get("target_score", 0)) <= 0:
			errors.append("Block level %d invalid target score" % n)
		if int(block_cfg.get("par", 0)) <= 0:
			errors.append("Block level %d invalid par" % n)
		if int(block_cfg.get("target_lines", -1)) < 0:
			errors.append("Block level %d invalid target lines" % n)
		if multi.difficulty_for_level(n) not in ["easy", "medium", "hard", "milestone", "boss"]:
			errors.append("Level %d invalid difficulty" % n)

	water.queue_free()
	block.queue_free()
	await process_frame

	if not errors.is_empty():
		for error in errors:
			push_error(error)
		push_error("10-level smoke validation failed: %d issue(s)" % errors.size())
		quit(1)
		return

	print("10-level smoke validation passed for Rescue Rush, Water Sort and Block Puzzle.")
	quit(0)
