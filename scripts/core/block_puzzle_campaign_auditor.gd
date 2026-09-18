class_name BlockPuzzleCampaignAuditor
extends RefCounted

const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const GRID_SIZE := 8

const BOT_NAMES := ["greedy", "space", "future", "pressure"]

static func audit_plan(profile: Dictionary, plan: Dictionary) -> Dictionary:
	if plan.is_empty():
		return {"valid": false, "reason": "empty_plan"}
	var proof := Generator.replay_proof(
		plan,
		int(profile.get("target_lines", 1)),
		int(profile.get("target_score", 1))
	)
	if not bool(proof.get("solved", false)):
		return {"valid": false, "reason": "proof_failed"}

	var wins := 0
	var results := {}
	for bot_name in BOT_NAMES:
		var result := _run_bot(profile, plan, bot_name)
		results[bot_name] = result
		if bool(result.get("solved", false)):
			wins += 1

	var success_rate := float(wins) / float(BOT_NAMES.size())
	var metadata: Dictionary = plan.get("metadata", {})
	var proof_moves := maxi(1, int(metadata.get("proof_moves", 1)))
	var initial_occupied := int(metadata.get("initial_occupancy", 0))
	var special_plan: Dictionary = plan.get("special_plan", {})
	var special_pressure := (special_plan.get("specials", []) as Array).size()
	special_pressure += (special_plan.get("target_rows", []) as Array).size()
	special_pressure += (special_plan.get("target_cols", []) as Array).size()
	special_pressure += int(special_plan.get("required_double_clears", 0))

	var calibrated := roundi(
		(1.0 - success_rate) * 48.0 +
		clampf(float(proof_moves) / 45.0, 0.0, 1.0) * 26.0 +
		clampf(float(initial_occupied) / 26.0, 0.0, 1.0) * 12.0 +
		clampf(float(special_pressure) / 8.0, 0.0, 1.0) * 14.0
	)
	var target := int(profile.get("difficulty_score", calibrated))
	var tolerance := 22 if int(profile.get("level_id", 1)) < 500 else 18
	return {
		"valid": true,
		"signature": canonical_signature(profile, plan),
		"bots": results,
		"bot_success_rate": success_rate,
		"calibrated_difficulty": clampi(calibrated, 0, 100),
		"target_difficulty": target,
		"difficulty_error": absi(calibrated - target),
		"within_tolerance": absi(calibrated - target) <= tolerance,
		"proof_moves": proof_moves,
	}

static func canonical_signature(profile: Dictionary, plan: Dictionary) -> String:
	var board := PackedStringArray()
	for row_value in (plan.get("initial_cells", []) as Array):
		var row := ""
		for value in (row_value as Array):
			row += "1" if bool(value) else "0"
		board.append(row)
	var trays := PackedStringArray()
	for tray_value in (plan.get("trays", []) as Array):
		var values := PackedStringArray()
		for value in (tray_value as Array):
			values.append(str(int(value)))
		trays.append(",".join(values))
	var specials := JSON.stringify(plan.get("special_plan", {}))
	return ("%s#%s#%s" % [
		"/".join(board),
		"/".join(trays),
		specials
	]).sha256_text()

static func _run_bot(profile: Dictionary, plan: Dictionary, strategy: String) -> Dictionary:
	var board: Array = (plan.get("initial_cells", []) as Array).duplicate(true)
	var trays: Array = (plan.get("trays", []) as Array).duplicate(true)
	var target_lines := int(profile.get("target_lines", 1))
	var target_score := int(profile.get("target_score", 1))
	var lines := 0
	var score := 0
	var moves := 0

	for tray_value in trays:
		var tray: Array = (tray_value as Array).duplicate()
		for _slot in range(tray.size()):
			var best := _best_move(board, tray, strategy)
			if best.is_empty():
				return {"solved": false, "moves": moves, "lines": lines, "score": score}
			var tray_index := int(best.get("tray_index", -1))
			var shape_index := int(best.get("shape", 0))
			var origin := Vector2i(int(best.get("x", 0)), int(best.get("y", 0)))
			var applied := _apply(board, Generator.SHAPES[shape_index], origin)
			if not bool(applied.get("legal", false)):
				return {"solved": false, "moves": moves, "lines": lines, "score": score}
			board = (applied.get("board", []) as Array).duplicate(true)
			tray[tray_index] = -1
			var cleared := int(applied.get("cleared", 0))
			lines += cleared
			score += Generator.SHAPES[shape_index].size() * 10
			if cleared > 0:
				score += cleared * 120 + maxi(0, cleared - 1) * 80
			moves += 1
			if lines >= target_lines and score >= target_score:
				return {"solved": true, "moves": moves, "lines": lines, "score": score}
	return {"solved": lines >= target_lines and score >= target_score, "moves": moves, "lines": lines, "score": score}

