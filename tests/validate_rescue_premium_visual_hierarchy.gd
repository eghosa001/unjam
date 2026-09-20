extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene could not be loaded")
	var game := packed.instantiate() as Control
	root.add_child(game)
	await _frames(10)

	var board_panel := game.get("board_panel") as PanelContainer
	var board_grid := game.get("board_grid") as GridContainer
	var objective := game.find_child("RescueObjectiveLabel",true,false) as Label
	if board_panel == null or board_grid == null or objective == null:
		return _fail("Rescue Rush Figma gameplay hierarchy is incomplete")
	if board_panel.size.distance_to(Vector2(348,348)) > 1.0:
		return _fail("Rescue board is not using the restored 348x348 play area")
	if board_grid.columns != 5 or board_grid.get_child_count() != 25:
		return _fail("Rescue board is not a complete 5x5 grid")
	if board_grid.get_theme_constant("h_separation") != 7 or board_grid.get_theme_constant("v_separation") != 7:
		return _fail("Rescue grid gaps are still too large")
	for child in board_grid.get_children():
		if child is Control and (child as Control).custom_minimum_size.x < 57.0:
			return _fail("Rescue arrows/obstacles are still undersized")
	if objective.text != "CLEAR THE LANE • FREE THE CHICK":
		return _fail("Rescue objective copy drifted")

	game.queue_free()
	await process_frame
	print("Rescue Rush readable 5x5 board hierarchy validated.")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
