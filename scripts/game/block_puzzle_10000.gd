extends "res://scripts/game/block_puzzle_final_polish.gd"

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const CampaignGenerator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")

var campaign_profile: Dictionary = {}
var campaign_plan: Dictionary = {}
var campaign_move_limit := -1
var campaign_failed := false
var campaign_special_cells: Dictionary = {}
var target_rows_pending: Array[int] = []
var target_cols_pending: Array[int] = []
var required_double_clears := 0
var double_clear_progress := 0

func block_progression_band(level: int = level_number) -> String:
	# Preserve the public band contract used by existing tests/UI while the
	# detailed 0-100 score is exposed through campaign_profile.
	if level <= 1: return "starter"
	if level <= 5: return "standard"
	if level <= 10: return "challenge"
	if level <= 30: return "medium"
	if level <= 130: return "hard"
	return "expert"

func difficulty() -> String:
	if daily_mode:
		return super.difficulty()
	var p := _profile()
	var score_value := int(p.get("difficulty_score", 50))
	if score_value < 35: return "easy"
	if score_value < 65: return "medium"
	return "hard"

func level_config() -> Dictionary:
	if daily_mode:
		return super.level_config()
	var target_score_value := int(_profile().get("target_score", 100))
	var target_lines_value := int(_profile().get("target_lines", 2))
	var par_value := int(_profile().get("par", 18))
	# Preserve the deliberately fast onboarding contract already proven by the
	# production tests: the first ten levels teach, then campaign math takes over.
	if level_number <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		var pars := [18, 18, 20, 20, 21, 22, 22, 23, 24, 24]
		var i := clampi(level_number - 1, 0, 9)
		target_score_value = scores[i]
		target_lines_value = lines[i]
		par_value = pars[i]
	var proof_moves := int((campaign_plan.get("metadata", {}) as Dictionary).get("proof_moves", 0))
	if proof_moves > 0:
		par_value = maxi(par_value, proof_moves)
	return {"target_score": target_score_value, "target_lines": target_lines_value, "par": par_value}

func load_level() -> void:
	campaign_profile = Progression.profile(level_number)
	campaign_plan = {}
	campaign_failed = false
	if not daily_mode:
		var generation_profile := campaign_profile.duplicate(true)
		if level_number <= 10:
			var opening := level_config()
			generation_profile["target_score"] = int(opening.get("target_score", 100))
			generation_profile["target_lines"] = int(opening.get("target_lines", 2))
		campaign_plan = LevelPack.plan_for_level(level_number, generation_profile)
		if campaign_plan.is_empty():
			push_error("Block Puzzle campaign generator produced no proof for level %d" % level_number)
	_reset_objective_state()
	var proof_moves := int((campaign_plan.get("metadata", {}) as Dictionary).get("proof_moves", 0))
	campaign_move_limit = int(campaign_profile.get("move_limit", -1))
	if campaign_move_limit > 0 and proof_moves > 0:
		var margin := 3 if level_number <= 5000 else (2 if level_number < 9000 else 1)
		campaign_move_limit = maxi(campaign_move_limit, proof_moves + margin)

	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	var restoring := (
		not checkpoint.is_empty()
		and int(checkpoint.get("level", -1)) == level_number
		and bool(checkpoint.get("daily", false)) == daily_mode
	)

	super.load_level()
	if daily_mode:
		return

	if not restoring:
		_apply_campaign_plan_board()
		piece_batch = 0
		refill_pieces()
		render()
		_save_checkpoint()
	else:
		if (campaign_move_limit > 0 and placements >= campaign_move_limit and not reached_goal()) or not any_move_available():
			campaign_failed = true
		render()

func refill_pieces() -> void:
	if daily_mode:
		super.refill_pieces()
		return

	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	var trays: Array = campaign_plan.get("trays", [])
	var tray_index := piece_batch - 1
	if tray_index < 0 or tray_index >= trays.size():
		selected_piece = -1
		return
	var tray: Array = trays[tray_index]
	var color_rng := RandomNumberGenerator.new()
	color_rng.seed = int(_profile().get("seed", level_number * 104729)) + piece_batch * 99991
	for raw_index in tray:
		var shape_index := clampi(int(raw_index), 0, CampaignGenerator.SHAPES.size() - 1)
		pieces.append(CampaignGenerator.SHAPES[shape_index].duplicate())
		piece_colors.append(COLOR_PALETTE[color_rng.randi_range(0, COLOR_PALETTE.size() - 1)])
	selected_piece = -1

