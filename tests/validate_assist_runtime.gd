extends SceneTree

const Solver = preload("res://scripts/core/water_sort_solver.gd")
const CAPACITY := 4

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Array = [[0,0,1,1], [1,1,2,2], [2,2,0,0], [], []]
	for step in range(40):
		if _solved(state):
			break
		var move: Vector2i = Solver.best_move(state, 40000)
		if move.x < 0:
			return _fail("Water solver returned no move at step %d" % step)
		if not _can(state, move.x, move.y):
			return _fail("Water solver returned illegal move %s" % str(move))
		_pour(state, move.x, move.y)
	if not _solved(state):
		return _fail("Water solver failed to finish a known solvable mixed board")

	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		return _fail("WaterSort scene failed to load")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	for pair in [[1,3], [10,3], [11,4], [30,4], [31,5], [130,5], [131,6], [210,6], [211,7], [300,7], [301,8], [1000,8]]:
		game.level_number = int(pair[0])
		var cfg: Dictionary = game.level_config()
		var actual := int(cfg.get("colors", 0))
		if actual != int(pair[1]):
			game.queue_free()
			return _fail("Water level %d colors=%d expected=%d" % [pair[0], actual, pair[1]])
	game.queue_free()
	await process_frame
	print("Assist runtime passed: solver finishes a mixed board and Water Sort progression boundaries are correct.")
	quit(0)

func _can(state: Array, from_idx: int, to_idx: int) -> bool:
	if from_idx == to_idx or from_idx < 0 or to_idx < 0 or from_idx >= state.size() or to_idx >= state.size():
		return false
	var source: Array = state[from_idx]
	var target: Array = state[to_idx]
	return not source.is_empty() and target.size() < CAPACITY and (target.is_empty() or int(source.back()) == int(target.back()))

func _pour(state: Array, from_idx: int, to_idx: int) -> void:
	var source: Array = state[from_idx]
	var target: Array = state[to_idx]
	var color := int(source.back())
	var amount := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) == color: amount += 1
		else: break
	amount = mini(amount, CAPACITY - target.size())
	for _i in range(amount): target.append(source.pop_back())
	state[from_idx] = source
	state[to_idx] = target

func _solved(state: Array) -> bool:
	for raw in state:
		var tube: Array = raw
		if tube.is_empty(): continue
		if tube.size() != CAPACITY: return false
		for value in tube:
			if int(value) != int(tube[0]): return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
