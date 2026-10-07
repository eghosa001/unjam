extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var multi = root.get_node_or_null("MultiGameManager")
	if multi == null:
		return _fail("MultiGameManager autoload is unavailable")

	var observed_families := {}
	for level in [1000, 1500, 1800]:
		multi.call("clear_checkpoint", "block_puzzle")
		game.level_number = level
		game.load_level()
		await process_frame
		var objective: Dictionary = game.campaign_plan.get("special_plan", {})
		var family := String(objective.get("family", ""))
		if family.is_empty():
			return _fail("Level %d has no authored objective family" % level)
		observed_families[family] = true
		if not _objective_state_is_live(game, objective):
			return _fail("Level %d objective family '%s' created no live blocking state" % [level, family])

		# Score/line completion alone must never bypass the active authored
		# objective, regardless of which family the current pacing system chose.
		game.score = game.target_score
		game.lines_cleared = game.target_lines
		if game.reached_goal():
			return _fail("Level %d completed while '%s' objective state was unfinished" % [level, family])

		_clear_objective_state(game)
		if not game.reached_goal():
			return _fail("Level %d stayed blocked after all authored objective state was satisfied" % level)

	if observed_families.size() < 2:
		return _fail("Sampled Block campaign objectives do not exercise enough family variety")

	print("BLOCK_OBJECTIVE_RUNTIME_OK families=%s" % str(observed_families.keys()))
	game.queue_free()
	await process_frame
	quit(0)

func _objective_state_is_live(game: Node, objective: Dictionary) -> bool:
	if not game.target_rows_pending.is_empty() or not game.target_cols_pending.is_empty():
		return true
	if game.required_double_clears > game.double_clear_progress:
		return true
	for raw in game.campaign_special_cells.values():
		var special: Dictionary = raw
		if String(special.get("kind", "")) in ["crate", "ice", "lock", "steel", "target"] and int(special.get("layers", 0)) > 0:
			return true
	# Some composite plans encode requirements directly. If the plan declares
	# no runtime-bearing target, it is not useful as a fixture for this test.
	return not (objective.get("specials", []) as Array).is_empty() or not (objective.get("target_rows", []) as Array).is_empty() or not (objective.get("target_cols", []) as Array).is_empty() or int(objective.get("required_double_clears", 0)) > 0

func _clear_objective_state(game: Node) -> void:
	game.campaign_special_cells.clear()
	game.target_rows_pending.clear()
	game.target_cols_pending.clear()
	game.double_clear_progress = game.required_double_clears

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
