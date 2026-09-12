extends "res://scripts/game/game.gd"

var hints_used_this_level := 0
var checkpoint_restored := false

func _ready() -> void:
	super._ready()
	_restore_checkpoint()

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
		_save_checkpoint()
	board_locked = false

func _legal_map() -> Dictionary:
	var result: Dictionary = {}
	for i in range(pieces.size()):
		result[i] = is_path_clear(i)
	return result

func _resolve_cascades(previous_legal: Dictionary) -> void:
	var baseline: Dictionary = previous_legal.duplicate()
	var guard: int = 0
	var max_steps: int = maxi(8, pieces.size() * 2)
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
	_clear_checkpoint(false)
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

func show_result(stars: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.022, 0.05, 0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	add_child(overlay)
	var fade := create_tween()
	fade.tween_property(overlay, "modulate:a", 1.0, 0.18)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-345, -445)
	panel.custom_minimum_size = Vector2(690, 890)
	panel.add_theme_stylebox_override("panel", style_box(Color("111f38"), 38, world_accent(), 3))
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	var token := RescueToken.new()
	token.custom_minimum_size = Vector2(180, 180)
	token.configure(rescue_id, Color("ffd166"))
	box.add_child(token)
	var title := Label.new()
	title.text = "DAILY COMPLETE" if daily_mode else "RESCUE COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)
	var star_label := Label.new()
	star_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 56)
	star_label.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(star_label)

	var base_reward := 100 if daily_mode else int(completion_rewards.get("base_coins", 0))
	var bonus_reward := 0 if daily_mode else int(completion_rewards.get("bonus_coins", 0))
	var total_reward := base_reward + bonus_reward
	var stats := Label.new()
	if total_reward > 0:
		stats.text = "%d MOVES   •   +%d COINS" % [moves, total_reward]
	else:
		stats.text = "%d MOVES   •   BEST REWARD ALREADY CLAIMED" % moves
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 22)
	box.add_child(stats)
	var premium_summary := reward_summary()
	if not premium_summary.is_empty():
		var reward_card := PanelContainer.new()
		reward_card.custom_minimum_size = Vector2(560, 120)
		reward_card.add_theme_stylebox_override("panel", style_box(Color(world_accent(),0.12), 24, Color(world_accent(),0.55), 2))
		var reward_label := Label.new()
		reward_label.text = premium_summary
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_label.add_theme_font_size_override("font_size", 18)
		reward_card.add_child(reward_label)
		box.add_child(reward_card)
		PremiumVisuals.burst(Vector2(540, 540), world_accent(), 24)

	var double_reward := Button.new()
	double_reward.text = "DOUBLE BASE REWARD" if base_reward > 0 else "REWARD ALREADY CLAIMED"
	double_reward.custom_minimum_size = Vector2(470, 82)
	double_reward.add_theme_font_size_override("font_size", 23)
	style_button(double_reward, true)
	double_reward.disabled = base_reward <= 0
	double_reward.pressed.connect(func():
		if base_reward <= 0:
			return
		double_reward.disabled = true
		AdManager.show_rewarded("double_reward", func(): SaveManager.add_coins(base_reward))
		double_reward.text = "BASE REWARD DOUBLED"
	)
	box.add_child(double_reward)

	var next := Button.new()
	next.text = "BACK HOME" if daily_mode else ("NEXT RESCUE" if LevelManager.has_level(level_number + 1) else "CAMPAIGN COMPLETE")
	next.custom_minimum_size = Vector2(470, 88)
	next.add_theme_font_size_override("font_size", 24)
	style_button(next)
	next.pressed.connect(func():
		if AdManager.should_show_interstitial():
			AdManager.show_interstitial()
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)
	box.add_child(next)
	PremiumVisuals.entrance(panel, 0.08)

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
		_save_checkpoint()
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
	_save_checkpoint()

func restart_level() -> void:
	AnalyticsManager.level_restarted(level_number)
	_clear_checkpoint(true)
	var replacement := load("res://scenes/Game.tscn").instantiate()
	replacement.level_number = level_number
	replacement.custom_level_data = custom_level_data.duplicate(true)
	replacement.daily_mode = daily_mode
	replacement.finished.connect(func(n): finished.emit(n))
	replacement.quit_requested.connect(func(): quit_requested.emit())
	get_parent().add_child(replacement)
	queue_free()

func _save_checkpoint() -> void:
	if rescued or level_data.is_empty():
		return
	SaveManager.data["active_run"] = {
		"level": level_number,
		"daily": daily_mode,
		"daily_key": String(level_data.get("daily_key", "")),
		"level_data": level_data.duplicate(true) if daily_mode else {},
		"pieces": pieces.duplicate(true),
		"moves": moves,
		"chain": chain_count,
		"hints": hints_used_this_level,
		"saved_at": int(Time.get_unix_time_from_system())
	}
	SaveManager.save()

func _restore_checkpoint() -> void:
	var raw = SaveManager.data.get("active_run", {})
	if not raw is Dictionary or raw.is_empty():
		return
	var checkpoint: Dictionary = raw
	if int(checkpoint.get("level", -999)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	if daily_mode and String(checkpoint.get("daily_key", "")) != String(level_data.get("daily_key", "")):
		return
	var restored_pieces = checkpoint.get("pieces", [])
	if not restored_pieces is Array or restored_pieces.size() != pieces.size():
		return
	var clean: Array[Dictionary] = []
	for raw_piece in restored_pieces:
		if not raw_piece is Dictionary:
			return
		clean.append(raw_piece.duplicate(true))
	pieces = clean
	moves = maxi(0, int(checkpoint.get("moves", 0)))
	chain_count = maxi(0, int(checkpoint.get("chain", 0)))
	hints_used_this_level = maxi(0, int(checkpoint.get("hints", 0)))
	history.clear()
	checkpoint_restored = true
	render_board()
	hint_label.text = "Rescue restored from your last checkpoint."
	AnalyticsManager.track("level_resume", {"level": level_number, "daily": daily_mode, "moves": moves})

func _clear_checkpoint(save_now: bool = true) -> void:
	SaveManager.data["active_run"] = {}
	if save_now:
		SaveManager.save()
