extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		push_error("Water Sort scene could not be loaded")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var stage := _find_node_named(game, "GameplayStage") as Control
	if stage == null or stage.custom_minimum_size.y < 1080.0:
		failures.append("Water Sort gameplay stage is still too small in the vertical play area")
	var board = game.get("board") as GridContainer
	if board == null or board.get_child_count() == 0:
		failures.append("Water Sort board/tubes are missing")
	else:
		var tube := board.get_child(0) as Control
		if tube == null or tube.custom_minimum_size.x < 230.0 or tube.custom_minimum_size.y < 400.0:
			failures.append("Water Sort bottles are still too small for the premium mobile layout")
	var objective := _find_label_with(game, "POUR")
	if objective == null:
		failures.append("Water Sort objective label is missing")
	else:
		if objective.text != "💧  SORT • POUR • SOLVE":
			failures.append("Water Sort objective copy is still visually overloaded")
		if objective.get_theme_font_size("font_size") < 20:
			failures.append("Water Sort objective text is still too small")

	game.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Water Sort premium visual hierarchy validated.")
	quit(0)

func _find_node_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, wanted)
		if found != null:
			return found
	return null

func _find_label_with(node: Node, fragment: String) -> Label:
	if node is Label and fragment in (node as Label).text:
		return node as Label
	for child in node.get_children():
		var found := _find_label_with(child, fragment)
		if found != null:
			return found
	return null
