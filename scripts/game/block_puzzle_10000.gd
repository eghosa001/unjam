extends "res://scripts/game/block_puzzle_final_polish.gd"

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const CampaignGenerator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const PremiumGameplayFeedbackLayer = preload("res://scripts/ui/premium_gameplay_feedback.gd")

var premium_feedback: PremiumGameplayFeedback

const VALID_MODES := ["campaign", "endless", "zen", "extreme"]

const BOOSTER_COSTS := {
	"undo": 20,
	"hammer": 45,
	"shuffle": 40,
	"rotate": 30,
}

var play_mode := "campaign"
var campaign_profile: Dictionary = {}
var campaign_plan: Dictionary = {}
var campaign_move_limit := -1
var campaign_failed := false
var campaign_special_cells: Dictionary = {}
var target_rows_pending: Array[int] = []
var target_cols_pending: Array[int] = []
var required_double_clears := 0
var double_clear_progress := 0
var booster_buttons: Dictionary = {}
var booster_uses := {"undo": 0, "hammer": 0, "shuffle": 0, "rotate": 0}
var attempt_number := 1
var attempt_restarts := 0
var attempt_started_msec := 0
var attempt_hint_uses := 0
var attempt_level_marker := -1
var attempt_mode_marker := ""
var attempt_closed := false

func build_ui() -> void:
	super.build_ui()
	_add_booster_bar()
	premium_feedback = PremiumGameplayFeedbackLayer.new()
	premium_feedback.name = "BlockPremiumFeedback"
	add_child(premium_feedback)

func _spawn_clear_feedback(indices: Array[int], line_count: int) -> void:
	super._spawn_clear_feedback(indices, line_count)
	if premium_feedback == null or not is_instance_valid(premium_feedback) or board_shell == null:
		return
	var global_rect := board_shell.get_global_rect()
	var local_rect := Rect2(global_rect.position - global_position, global_rect.size)
	premium_feedback.show_sweep(local_rect, Color("#ff7a66"))
	var center := local_rect.get_center()
	if line_count >= 2:
		premium_feedback.show_banner("%d-LINE BLAST" % line_count, Color("#ff7a66"), Vector2(center.x, maxf(170.0, local_rect.position.y - 18.0)), 196.0)
	elif _clear_streak >= 2:
		premium_feedback.show_banner("COMBO ×%d" % _clear_streak, Color("#ffd166"), Vector2(center.x, maxf(170.0, local_rect.position.y - 18.0)), 184.0)
	if score_label != null:
		MotionSystem.pop(score_label, 0.82)

func _add_booster_bar() -> void:
	var canvas := find_child("FigmaBlock390x844", true, false) as Control
	if canvas == null:
		return
	var existing := canvas.get_node_or_null("CampaignBoosters")
	if existing != null:
		return
	var bar := HBoxContainer.new()
	bar.name = "CampaignBoosters"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 7)
	FigmaReferenceCanvas.set_rect(bar, 17, 649, 349, 54)
	for spec in [
		["undo", "UNDO", "↶"],
		["hammer", "HAMMER", "◆"],
		["shuffle", "SHUFFLE", "⟳"],
		["rotate", "ROTATE", "↻"],
	]:
		var key := String(spec[0])
		var button := FigmaReferenceCanvas.premium_button(
			"%s  %s\n◈ %d" % [String(spec[2]), String(spec[1]), int(BOOSTER_COSTS[key])],
			12,
			Color(1, 0.995, 0.97),
			Color("#7d21d6"),
			15,
			Color(0.75, 0.56, 0.92, 0.56),
			1.3
		)
		button.name = "Booster_%s" % key.capitalize()
		button.custom_minimum_size = Vector2(82, 54)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(_use_booster.bind(key))
		bar.add_child(button)
		booster_buttons[key] = button
	canvas.add_child(bar)
	_refresh_booster_buttons()
	call_deferred("_fit_3d_board_layout")

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
	if play_mode == "zen":
		return "easy"
	if play_mode == "extreme":
		return "hard"
	var p := _profile()
	var score_value := int(p.get("difficulty_score", 50))
	if score_value < 35: return "easy"
	if score_value < 65: return "medium"
	return "hard"

