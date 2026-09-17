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
			existing.custom_minimum_size.x = 0
			existing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			existing.add_theme_font_size_override("font_size", 17)
	var add_tube := Button.new()
	add_tube.name = "AddTubeAction"
	add_tube.custom_minimum_size = Vector2(0, 116)
	add_tube.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_tube.add_theme_font_size_override("font_size", 16)
	Unjam3DTheme.gloss_button(add_tube, Unjam3DTheme.WATER, true, 24)
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
	if completed:
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
	button.disabled = extra_tube_used
	button.text = "✓  TUBE USED\n◈ %d" % balance if extra_tube_used else "+  TUBE • %d\n◈ %d" % [EXTRA_TUBE_COST, balance]
	button.tooltip_text = "Already used this attempt • Balance %d" % balance if extra_tube_used else "Costs %d coins • Balance %d" % [EXTRA_TUBE_COST, balance]
