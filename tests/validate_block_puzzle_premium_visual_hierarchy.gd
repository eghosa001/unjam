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
	var score_card := game.find_child("BlockScoreCard",true,false) as Control
	var score := game.get("score_label") as Label
	var goal := game.get("goal_label") as Label
	var hint := game.find_child("HintAction",true,false) as Button
	if score_card == null or score == null or goal == null or hint == null:
		return _fail("Block score-card diagnostics are incomplete")
	if score.get_global_rect().intersects(goal.get_global_rect()) or goal.get_global_rect().intersects(hint.get_global_rect()):
		return _fail("Block score/objective/hint columns overlap")
	if not score_card.get_global_rect().encloses(goal.get_global_rect()):
		return _fail("Block objective text escapes the score card")
	if goal.autowrap_mode == TextServer.AUTOWRAP_OFF or not goal.clip_text:
		return _fail("Block objective text is not bounded for late-game goals")
	if piece_row.custom_minimum_size.y < 71.0 or piece_row.custom_minimum_size.y > 73.0:
		return _fail("Block piece row drifted from the 72px Figma tray slot height")
	if game.find_child("BlockPuzzle3DEnvironment",true,false) != null:
		return _fail("Retired oversized Block 3D environment returned above Figma composition")
	for booster_name in ["Booster_Undo","Booster_Hammer","Booster_Shuffle","Booster_Rotate"]:
		var booster := game.find_child(booster_name,true,false) as Button
		if booster == null or booster.custom_minimum_size.distance_to(Vector2(82,54)) > 1.0:
			return _fail("%s is missing or not Figma-sized" % booster_name)

	var single := BlockPieceButton.new()
	single.size = Vector2(104,72)
	single.configure([Vector2i.ZERO],false,Color("8b7cf6"),0)
	var tray_cell := single.tray_visual_cell_size()
	if tray_cell < 31.5 or tray_cell > 32.1:
		return _fail("Single Block tray piece no longer matches the premium board-scale target: %.2f" % tray_cell)
	single.queue_free()

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
