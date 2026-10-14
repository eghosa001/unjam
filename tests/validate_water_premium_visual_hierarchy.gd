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
	var tube_aspect := tube.custom_minimum_size.y / maxf(1.0,tube.custom_minimum_size.x)
	if tube_aspect > 3.15:
		return _fail("Water Sort onboarding bottle is still too elongated for accurate pouring")
	var objective_label := game.find_child("WaterObjectiveLabel", true, false) as Label
	if objective_label == null:
		return _fail("Water Sort objective label is missing")
	if objective_label.text != "WIN • ONE COLOUR PER FULL TUBE":
		return _fail("Water Sort objective copy drifted from the explicit win-condition contract")
	if game.find_child("WaterObjectiveDrop", true, false) == null:
		return _fail("Water Sort objective droplet icon is missing")
	if objective_label.get_theme_font_size("font_size") < 16:
		return _fail("Water Sort objective typography drifted from 16px readability floor")
	if not _rect_eq(Rect2(emblem.position,emblem.size),Rect2(77,17,30,30)):
		return _fail("Water identity emblem drifted from Figma header geometry")

	game.set("moves", 12345)
	game.set("par_moves", 6789)
	game.call("render_board")
	await _frames(2)
	var move_count := game.find_child("WaterMoveCount", true, false) as Label
	var star_target := game.find_child("WaterThreeStarTarget", true, false) as Label
	if move_count == null or star_target == null:
		return _fail("Water compact move/star HUD is missing")
	var status := game.find_child("WaterStatusText", true, false) as Label
	var guidance := game.find_child("WaterGuidanceText", true, false) as Label
	var meta := game.get("meta_label") as Label
	if status == null or guidance == null or meta == null:
		return _fail("Water compact secondary typography nodes are missing")
	if meta.get_theme_font_size("font_size") < 14 or move_count.get_theme_font_size("font_size") < 14 or star_target.get_theme_font_size("font_size") < 14 or status.get_theme_font_size("font_size") < 16 or guidance.get_theme_font_size("font_size") < 16:
		return _fail("Water secondary typography fell below the compact-phone readability floor")
	if move_count.text != "MOVES 12345" or star_target.text != "3★≤6789":
		return _fail("Water compact move/star HUD does not preserve large values")
	if move_count.position.x + move_count.size.x > 283.0 or star_target.position.x + star_target.size.x > 354.0:
		return _fail("Water move/star HUD can escape the audited info strip")

	var undo := game.find_child("WaterUndoAction",true,false) as Button
	if undo == null or not undo.disabled or undo.text != "NO MOVE":
		return _fail("Opening Water board must make the empty Undo state obvious")
	if not undo.has_theme_stylebox_override("disabled") or not undo.has_theme_color_override("font_disabled_color"):
		return _fail("Water unavailable Undo button is too washed out")
	if not undo.accessibility_name.contains("Make a pour first"):
		return _fail("Water Undo empty state lacks an accessible explanation")
	var history_ref: Array = game.get("history") as Array
	history_ref.append({"tubes":[],"moves":0})
	game.call("_refresh_water_undo_action")
	if undo.disabled or undo.text != "↶  UNDO":
		return _fail("Water Undo did not activate after the first reversible pour")
	game.set("daily_mode",true)
	game.call("_refresh_water_undo_action")
	if not undo.disabled or undo.text != "NO UNDO" or not undo.accessibility_name.contains("Daily"):
		return _fail("Water ranked Daily wrongly advertises an Undo action")
	game.set("daily_mode",false)
	history_ref.pop_back()
	game.call("_refresh_water_undo_action")
	if not undo.disabled or undo.text != "NO MOVE":
		return _fail("Water Undo does not restore the empty-state hint after history clears")

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
