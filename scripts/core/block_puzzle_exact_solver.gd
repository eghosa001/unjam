class_name BlockPuzzleExactSolver
extends RefCounted

const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const GRID_SIZE := 8
const FULL_ROW := 0xff

static func find_solution(profile: Dictionary, plan: Dictionary, max_nodes: int = 250000) -> Dictionary:
	var state := _initial_state(profile, plan)
	if state.is_empty():
		return {"solved": false, "nodes": 0, "reason": "invalid_state"}
	var proof_shapes: Array = plan.get("proof_shapes", [])
	var proof_origins: Array = plan.get("proof_origins", [])
	var upper := maxi(1, proof_shapes.size())
	var context := {
		"nodes": 0,
		"max_nodes": maxi(1, max_nodes),
		"cutoff": false,
		"memo": {},
		"profile": profile,
		"plan": plan,
		"proof_shapes": proof_shapes,
		"proof_origins": proof_origins,
	}
	var path: Array[Dictionary] = []
	var solved := _dfs(state, upper, path, context)
	return {
		"solved": solved,
		"moves": path.size() if solved else -1,
		"path": path.duplicate(true) if solved else [],
		"nodes": int(context["nodes"]),
		"cutoff": bool(context["cutoff"]),
		"uses_64_bit_board": true,
	}

static func find_optimal(profile: Dictionary, plan: Dictionary, max_nodes: int = 350000) -> Dictionary:
	var proof_replay := validate_known_solution(profile, plan)
	if not bool(proof_replay.get("solved", false)):
		return {"solved": false, "optimal_verified": false, "nodes": 0, "reason": "invalid_proof"}
	var upper_bound := maxi(1, int(proof_replay.get("moves", 0)))
	var initial_state := _initial_state(profile, plan)
	if initial_state.is_empty():
		return {"solved": false, "optimal_verified": false, "nodes": 0, "reason": "invalid_state"}

	var start_h := maxi(
		_optimistic_line_move_lower_bound(initial_state, profile, plan),
		_initial_geometry_line_lower_bound(initial_state, profile, plan)
	)
	if start_h > upper_bound:
		return {"solved": false, "optimal_verified": false, "nodes": 0, "reason": "lower_bound_exceeds_proof"}

	# Uniform-cost A* over exact states. The heuristic is admissible: it ignores
	# collisions, special-objective pressure and most geometry, so it can only
	# underestimate moves remaining. Therefore the first goal popped at the
	# lowest f=g+h is an optimal solution.
	var buckets: Array = []
	for _i in range(upper_bound + 1):
		buckets.append([])
	var nodes: Array[Dictionary] = []
	nodes.append({
		"state": initial_state,
		"parent": -1,
		"move": {},
		"g": 0,
	})
	(buckets[start_h] as Array).append(0)
	var seen_depth := {_state_key(initial_state, profile): 0}
	var visited := 0

	for priority in range(start_h, upper_bound + 1):
		var bucket: Array = buckets[priority]
		var cursor := 0
		while cursor < bucket.size():
			var node_index := int(bucket[cursor])
			cursor += 1
			var node: Dictionary = nodes[node_index]
			var state: Dictionary = node["state"]
			var g := int(node["g"])
			visited += 1
			if visited > maxi(1, max_nodes):
				return {
					"solved": false,
					"optimal_verified": false,
					"optimal_moves": -1,
					"nodes": visited,
					"cutoff": true,
					"uses_64_bit_board": true,
				}
			if _goal(state, profile):
				var path := _reconstruct_optimal_path(nodes, node_index)
				return {
					"solved": true,
					"optimal_verified": true,
					"optimal_moves": path.size(),
					"path": path,
					"nodes": visited,
					"cutoff": false,
					"uses_64_bit_board": true,
				}
			if g >= upper_bound:
				continue

			var tray := _current_tray(state, plan)
			if tray.is_empty():
				continue
			var context := {
				"profile": profile,
				"plan": plan,
				"proof_shapes": plan.get("proof_shapes", []),
				"proof_origins": plan.get("proof_origins", []),
			}
			for candidate in _ordered_candidates(state, tray, context):
				var next := _apply_move(
					state,
					int(candidate["shape"]),
					int(candidate["slot"]),
					int(candidate["origin"]),
					profile,
					plan
				)
				if next.is_empty():
					continue
				var next_g := g + 1
				var next_h := _optimistic_line_move_lower_bound(next, profile, plan)
				var next_f := next_g + next_h
				if next_f > upper_bound:
					continue
				var key := _state_key(next, profile)
				if seen_depth.has(key) and int(seen_depth[key]) <= next_g:
					continue
				seen_depth[key] = next_g
				var child_index := nodes.size()
				nodes.append({
					"state": next,
					"parent": node_index,
					"move": candidate.duplicate(true),
					"g": next_g,
				})
				(buckets[next_f] as Array).append(child_index)

	return {
		"solved": false,
		"optimal_verified": false,
		"optimal_moves": -1,
		"nodes": visited,
		"cutoff": false,
		"uses_64_bit_board": true,
	}