func level_config() -> Dictionary:
	if daily_mode:
		return super.level_config()
	if play_mode in ["endless", "zen"]:
		return {"target_score": 999999999, "target_lines": 999999, "par": 999999}
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
	play_mode = play_mode if play_mode in VALID_MODES else "campaign"
	if attempt_level_marker != level_number or attempt_mode_marker != play_mode:
		attempt_number = 1
		attempt_restarts = 0
		attempt_level_marker = level_number
		attempt_mode_marker = play_mode
	attempt_started_msec = Time.get_ticks_msec()
	attempt_hint_uses = 0
	attempt_closed = false
	campaign_profile = _mode_profile()
	campaign_plan = {}
	campaign_failed = false
	booster_uses = {"undo": 0, "hammer": 0, "shuffle": 0, "rotate": 0}

	if not daily_mode and play_mode in ["campaign", "extreme"]:
		var generation_profile := campaign_profile.duplicate(true)
		if play_mode == "campaign" and level_number <= 10:
			var opening := level_config()
			generation_profile["target_score"] = int(opening.get("target_score", 100))
			generation_profile["target_lines"] = int(opening.get("target_lines", 2))
		if play_mode == "campaign":
			campaign_plan = LevelPack.plan_for_level(level_number, generation_profile)
		else:
			campaign_plan = CampaignGenerator.generate(generation_profile)
		if campaign_plan.is_empty():
			push_error("Block Puzzle %s generator produced no proof for level %d" % [play_mode, level_number])

	_reset_objective_state()
	var proof_moves := int((campaign_plan.get("metadata", {}) as Dictionary).get("proof_moves", 0))
	campaign_move_limit = -1
	if play_mode == "campaign":
		campaign_move_limit = int(campaign_profile.get("move_limit", -1))
		if campaign_move_limit > 0 and proof_moves > 0:
			var margin := 3 if level_number <= 5000 else (2 if level_number < 9000 else 1)
			campaign_move_limit = maxi(campaign_move_limit, proof_moves + margin)
	elif play_mode == "extreme" and proof_moves > 0:
		campaign_move_limit = proof_moves + (2 if level_number < 7500 else 1)

	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	var checkpoint_mode := String(checkpoint.get("play_mode", "campaign"))
	var restoring := (
		not checkpoint.is_empty()
		and int(checkpoint.get("level", -1)) == level_number
		and bool(checkpoint.get("daily", false)) == daily_mode
		and (daily_mode or checkpoint_mode == play_mode)
	)

	super.load_level()
	if daily_mode:
		return

	if not restoring:
		if play_mode in ["campaign", "extreme"]:
			_apply_campaign_plan_board()
		else:
			_apply_free_mode_board()
		piece_batch = 0
		refill_pieces()
		render()
		_save_checkpoint()
	else:
		if play_mode in ["campaign", "extreme"] and ((campaign_move_limit > 0 and placements >= campaign_move_limit and not reached_goal()) or not any_move_available()):
			campaign_failed = true
		render()
	AnalyticsManager.track("block_puzzle_attempt_started", {
		"level": level_number,
		"mode": play_mode,
		"daily": daily_mode,
		"attempt": attempt_number,
		"restarts": attempt_restarts,
		"difficulty_score": int(campaign_profile.get("difficulty_score", -1))
	})

func refill_pieces() -> void:
	if daily_mode:
		super.refill_pieces()
		return
	if play_mode in ["endless", "zen"]:
		_refill_free_mode()
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
	if play_mode == "endless":
		title_label.text = "ENDLESS"
		goal_label.text = "SCORE %d  •  LINES %d" % [score, lines_cleared]
		hint_label.text = "SURVIVE AS LONG AS POSSIBLE  •  NO TARGET"
	elif play_mode == "zen":
		title_label.text = "ZEN"
		goal_label.text = "SCORE %d  •  LINES %d" % [score, lines_cleared]
		hint_label.text = "NO MOVE LIMIT  •  NO GAME OVER"
	else:
		var world := int(campaign_profile.get("world", 1))
		var local_level := int(campaign_profile.get("level_in_world", level_number))
		var score_value := int(campaign_profile.get("difficulty_score", 0))
		var milestone := String(campaign_profile.get("milestone", "normal"))
		title_label.text = ("EXTREME  •  %d" % level_number) if play_mode == "extreme" else "WORLD %d  •  %d" % [world, local_level]
		var move_text := ""
		if campaign_move_limit > 0:
			move_text = "  •  MOVES %d/%d" % [placements, campaign_move_limit]
		goal_label.text = "LINES %d/%d  •  TARGET %d%s%s" % [lines_cleared, target_lines, target_score, move_text, _objective_status_text()]
		_render_special_cells()
		if campaign_failed:
			hint_label.text = "This attempt is blocked. Undo a mistake or restart the same deterministic puzzle."
		elif play_mode == "extreme":
			hint_label.text = "EXTREME  •  DIFFICULTY %d/100  •  NO MERCY" % score_value
		elif milestone != "normal":
			hint_label.text = "%s  •  DIFFICULTY %d/100" % [milestone.replace("_", " ").to_upper(), score_value]
		else:
			# Keep the gameplay surface quiet. Difficulty/planning metadata belongs
			# in level selection; this row is reserved for actionable hint/error text.
			hint_label.text = ""
	_refresh_booster_buttons()

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
	if play_mode in ["endless", "zen"] and not daily_mode:
		return false
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
		if kind in ["crate", "ice", "lock", "steel", "target"] and int(special.get("layers", 0)) > 0:
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
		if play_mode == "zen":
			_reset_zen_board()
			return
		if play_mode == "endless":
			_record_mode_best()
			_fail_campaign("ENDLESS RUN OVER • SCORE %d" % score)
			return
		_fail_campaign("NO LEGAL MOVES")
		return

	selected_piece = -1
	render()
	_save_checkpoint()

