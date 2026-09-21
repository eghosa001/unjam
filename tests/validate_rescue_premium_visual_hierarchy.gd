extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene could not be loaded")
	var game := packed.instantiate() as Control
	game.set("level_number",1)
	root.add_child(game)
	await _frames(10)

	var board_panel := game.get("board_panel") as PanelContainer
	var board_grid := game.get("board_grid") as GridContainer
	var objective := game.find_child("RescueObjectiveLabel",true,false) as Label
	if board_panel == null or board_grid == null or objective == null:
		return _fail("Rescue Rush gameplay hierarchy is incomplete")
	if board_panel.size.distance_to(Vector2(348,348)) > 1.0:
		return _fail("Rescue board is not using the restored 348x348 play area")
	var width := int(game.get("width"))
	var height := int(game.get("height"))
	if width != 7 or height != 7:
		return _fail("Opening Rescue campaign level should preserve its 7x7 progression board")
	if board_grid.columns != width or board_grid.get_child_count() != width * height:
		return _fail("Rescue board does not render its complete progression grid")
	if board_grid.get_theme_constant("h_separation") != 5 or board_grid.get_theme_constant("v_separation") != 5:
		return _fail("Rescue grid gaps are still too large")
	var minimum_cell := 40.0
	for child in board_grid.get_children():
		if child is Control and (child as Control).custom_minimum_size.x < minimum_cell:
			return _fail("Rescue grid cells are still undersized")
	if objective.text != "OPEN A CLEAR LANE AND FREE THE CHICK":
		return _fail("Rescue objective copy drifted")

	var arrow_source := _read("res://scripts/ui/rescue_piece_3d_button.gd")
	for token in [
		"var readable_scale := scale_value * 1.18",
		"Color(\"#073b78\"), 5.0",
		"Color(\"#dff8ff\"), 2.0",
		"Directional spine reinforces orientation",
	]:
		if not arrow_source.contains(token):
			return _fail("Rescue arrow clarity contract is missing: %s" % token)

	game.queue_free()
	await process_frame
	print("Rescue Rush dense 7x7 board hierarchy validated.")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