static func _reconstruct_optimal_path(nodes: Array[Dictionary], goal_index: int) -> Array[Dictionary]:
	var reverse_path: Array[Dictionary] = []
	var index := goal_index
	while index >= 0:
		var node: Dictionary = nodes[index]
		var move: Dictionary = node.get("move", {})
		if not move.is_empty():
			reverse_path.append(move.duplicate(true))
		index = int(node.get("parent", -1))
	reverse_path.reverse()
	return reverse_path

static func validate_known_solution(profile: Dictionary, plan: Dictionary) -> Dictionary:
	var state := _initial_state(profile, plan)
	if state.is_empty():
		return {"solved": false, "reason": "invalid_state"}
	var shapes: Array = plan.get("proof_shapes", [])
	var origins: Array = plan.get("proof_origins", [])
	if shapes.size() != origins.size() or shapes.is_empty():
		return {"solved": false, "reason": "missing_proof"}
	for i in range(shapes.size()):
		var shape_index := int(shapes[i])
		var origin_cell := int(origins[i])
		var tray := _current_tray(state, plan)
		var slot := _find_unused_shape_slot(tray, int(state["used_mask"]), shape_index)
		if slot < 0:
			return {"solved": false, "reason": "proof_piece_not_in_tray", "move": i}
		var move := _apply_move(state, shape_index, slot, origin_cell, profile, plan)
		if move.is_empty():
			return {"solved": false, "reason": "illegal_proof_move", "move": i}
		state = move
		if _goal(state, profile):
			return {
				"solved": true,
				"moves": i + 1,
				"score": int(state["score"]),
				"lines": int(state["lines"]),
				"uses_64_bit_board": true,
			}
	return {
		"solved": _goal(state, profile),
		"moves": shapes.size(),
		"score": int(state.get("score", 0)),
		"lines": int(state.get("lines", 0)),
		"uses_64_bit_board": true,
	}

static func board_to_mask(board: Array) -> int:
	var mask: int = 0
	for y in range(mini(GRID_SIZE, board.size())):
		var row: Array = board[y]
		for x in range(mini(GRID_SIZE, row.size())):
			if bool(row[x]):
				mask |= (1 << (y * GRID_SIZE + x))
	return mask

