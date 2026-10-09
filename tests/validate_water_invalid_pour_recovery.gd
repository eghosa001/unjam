extends SceneTree

# Contract: Water Sort invalid destination taps never destroy a selected source,
# consume a move, or record history. A valid bottle still cancels when re-tapped.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		return _fail("Water Sort scene not loadable")
	var game = scene.instantiate()
	game.set("level_number", 1)
	root.add_child(game)
	await _frames(6)
	var tubes: Array = game.get("tubes")
	if tubes.size() < 3:
		return _fail("Water Sort opening board has too few tubes")

	var from_idx := -1
	var invalid_idx := -1
	for i in range(tubes.size()):
		if (tubes[i] as Array).is_empty():
			continue
		for j in range(tubes.size()):
			if j == i:
				continue
			if not bool(game.call("can_pour",i,j)):
				from_idx = i
				invalid_idx = j
				break
		if from_idx >= 0:
			break
	if from_idx < 0 or invalid_idx < 0:
		return _fail("Opening puzzle has no invalid pour pair to test")
	var start_moves := int(game.get("moves"))
	var start_history := (game.get("history") as Array).size()
	var start_tubes: Array = tubes.duplicate(true)
	game.call("select_tube",-1)
	game.call("select_tube",tubes.size())
	if int(game.get("moves")) != start_moves or int(game.get("selected")) != -1:
		return _fail("Out-of-range bottle input unexpectedly changed the board")
	game.call("select_tube",from_idx)
	await process_frame
	if int(game.get("selected")) != from_idx:
		return _fail("Selecting the first source bottle failed")
	game.call("select_tube",invalid_idx)
	await _frames(2)
	if int(game.get("selected")) != from_idx:
		return _fail("Invalid destination incorrectly cleared the selected source")
	if int(game.get("moves")) != start_moves or (game.get("history") as Array).size() != start_history or (game.get("tubes") as Array) != start_tubes:
		return _fail("Invalid destination consumed moves or changed puzzle state")
	var status := game.get("status_label") as Label
	if status == null or not status.text.contains("choose another tube"):
		return _fail("Invalid pour does not explain how to recover")
	var target_button := (game.get("board") as GridContainer).get_child(invalid_idx) as Control
	var cell_position := target_button.position
	# Fast repeat taps may overlap multiple rejection animations. The source
	# remains selected, while the target glass must stay in its grid cell.
	for _i in range(6):
		game.call("select_tube", invalid_idx)
		await process_frame
		if target_button.position.distance_to(cell_position) > 0.75:
			return _fail("Rejected pour shifted a bottle away from its grid slot")
	await create_timer(0.23).timeout
	if target_button.position.distance_to(cell_position) > 0.75:
		return _fail("Rejected pour did not restore original bottle layout")
	if absf(target_button.rotation) > 0.015:
		return _fail("Repeated invalid-tap wobble did not settle to zero rotation")
	var motion_source := FileAccess.get_file_as_string("res://scripts/ui/water_tube_reference_button.gd")
	if not motion_source.contains('motion.call("reduced")'):
		return _fail("Rejected pour does not honor Reduce Motion")
	game.call("select_tube",from_idx)
	await process_frame
	if int(game.get("selected")) != -1:
		return _fail("Retapping the highlighted source did not cancel selection")
	game.queue_free()
	await process_frame
	print("WATER_INVALID_POUR_RECOVERY_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