func _use_booster(kind: String) -> void:
	if completed or _clear_transition_active:
		return
	match kind:
		"undo":
			if history.is_empty():
				_booster_unavailable("Nothing to undo")
				return
			if not _spend_booster(kind):
				return
			booster_uses[kind] = int(booster_uses.get(kind, 0)) + 1
			undo_move()
		"hammer":
			var target := _hammer_target()
			if target < 0:
				_booster_unavailable("Hammer has no useful target")
				return
			if not _spend_booster(kind):
				return
			booster_uses[kind] = int(booster_uses.get(kind, 0)) + 1
			_apply_hammer(target)
		"shuffle":
			if not _spend_booster(kind):
				return
			booster_uses[kind] = int(booster_uses.get(kind, 0)) + 1
			_apply_shuffle()
		"rotate":
			var index := selected_piece
			if index < 0 or index >= pieces.size() or pieces[index].is_empty():
				_booster_unavailable("Select a block to rotate")
				return
			var rotated := _rotated_shape(pieces[index])
			if _shape_signature(rotated) == _shape_signature(pieces[index]) or not _shape_has_legal_move(rotated):
				_booster_unavailable("That block has no useful rotation")
				return
			if not _spend_booster(kind):
				return
			booster_uses[kind] = int(booster_uses.get(kind, 0)) + 1
			pieces[index] = rotated
			render_pieces()
			render()
			_save_checkpoint()
		_:
			return
	AnalyticsManager.track("block_puzzle_booster_used", {
		"level": level_number,
		"booster": kind,
		"cost": int(BOOSTER_COSTS.get(kind, 0)),
		"uses": int(booster_uses.get(kind, 0))
	})

func _spend_booster(kind: String) -> bool:
	var cost := int(BOOSTER_COSTS.get(kind, 0))
	if cost <= 0:
		return true
	if EconomyManager.spend(cost, "block_puzzle_booster_%s" % kind, {"level": level_number}):
		return true
	_booster_unavailable("Need %d coins for %s" % [cost, kind.capitalize()])
	return false

func _booster_unavailable(message: String) -> void:
	status_label.text = message
	FeedbackManager.blocked()
	_refresh_booster_buttons()

func _hammer_target() -> int:
	for key in campaign_special_cells.keys():
		var special: Dictionary = campaign_special_cells[key]
		if String(special.get("kind", "")) in ["crate", "ice", "lock", "steel"] and int(special.get("layers", 0)) > 0:
			return int(key)
	var best := -1
	var best_fits := -1
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if not bool(cells[y][x]):
				continue
			var idx := y * GRID_SIZE + x
			var special: Dictionary = campaign_special_cells.get(str(idx), {})
			if String(special.get("kind", "")) == "preserve":
				continue
			var old := bool(cells[y][x])
			cells[y][x] = false
			var fits := _current_legal_fit_count(32)
			cells[y][x] = old
			if fits > best_fits:
				best_fits = fits
				best = idx
	return best

