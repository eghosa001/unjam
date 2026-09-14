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
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(4)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game): return _fail("Water Sort interaction test could not launch")
	var before: Array = game.get("tubes").duplicate(true)
	game.call("show_hint")
	if String(game.get("hint_label").text).is_empty(): return _fail("Water Sort hint produced no guidance")
	var moved := false
	for a in range(before.size()):
		for b in range(before.size()):
			if a != b and bool(game.call("can_pour", a, b)):
				# Model the real UI as two distinct taps. The premium pour sequence is
				# asynchronous, so wait for the live move counter and animation state
				# instead of assuming a fixed number of frames.
				game.call("select_tube", a)
				await _frames(2)
				var before_moves := int(game.get("moves"))
				game.call("select_tube", b)
				moved = await _wait_for_water_move(game, before_moves)
				break
		if moved: break
	if not moved or int(game.get("moves")) != 1: return _fail("Water Sort could not execute a legal move")
	if _manager().call("checkpoint", "water_sort").is_empty(): return _fail("Water Sort move did not save a checkpoint")
	game.call("undo_move")
	await _frames(2)
	if int(game.get("moves")) != 0 or game.get("tubes") != before: return _fail("Water Sort undo did not restore state")
	game.call("restart_level")
	await _frames(2)
	if int(game.get("moves")) != 0: return _fail("Water Sort retry did not reset moves")
	return true

func _wait_for_water_move(game: Node, previous_moves: int, max_frames: int = 240) -> bool:
	for _i in range(max_frames):
		if not is_instance_valid(game):
			return false
		if int(game.get("moves")) > previous_moves and not bool(game.get("animating")):
			return true
		await process_frame
	return false

func _test_block(main: Control) -> bool:
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(4)
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game): return _fail("Block Puzzle interaction test could not launch")
	game.call("show_hint")
	if String(game.get("hint_label").text).is_empty(): return _fail("Block Puzzle hint produced no guidance")
	var before: Array = game.get("cells").duplicate(true)
	var placed := false
	for pi in range(game.get("pieces").size()):
		var shape: Array = game.get("pieces")[pi]
		for y in range(8):
			for x in range(8):
				if bool(game.call("can_place", shape, Vector2i(x, y))):
					game.call("select_piece", pi)
					game.call("place_selected", Vector2i(x, y))
					placed = true
					break
			if placed: break
		if placed: break
	if not placed or int(game.get("placements")) != 1: return _fail("Block Puzzle could not place a legal piece")
	if _manager().call("checkpoint", "block_puzzle").is_empty(): return _fail("Block Puzzle placement did not save a checkpoint")
	game.call("undo_move")
	if int(game.get("placements")) != 0 or game.get("cells") != before: return _fail("Block Puzzle undo did not restore state")
	game.call("restart_level")
	await _frames(2)
	if int(game.get("placements")) != 0 or int(game.get("score")) != 0: return _fail("Block Puzzle retry did not reset state")
	return true

func _frames(count: int) -> void:
	for _i in range(count): await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
