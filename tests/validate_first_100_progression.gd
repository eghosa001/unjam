extends SceneTree

const LAST_LEVEL := 100

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	if main == null:
		_fail("Main scene could not be instantiated")
		return
	root.add_child(main)
	await _frames(4)

	if not await _run_rescue(main): return
	main.call("build_home")
	await _frames(3)
	if not await _run_water(main): return
	main.call("build_home")
	await _frames(3)
	if not await _run_block(main): return

	main.queue_free()
	await _frames(3)
	print("First-100 progression validated for Rescue Rush, Water Sort and Block Puzzle: launch, legal interaction availability, finish signal, teardown and next-level transition.")
	quit(0)

func _active_game(main: Control):
	var game = main.get("active_game")
	return game if game != null and is_instance_valid(game) else null

func _run_rescue(main: Control) -> bool:
	main.call("start_level", 1)
	await _frames(4)
	for level in range(1, LAST_LEVEL + 1):
		var game = _active_game(main)
		if game == null:
			return _fail("Rescue Rush level %d did not create an active game" % level)
		if int(game.get("level_number")) != level:
			return _fail("Rescue Rush progression mismatch: expected %d, got %d" % [level, int(game.get("level_number"))])
		if not game.visible:
			return _fail("Rescue Rush level %d is not visible" % level)
		var pieces: Array = game.get("pieces")
		var legal := false
		for i in range(pieces.size()):
			if bool(game.call("is_path_clear", i)):
				legal = true
				break
		if not legal:
			return _fail("Rescue Rush level %d exposes no legal live interaction" % level)
		game.finished.emit(level)
		await _frames(4)
		if level < LAST_LEVEL:
			var next_game = _active_game(main)
			if next_game == null or int(next_game.get("level_number")) != level + 1:
				return _fail("Rescue Rush failed transition %d -> %d" % [level, level + 1])
	return true

func _run_water(main: Control) -> bool:
	main.call("start_multi_level", "water_sort", 1, false)
	await _frames(4)
	for level in range(1, LAST_LEVEL + 1):
		var game = _active_game(main)
		if game == null:
			return _fail("Water Sort level %d did not create an active game" % level)
		if int(game.get("level_number")) != level:
			return _fail("Water Sort progression mismatch: expected %d, got %d" % [level, int(game.get("level_number"))])
		if not game.visible:
			return _fail("Water Sort level %d is not visible" % level)
		var tubes: Array = game.get("tubes")
		var legal := false
		for a in range(tubes.size()):
			for b in range(tubes.size()):
				if a != b and bool(game.call("can_pour", a, b)):
					legal = true
					break
			if legal: break
		if not legal:
			return _fail("Water Sort level %d exposes no legal pour" % level)
		game.finished.emit(level)
		await _frames(4)
		if level < LAST_LEVEL:
			var next_game = _active_game(main)
			if next_game == null or int(next_game.get("level_number")) != level + 1:
				return _fail("Water Sort failed transition %d -> %d" % [level, level + 1])
	return true

func _run_block(main: Control) -> bool:
	main.call("start_multi_level", "block_puzzle", 1, false)
	await _frames(4)
	for level in range(1, LAST_LEVEL + 1):
		var game = _active_game(main)
		if game == null:
			return _fail("Block Puzzle level %d did not create an active game" % level)
		if int(game.get("level_number")) != level:
			return _fail("Block Puzzle progression mismatch: expected %d, got %d" % [level, int(game.get("level_number"))])
		if not game.visible:
			return _fail("Block Puzzle level %d is not visible" % level)
		var pieces: Array = game.get("pieces")
		var legal := false
		for shape in pieces:
			for y in range(8):
				for x in range(8):
					if bool(game.call("can_place", shape, Vector2i(x, y))):
						legal = true
						break
				if legal: break
			if legal: break
		if not legal:
			return _fail("Block Puzzle level %d exposes no legal placement" % level)
		game.finished.emit(level)
		await _frames(4)
		if level < LAST_LEVEL:
			var next_game = _active_game(main)
			if next_game == null or int(next_game.get("level_number")) != level + 1:
				return _fail("Block Puzzle failed transition %d -> %d" % [level, level + 1])
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
