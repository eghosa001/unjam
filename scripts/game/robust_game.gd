extends "res://scripts/game/game.gd"

var hints_used_this_level := 0

func try_move(index: int) -> void:
	if board_locked:
		return
	hint_label.text = ""
	if not is_path_clear(index):
		chain_count = 0
		hint_label.text = "Blocked — clear its path first."
		FeedbackManager.blocked()
		shake_board()
		AnalyticsManager.track("blocked_move", {"level": level_number, "piece": index})
		return
	board_locked = true
	var legal_before: Dictionary = _legal_map()
	history.append(snapshot())
	moves += 1
	chain_count = 1
	FeedbackManager.escape(chain_count)
	escape_piece(index, true)
	await get_tree().create_timer(0.07).timeout
	await _resolve_cascades(legal_before)
	await resolve_rescue()
	if not rescued:
		render_board()
	board_locked = false

func _legal_map() -> Dictionary:
	var result: Dictionary = {}
	for i in range(pieces.size()):
		result[i] = is_path_clear(i)
	return result

func _resolve_cascades(previous_legal: Dictionary) -> void:
	var baseline: Dictionary = previous_legal.duplicate()
	var guard: int = 0
	var max_steps: int = max(8, pieces.size() * 2)
	while guard < max_steps:
		guard += 1
		var newly_opened: Array[int] = []
		for i in range(pieces.size()):
			if not bool(pieces[i].get("active", true)):
				continue
			if is_path_clear(i) and not bool(baseline.get(i, false)):
				newly_opened.append(i)
		if newly_opened.is_empty():
			break
		var before_batch: Dictionary = _legal_map()
		for index in newly_opened:
			if index < 0 or index >= pieces.size():
				continue
			if not bool(pieces[index].get("active", true)) or not is_path_clear(index):
				continue
			chain_count += 1
			FeedbackManager.escape(chain_count)
			escape_piece(index, true)
			PremiumVisuals.burst(Vector2(540, 860), world_accent(), mini(18, 5 + chain_count))
			await get_tree().create_timer(0.045).timeout
		baseline = before_batch
	if chain_count >= 3:
		AnalyticsManager.track("cascade", {"level": level_number, "chain": chain_count})

func complete_level() -> void:
	var stars := 3
	if moves > par_moves:
		stars = 2
	if moves > par_moves + 3:
		stars = 1
	completion_rewards = {}
	if daily_mode:
		SaveManager.complete_daily(String(level_data.get("daily_key", DailyChallenge.date_key())), 100)
	else:
		completion_rewards = SaveManager.complete_level(level_number, stars, rescue_id, 25 * stars)
		RetentionManager.record_level_complete(level_number, stars, moves, par_moves, chain_count, rescue_id, hints_used_this_level)
	AdManager.note_level_completed()
	AnalyticsManager.level_completed(level_number, moves, stars)
	AnalyticsManager.track("level_quality", {
		"level": level_number,
		"moves": moves,
		"par": par_moves,
		"chain": chain_count,
		"hints": hints_used_this_level,
		"difficulty": String(level_data.get("difficulty", "tutorial")),
		"daily": daily_mode
	})
	show_result(stars)

func show_hint() -> void:
	if board_locked or rescued:
		return
	hints_used_this_level += 1
	SaveManager.record_hint()
	FeedbackManager.tap()
	AnalyticsManager.hint_used(level_number)
	var index := PuzzleSolver.first_solution_move(level_data, pieces, 6000)
	if index >= 0 and index < pieces.size():
		var p: Dictionary = pieces[index]
		var row := int(p.get("y", 0)) + 1
		var column := int(p.get("x", 0)) + 1
		var type := String(p.get("type", "normal")).capitalize()
		hint_label.text = "Solution hint: move the %s at row %d, column %d." % [type, row, column]
		return
	if rescue_has_exit():
		hint_label.text = "The rescue route is open — make any valid finishing move."
		return
	var any_legal := false
	for i in range(pieces.size()):
		if is_path_clear(i):
			any_legal = true
			break
	if any_legal:
		hint_label.text = "This position has no verified solution. Undo your last move and try a different order."
	else:
		hint_label.text = "Dead end. Use Undo or Restart to recover."
	PremiumVisuals.screen_flash(Color("ffb347"), 0.08)

func undo_move() -> void:
	if history.is_empty() or rescued or board_locked:
		return
	super.undo_move()
	AnalyticsManager.undo_used(level_number)

func restart_level() -> void:
	AnalyticsManager.level_restarted(level_number)
	var replacement := load("res://scenes/Game.tscn").instantiate()
	replacement.level_number = level_number
	replacement.custom_level_data = custom_level_data.duplicate(true)
	replacement.daily_mode = daily_mode
	replacement.finished.connect(func(n): finished.emit(n))
	replacement.quit_requested.connect(func(): quit_requested.emit())
	get_parent().add_child(replacement)
	queue_free()
