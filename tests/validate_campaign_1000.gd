extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var multi = root.get_node("MultiGameManager")
	var levels = root.get_node("LevelManager")
	var water = (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate()
	root.add_child(water)
	await process_frame
	for level_number in range(1, 1001):
		water.level_number = level_number
		var config: Dictionary = water.level_config()
		var colors := int(config.get("colors", 0))
		var tubes: Array = water.generate_tubes(level_number, colors)
		if tubes.size() != colors + 2:
			errors.append("Water Sort %d: tube count" % level_number)
		var counts := {}
		for tube in tubes:
			if tube.size() > 4:
				errors.append("Water Sort %d: capacity" % level_number)
			for color in tube:
				counts[color] = int(counts.get(color, 0)) + 1
		for color in range(colors):
			if int(counts.get(color, 0)) != 4:
				errors.append("Water Sort %d: color distribution" % level_number)
	water.queue_free()
	await process_frame

	var block = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(block)
	await process_frame
	for level_number in range(1, 1001):
		block.level_number = level_number
		var config: Dictionary = block.level_config()
		if int(config.get("target_score", 0)) <= 0 or int(config.get("target_lines", 0)) <= 0 or int(config.get("par", 0)) <= 0:
			errors.append("Block Puzzle %d: invalid goal" % level_number)
		if multi.difficulty_for_level(level_number) not in ["easy", "medium", "hard", "milestone", "boss"]:
			errors.append("Level %d: invalid difficulty" % level_number)
	block.queue_free()
	await process_frame

	for level_number in range(1, 1001):
		if not levels.has_level(level_number):
			errors.append("Rescue Rush %d: missing level" % level_number)

	if not errors.is_empty():
		for message in errors.slice(0, 30): push_error(message)
		push_error("Campaign 1-1000 validation failed with %d errors" % errors.size())
		quit(1)
		return
	print("Campaign levels 1-1000 validated for all three games.")
	quit(0)