static func _best_move(board: Array, tray: Array, strategy: String) -> Dictionary:
	var best := {}
	var best_value := -1.0e20
	for tray_index in range(tray.size()):
		var shape_index := int(tray[tray_index])
		if shape_index < 0 or shape_index >= Generator.SHAPES.size():
			continue
		var shape: Array = Generator.SHAPES[shape_index]
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				var applied := _apply(board, shape, Vector2i(x, y))
				if not bool(applied.get("legal", false)):
					continue
				var next: Array = applied.get("board", [])
				var cleared := int(applied.get("cleared", 0))
				var occupied := _occupied(next)
				var pockets := _pockets(next)
				var line_fill := _max_line_fill(next)
				var future := _future_fits(next, tray, tray_index)
				var value := 0.0
				match strategy:
					"greedy":
						value = cleared * 10000.0 + shape.size() * 20.0 - occupied
					"space":
						value = cleared * 500.0 - occupied * 14.0 - pockets * 180.0 + future * 2.0
					"future":
						value = cleared * 1600.0 + future * 36.0 - pockets * 260.0 - occupied * 3.0
					"pressure":
						value = line_fill * 130.0 + occupied * 6.0 + shape.size() * 18.0 - cleared * 90.0
						if occupied > 44:
							value += cleared * 2400.0
					_:
						value = cleared * 1000.0 + future
				if value > best_value:
					best_value = value
					best = {"tray_index": tray_index, "shape": shape_index, "x": x, "y": y}
	return best

static func _future_fits(board: Array, tray: Array, used_index: int) -> int:
	var total := 0
	for tray_index in range(tray.size()):
		if tray_index == used_index:
			continue
		var shape_index := int(tray[tray_index])
		if shape_index < 0 or shape_index >= Generator.SHAPES.size():
			continue
		var shape: Array = Generator.SHAPES[shape_index]
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if bool(_apply(board, shape, Vector2i(x, y)).get("legal", false)):
					total += 1
					if total >= 36:
						return total
	return total

static func _apply(board: Array, shape: Array, origin: Vector2i) -> Dictionary:
	var next := board.duplicate(true)
	for raw in shape:
		var point: Vector2i = raw
		var x := origin.x + point.x
		var y := origin.y + point.y
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

static func _occupied(board: Array) -> int:
	var count := 0
	for row_value in board:
		for value in (row_value as Array):
			if bool(value):
				count += 1
	return count

static func _max_line_fill(board: Array) -> int:
	var best := 0
	for y in range(GRID_SIZE):
		var n := 0
		for x in range(GRID_SIZE):
			if bool(board[y][x]):
				n += 1
		best = maxi(best, n)
	for x in range(GRID_SIZE):
		var n := 0
		for y in range(GRID_SIZE):
			if bool(board[y][x]):
				n += 1
		best = maxi(best, n)
	return best

static func _pockets(board: Array) -> int:
	var count := 0
	var dirs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if bool(board[y][x]):
				continue
			var blocked := 0
			for dir in dirs:
				var p: Vector2i = Vector2i(x, y) + dir
				if p.x < 0 or p.y < 0 or p.x >= GRID_SIZE or p.y >= GRID_SIZE or bool(board[p.y][p.x]):
					blocked += 1
			if blocked >= 3:
				count += 1
	return count