static func _initial_state(profile: Dictionary, plan: Dictionary) -> Dictionary:
	var board: Array = plan.get("initial_cells", [])
	var trays: Array = plan.get("trays", [])
	if board.size() != GRID_SIZE or trays.is_empty():
		return {}
	var objective: Dictionary = plan.get("special_plan", {})
	var layers := {}
	var preserve_mask: int = 0
	for raw in (objective.get("specials", []) as Array):
		var special: Dictionary = raw
		var idx := int(special.get("index", -1))
		if idx < 0 or idx >= 64:
			continue
		var kind := String(special.get("kind", ""))
		if kind == "preserve":
			preserve_mask |= (1 << idx)
		elif kind in ["crate", "ice", "lock", "steel", "target"]:
			layers[idx] = maxi(1, int(special.get("layers", 1)))
	var rows_mask := 0
	for raw in (objective.get("target_rows", []) as Array):
		var row := int(raw)
		if row >= 0 and row < 8:
			rows_mask |= (1 << row)
	var cols_mask := 0
	for raw in (objective.get("target_cols", []) as Array):
		var col := int(raw)
		if col >= 0 and col < 8:
			cols_mask |= (1 << col)
	var raw_move_limit := int(profile.get("move_limit", -1))
	var proof_moves := (plan.get("proof_shapes", []) as Array).size()
	var effective_move_limit := -1
	if raw_move_limit > 0:
		effective_move_limit = maxi(raw_move_limit, proof_moves)
	return {
		"board": board_to_mask(board),
		"tray_index": 0,
		"used_mask": 0,
		"score": 0,
		"lines": 0,
		"moves": 0,
		"combo": 0,
		"special_layers": layers,
		"preserve_mask": preserve_mask,
		"rows_pending": rows_mask,
		"cols_pending": cols_mask,
		"double_progress": 0,
		"double_required": maxi(0, int(objective.get("required_double_clears", 0))),
		"moves_remaining": effective_move_limit,
	}

static func _dfs(state: Dictionary, depth_left: int, path: Array[Dictionary], context: Dictionary) -> bool:
	context["nodes"] = int(context["nodes"]) + 1
	if int(context["nodes"]) > int(context["max_nodes"]):
		context["cutoff"] = true
		return false
	var profile: Dictionary = context["profile"]
	if _goal(state, profile):
		return true
	if depth_left <= 0:
		return false

	var plan: Dictionary = context["plan"]
	if _optimistic_line_move_lower_bound(state, profile, plan) > depth_left:
		return false
	var tray := _current_tray(state, plan)
	if tray.is_empty():
		return false
	var key := _state_key(state, profile)
	var memo: Dictionary = context["memo"]
	if memo.has(key) and int(memo[key]) >= depth_left:
		return false
	memo[key] = depth_left
	context["memo"] = memo

	# Try the constructive proof branch first. It is still validated through the
	# exact 64-bit state transition; this avoids enumerating every alternative on
	# all 10,000 release levels when a verified winning branch is already known.
	var move_number := int(state["moves"])
	var proof_shapes: Array = context["proof_shapes"]
	var proof_origins: Array = context["proof_origins"]
	if move_number < proof_shapes.size() and move_number < proof_origins.size():
		var proof_shape := int(proof_shapes[move_number])
		var proof_origin := int(proof_origins[move_number])
		var proof_slot := _find_unused_shape_slot(tray, int(state["used_mask"]), proof_shape)
		if proof_slot >= 0:
			var proof_next := _apply_move(state, proof_shape, proof_slot, proof_origin, profile, plan)
			if not proof_next.is_empty():
				var proof_candidate := {"slot": proof_slot, "shape": proof_shape, "origin": proof_origin, "priority": 1000000}
				path.append(proof_candidate)
				if _dfs(proof_next, depth_left - 1, path, context):
					return true
				path.pop_back()
				if bool(context["cutoff"]):
					return false

	var candidates := _ordered_candidates(state, tray, context)
	for candidate in candidates:
		if move_number < proof_shapes.size() and move_number < proof_origins.size():
			if int(candidate["shape"]) == int(proof_shapes[move_number]) and int(candidate["origin"]) == int(proof_origins[move_number]):
				continue
		var next := _apply_move(
			state,
			int(candidate["shape"]),
			int(candidate["slot"]),
			int(candidate["origin"]),
			profile,
			plan
		)
		if next.is_empty():
			continue
		path.append(candidate)
		if _dfs(next, depth_left - 1, path, context):
			return true
		path.pop_back()
		if bool(context["cutoff"]):
			return false
	return false

