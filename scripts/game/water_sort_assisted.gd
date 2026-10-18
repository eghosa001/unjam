extends "res://scripts/game/water_sort_casual.gd"

const WaterSolver = preload("res://scripts/core/water_sort_solver.gd")
const EXTRA_TUBE_COST := 75

var extra_tube_used := false

# Research-aligned curve: 3 colours for the tutorial, then 4, 5, 6-7 and 8.
# The constructive generator still guarantees every shipped board has a proof.
func level_config() -> Dictionary:
	var tier := campaign_tier()
	var colors := 3
	if level_number <= 10:
		colors = 3
	elif level_number <= 30:
		colors = 4
	elif level_number <= 130:
		colors = 5
	elif level_number <= 210:
		colors = 6
	elif level_number <= 300:
		colors = 7
	else:
		colors = 8
	var par := 14 + colors * 5 + tier * 2
	var d := difficulty()
	if d == "hard": par += 5
	elif d == "milestone": par += 8
	elif d == "boss": par += 12
	return {"colors": colors, "par": par, "tier": tier}

func build_ui() -> void:
	super.build_ui()
	var actions := find_child("CompactGameActions", true, false) as HBoxContainer
	if actions == null:
		return
	for child in actions.get_children():
		if child is Button:
			var existing := child as Button
			existing.custom_minimum_size = Vector2(106, 60)
			existing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			existing.add_theme_font_size_override("font_size", 15)
	var add_tube := RefCanvas.premium_button("+ TUBE\n75 ◈", 15, Color(1.0, 0.995, 0.97), Color(0.10, 0.66, 1.0), 16, Color(0.55, 0.83, 1.0, 0.56), 1.3)
	add_tube.name = "AddTubeAction"
	add_tube.custom_minimum_size = Vector2(106, 60)
	add_tube.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_tube.pressed.connect(add_extra_tube)
	actions.add_child(add_tube)
	if not EconomyManager.balance_changed.is_connected(_on_economy_balance_changed):
		EconomyManager.balance_changed.connect(_on_economy_balance_changed)
	_refresh_extra_tube_button()

func load_level() -> void:
	extra_tube_used = false
	super.load_level()
	_refresh_extra_tube_button()

func add_extra_tube() -> bool:
	if daily_mode:
		status_label.text = "Ranked Daily Games do not allow extra tubes."
		FeedbackManager.blocked()
		return false
	if completed:
		return false
	if extra_tube_used:
		status_label.text = "Extra tube already used on this attempt"
		FeedbackManager.blocked()
		return false
	if has_method("_has_active_pours") and bool(call("_has_active_pours")):
		status_label.text = "Finish active pours before adding a tube"
		return false
	if not EconomyManager.spend(EXTRA_TUBE_COST, "extra_tube", {"game": GAME_ID, "level": level_number}):
		status_label.text = "Need %d coins for an extra tube" % EXTRA_TUBE_COST
		FeedbackManager.blocked()
		_show_tube_recovery()
		_refresh_extra_tube_button()
		return false
	# A paid assist is not an undoable puzzle move. Keeping the extra tube out of
	# move history prevents Undo from destroying a purchased tube while the
	# one-use-per-attempt guard remains consumed.
	tubes.append([])
	extra_tube_used = true
	selected = -1
	status_label.text = "Extra empty tube added • -%d coins" % EXTRA_TUBE_COST
	FeedbackManager.tap()
	render_board()
	_refresh_extra_tube_button()
	_save_checkpoint()
	return true

func _show_tube_recovery() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var prompt := scene.get_node_or_null("InsufficientCoinsPrompt")
	if prompt == null or not prompt.has_method("show_for"):
		return false
	prompt.call("show_for", "EXTRA TUBE", EXTRA_TUBE_COST, Callable(self, "add_extra_tube"))
	return true

# HintManager delegates the paid Hint button here. Even at level 10,000,
# never run up to 40k state expansions inside the tap callback. First prove
# there is a winning move in small main-loop slices; only THEN offer a paid or
# rewarded hint. A failed search costs exactly zero coins and zero ads.
var _hint_preparing := false
var _hint_preparing_key := ""

func request_verified_hint() -> bool:
	if completed or pending_completion or _hint_preparing:
		if _hint_preparing and hint_label != null:
			hint_label.text = "Checking the safest pour…"
		return _hint_preparing
	if has_method("_has_active_pours") and bool(call("_has_active_pours")):
		if status_label != null:
			status_label.text = "Finish pouring before requesting a hint"
		return false
	var found_legal := false
	for i in range(tubes.size()):
		for j in range(tubes.size()):
			if can_pour(i,j):
				found_legal = true
				break
		if found_legal: break
	if not found_legal:
		if hint_label != null: hint_label.text = "No legal pour. Undo or retry."
		return false
	_hint_preparing = true
	_hint_preparing_key = JSON.stringify(tubes)
	if hint_label != null: hint_label.text = "Checking the safest pour…"
	call_deferred("_solve_water_hint_in_frames",_hint_preparing_key,tubes.duplicate(true))
	return true