func render() -> void:
	super.render()
	if daily_mode or campaign_profile.is_empty():
		return
	var world := int(campaign_profile.get("world", 1))
	var local_level := int(campaign_profile.get("level_in_world", level_number))
	var score_value := int(campaign_profile.get("difficulty_score", 0))
	var milestone := String(campaign_profile.get("milestone", "normal"))
	title_label.text = "WORLD %d  •  %d" % [world, local_level]
	var move_text := ""
	if campaign_move_limit > 0:
		move_text = "  •  MOVES %d/%d" % [placements, campaign_move_limit]
	goal_label.text = "LINES %d/%d  •  TARGET %d%s%s" % [lines_cleared, target_lines, target_score, move_text, _objective_status_text()]
	_render_special_cells()
	if campaign_failed:
		hint_label.text = "This attempt is blocked. Undo a mistake or restart the same deterministic puzzle."
	elif milestone != "normal":
		hint_label.text = "%s  •  DIFFICULTY %d/100" % [milestone.replace("_", " ").to_upper(), score_value]
	else:
		hint_label.text = "DIFFICULTY %d/100  •  PLAN %d+ MOVES AHEAD" % [
			score_value,
			int(campaign_profile.get("planning_horizon", 1))
		]

func can_place(shape: Array, origin: Vector2i) -> bool:
	if not super.can_place(shape, origin):
		return false
	if daily_mode:
		return true
	for raw in shape:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		var idx := (origin.y + point.y) * GRID_SIZE + origin.x + point.x
		var special: Dictionary = campaign_special_cells.get(str(idx), {})
		if String(special.get("kind", "")) == "preserve" and int(special.get("layers", 0)) > 0:
			return false
	return true

func reached_goal() -> bool:
	if not super.reached_goal():
		return false
	if daily_mode:
		return true
	if not target_rows_pending.is_empty() or not target_cols_pending.is_empty():
		return false
	if double_clear_progress < required_double_clears:
		return false
	for raw in campaign_special_cells.values():
		var special: Dictionary = raw
		var kind := String(special.get("kind", ""))
		if kind in ["crate", "ice", "target"] and int(special.get("layers", 0)) > 0:
			return false
	return true

func place_selected(origin: Vector2i) -> void:
	if daily_mode:
		await super.place_selected(origin)
		return
	if completed or campaign_failed or _clear_transition_active:
		return
	if selected_piece < 0 or selected_piece >= pieces.size():
		status_label.text = "Choose a block"
		return
	var shape: Array = pieces[selected_piece]
	if shape.is_empty():
		return
	if not can_place(shape, origin):
		status_label.text = "Doesn't fit"
		_invalid_bump()
		return

	history.append({
		"cells": cells.duplicate(true),
		"cell_colors": cell_colors.duplicate(true),
		"pieces": pieces.duplicate(true),
		"piece_colors": piece_colors.duplicate(true),
		"selected": selected_piece,
		"score": score,
		"lines": lines_cleared,
		"placements": placements,
		"batch": piece_batch,
		"rng_state": rng.state,
		"campaign_special_cells": campaign_special_cells.duplicate(true),
		"target_rows_pending": target_rows_pending.duplicate(),
		"target_cols_pending": target_cols_pending.duplicate(),
		"double_clear_progress": double_clear_progress
	})
	if history.size() > 5:
		history.pop_front()

	var placed_color: Color = piece_colors[selected_piece]
	var placed_indices: Array[int] = []
	for raw in shape:
		var point := _as_point(raw)
		if point.x < 0 or point.y < 0:
			continue
		var px: int = origin.x + point.x
		var py: int = origin.y + point.y
		cells[py][px] = true
		cell_colors[py][px] = placed_color
		placed_indices.append(py * GRID_SIZE + px)
	pieces[selected_piece] = []
	placements += 1
	var placement_score := shape.size() * 10
	score += placement_score

	_sync_placed_cells(placed_indices, placed_color)
	render_pieces()
	_play_place_feedback(placed_indices, placed_color, placement_score)

	var clear_plan := _plan_line_clear()
	var cleared := int(clear_plan.get("line_count", 0))
	if cleared > 0:
		_clear_transition_active = true
		await _animate_line_clear(clear_plan)
		if not is_inside_tree():
			return
		_commit_line_clear(clear_plan)
		_apply_objective_clear(clear_plan)
		_clear_transition_active = false
		lines_cleared += cleared
		score += cleared * 120 + maxi(0, cleared - 1) * 80
		_spawn_score_popup("+%d" % (cleared * 120 + maxi(0, cleared - 1) * 80), Color("ff665e"), 0.18)

	if reached_goal():
		complete_level()
		return

	if campaign_move_limit > 0 and placements >= campaign_move_limit:
		_fail_campaign("MOVE LIMIT REACHED")
		return

	if all_pieces_used():
		refill_pieces()

	if not any_move_available():
		_fail_campaign("NO LEGAL MOVES")
		return

	selected_piece = -1
	render()
	_save_checkpoint()