static func _ordered_candidates(state: Dictionary, tray: Array, context: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var used_mask := int(state["used_mask"])
	var move_number := int(state["moves"])
	var proof_shapes: Array = context["proof_shapes"]
	var proof_origins: Array = context["proof_origins"]
	var preferred_shape := int(proof_shapes[move_number]) if move_number < proof_shapes.size() else -1
	var preferred_origin := int(proof_origins[move_number]) if move_number < proof_origins.size() else -1

	var seen_shapes := {}
	for slot in range(tray.size()):
		if (used_mask & (1 << slot)) != 0:
			continue
		var shape_index := int(tray[slot])
		if shape_index < 0 or shape_index >= Generator.SHAPES.size():
			continue
		# Identical unused tray pieces are interchangeable. Exploring every slot
		# produces equivalent positions with different bit identities.
		if seen_shapes.has(shape_index):
			continue
		seen_shapes[shape_index] = true
		for origin in _legal_origins(int(state["board"]), int(state["preserve_mask"]), shape_index):
			var priority := 0
			if shape_index == preferred_shape and origin == preferred_origin:
				priority = 1000000
			else:
				var preview := _preview_clear_count(int(state["board"]), shape_index, origin)
				priority = preview * 10000 + Generator.SHAPES[shape_index].size() * 100
			candidates.append({"slot": slot, "shape": shape_index, "origin": origin, "priority": priority})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["priority"]) > int(b["priority"])
	)
	return candidates

static func _apply_move(
	state: Dictionary,
	shape_index: int,
	slot: int,
	origin_cell: int,
	profile: Dictionary,
	plan: Dictionary
) -> Dictionary:
	var tray := _current_tray(state, plan)
	if slot < 0 or slot >= tray.size() or (int(state["used_mask"]) & (1 << slot)) != 0:
		return {}
	if int(tray[slot]) != shape_index:
		return {}
	var placement: Variant = _placement_mask(shape_index, origin_cell)
	if placement == null:
		return {}
	var placement_mask := int(placement)
	var board := int(state["board"])
	if (board & placement_mask) != 0 or (int(state["preserve_mask"]) & placement_mask) != 0:
		return {}

	var next := state.duplicate(true)
	if int(state.get("moves_remaining", -1)) == 0:
		return {}
	if int(state.get("moves_remaining", -1)) > 0:
		next["moves_remaining"] = int(state["moves_remaining"]) - 1
	var filled := board | placement_mask
	var clear_data := _clear_data(filled)
	var clear_mask := int(clear_data["mask"])
	var cleared := int(clear_data["count"])
	next["board"] = filled & ~clear_mask
	next["score"] = int(state["score"]) + Generator.SHAPES[shape_index].size() * 10
	next["lines"] = int(state["lines"]) + cleared
	next["moves"] = int(state["moves"]) + 1
	next["combo"] = int(state["combo"]) + 1 if cleared > 0 else 0
	if cleared > 0:
		next["score"] = int(next["score"]) + cleared * 120 + maxi(0, cleared - 1) * 80
		if cleared >= 2:
			next["double_progress"] = int(state["double_progress"]) + 1

	var rows_pending := int(state["rows_pending"])
	for row in (clear_data["rows"] as Array):
		rows_pending &= ~(1 << int(row))
	next["rows_pending"] = rows_pending
	var cols_pending := int(state["cols_pending"])
	for col in (clear_data["cols"] as Array):
		cols_pending &= ~(1 << int(col))
	next["cols_pending"] = cols_pending

	var layers: Dictionary = (state["special_layers"] as Dictionary).duplicate(true)
	if clear_mask != 0:
		for raw_idx in layers.keys().duplicate():
			var idx := int(raw_idx)
			if (clear_mask & (1 << idx)) == 0:
				continue
			var remain := int(layers[raw_idx]) - 1
			if remain <= 0:
				layers.erase(raw_idx)
			else:
				layers[raw_idx] = remain
	next["special_layers"] = layers

	var used := int(state["used_mask"]) | (1 << slot)
	var tray_index := int(state["tray_index"])
	var full_used_mask := (1 << tray.size()) - 1
	if used == full_used_mask:
		tray_index += 1
		used = 0
	next["tray_index"] = tray_index
	next["used_mask"] = used

	return next

