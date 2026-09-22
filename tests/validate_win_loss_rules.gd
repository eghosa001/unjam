extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _check_water():
		return
	if not await _check_block():
		return
	if not await _check_rescue():
		return
	print("WIN_LOSS_RULES_OK: win predicates and player-facing loss reasons are explicit for all three games.")
	quit(0)

func _check_water() -> bool:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var objective := game.find_child("WaterObjectiveLabel", true, false) as Label
	if objective == null or not objective.text.begins_with("WIN •"):
		game.queue_free()
		return _fail("Water Sort objective does not state the win condition")
	if not _label_fits(objective):
		game.queue_free()
		return _fail("Water Sort win condition does not fit its phone label")

	game.set("tubes", [[0,0,0,0], [1,1,1,1], [], []])
	if not bool(game.call("is_complete")):
		game.queue_free()
		return _fail("Water Sort should win when every non-empty tube is full and monochrome")
	game.set("tubes", [[0,0,0], [1,1,1,1], [], []])
	if bool(game.call("is_complete")):
		game.queue_free()
		return _fail("Water Sort must not win with a partially filled non-empty tube")

	game.set("tubes", [[0,0,0,0], [1,1,1], [2,2,2], [3,3,3], [4,4,4,4]])
	game.set("completed", false)
	game.set("pending_completion", false)
	game.call("_check_no_legal_pours")
	if not bool(game.get("stuck")):
		game.queue_free()
		return _fail("Water Sort dead end should enter STUCK recovery state")
	var status := game.get("status_label") as Label
	var hint := game.get("hint_label") as Label
	if status == null or not status.text.begins_with("STUCK"):
		game.queue_free()
		return _fail("Water Sort stuck state is not clearly labeled")
	if hint == null or "UNDO" not in hint.text or "RETRY" not in hint.text:
		game.queue_free()
		return _fail("Water Sort stuck state does not explain recovery options")
	if game.find_child("BlockFailureResult", true, false) != null:
		game.queue_free()
		return _fail("Water Sort dead end incorrectly created a hard failure overlay")

	game.queue_free()
	await process_frame
	return true

func _check_block() -> bool:
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		return _fail("Block Puzzle scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var goal := game.get("goal_label") as Label
	if goal == null or not goal.text.begins_with("WIN •"):
		game.queue_free()
		return _fail("Block Puzzle does not show a clear win checklist")
	if not _label_fits(goal):
		game.queue_free()
		return _fail("Block Puzzle win checklist does not fit its phone label")

	game.set("play_mode", "campaign")
	game.set("daily_mode", false)
	game.set("score", int(game.get("target_score")))
	game.set("lines_cleared", int(game.get("target_lines")))
	var rows: Array = game.get("target_rows_pending")
	var cols: Array = game.get("target_cols_pending")
	var specials: Dictionary = game.get("campaign_special_cells")
	rows.clear()
	cols.clear()
	specials.clear()
	game.set("required_double_clears", 0)
	game.set("double_clear_progress", 0)
	if not bool(game.call("reached_goal")):
		game.queue_free()
		return _fail("Block Puzzle should win when every displayed goal is complete")
	rows.append(0)
	if bool(game.call("reached_goal")):
		game.queue_free()
		return _fail("Block Puzzle must not win while a required row objective remains")
	rows.clear()

	var move_fail: Dictionary = game.call("_failure_presentation", "MOVE LIMIT REACHED")
	var fit_fail: Dictionary = game.call("_failure_presentation", "NO LEGAL MOVES")
	if String(move_fail.get("title", "")) != "OUT OF MOVES":
		game.queue_free()
		return _fail("Block Puzzle move-limit loss is not identified")
	if String(fit_fail.get("title", "")) != "NO MOVES LEFT":
		game.queue_free()
		return _fail("Block Puzzle no-fit loss is not identified")
	if String(move_fail.get("subtitle", "")) == String(fit_fail.get("subtitle", "")):
		game.queue_free()
		return _fail("Block Puzzle distinct loss causes use the same explanation")

	game.queue_free()
	await process_frame
	return true

func _check_rescue() -> bool:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var objective := game.find_child("RescueObjectiveLabel", true, false) as Label
	if objective == null or not objective.text.begins_with("WIN •"):
		game.queue_free()
		return _fail("Rescue Rush objective does not state the win condition")
	if not _label_fits(objective):
		game.queue_free()
		return _fail("Rescue Rush win condition does not fit its phone label")

	var moves_label := game.get("moves_label") as Label
	if moves_label == null or "LIVES" not in moves_label.text:
		game.queue_free()
		return _fail("Rescue Rush does not show remaining lives")
	if not _label_fits(moves_label):
		game.queue_free()
		return _fail("Rescue Rush move/lives rule does not fit its phone label")
	if String(game.get("objective_type")) != "perfect_rescue" and "3★" not in moves_label.text:
		game.queue_free()
		return _fail("Rescue Rush ordinary levels do not distinguish the 3-star target from a loss limit")

	var lives_fail: Dictionary = game.call("_failure_presentation", "No lives left.")
	var limit_fail: Dictionary = game.call("_failure_presentation", "Action budget reached before the rescue.")
	var route_fail: Dictionary = game.call("_failure_presentation", "No valid arrow can leave the board.")
	if String(lives_fail.get("title", "")) != "OUT OF LIVES":
		game.queue_free()
		return _fail("Rescue Rush life loss is not identified")
	if String(limit_fail.get("title", "")) != "OUT OF MOVES":
		game.queue_free()
		return _fail("Rescue Rush move-limit loss is not identified")
	if String(route_fail.get("title", "")) != "NO ROUTE LEFT":
		game.queue_free()
		return _fail("Rescue Rush dead-route loss is not identified")

	game.set("objective_type", "perfect_rescue")
	game.set("action_budget", 7)
	var instruction := String(game.call("objective_instruction"))
	if not instruction.begins_with("WIN:") or "7 moves" not in instruction:
		game.queue_free()
		return _fail("Rescue Rush perfect-rescue limit is not explicit")

	game.queue_free()
	await process_frame
	return true

func _label_fits(label: Label) -> bool:
	return label.get_minimum_size().x <= label.size.x + 4.0

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
