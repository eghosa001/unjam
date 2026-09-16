extends SceneTree

const TRANSITION_STARTS: Array[int] = [1, 9, 10, 99, 100, 999, 1000, 9999]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	if main == null:
		_fail("Main scene could not be instantiated")
		return
	root.add_child(main)
	await _frames(4)

	if not await _run_rescue(main):
		return
	if not await _run_multi(main, "water_sort", "Water Sort"):
		return
	if not await _run_multi(main, "block_puzzle", "Block Puzzle"):
		return

	main.queue_free()
	await _frames(3)
	print("Representative progression transitions validated across tutorial, milestone, world and late-campaign boundaries for all three games.")
	quit(0)

func _run_rescue(main: Control) -> bool:
	for start_level in TRANSITION_STARTS:
		main.call("build_home")
		await _frames(2)
		main.call("start_level", start_level)
		await _frames(4)
		if not await _assert_transition(main, start_level, "Rescue Rush"):
			return false
	return true

func _run_multi(main: Control, game_id: String, game_name: String) -> bool:
	for start_level in TRANSITION_STARTS:
		main.call("build_home")
		await _frames(2)
		main.call("start_multi_level", game_id, start_level, false)
		await _frames(4)
		if not await _assert_transition(main, start_level, game_name):
			return false
	return true

func _assert_transition(main: Control, start_level: int, game_name: String) -> bool:
	var game = _active_game(main)
	if game == null:
		return _fail("%s level %d did not create an active game" % [game_name, start_level])
	if int(game.get("level_number")) != start_level:
		return _fail("%s launch mismatch: expected %d, got %d" % [game_name, start_level, int(game.get("level_number"))])
	if not game.visible:
		return _fail("%s level %d is not visible" % [game_name, start_level])

	game.finished.emit(start_level)
	await _frames(5)
	var next_game = _active_game(main)
	var expected := start_level + 1
	if next_game == null:
		return _fail("%s transition %d -> %d created no next game" % [game_name, start_level, expected])
	if int(next_game.get("level_number")) != expected:
		return _fail("%s transition mismatch: expected %d, got %d" % [game_name, expected, int(next_game.get("level_number"))])
	return true

func _active_game(main: Control):
	var game = main.get("active_game")
	return game if game != null and is_instance_valid(game) else null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