static func _current_tray(state: Dictionary, plan: Dictionary) -> Array:
	var trays: Array = plan.get("trays", [])
	var index := int(state["tray_index"])
	if index < 0 or index >= trays.size():
		return []
	return trays[index] as Array

static func _find_unused_shape_slot(tray: Array, used_mask: int, shape_index: int) -> int:
	for slot in range(tray.size()):
		if (used_mask & (1 << slot)) == 0 and int(tray[slot]) == shape_index:
			return slot
	return -1

static func _goal(state: Dictionary, profile: Dictionary) -> bool:
	if int(state["score"]) < int(profile.get("target_score", 0)):
		return false
	if int(state["lines"]) < int(profile.get("target_lines", 0)):
		return false
	if not (state["special_layers"] as Dictionary).is_empty():
		return false
	if int(state["rows_pending"]) != 0 or int(state["cols_pending"]) != 0:
		return false
	if int(state["double_progress"]) < int(state["double_required"]):
		return false
	return true

static func _legal_origins(board: int, preserve_mask: int, shape_index: int) -> Array[int]:
	var out: Array[int] = []
	for origin in range(64):
		var placement = _placement_mask(shape_index, origin)
		if placement == null:
			continue
		var mask := int(placement)
		if (board & mask) == 0 and (preserve_mask & mask) == 0:
			out.append(origin)
	return out

static func _placement_mask(shape_index: int, origin_cell: int) -> Variant:
	if shape_index < 0 or shape_index >= Generator.SHAPES.size() or origin_cell < 0 or origin_cell >= 64:
		return null
	var origin_x := origin_cell % 8
	var origin_y := int(origin_cell / 8)
	var mask: int = 0
	for raw in (Generator.SHAPES[shape_index] as Array):
		var p: Vector2i = raw
		var x := origin_x + p.x
		var y := origin_y + p.y
		if x < 0 or x >= 8 or y < 0 or y >= 8:
			return null
		mask |= (1 << (y * 8 + x))
	return mask

static func _preview_clear_count(board: int, shape_index: int, origin: int) -> int:
	var placement = _placement_mask(shape_index, origin)
	if placement == null or (board & int(placement)) != 0:
		return -1
	return int(_clear_data(board | int(placement))["count"])

static func _clear_data(board: int) -> Dictionary:
	var rows: Array[int] = []
	var cols: Array[int] = []
	var clear_mask: int = 0
	for y in range(8):
		var row_mask := FULL_ROW << (y * 8)
		if (board & row_mask) == row_mask:
			rows.append(y)
			clear_mask |= row_mask
	for x in range(8):
		var col_mask: int = 0
		for y in range(8):
			col_mask |= (1 << (y * 8 + x))
		if (board & col_mask) == col_mask:
			cols.append(x)
			clear_mask |= col_mask
	return {"mask": clear_mask, "count": rows.size() + cols.size(), "rows": rows, "cols": cols}

