extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene could not be loaded")
	var game := packed.instantiate() as Control
	root.add_child(game)
	await _frames(8)

	var canvas := game.find_child("FigmaWater390x844",true,false) as Control
	var stage := game.find_child("GameplayStage",true,false) as Control
	var board := game.get("board") as GridContainer
	var objective := game.find_child("WaterObjective",true,false) as Control
	var emblem := game.find_child("*Water*Emblem*",true,false) as Control
	if canvas == null:
		return _fail("Water Sort Figma canvas is missing")
	if stage == null:
		return _fail("Water Sort Figma gameplay stage is missing")
	if board == null:
		return _fail("Water Sort board reference is missing")
	if objective == null:
		return _fail("Water Sort Figma objective is missing")
	if emblem == null:
		return _fail("Water Sort Figma identity emblem is missing")
	if not _rect_eq(Rect2(stage.position,stage.size),Rect2(17,169,354,450)):
		return _fail("Water gameplay stage drifted from Figma 354x450 geometry")
	if not _rect_eq(Rect2(objective.position,objective.size),Rect2(17,129,354,30)):
		return _fail("Water objective drifted from Figma geometry")
	if board.get_child_count() == 0:
		return _fail("Water Sort board/tubes are missing")
	var tube := board.get_child(0) as Control
	if tube == null:
		return _fail("Water Sort first bottle is missing")
	var board_rect := Rect2(board.position, board.size)
	var board_bounds := Rect2(31.0, 169.0, 326.0, 450.0)
	if board_rect.position.x < board_bounds.position.x - 1.0 or board_rect.end.x > board_bounds.end.x + 1.0:
		return _fail("Water Sort board exceeds the audited stage width")
	if board_rect.position.y < board_bounds.position.y - 1.0 or board_rect.end.y > board_bounds.end.y + 1.0:
		return _fail("Water Sort board exceeds the audited stage height")
	if tube.custom_minimum_size.x < 38.0 or tube.custom_minimum_size.y < 90.0:
		return _fail("Water Sort bottles became too small for reliable compact-phone play")
	var objective_label := game.find_child("WaterObjectiveLabel", true, false) as Label
	if objective_label == null:
		return _fail("Water Sort objective label is missing")
	if objective_label.text != "WIN • ONE COLOUR PER FULL TUBE":
		return _fail("Water Sort objective copy drifted from the explicit win-condition contract")
	if game.find_child("WaterObjectiveDrop", true, false) == null:
		return _fail("Water Sort objective droplet icon is missing")
	if objective_label.get_theme_font_size("font_size") < 15:
		return _fail("Water Sort objective typography drifted from 15px readability floor")
	if not _rect_eq(Rect2(emblem.position,emblem.size),Rect2(77,17,30,30)):
		return _fail("Water identity emblem drifted from Figma header geometry")

	game.queue_free()
	await process_frame
	print("Water Sort Figma visual hierarchy validated.")
	quit(0)

func _find_label_with(node: Node, fragment: String) -> Label:
	if node is Label and fragment in (node as Label).text:
		return node as Label
	for child in node.get_children():
		var found := _find_label_with(child, fragment)
		if found != null:
			return found
	return null

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
