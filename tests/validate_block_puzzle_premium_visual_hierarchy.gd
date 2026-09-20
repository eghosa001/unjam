extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		return _fail("Block Puzzle scene could not be loaded")
	var game := packed.instantiate() as Control
	root.add_child(game)
	await _frames(10)

	var canvas := game.find_child("FigmaBlock390x844",true,false) as Control
	var board_shell := game.get("board_shell") as PanelContainer
	var piece_row := game.get("piece_row") as HBoxContainer
	var board_grid := game.get("board_grid") as GridContainer
	var tray := game.find_child("BlockTray",true,false) as Control
	if canvas == null or board_shell == null or piece_row == null or board_grid == null or tray == null:
		return _fail("Block Figma hierarchy is incomplete")
	if board_grid.columns != 8:
		return _fail("Block board is no longer the required 8x8 grid")
	if board_grid.get_child_count() != 64:
		return _fail("Block board does not expose 64 runtime cells")
	if board_shell.size.distance_to(Vector2(330,330)) > 1.0:
		return _fail("Block board is not the Figma 330x330 surface")
	if tray.size.distance_to(Vector2(354,104)) > 1.0:
		return _fail("Block tray is not the Figma 354x104 surface")
	if piece_row.custom_minimum_size.y < 71.0 or piece_row.custom_minimum_size.y > 73.0:
		return _fail("Block piece row drifted from the 72px Figma tray slot height")
	if game.find_child("BlockPuzzle3DEnvironment",true,false) != null:
		return _fail("Retired oversized Block 3D environment returned above Figma composition")
	for booster_name in ["Booster_Undo","Booster_Hammer","Booster_Shuffle","Booster_Rotate"]:
		var booster := game.find_child(booster_name,true,false) as Button
		if booster == null or booster.custom_minimum_size.distance_to(Vector2(82,54)) > 1.0:
			return _fail("%s is missing or not Figma-sized" % booster_name)

	game.queue_free()
	await process_frame
	print("Block Puzzle Figma visual hierarchy validated.")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