static func _initial_geometry_line_lower_bound(state: Dictionary, profile: Dictionary, plan: Dictionary) -> int:
	var remaining_lines := maxi(0, int(profile.get("target_lines", 0)) - int(state.get("lines", 0)))
	if remaining_lines <= 0 or remaining_lines > 2:
		return 0
	var proof_shapes: Array = plan.get("proof_shapes", [])
	if proof_shapes.is_empty():
		return 0
	var line_masks: Array[int] = []
	for y in range(8):
		line_masks.append(FULL_ROW << (y * 8))
	for x in range(8):
		var col_mask: int = 0
		for y in range(8):
			col_mask |= (1 << (y * 8 + x))
		line_masks.append(col_mask)
	var board := int(state.get("board", 0))
	for moves in range(1, proof_shapes.size() + 1):
		if remaining_lines == 1:
			for mask in line_masks:
				var missing_mask := int(mask) & ~board
				var missing_count := _count_bits64(missing_mask)
				if _max_target_cells_with_moves(state, plan, moves, missing_mask) >= missing_count:
					return moves
		else:
			for a in range(line_masks.size()):
				for b in range(a + 1, line_masks.size()):
					var union_mask := int(line_masks[a]) | int(line_masks[b])
					var missing_mask := union_mask & ~board
					var missing_count := _count_bits64(missing_mask)
					if _max_target_cells_with_moves(state, plan, moves, missing_mask) >= missing_count:
						return moves
	return proof_shapes.size() + 1

static func _max_target_cells_with_moves(state: Dictionary, plan: Dictionary, move_count: int, target_mask: int) -> int:
	if move_count <= 0 or target_mask == 0:
		return 0
	var trays: Array = plan.get("trays", [])
	var tray_index := int(state.get("tray_index", 0))
	var current_tray_index := tray_index
	var used_mask := int(state.get("used_mask", 0))
	var moves_left := move_count
	var total := 0
	while moves_left > 0 and tray_index < trays.size():
		var tray: Array = trays[tray_index]
		var capacities: Array[int] = []
		for slot in range(tray.size()):
			if tray_index == current_tray_index and (used_mask & (1 << slot)) != 0:
				continue
			var shape_index := int(tray[slot])
			if shape_index >= 0 and shape_index < Generator.SHAPES.size():
				capacities.append(_shape_target_capacity(shape_index, target_mask))
		if capacities.is_empty():
			tray_index += 1
			used_mask = 0
			continue
		capacities.sort()
		capacities.reverse()
		if moves_left < capacities.size():
			for i in range(moves_left):
				total += capacities[i]
			return total
		for capacity in capacities:
			total += capacity
		moves_left -= capacities.size()
		tray_index += 1
		used_mask = 0
	return total

static func _shape_target_capacity(shape_index: int, target_mask: int) -> int:
	var best := 0
	for origin in range(64):
		var placement: Variant = _placement_mask(shape_index, origin)
		if placement == null:
			continue
		best = maxi(best, _count_bits64(int(placement) & target_mask))
	return best

static func _optimistic_line_move_lower_bound(state: Dictionary, profile: Dictionary, plan: Dictionary) -> int:
	var remaining_lines := maxi(0, int(profile.get("target_lines", 0)) - int(state.get("lines", 0)))
	if remaining_lines <= 0:
		return 0
	var missing_cells := _minimum_missing_cells_for_lines(int(state.get("board", 0)), remaining_lines)
	if missing_cells <= 0:
		return 0
	var proof_shapes: Array = plan.get("proof_shapes", [])
	if proof_shapes.is_empty():
		return 0
	# Find the first move count whose remaining fixed trays could optimistically
	# contribute enough cells. This ignores geometry and clears, so it can only
	# underestimate the true distance and is safe for optimality pruning.
	for moves in range(1, proof_shapes.size() + 1):
		if _max_placeable_cells(state, plan, moves) >= missing_cells:
			return moves
	return proof_shapes.size() + 1

