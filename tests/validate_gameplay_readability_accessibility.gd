extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var rescue := await _open("res://scenes/Game.tscn", 1)
	if not _check(rescue != null, "Rescue scene failed to open"): return
	var hud := rescue.get("moves_label") as Label
	var objective := rescue.find_child("RescueObjectiveLabel", true, false) as Label
	if not _check(hud != null and hud.visible and hud.text.contains("MOVES") and hud.text.contains("LIVES") and hud.accessibility_name.contains("3 stars"), "Rescue status is not readable or accessible"): return
	if not _check(objective != null and not objective.accessibility_name.is_empty() and objective.accessibility_name.contains("WIN:"), "Rescue full objective is missing for accessibility"): return
	rescue.queue_free()
	await process_frame

	var water := await _open("res://scenes/WaterSort.tscn", 2)
	if not _check(water != null, "Water Sort scene failed to open"): return
	var board := water.get("board") as GridContainer
	var tubes: Array = water.get("tubes")
	if not _check(board != null and board.get_child_count() == tubes.size(), "Water tube buttons do not match the state"): return
	for i in range(tubes.size()):
		var button := board.get_child(i) as Button
		if not _check(button != null and button.accessibility_name.begins_with("Tube %d" % (i + 1)) and button.accessibility_name.contains("bottom to top") == not (tubes[i] as Array).is_empty(), "Water accessibility text missing or incorrect for tube %d" % (i + 1)): return
	water.queue_free()
	await process_frame

	var block := await _open("res://scenes/BlockPuzzle.tscn", 1800)
	if not _check(block != null, "Block Puzzle scene failed to open"): return
	var goal := block.get("goal_label") as Label
	if not _check(goal != null and goal.text.contains("PTS") and goal.text.contains("LINES") and goal.accessibility_name.contains("lines cleared"), "Block goal does not show readable live progress"): return
	if not _check(goal.get_theme_font_size("font_size") >= 17, "Block goal font size regressed to tiny 15px"): return
	block.queue_free()
	await process_frame

	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null, "Main scene missing"): return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(6)
	main.call("build_goals")
	await _frames(3)
	var progress_count := 0
	for child in main.find_children("*", "Label", true, false):
		var label := child as Label
		if String(label.name).begins_with("GoalProgress"):
			progress_count += 1
			if not _check(label.get_theme_font_size("font_size") >= 12 and label.accessibility_name.contains("complete"), "Mission progress unreadable or not accessible"): return
	if not _check(progress_count > 0, "Goal screen has no mission progress labels"): return
	main.queue_free()
	await process_frame
	print("GAMEPLAY_READABILITY_ACCESSIBILITY_OK: Rescue, Water, Block and Goals texts are accessible and legible.")
	quit(0)

func _open(scene_path: String, level: int) -> Control:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var game := packed.instantiate() as Control
	game.set("level_number", level)
	root.add_child(game)
	await _frames(8)
	return game

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	push_error(message)
	quit(1)
	return false