func undo_move() -> void:
	if daily_mode:
		super.undo_move()
		return
	if history.is_empty() or completed or _clear_transition_active:
		return
	var state: Dictionary = history.pop_back()
	cells = _normalize_cells(state.get("cells", []))
	cell_colors = _normalize_cell_colors(state.get("cell_colors", []))
	pieces = _normalize_pieces(state.get("pieces", []))
	piece_colors = _normalize_piece_colors(state.get("piece_colors", []), pieces.size())
	selected_piece = int(state.get("selected", -1))
	score = int(state.get("score", 0))
	lines_cleared = int(state.get("lines", 0))
	placements = int(state.get("placements", 0))
	piece_batch = int(state.get("batch", 0))
	rng.state = int(state.get("rng_state", rng.state))
	campaign_special_cells = (state.get("campaign_special_cells", campaign_special_cells) as Dictionary).duplicate(true)
	target_rows_pending = _to_int_array(state.get("target_rows_pending", target_rows_pending))
	target_cols_pending = _to_int_array(state.get("target_cols_pending", target_cols_pending))
	double_clear_progress = int(state.get("double_clear_progress", double_clear_progress))
	campaign_failed = false
	status_label.text = ""
	SaveManager.record_undo()
	render()
	_save_checkpoint()

func restart_level() -> void:
	campaign_failed = false
	super.restart_level()

func complete_level() -> void:
	if not daily_mode:
		AnalyticsManager.track("block_puzzle_campaign_profile", {
			"level": level_number,
			"world": int(_profile().get("world", 1)),
			"difficulty_score": int(_profile().get("difficulty_score", 0)),
			"piece_tier": int(_profile().get("piece_tier", 1)),
			"planning_horizon": int(_profile().get("planning_horizon", 1)),
			"milestone": String(_profile().get("milestone", "normal")),
			"move_limited": campaign_move_limit > 0,
			"proof_moves": int((campaign_plan.get("metadata", {}) as Dictionary).get("proof_moves", 0)),
			"constructive_verified": bool((campaign_plan.get("metadata", {}) as Dictionary).get("verified_constructive", false)),
			"objective_family": String((campaign_plan.get("special_plan", {}) as Dictionary).get("family", "score"))
		})
	super.complete_level()

func campaign_profile_for_level(level: int) -> Dictionary:
	return Progression.profile(level)

func campaign_plan_for_level(level: int) -> Dictionary:
	var p := Progression.profile(level)
	if level <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		var i := clampi(level - 1, 0, 9)
		p["target_score"] = scores[i]
		p["target_lines"] = lines[i]
	return LevelPack.plan_for_level(level, p)

func deterministic_tray_signature(level: int, batch: int) -> String:
	var plan := campaign_plan_for_level(clampi(level, 1, Progression.MAX_LEVEL))
	var trays: Array = plan.get("trays", [])
	var tray_index := maxi(0, batch - 1)
	if tray_index >= trays.size():
		return ""
	var parts: PackedStringArray = []
	for raw_index in (trays[tray_index] as Array):
		parts.append(str(int(raw_index)))
	return "|".join(parts)

func _profile() -> Dictionary:
	if campaign_profile.is_empty() or int(campaign_profile.get("level_id", -1)) != level_number:
		campaign_profile = Progression.profile(level_number)
	return campaign_profile

func _apply_campaign_plan_board() -> void:
	var initial: Array = campaign_plan.get("initial_cells", [])
	if initial.size() != GRID_SIZE:
		return
	for y in range(GRID_SIZE):
		var row: Array = initial[y]
		if row.size() != GRID_SIZE:
			continue
		for x in range(GRID_SIZE):
			cells[y][x] = bool(row[x])
			cell_colors[y][x] = COLOR_PALETTE[posmod(x * 7 + y * 11 + level_number, COLOR_PALETTE.size())] if bool(row[x]) else Color.TRANSPARENT

func _reset_objective_state() -> void:
	campaign_special_cells.clear()
	target_rows_pending.clear()
	target_cols_pending.clear()
	required_double_clears = 0
	double_clear_progress = 0
	if daily_mode:
		return
	var objective_plan: Dictionary = campaign_plan.get("special_plan", {})
	for raw in (objective_plan.get("specials", []) as Array):
		var special: Dictionary = raw
		var idx := int(special.get("index", -1))
		if idx < 0 or idx >= GRID_SIZE * GRID_SIZE:
			continue
		campaign_special_cells[str(idx)] = {
			"kind": String(special.get("kind", "")),
			"layers": maxi(1, int(special.get("layers", 1)))
		}
	target_rows_pending = _to_int_array(objective_plan.get("target_rows", []))
	target_cols_pending = _to_int_array(objective_plan.get("target_cols", []))
	required_double_clears = maxi(0, int(objective_plan.get("required_double_clears", 0)))

