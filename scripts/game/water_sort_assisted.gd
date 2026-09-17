extends "res://scripts/game/water_sort_casual.gd"

const WaterSolver = preload("res://scripts/core/water_sort_solver.gd")

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
	add_tube.text = "+\nTUBE"
	add_tube.custom_minimum_size = Vector2(0, 116)
	add_tube.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_tube.add_theme_font_size_override("font_size", 17)
	Unjam3DTheme.gloss_button(add_tube, Unjam3DTheme.WATER, true, 24)
	add_tube.pressed.connect(add_extra_tube)
	actions.add_child(add_tube)

func load_level() -> void:
	extra_tube_used = false
	super.load_level()
	_refresh_extra_tube_button()

func add_extra_tube() -> void:
	if completed:
		return
	if extra_tube_used:
		status_label.text = "Extra tube already used on this attempt"
		FeedbackManager.blocked()
		return
	if has_method("_has_active_pours") and bool(call("_has_active_pours")):
		status_label.text = "Finish active pours before adding a tube"
		return
	history.append({"tubes": tubes.duplicate(true), "moves": moves})
	tubes.append([])
	extra_tube_used = true
	selected = -1
	status_label.text = "Extra empty tube added"
	FeedbackManager.tap()
	render_board()
	_refresh_extra_tube_button()
	_save_checkpoint()

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
	hint_label.text = "Best move: tube %d → tube %d" % [move.x + 1, move.y + 1]
	# Use the normal interaction path so history, concurrent pour animation,
	# checkpoints and completion timing remain owned by the active game layer.
	select_tube(move.x)
	select_tube(move.y)

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

func _refresh_extra_tube_button() -> void:
	var button := find_child("AddTubeAction", true, false) as Button
	if button == null:
		return
	button.disabled = extra_tube_used
	button.text = "✓\nTUBE" if extra_tube_used else "+\nTUBE"