func _apply_hammer(index: int) -> void:
	var key := str(index)
	var special: Dictionary = campaign_special_cells.get(key, {})
	var kind := String(special.get("kind", ""))
	if kind in ["crate", "ice", "lock", "steel"]:
		var layers := maxi(0, int(special.get("layers", 1)) - 1)
		if layers <= 0:
			campaign_special_cells.erase(key)
			if kind == "crate":
				var y := int(index / GRID_SIZE)
				var x := index % GRID_SIZE
				cells[y][x] = false
				cell_colors[y][x] = Color.TRANSPARENT
		else:
			special["layers"] = layers
			campaign_special_cells[key] = special
	else:
		var y := int(index / GRID_SIZE)
		var x := index % GRID_SIZE
		cells[y][x] = false
		cell_colors[y][x] = Color.TRANSPARENT
	campaign_failed = false
	selected_piece = -1
	status_label.text = "Hammer opened space"
	FeedbackManager.line_clear(1)
	render()
	_save_checkpoint()

func _apply_shuffle() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = int(_profile().get("seed", level_number * 104729)) + placements * 131071 + int(booster_uses.get("shuffle", 0)) * 524287
	var tier := clampi(int(_profile().get("piece_tier", 1)), 1, 6)
	var pool: Array = (CampaignGenerator.TIER_POOLS.get(tier, CampaignGenerator.TIER_POOLS[1]) as Array)
	pieces.clear()
	piece_colors.clear()
	pieces.append(CampaignGenerator.SHAPES[0].duplicate())
	piece_colors.append(COLOR_PALETTE[random.randi_range(0, COLOR_PALETTE.size() - 1)])
	for _i in range(2):
		var shape_index := int(pool[random.randi_range(0, pool.size() - 1)])
		var shape: Array = CampaignGenerator.SHAPES[shape_index].duplicate()
		if not _shape_has_legal_move(shape):
			shape = CampaignGenerator.SHAPES[random.randi_range(1, 2)].duplicate()
		pieces.append(shape)
		piece_colors.append(COLOR_PALETTE[random.randi_range(0, COLOR_PALETTE.size() - 1)])
	selected_piece = -1
	campaign_failed = false
	status_label.text = "Tray shuffled"
	render()
	_save_checkpoint()

func _rotated_shape(shape: Array) -> Array:
	var rotated: Array[Vector2i] = []
	var min_x := 999
	var min_y := 999
	for raw in shape:
		var p := _as_point(raw)
		var r := Vector2i(-p.y, p.x)
		rotated.append(r)
		min_x = mini(min_x, r.x)
		min_y = mini(min_y, r.y)
	var normalized: Array = []
	for p in rotated:
		normalized.append(Vector2i(p.x - min_x, p.y - min_y))
	return normalized

func _shape_signature(shape: Array) -> String:
	var values: Array[String] = []
	for raw in shape:
		var p := _as_point(raw)
		values.append("%d:%d" % [p.x, p.y])
	values.sort()
	return "|".join(values)

func _shape_has_legal_move(shape: Array) -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if can_place(shape, Vector2i(x, y)):
				return true
	return false

func _current_legal_fit_count(cap: int) -> int:
	var fits := 0
	for shape in pieces:
		if (shape as Array).is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if can_place(shape, Vector2i(x, y)):
					fits += 1
					if fits >= cap:
						return fits
	return fits

func _refresh_booster_buttons() -> void:
	if booster_buttons.is_empty():
		return
	for key in booster_buttons.keys():
		var button = booster_buttons[key] as Button
		if button == null or not is_instance_valid(button):
			continue
		button.disabled = completed or _clear_transition_active
	var undo_button = booster_buttons.get("undo") as Button
	if undo_button != null:
		undo_button.disabled = undo_button.disabled or history.is_empty()
	var rotate_button = booster_buttons.get("rotate") as Button
	if rotate_button != null:
		rotate_button.disabled = rotate_button.disabled or selected_piece < 0 or selected_piece >= pieces.size() or pieces[selected_piece].is_empty()

func show_hint() -> void:
	if completed or _clear_transition_active:
		return
	attempt_hint_uses += 1
	AnalyticsManager.track("block_puzzle_attempt_hint", {
		"level": level_number,
		"mode": play_mode,
		"attempt": attempt_number,
		"hint_number": attempt_hint_uses,
		"placements": placements
	})
	await super.show_hint()

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
	if not completed:
		_track_attempt_end("restart", false)
	attempt_number += 1
	attempt_restarts += 1
	campaign_failed = false
	super.restart_level()

func complete_level() -> void:
	if not attempt_closed:
		_track_attempt_end("complete", true)
	if not daily_mode and play_mode == "extreme":
		_complete_extreme_mode()
		return
	if not daily_mode and play_mode in ["endless", "zen"]:
		return
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
			"objective_family": String((campaign_plan.get("special_plan", {}) as Dictionary).get("family", "score")),
			"play_mode": play_mode
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
		campaign_profile = _mode_profile()
	return campaign_profile