func _apply_objective_clear(clear_plan: Dictionary) -> void:
	for raw in (clear_plan.get("rows", []) as Array):
		target_rows_pending.erase(int(raw))
	for raw in (clear_plan.get("cols", []) as Array):
		target_cols_pending.erase(int(raw))
	if int(clear_plan.get("line_count", 0)) >= 2:
		double_clear_progress += 1
	for raw in (clear_plan.get("indices", []) as Array):
		var key := str(int(raw))
		if not campaign_special_cells.has(key):
			continue
		var special: Dictionary = campaign_special_cells[key]
		var kind := String(special.get("kind", ""))
		if kind not in ["crate", "ice", "target"]:
			continue
		var layers := maxi(0, int(special.get("layers", 0)) - 1)
		if layers <= 0:
			campaign_special_cells.erase(key)
		else:
			special["layers"] = layers
			campaign_special_cells[key] = special

func _render_special_cells() -> void:
	for i in range(cell_buttons.size()):
		var cell = cell_buttons[i]
		if cell == null or not is_instance_valid(cell) or not cell.has_method("set_special"):
			continue
		var special: Dictionary = campaign_special_cells.get(str(i), {})
		if special.is_empty():
			var row := int(i / GRID_SIZE)
			var col := i % GRID_SIZE
			if row in target_rows_pending or col in target_cols_pending:
				cell.call("set_special", "target", 1)
				continue
		cell.call("set_special", String(special.get("kind", "")), int(special.get("layers", 0)))

func _objective_status_text() -> String:
	if daily_mode:
		return ""
	var crates := 0
	var ice_layers := 0
	var targets := 0
	for raw in campaign_special_cells.values():
		var special: Dictionary = raw
		var kind := String(special.get("kind", ""))
		var layers := int(special.get("layers", 0))
		if kind == "crate": crates += layers
		elif kind == "ice": ice_layers += layers
		elif kind == "target": targets += layers
	var parts := PackedStringArray()
	if crates > 0: parts.append("CRATE %d" % crates)
	if ice_layers > 0: parts.append("ICE %d" % ice_layers)
	if targets > 0: parts.append("TARGET %d" % targets)
	if not target_rows_pending.is_empty(): parts.append("ROW %d" % target_rows_pending.size())
	if not target_cols_pending.is_empty(): parts.append("COL %d" % target_cols_pending.size())
	var doubles_left := maxi(0, required_double_clears - double_clear_progress)
	if doubles_left > 0: parts.append("DOUBLE %d" % doubles_left)
	return "" if parts.is_empty() else "  •  " + " / ".join(parts)

func _to_int_array(raw: Variant) -> Array[int]:
	var out: Array[int] = []
	if raw is Array:
		for value in raw:
			out.append(int(value))
	return out

func _save_checkpoint() -> void:
	super._save_checkpoint()
	if daily_mode or completed:
		return
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty():
		return
	checkpoint["campaign_special_cells"] = campaign_special_cells.duplicate(true)
	checkpoint["target_rows_pending"] = target_rows_pending.duplicate()
	checkpoint["target_cols_pending"] = target_cols_pending.duplicate()
	checkpoint["required_double_clears"] = required_double_clears
	checkpoint["double_clear_progress"] = double_clear_progress
	checkpoint["campaign_failed"] = campaign_failed
	MultiGameManager.save_checkpoint(GAME_ID, checkpoint)

func _restore_checkpoint() -> void:
	super._restore_checkpoint()
	if daily_mode:
		return
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number:
		return
	var saved_specials = checkpoint.get("campaign_special_cells", null)
	if saved_specials is Dictionary:
		campaign_special_cells = (saved_specials as Dictionary).duplicate(true)
	target_rows_pending = _to_int_array(checkpoint.get("target_rows_pending", target_rows_pending))
	target_cols_pending = _to_int_array(checkpoint.get("target_cols_pending", target_cols_pending))
	required_double_clears = maxi(0, int(checkpoint.get("required_double_clears", required_double_clears)))
	double_clear_progress = maxi(0, int(checkpoint.get("double_clear_progress", double_clear_progress)))
	campaign_failed = bool(checkpoint.get("campaign_failed", false))

func _fail_campaign(reason: String) -> void:
	campaign_failed = true
	selected_piece = -1
	status_label.text = reason
	FeedbackManager.blocked()
	AnalyticsManager.track("block_puzzle_attempt_blocked", {
		"level": level_number,
		"reason": reason,
		"placements": placements,
		"difficulty_score": int(_profile().get("difficulty_score", 0)),
		"batch": piece_batch
	})
	render()
	_save_checkpoint()
