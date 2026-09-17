extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _manager() -> Node:
	return root.get_node("MultiGameManager")

func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await _frames(3)
	if not await _test_water(main): return
	main.call("build_home")
	await _frames(2)
	if not await _test_block(main): return
	print("Gameplay interactions validated: move/place, hint, undo, retry and checkpoint restore.")
	main.queue_free()
	await process_frame
	quit(0)

func _test_water(main: Control) -> bool:
	# Keep the interaction contract repeatable even when a previous test run
	# intentionally saved an in-flight checkpoint.
	_manager().call("clear_checkpoint", "water_sort")
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(4)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game): return _fail("Water Sort interaction test could not launch")
	var before: Array = game.get("tubes").duplicate(true)
	var before_moves := int(game.get("moves"))
	game.call("show_hint")
	if String(game.get("hint_label").text).is_empty(): return _fail("Water Sort hint produced no guidance")
	# Water hints intentionally execute the solver-selected pour through the same
	# interaction path as two player taps. Wait for that pour to settle before
	# validating checkpoint/undo so the contract matches live gameplay.
	if not await _wait_for_water_move(game, before_moves):
		return _fail("Water Sort Hint did not execute a verified move")
	if int(game.get("moves")) != before_moves + 1:
		return _fail("Water Sort Hint executed an unexpected number of moves")
	if _manager().call("checkpoint", "water_sort").is_empty(): return _fail("Water Sort Hint move did not save a checkpoint")
	game.call("undo_move")
	if not await _wait_for_water_undo(game, before):
		return _fail("Water Sort undo did not restore the pre-Hint state")
	game.call("restart_level")
	await _frames(2)
	if int(game.get("moves")) != 0: return _fail("Water Sort retry did not reset moves")
	return true

func _wait_for_water_move(game: Node, previous_moves: int, max_frames: int = 240) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game):
			return false
		var active := bool(game.call("_has_active_pours")) if game.has_method("_has_active_pours") else bool(game.get("animating"))
		if int(game.get("moves")) > previous_moves and not active:
			return true
		await process_frame
	return false

func _wait_for_water_undo(game: Node, expected_tubes: Array, max_frames: int = 300) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game):
			return false
		var active := bool(game.call("_has_active_pours")) if game.has_method("_has_active_pours") else bool(game.get("animating"))
		if not active and int(game.get("moves")) == 0 and game.get("tubes") == expected_tubes:
			return true
		await process_frame
	return false

func _test_block(main: Control) -> bool:
	_manager().call("clear_checkpoint", "block_puzzle")
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(4)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game): return _fail("Block Puzzle interaction test could not launch")
	var before: Array = game.get("cells").duplicate(true)
	var before_placements := int(game.get("placements"))
	game.call("show_hint")
	if String(game.get("hint_label").text).is_empty(): return _fail("Block Puzzle hint produced no guidance")
	# Block hints intentionally execute the solver-selected placement. Wait for
	# any premium line-clear transaction to finish before validating undo.
	if not await _wait_for_block_hint(game, before_placements):
		return _fail("Block Puzzle Hint did not execute a verified placement")
	if int(game.get("placements")) != before_placements + 1:
		return _fail("Block Puzzle Hint executed an unexpected number of placements")
	if _manager().call("checkpoint", "block_puzzle").is_empty(): return _fail("Block Puzzle Hint placement did not save a checkpoint")
	game.call("undo_move")
	if int(game.get("placements")) != before_placements or game.get("cells") != before: return _fail("Block Puzzle undo did not restore the pre-Hint state")
	game.call("restart_level")
	await _frames(2)
	if int(game.get("placements")) != 0 or int(game.get("score")) != 0: return _fail("Block Puzzle retry did not reset state")
	return true

func _wait_for_block_hint(game: Node, previous_placements: int, max_frames: int = 240) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game):
			return false
		var clearing := bool(game.get("_clear_transition_active"))
		if int(game.get("placements")) > previous_placements and not clearing:
			return true
		await process_frame
	return false

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
