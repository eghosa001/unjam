class_name BlockPuzzleCampaignGenerator
extends RefCounted

const GRID_SIZE := 8
const GENERATOR_VERSION := 2

const SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0), Vector2i(1,0)],
	[Vector2i(0,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(1,2)],
	[Vector2i(0,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(1,2)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(1,3)],
]

const TIER_POOLS := {
	1: [0, 1, 2, 3, 4],
	2: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
	3: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
	4: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
	5: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 23, 24],
	6: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24],
}

static func generate(profile: Dictionary) -> Dictionary:
	var level := int(profile.get("level_id", 1))
	var seed_value := int(profile.get("seed", level * 104729)) + GENERATOR_VERSION * 65537
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var board := _initial_board(profile, rng)
	var initial_board := board.duplicate(true)
	var tier := clampi(int(profile.get("piece_tier", 1)), 1, 6)
	var pool: Array = (TIER_POOLS.get(tier, TIER_POOLS[1]) as Array).duplicate()
	var target_lines := maxi(1, int(profile.get("target_lines", 2)))
	var target_score := maxi(1, int(profile.get("target_score", 100)))
	var difficulty := clampi(int(profile.get("difficulty_score", 20)), 0, 100)
	var desired_delay := clampi(1 + int(profile.get("planning_horizon", 1) / 2), 1, 5)
	var max_moves := maxi(18, target_lines * 5 + int(profile.get("planning_horizon", 1)) + 12)

	var proof_origins: Array[int] = []
	var proof_shapes: Array[int] = []
	var total_lines := 0
	var score := 0
	var since_clear := 0
	var clear_events := 0
	var advanced_moves := 0
	var ambiguity_total := 0.0

	while (total_lines < target_lines or score < target_score) and proof_shapes.size() < max_moves:
		var move := _choose_constructive_move(board, pool, difficulty, desired_delay, since_clear, rng)
		if move.is_empty():
			move = _forced_single_move(board)
		if move.is_empty():
			break
		var shape_index := int(move.get("shape", 0))
		var origin := Vector2i(int(move.get("x", 0)), int(move.get("y", 0)))
		var result := _apply(board, SHAPES[shape_index], origin)
		if not bool(result.get("legal", false)):
			break
		board = (result.get("board", []) as Array).duplicate(true)
		var cleared := int(result.get("cleared", 0))
		total_lines += cleared
		score += SHAPES[shape_index].size() * 10
		if cleared > 0:
			score += cleared * 120 + maxi(0, cleared - 1) * 80
			since_clear = 0
			clear_events += 1
		else:
			since_clear += 1
		if shape_index >= 10:
			advanced_moves += 1
		ambiguity_total += float(move.get("legal_count", 1))
		proof_shapes.append(shape_index)
		proof_origins.append(origin.y * GRID_SIZE + origin.x)

	if total_lines < target_lines or score < target_score:
		return {}

	var trays: Array = []
	for start in range(0, proof_shapes.size(), 3):
		var tray: Array[int] = []
		for offset in range(3):
			var index := start + offset
			tray.append(int(proof_shapes[index]) if index < proof_shapes.size() else 0)
		trays.append(tray)

	var proof_moves := proof_shapes.size()
	var average_ambiguity := ambiguity_total / float(maxi(1, proof_moves))
	var advanced_ratio := float(advanced_moves) / float(maxi(1, proof_moves))
	var metrics := {
		"proof_moves": proof_moves,
		"proof_lines": total_lines,
		"proof_score": score,
		"clear_events": clear_events,
		"advanced_piece_ratio": advanced_ratio,
		"average_legal_choices": average_ambiguity,
		"initial_occupancy": _occupied_count(initial_board),
		"generator_version": GENERATOR_VERSION,
		"verified_constructive": true,
	}
	return {
		"initial_cells": initial_board,
		"trays": trays,
		"proof_shapes": proof_shapes,
		"proof_origins": proof_origins,
		"metadata": metrics,
	}

static func replay_proof(plan: Dictionary, target_lines: int, target_score: int) -> Dictionary:
	var board: Array = (plan.get("initial_cells", []) as Array).duplicate(true)
	var shapes: Array = plan.get("proof_shapes", [])
	var origins: Array = plan.get("proof_origins", [])
	if board.size() != GRID_SIZE or shapes.is_empty() or shapes.size() != origins.size():
		return {"solved": false}
	var lines := 0
	var score := 0
	for i in range(shapes.size()):
		var shape_index := int(shapes[i])
		var cell := int(origins[i])
		if shape_index < 0 or shape_index >= SHAPES.size() or cell < 0 or cell >= GRID_SIZE * GRID_SIZE:
			return {"solved": false}
		var result := _apply(board, SHAPES[shape_index], Vector2i(cell % GRID_SIZE, int(cell / GRID_SIZE)))
		if not bool(result.get("legal", false)):
			return {"solved": false}
		board = (result.get("board", []) as Array).duplicate(true)
		var cleared := int(result.get("cleared", 0))
		lines += cleared
		score += SHAPES[shape_index].size() * 10
		if cleared > 0:
			score += cleared * 120 + maxi(0, cleared - 1) * 80
		if lines >= target_lines and score >= target_score:
			return {"solved": true, "moves": i + 1, "lines": lines, "score": score}
	return {"solved": lines >= target_lines and score >= target_score, "moves": shapes.size(), "lines": lines, "score": score}

