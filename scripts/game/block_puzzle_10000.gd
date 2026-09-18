extends "res://scripts/game/block_puzzle_final_polish.gd"

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")

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
	var p := _profile()
	return {
		"target_score": int(p.get("target_score", 100)),
		"target_lines": int(p.get("target_lines", 2)),
		"par": int(p.get("par", 18)),
	}

func load_level() -> void:
	campaign_profile = Progression.profile(level_number)
	campaign_move_limit = int(campaign_profile.get("move_limit", -1))
	campaign_failed = false

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
		_apply_campaign_prefill()
		piece_batch = 0
		refill_pieces()
		render()
		_save_checkpoint()
	else:
		render()

func refill_pieces() -> void:
	if daily_mode:
		super.refill_pieces()
		return

	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	var tray_rng := RandomNumberGenerator.new()
	tray_rng.seed = int(_profile().get("seed", level_number * 104729)) + piece_batch * 99991
	var tier := int(_profile().get("piece_tier", 1))
	var pool: Array = (TIER_POOLS.get(tier, TIER_POOLS[1]) as Array).duplicate()
	var flex_pool := [0, 1, 2, 3, 4]
	var flex_slot := tray_rng.randi_range(0, 2)

	for i in range(3):
		var shape_index: int
		if i == flex_slot:
			shape_index = int(flex_pool[tray_rng.randi_range(0, flex_pool.size() - 1)])
		else:
			var start_index := 0
			if tier >= 4:
				start_index = int(floor(float(pool.size()) * 0.35))
			elif tier >= 2:
				start_index = int(floor(float(pool.size()) * 0.20))
			shape_index = int(pool[tray_rng.randi_range(start_index, pool.size() - 1)])
		pieces.append(CAMPAIGN_SHAPES[shape_index].duplicate())
		piece_colors.append(COLOR_PALETTE[tray_rng.randi_range(0, COLOR_PALETTE.size() - 1)])
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
			"move_limited": campaign_move_limit > 0
		})
	super.complete_level()

func campaign_profile_for_level(level: int) -> Dictionary:
	return Progression.profile(level)

func deterministic_tray_signature(level: int, batch: int) -> String:
	var old_level := level_number
	var old_profile := campaign_profile
	var old_batch := piece_batch
	var old_pieces := pieces.duplicate(true)
	var old_colors := piece_colors.duplicate(true)
	level_number = clampi(level, 1, Progression.MAX_LEVEL)
	campaign_profile = Progression.profile(level_number)
	piece_batch = maxi(0, batch - 1)
	refill_pieces()
	var signature_parts: PackedStringArray = []
	for shape in pieces:
		var cells_text: PackedStringArray = []
		for raw in shape:
			var p := _as_point(raw)
			cells_text.append("%d:%d" % [p.x, p.y])
		signature_parts.append(",".join(cells_text))
	var signature := "|".join(signature_parts)
	level_number = old_level
	campaign_profile = old_profile
	piece_batch = old_batch
	pieces = old_pieces
	piece_colors = old_colors
	return signature

func _profile() -> Dictionary:
	if campaign_profile.is_empty() or int(campaign_profile.get("level_id", -1)) != level_number:
		campaign_profile = Progression.profile(level_number)
	return campaign_profile

func _apply_campaign_prefill() -> void:
	var ratio := float(_profile().get("initial_occupancy", 0.0))
	var target := clampi(int(round(ratio * float(GRID_SIZE * GRID_SIZE))), 0, 26)
	if target <= 0:
		return

	var board_rng := RandomNumberGenerator.new()
	board_rng.seed = int(_profile().get("seed", level_number * 104729)) + 31337
	var reserve_x := board_rng.randi_range(1, GRID_SIZE - 4)
	var reserve_y := board_rng.randi_range(1, GRID_SIZE - 4)
	var candidates: Array[Vector2i] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if x >= reserve_x and x < reserve_x + 3 and y >= reserve_y and y < reserve_y + 3:
				continue
			candidates.append(Vector2i(x, y))
	_shuffle_points(candidates, board_rng)

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
		cells[point.y][point.x] = true
		cell_colors[point.y][point.x] = COLOR_PALETTE[board_rng.randi_range(0, COLOR_PALETTE.size() - 1)]
		row_load[point.y] += 1
		col_load[point.x] += 1
		placed += 1

func _shuffle_points(values: Array[Vector2i], random: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp

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