func _mode_profile() -> Dictionary:
	var profile := Progression.profile(level_number)
	if play_mode != "extreme":
		return profile
	profile = profile.duplicate(true)
	profile["difficulty_score"] = mini(100, int(profile.get("difficulty_score", 50)) + 10)
	profile["piece_tier"] = 6
	profile["planning_horizon"] = mini(14, int(profile.get("planning_horizon", 1)) + 3)
	profile["initial_occupancy"] = minf(0.40, float(profile.get("initial_occupancy", 0.0)) + 0.08)
	profile["target_lines"] = mini(16, int(profile.get("target_lines", 2)) + 2)
	profile["target_score"] = int(profile.get("target_score", 100)) + 420
	profile["objective"] = "advanced_conditional"
	profile["move_limited"] = true
	profile["milestone"] = "extreme"
	profile["seed"] = int(profile.get("seed", level_number * 104729)) + 700000001
	return profile

func _refill_free_mode() -> void:
	pieces.clear()
	piece_colors.clear()
	piece_batch += 1
	var random := RandomNumberGenerator.new()
	var salt := 300000007 if play_mode == "endless" else 500000009
	random.seed = level_number * 104729 + piece_batch * 99991 + salt
	var tier := 6 if play_mode == "endless" else 4
	var pool: Array = (CampaignGenerator.TIER_POOLS.get(tier, CampaignGenerator.TIER_POOLS[1]) as Array)
	for i in range(3):
		var shape_index := int(pool[random.randi_range(0, pool.size() - 1)])
		if play_mode == "zen" and i == 0:
			shape_index = random.randi_range(0, 4)
		pieces.append(CampaignGenerator.SHAPES[shape_index].duplicate())
		piece_colors.append(COLOR_PALETTE[random.randi_range(0, COLOR_PALETTE.size() - 1)])
	selected_piece = -1
	if not any_move_available():
		pieces[0] = CampaignGenerator.SHAPES[0].duplicate()

func _apply_free_mode_board() -> void:
	if play_mode == "zen":
		return
	var random := RandomNumberGenerator.new()
	random.seed = level_number * 65537 + 170141
	var candidates: Array[int] = []
	for idx in range(GRID_SIZE * GRID_SIZE):
		candidates.append(idx)
	for i in range(candidates.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var target := 8
	for i in range(target):
		var idx := candidates[i]
		var y := int(idx / GRID_SIZE)
		var x := idx % GRID_SIZE
		cells[y][x] = true
		cell_colors[y][x] = COLOR_PALETTE[random.randi_range(0, COLOR_PALETTE.size() - 1)]

func _reset_zen_board() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			cells[y][x] = false
			cell_colors[y][x] = Color.TRANSPARENT
	campaign_special_cells.clear()
	target_rows_pending.clear()
	target_cols_pending.clear()
	campaign_failed = false
	piece_batch += 1
	refill_pieces()
	selected_piece = -1
	status_label.text = "Fresh space"
	render()
	_save_checkpoint()

func _complete_extreme_mode() -> void:
	if completed:
		return
	completed = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	_record_mode_best()
	FeedbackManager.complete()
	status_label.text = "EXTREME MASTERED"
	AnalyticsManager.track("block_puzzle_extreme_completed", {
		"level": level_number,
		"score": score,
		"lines": lines_cleared,
		"placements": placements
	})
	var result := PremiumResultOverlay.new()
	result.configure(
		"EXTREME COMPLETE",
		"You cleared the expert variant without changing campaign progression.",
		"SCORE %d   •   %d LINES\n%d PLACEMENTS   •   LIMIT %d" % [score, lines_cleared, placements, campaign_move_limit],
		3 if placements <= par_placements else 2,
		Color("ff5f72"),
		"BACK TO LEVELS"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1)
		queue_free()
	)

