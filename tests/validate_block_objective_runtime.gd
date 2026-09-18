extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game.level_number = 1000
	game.load_level()
	await process_frame
	if String((game.campaign_plan.get("special_plan", {}) as Dictionary).get("family", "")) != "ice":
		return _fail("Level 1000 must introduce the ice objective family")
	var required := 0
	for raw in game.campaign_special_cells.values():
		var special: Dictionary = raw
		if String(special.get("kind", "")) in ["crate", "ice", "lock", "steel", "target"]:
			required += int(special.get("layers", 0))
	if required <= 0:
		return _fail("Level 1000 generated no proof-backed ice target")

	for fixture in [[1500, "locks", "lock"], [1800, "steel", "steel"]]:
		MultiGameManager.clear_checkpoint("block_puzzle")
		game.level_number = int(fixture[0])
		game.load_level()
		await process_frame
		var objective: Dictionary = game.campaign_plan.get("special_plan", {})
		if String(objective.get("family", "")) != String(fixture[1]):
			return _fail("Level %d did not load the %s family" % [int(fixture[0]), String(fixture[1])])
		var found := false
		for raw in game.campaign_special_cells.values():
			if String((raw as Dictionary).get("kind", "")) == String(fixture[2]):
				found = true
				break
		if not found:
			return _fail("Level %d generated no %s objective cells" % [int(fixture[0]), String(fixture[2])])

	MultiGameManager.clear_checkpoint("block_puzzle")
	game.level_number = 1000
	game.load_level()
	await process_frame
	game.score = game.target_score
	game.lines_cleared = game.target_lines
	if game.reached_goal():
		return _fail("Campaign completed while proof-backed objectives were unfinished")

	for key in game.campaign_special_cells.keys().duplicate():
		var special: Dictionary = game.campaign_special_cells[key]
		if String(special.get("kind", "")) in ["crate", "ice", "target"]:
			game.campaign_special_cells.erase(key)
	game.target_rows_pending.clear()
	game.target_cols_pending.clear()
	game.double_clear_progress = game.required_double_clears
	if not game.reached_goal():
		return _fail("Campaign stayed blocked after all required objectives were satisfied")

	print("BLOCK_OBJECTIVE_RUNTIME_OK")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
