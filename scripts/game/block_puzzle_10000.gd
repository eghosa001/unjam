extends "res://scripts/game/block_puzzle_final_polish.gd"

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const CampaignGenerator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")

# Fixed-orientation campaign library. The first five shapes remain flexible;
# higher tiers progressively unlock space-demanding polyominoes.
const CAMPAIGN_SHAPES := [
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

var campaign_profile: Dictionary = {}
var campaign_plan: Dictionary = {}
var campaign_move_limit := -1
var campaign_failed := false

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
		campaign_plan = CampaignGenerator.generate(generation_profile)
		if campaign_plan.is_empty():
			push_error("Block Puzzle campaign generator produced no proof for level %d" % level_number)
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
		var shape_index := clampi(int(raw_index), 0, CAMPAIGN_SHAPES.size() - 1)
		pieces.append(CAMPAIGN_SHAPES[shape_index].duplicate())
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
	goal_label.text = "LINES %d/%d  •  TARGET %d%s" % [lines_cleared, target_lines, target_score, move_text]
	if campaign_failed:
		hint_label.text = "This attempt is blocked. Undo a mistake or restart the same deterministic puzzle."
	elif milestone != "normal":
		hint_label.text = "%s  •  DIFFICULTY %d/100" % [milestone.replace("_", " ").to_upper(), score_value]
	else:
		hint_label.text = "DIFFICULTY %d/100  •  PLAN %d+ MOVES AHEAD" % [
			score_value,
			int(campaign_profile.get("planning_horizon", 1))
		]

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
		"rng_state": rng.state
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
	campaign_failed = false
	status_label.text = ""
	super.undo_move()
	render()

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
			"constructive_verified": bool((campaign_plan.get("metadata", {}) as Dictionary).get("verified_constructive", false))
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
	return CampaignGenerator.generate(p)

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