func _record_mode_best() -> void:
	if play_mode == "campaign" or daily_mode:
		return
	var stats = SaveManager.data.get("block_mode_stats", {})
	if not stats is Dictionary:
		stats = {}
	var mode_stats = (stats as Dictionary).get(play_mode, {})
	if not mode_stats is Dictionary:
		mode_stats = {}
	mode_stats["best_score"] = maxi(int((mode_stats as Dictionary).get("best_score", 0)), score)
	mode_stats["best_lines"] = maxi(int((mode_stats as Dictionary).get("best_lines", 0)), lines_cleared)
	mode_stats["runs"] = int((mode_stats as Dictionary).get("runs", 0)) + 1
	if play_mode == "extreme":
		mode_stats["best_level"] = maxi(int((mode_stats as Dictionary).get("best_level", 0)), level_number)
	(stats as Dictionary)[play_mode] = mode_stats
	SaveManager.data["block_mode_stats"] = stats
	SaveManager.save()

func _quit() -> void:
	if not completed:
		_track_attempt_end("quit", false)
	_record_mode_best()
	super._quit()

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
		if kind not in ["crate", "ice", "lock", "steel", "target"]:
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
			var row_target := row in target_rows_pending
			var col_target := col in target_cols_pending
			if row_target and col_target:
				cell.call("set_special", "cross_target", 1)
				continue
			if row_target:
				cell.call("set_special", "row_target", 1)
				continue
			if col_target:
				cell.call("set_special", "col_target", 1)
				continue
		cell.call("set_special", String(special.get("kind", "")), int(special.get("layers", 0)))

func _objective_status_text() -> String:
	if daily_mode:
		return ""
	var crates := 0
	var ice_layers := 0
	var locks := 0
	var steel_layers := 0
	var targets := 0
	for raw in campaign_special_cells.values():
		var special: Dictionary = raw
		var kind := String(special.get("kind", ""))
		var layers := int(special.get("layers", 0))
		if kind == "crate": crates += layers
		elif kind == "ice": ice_layers += layers
		elif kind == "lock": locks += layers
		elif kind == "steel": steel_layers += layers
		elif kind == "target": targets += layers
	var parts := PackedStringArray()
	if crates > 0: parts.append("CRATE %d" % crates)
	if ice_layers > 0: parts.append("ICE %d" % ice_layers)
	if locks > 0: parts.append("LOCK %d" % locks)
	if steel_layers > 0: parts.append("STEEL %d" % steel_layers)
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
	checkpoint["play_mode"] = play_mode
	checkpoint["booster_uses"] = booster_uses.duplicate(true)
	MultiGameManager.save_checkpoint(GAME_ID, checkpoint)

func _restore_checkpoint() -> void:
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number:
		return
	if not daily_mode and String(checkpoint.get("play_mode", "campaign")) != play_mode:
		return
	super._restore_checkpoint()
	checkpoint = MultiGameManager.checkpoint(GAME_ID)
	var saved_specials = checkpoint.get("campaign_special_cells", null)
	if saved_specials is Dictionary:
		campaign_special_cells = (saved_specials as Dictionary).duplicate(true)
	target_rows_pending = _to_int_array(checkpoint.get("target_rows_pending", target_rows_pending))
	target_cols_pending = _to_int_array(checkpoint.get("target_cols_pending", target_cols_pending))
	required_double_clears = maxi(0, int(checkpoint.get("required_double_clears", required_double_clears)))
	double_clear_progress = maxi(0, int(checkpoint.get("double_clear_progress", double_clear_progress)))
	campaign_failed = bool(checkpoint.get("campaign_failed", false))
	var saved_boosters = checkpoint.get("booster_uses", null)
	if saved_boosters is Dictionary:
		booster_uses = (saved_boosters as Dictionary).duplicate(true)

func _track_attempt_end(outcome: String, success: bool) -> void:
	if attempt_closed:
		return
	attempt_closed = true
	var elapsed_seconds := maxf(0.0, float(Time.get_ticks_msec() - attempt_started_msec) / 1000.0)
	var booster_total := 0
	for value in booster_uses.values():
		booster_total += int(value)
	AnalyticsManager.track("block_puzzle_attempt_finished", {
		"level": level_number,
		"mode": play_mode,
		"daily": daily_mode,
		"attempt": attempt_number,
		"first_attempt_success": success and attempt_number == 1,
		"success": success,
		"outcome": outcome,
		"moves": placements,
		"lines": lines_cleared,
		"score": score,
		"restarts": attempt_restarts,
		"hint_uses": attempt_hint_uses,
		"booster_uses": booster_total,
		"booster_breakdown": booster_uses.duplicate(true),
		"elapsed_seconds": elapsed_seconds,
		"difficulty_score": int(campaign_profile.get("difficulty_score", -1))
	})

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
		"batch": piece_batch,
		"play_mode": play_mode
	})
	render()
	_save_checkpoint()