static func _minimum_missing_cells_for_lines(board: int, needed_lines: int) -> int:
	if needed_lines <= 0:
		return 0
	var row_missing: Array[int] = []
	var col_missing: Array[int] = []
	for y in range(8):
		var filled := 0
		for x in range(8):
			if (board & (1 << (y * 8 + x))) != 0:
				filled += 1
		row_missing.append(8 - filled)
	for x in range(8):
		var filled := 0
		for y in range(8):
			if (board & (1 << (y * 8 + x))) != 0:
				filled += 1
		col_missing.append(8 - filled)
	if needed_lines == 1:
		var best := 8
		for value in row_missing:
			best = mini(best, value)
		for value in col_missing:
			best = mini(best, value)
		return best
	if needed_lines == 2:
		var best_pair := 16
		for a in range(8):
			for b in range(a + 1, 8):
				best_pair = mini(best_pair, row_missing[a] + row_missing[b])
				best_pair = mini(best_pair, col_missing[a] + col_missing[b])
		for row in range(8):
			for col in range(8):
				var intersection_missing := 1 if (board & (1 << (row * 8 + col))) == 0 else 0
				best_pair = mini(best_pair, row_missing[row] + col_missing[col] - intersection_missing)
		return best_pair
	# Optimistic union bound for larger goals: r chosen rows/columns occupy at
	# least 8r-floor(r^2/4) distinct cells before considering existing blocks.
	var occupied := _count_bits64(board)
	var r := mini(16, needed_lines)
	var minimum_union := mini(64, 8 * r - int(floor(float(r * r) / 4.0)))
	return maxi(0, minimum_union - occupied)

static func _max_placeable_cells(state: Dictionary, plan: Dictionary, move_count: int) -> int:
	if move_count <= 0:
		return 0
	var trays: Array = plan.get("trays", [])
	var tray_index := int(state.get("tray_index", 0))
	var used_mask := int(state.get("used_mask", 0))
	var moves_left := move_count
	var total := 0
	while moves_left > 0 and tray_index < trays.size():
		var tray: Array = trays[tray_index]
		var sizes: Array[int] = []
		for slot in range(tray.size()):
			if tray_index == int(state.get("tray_index", 0)) and (used_mask & (1 << slot)) != 0:
				continue
			var shape_index := int(tray[slot])
			if shape_index >= 0 and shape_index < Generator.SHAPES.size():
				sizes.append((Generator.SHAPES[shape_index] as Array).size())
		if sizes.is_empty():
			tray_index += 1
			used_mask = 0
			continue
		sizes.sort()
		sizes.reverse()
		if moves_left < sizes.size():
			for i in range(moves_left):
				total += sizes[i]
			return total
		for size_value in sizes:
			total += size_value
		moves_left -= sizes.size()
		tray_index += 1
		used_mask = 0
	return total

static func _count_bits64(value: int) -> int:
	var count := 0
	var bits := value
	while bits != 0:
		bits &= bits - 1
		count += 1
	return count

static func _state_key(state: Dictionary, profile: Dictionary) -> String:
	var layers: Dictionary = state["special_layers"]
	var encoded_layers: Array[String] = []
	for raw_idx in layers.keys():
		encoded_layers.append("%d:%d" % [int(raw_idx), int(layers[raw_idx])])
	encoded_layers.sort()
	# Progress beyond a completed score/line requirement has no effect on future
	# legality, so canonicalize it in the transposition key.
	var score_key := mini(int(state["score"]), maxi(0, int(profile.get("target_score", 0))))
	var lines_key := mini(int(state["lines"]), maxi(0, int(profile.get("target_lines", 0))))
	var double_key := mini(int(state["double_progress"]), int(state["double_required"]))
	return "%d/%d/%d/%d/%d/%d/%d/%d/%d/%s" % [
		int(state["board"]),
		int(state["tray_index"]),
		int(state["used_mask"]),
		score_key,
		lines_key,
		int(state["rows_pending"]),
		int(state["cols_pending"]),
		double_key,
		int(state.get("moves_remaining", -1)),
		",".join(encoded_layers),
	]