static func _choose_constructive_move(
	board: Array,
	pool: Array,
	difficulty: int,
	desired_delay: int,
	since_clear: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var occupied := _occupied_count(board)
	var need_clear := since_clear >= desired_delay or occupied >= 46
	var sampled: Array[int] = [0]
	var desired_samples := 4 if difficulty < 50 else (6 if difficulty < 80 else 8)
	for _i in range(desired_samples):
		var pick := int(pool[rng.randi_range(0, pool.size() - 1)])
		if pick not in sampled:
			sampled.append(pick)

	var best: Dictionary = {}
	var best_value := -1.0e20
	var legal_count := 0
	for shape_index in sampled:
		var shape: Array = SHAPES[shape_index]
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				var result := _apply(board, shape, Vector2i(x, y))
				if not bool(result.get("legal", false)):
					continue
				legal_count += 1
				var after: Array = result.get("board", [])
				var cleared := int(result.get("cleared", 0))
				var pressure := float(_occupied_count(after)) / 64.0
				var line_pressure := float(_max_line_fill(after)) / 8.0
				var shape_weight := float(shape.size()) / 9.0
				var value := rng.randf_range(0.0, 2.5)
				if need_clear:
					value += float(cleared) * 900.0
					value += line_pressure * 80.0
					value -= pressure * 20.0
				else:
					value -= float(cleared) * (130.0 + float(difficulty))
					value += line_pressure * (45.0 + float(difficulty) * 0.45)
					value += pressure * (30.0 + float(difficulty) * 0.65)
					value += shape_weight * float(difficulty) * 0.9
					if difficulty >= 70 and shape_index >= 10:
						value += 20.0
				if value > best_value:
					best_value = value
					best = {"shape": shape_index, "x": x, "y": y, "legal_count": legal_count}
	if not best.is_empty():
		best["legal_count"] = legal_count
	return best

static func _forced_single_move(board: Array) -> Dictionary:
	var best := {}
	var best_fill := -1
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if bool(board[y][x]):
				continue
			var result := _apply(board, SHAPES[0], Vector2i(x, y))
			if not bool(result.get("legal", false)):
				continue
			var fill := _max_line_fill(result.get("board", []))
			if int(result.get("cleared", 0)) > 0:
				fill += 20
			if fill > best_fill:
				best_fill = fill
				best = {"shape": 0, "x": x, "y": y, "legal_count": 1}
	return best

static func _initial_board(profile: Dictionary, rng: RandomNumberGenerator) -> Array:
	var board := _empty_board()
	var ratio := clampf(float(profile.get("initial_occupancy", 0.0)), 0.0, 0.40)
	var target := clampi(int(round(ratio * 64.0)), 0, 26)
	if target <= 0:
		return board

	var reserve_x := rng.randi_range(1, GRID_SIZE - 4)
	var reserve_y := rng.randi_range(1, GRID_SIZE - 4)
	var candidates: Array[Vector2i] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if x >= reserve_x and x < reserve_x + 3 and y >= reserve_y and y < reserve_y + 3:
				continue
			candidates.append(Vector2i(x, y))
	_shuffle_points(candidates, rng)
	var row_load: Array[int] = []
	var col_load: Array[int] = []
	for _i in range(GRID_SIZE):
		row_load.append(0)
		col_load.append(0)
	var placed := 0
	for point in candidates:
		if placed >= target:
			break
		if row_load[point.y] >= 6 or col_load[point.x] >= 6:
			continue
		board[point.y][point.x] = true
		row_load[point.y] += 1
		col_load[point.x] += 1
		placed += 1
	return board

static func _apply(board: Array, shape: Array, origin: Vector2i) -> Dictionary:
	var next := board.duplicate(true)
	for point in shape:
		var p: Vector2i = point
		var x := origin.x + p.x
		var y := origin.y + p.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE or bool(next[y][x]):
			return {"legal": false}
		next[y][x] = true

	var rows: Array[int] = []
	var cols: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if not bool(next[y][x]):
				full = false
				break
		if full:
			rows.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if not bool(next[y][x]):
				full = false
				break
		if full:
			cols.append(x)
	for y in rows:
		for x in range(GRID_SIZE):
			next[y][x] = false
	for x in cols:
		for y in range(GRID_SIZE):
			next[y][x] = false
	return {"legal": true, "board": next, "cleared": rows.size() + cols.size()}

static func _empty_board() -> Array:
	var board: Array = []
	for _y in range(GRID_SIZE):
		var row: Array = []
		for _x in range(GRID_SIZE):
			row.append(false)
		board.append(row)
	return board

static func _occupied_count(board: Array) -> int:
	var count := 0
	for row_value in board:
		for value in (row_value as Array):
			if bool(value):
				count += 1
	return count

static func _max_line_fill(board: Array) -> int:
	var best := 0
	for y in range(GRID_SIZE):
		var count := 0
		for x in range(GRID_SIZE):
			if bool(board[y][x]):
				count += 1
		best = maxi(best, count)
	for x in range(GRID_SIZE):
		var count := 0
		for y in range(GRID_SIZE):
			if bool(board[y][x]):
				count += 1
		best = maxi(best, count)
	return best

static func _shuffle_points(values: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp
