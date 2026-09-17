extends RefCounted
class_name WaterSortSolver

const CAPACITY := 4
const NO_MOVE := Vector2i(-1, -1)

# Best-first search over legal pours. The returned move is always the first move
# of a complete solution path; it never recommends a merely legal dead-end move.
static func best_move(tubes: Array, max_states: int = 40000) -> Vector2i:
	var start := tubes.duplicate(true)
	if _solved(start):
		return NO_MOVE
	var heap: Array[Dictionary] = []
	var start_key := _key(start)
	var visited := {start_key: 0}
	_heap_push(heap, {"state": start, "depth": 0, "first": NO_MOVE, "priority": float(_heuristic(start))})
	var expanded := 0
	while not heap.is_empty() and expanded < max_states:
		var node: Dictionary = _heap_pop(heap)
		var state: Array = node.get("state", [])
		var depth := int(node.get("depth", 0))
		var first: Vector2i = node.get("first", NO_MOVE)
		if _solved(state):
			return first
		expanded += 1
		for move in _legal_moves(state):
			var next := _apply_pour(state, move.x, move.y)
			var key := _key(next)
			var next_depth := depth + 1
			if visited.has(key) and int(visited[key]) <= next_depth:
				continue
			visited[key] = next_depth
			var first_move := move if first == NO_MOVE else first
			var priority := float(next_depth) + float(_heuristic(next)) * 1.7 - float(_move_bonus(state, move))
			_heap_push(heap, {"state": next, "depth": next_depth, "first": first_move, "priority": priority})
	return NO_MOVE

static func _legal_moves(state: Array) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var first_empty_target := -1
	for i in range(state.size()):
		if (state[i] as Array).is_empty():
			first_empty_target = i
			break
	for from_idx in range(state.size()):
		var source: Array = state[from_idx]
		if source.is_empty() or _complete_tube(source):
			continue
		var source_uniform := _uniform(source)
		for to_idx in range(state.size()):
			if from_idx == to_idx:
				continue
			var target: Array = state[to_idx]
			if target.size() >= CAPACITY:
				continue
			if not target.is_empty() and int(target.back()) != int(source.back()):
				continue
			# Empty tubes are interchangeable. Exploring one representative removes a
			# large amount of symmetry without removing any solvable route.
			if target.is_empty() and to_idx != first_empty_target:
				continue
			# Moving an already uniform stack wholesale into an empty tube only renames
			# the tube and never advances the puzzle.
			if target.is_empty() and source_uniform:
				continue
			moves.append(Vector2i(from_idx, to_idx))
	return moves

static func _apply_pour(state: Array, from_idx: int, to_idx: int) -> Array:
	var out := state.duplicate(true)
	var source: Array = out[from_idx]
	var target: Array = out[to_idx]
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
	out[from_idx] = source
	out[to_idx] = target
	return out

static func _heuristic(state: Array) -> int:
	var score := 0
	for raw in state:
		var tube: Array = raw
		if tube.is_empty() or _complete_tube(tube):
			continue
		var runs := 1
		for i in range(1, tube.size()):
			if int(tube[i]) != int(tube[i - 1]):
				runs += 1
		score += (runs - 1) * 4
		if tube.size() < CAPACITY:
			score += 1
	return score

static func _move_bonus(state: Array, move: Vector2i) -> int:
	var source: Array = state[move.x]
	var target: Array = state[move.y]
	var bonus := 0
	if not target.is_empty() and int(target.back()) == int(source.back()):
		bonus += 3
	var next := _apply_pour(state, move.x, move.y)
	if _complete_tube(next[move.y] as Array):
		bonus += 5
	if (next[move.x] as Array).is_empty():
		bonus += 2
	return bonus

static func _solved(state: Array) -> bool:
	for raw in state:
		var tube: Array = raw
		if tube.is_empty():
			continue
		if not _complete_tube(tube):
			return false
	return true

static func _complete_tube(tube: Array) -> bool:
	return tube.size() == CAPACITY and _uniform(tube)

static func _uniform(tube: Array) -> bool:
	if tube.is_empty():
		return true
	var color := int(tube[0])
	for value in tube:
		if int(value) != color:
			return false
	return true

static func _key(state: Array) -> String:
	var tubes_encoded: Array[String] = []
	for raw in state:
		var tube: Array = raw
		var values: PackedStringArray = []
		for value in tube:
			values.append(str(int(value)))
		tubes_encoded.append(",".join(values))
	tubes_encoded.sort()
	return "|".join(tubes_encoded)

static func _heap_push(heap: Array[Dictionary], node: Dictionary) -> void:
	heap.append(node)
	var index := heap.size() - 1
	while index > 0:
		var parent := int((index - 1) / 2)
		if float(heap[parent].get("priority", INF)) <= float(heap[index].get("priority", INF)):
			break
		var tmp: Dictionary = heap[parent]
		heap[parent] = heap[index]
		heap[index] = tmp
		index = parent

static func _heap_pop(heap: Array[Dictionary]) -> Dictionary:
	var first: Dictionary = heap[0]
	var last: Dictionary = heap.pop_back()
	if heap.is_empty():
		return first
	heap[0] = last
	var index := 0
	while true:
		var left := index * 2 + 1
		var right := left + 1
		if left >= heap.size():
			break
		var smallest := left
		if right < heap.size() and float(heap[right].get("priority", INF)) < float(heap[left].get("priority", INF)):
			smallest = right
		if float(heap[index].get("priority", INF)) <= float(heap[smallest].get("priority", INF)):
			break
		var tmp: Dictionary = heap[index]
		heap[index] = heap[smallest]
		heap[smallest] = tmp
		index = smallest
	return first