func _solve_water_hint_in_frames(board_key: String, snapshot: Array) -> void:
	var job := WaterSolver.begin_search(snapshot,40000)
	while true:
		if not is_inside_tree() or completed or pending_completion or JSON.stringify(tubes) != board_key:
			_hint_preparing = false
			if is_inside_tree() and hint_label != null:
				hint_label.text = "Board changed. Tap Hint to check again."
			return
		var report := WaterSolver.advance_search(job,32)
		if bool(report.get("done",false)):
			_hint_preparing = false
			var move: Vector2i = report.get("move",WaterSolver.NO_MOVE)
			if move == WaterSolver.NO_MOVE or not can_pour(move.x,move.y):
				if hint_label != null:
					hint_label.text = "No verified winning path found. Undo or retry. No coins spent."
				return
			if hint_label != null: hint_label.text = "Winning move found. Choose your hint reward."
			HintManager.request_hint(GAME_ID,Callable(self,"_apply_verified_water_hint").bind(move,board_key),Callable(self,"_on_verified_water_hint_unavailable"))
			return
		await get_tree().process_frame

func _on_verified_water_hint_unavailable(reason: String) -> void:
	if is_inside_tree() and hint_label != null:
		hint_label.text = reason

func _apply_verified_water_hint(move: Vector2i, board_key: String) -> bool:
	# HintManager sees FALSE and safely preserves the already-paid/ad-earned
	# hint for the player's next board rather than losing the entitlement.
	if not is_inside_tree() or completed or pending_completion:
		return false
	if JSON.stringify(tubes) != board_key or not can_pour(move.x,move.y):
		if hint_label != null:
			hint_label.text = "Puzzle changed. Your paid Hint is saved for next time."
		return false
	SaveManager.record_hint()
	if has_method("_note_attempt_hint"):
		call("_note_attempt_hint")
	FeedbackManager.tap()
	var guidance := "Best move: tube %d → tube %d" % [move.x+1,move.y+1]
	select_tube(move.x)
	select_tube(move.y)
	if hint_label != null: hint_label.text = guidance
	return true

func can_show_hint() -> bool:
	if completed or pending_completion:
		return false
	if has_method("_has_active_pours") and bool(call("_has_active_pours")):
		return false
	var move := _best_water_move()
	return move.x >= 0 and move.y >= 0

func show_hint() -> void:
	if completed or pending_completion:
		return
	if has_method("_has_active_pours") and bool(call("_has_active_pours")):
		status_label.text = "Finish active pours to use a hint"
		return
	var move := _best_water_move()
	if move.x < 0:
		hint_label.text = "No verified finish found — Undo, Retry, or add a tube."
		FeedbackManager.blocked()
		return
	SaveManager.record_hint()
	if has_method("_note_attempt_hint"):
		call("_note_attempt_hint")
	FeedbackManager.tap()
	var guidance := "Best move: tube %d → tube %d" % [move.x + 1, move.y + 1]
	hint_label.text = guidance
	# Use the normal interaction path so history, concurrent pour animation,
	# checkpoints and completion timing remain owned by the active game layer.
	# Normal tube taps clear stale hints; restore this fresh guidance after the
	# automated taps so the player can still see what the Hint just executed.
	select_tube(move.x)
	select_tube(move.y)
	hint_label.text = guidance

func _best_water_move() -> Vector2i:
	return WaterSolver.best_move(tubes, 40000)

func _save_checkpoint() -> void:
	if daily_mode or completed:
		return
	MultiGameManager.save_checkpoint(GAME_ID, {
		"level": level_number,
		"daily": daily_mode,
		"moves": moves,
		"tubes": tubes.duplicate(true),
		"history": history.duplicate(true),
		"extra_tube_used": extra_tube_used
	})

func _restore_checkpoint() -> void:
	if daily_mode:
		return
	super._restore_checkpoint()
	var checkpoint := MultiGameManager.checkpoint(GAME_ID)
	if checkpoint.is_empty() or int(checkpoint.get("level", -1)) != level_number or bool(checkpoint.get("daily", false)) != daily_mode:
		return
	extra_tube_used = bool(checkpoint.get("extra_tube_used", false))

func _on_economy_balance_changed(_new_balance: int, _delta: int, _reason: String) -> void:
	_refresh_extra_tube_button()

func _refresh_extra_tube_button() -> void:
	var button := find_child("AddTubeAction", true, false) as Button
	if button == null:
		return
	var balance := EconomyManager.balance()
	if daily_mode:
		button.disabled = true
		button.text = "RANKED • NO EXTRA TUBE"
		button.tooltip_text = "Extra tubes are disabled in ranked Daily competition."
		return
	button.disabled = extra_tube_used
	button.text = "✓ TUBE\nUSED" if extra_tube_used else "+ TUBE\n%d ◈" % EXTRA_TUBE_COST
	button.tooltip_text = "Already used this attempt • Balance %d" % balance if extra_tube_used else "Costs %d coins • Balance %d" % [EXTRA_TUBE_COST, balance]
