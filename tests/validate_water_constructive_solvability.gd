extends SceneTree

const MAX_LEVEL := 10000
const CAPACITY := 4

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	if not game.has_method("generate_tubes_with_solution"):
		game.queue_free()
		return _fail("Water Sort generator does not expose a constructive solution proof")
	var max_solution := 0
	var signatures := {}
	for level in range(1, MAX_LEVEL + 1):
		game.level_number = level
		var cfg: Dictionary = game.level_config()
		var generated: Dictionary = game.call("generate_tubes_with_solution", level, int(cfg.get("colors", 4)))
		var tubes: Array = generated.get("tubes", []).duplicate(true)
		var solution: Array = generated.get("solution", [])
		if tubes.is_empty() or solution.is_empty():
			game.queue_free()
			return _fail("Water Sort level %d has no constructive solution proof" % level)
		if solution.size() > int(cfg.get("par", 0)):
			game.queue_free()
			return _fail("Water Sort level %d known solution %d exceeds par %d" % [level, solution.size(), int(cfg.get("par", 0))])
		max_solution = maxi(max_solution, solution.size())
		for raw_move in solution:
			var move: Vector2i = raw_move
			if not _can_pour(tubes, move.x, move.y):
				game.queue_free()
				return _fail("Water Sort level %d proof contains illegal pour %s" % [level, str(move)])
			_pour(tubes, move.x, move.y)
		if not _solved(tubes):
			game.queue_free()
			return _fail("Water Sort level %d proof does not solve generated board" % level)
		if level % 25 == 0:
			signatures[_signature(generated.get("tubes", []))] = true
		if level % 1000 == 0:
			print("Water constructive proof: %d/%d" % [level, MAX_LEVEL])
	if signatures.size() < 300:
		game.queue_free()
		return _fail("Water Sort constructive generator diversity too low: %d signatures" % signatures.size())
	game.queue_free()
	await process_frame
	print("WATER_CONSTRUCTIVE_10000_OK: every generated level has a legal replayable solution proof within par; max proof length %d." % max_solution)
	quit(0)

func _can_pour(tubes: Array, from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or from_idx >= tubes.size() or to_idx < 0 or to_idx >= tubes.size() or from_idx == to_idx:
		return false
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	if source.is_empty() or target.size() >= CAPACITY:
		return false
	return target.is_empty() or int(target.back()) == int(source.back())

func _pour(tubes: Array, from_idx: int, to_idx: int) -> void:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	var color := int(source.back())
	var amount := 0
	for i in range(source.size() - 1, -1, -1):
		if int(source[i]) == color:
			amount += 1
		else:
			break
	amount = mini(amount, CAPACITY - target.size())
	for _i in range(amount):
		target.append(source.pop_back())
	tubes[from_idx] = source
	tubes[to_idx] = target

func _solved(tubes: Array) -> bool:
	for tube_value in tubes:
		var tube: Array = tube_value
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY:
			return false
		var color := int(tube[0])
		for value in tube:
			if int(value) != color:
				return false
	return true

func _signature(tubes: Array) -> String:
	var parts: PackedStringArray = []
	for tube_value in tubes:
		var tube: Array = tube_value
		var values: PackedStringArray = []
		for value in tube:
			values.append(str(int(value)))
		parts.append(",".join(values))
	return "|".join(parts)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
