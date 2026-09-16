extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		push_error("Block Puzzle scene could not be loaded")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var board_shell = game.get("board_shell") as PanelContainer
	var piece_row = game.get("piece_row") as HBoxContainer
	if board_shell == null:
		failures.append("Block Puzzle has no board shell")
	else:
		var style := board_shell.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null or style.shadow_size < 20:
			failures.append("Block Puzzle board frame does not have premium depth")
	if piece_row == null or piece_row.custom_minimum_size.y < 176.0:
		failures.append("Block Puzzle tray is too shallow for large readable pieces")

	var stage := game.get_node_or_null("BlockPuzzle3DEnvironment") as Unjam3DGameplayStage
	if stage == null or stage.stage == null:
		failures.append("Block Puzzle 3D environment is missing")
	else:
		var world_environment := _find_world_environment(stage.stage)
		if world_environment == null or world_environment.environment == null:
			failures.append("Block Puzzle 3D environment has no world environment")
		else:
			if world_environment.environment.background_color != Color("a56cff"):
				failures.append("Block Puzzle background is not using the brighter candy-sky palette")
			if world_environment.environment.ambient_light_energy < 1.30:
				failures.append("Block Puzzle ambient lighting is too flat/dim")

	var objective := _find_label_with(game, "DRAG")
	if objective == null:
		failures.append("Block Puzzle objective label is missing")
	else:
		if objective.text != "▦  DRAG • PLACE • CLEAR":
			failures.append("Block Puzzle objective copy is still visually overloaded")
		if objective.get_theme_font_size("font_size") < 20:
			failures.append("Block Puzzle objective is still too small")

	game.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Block Puzzle premium visual hierarchy validated.")
	quit(0)

func _find_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node as WorldEnvironment
	for child in node.get_children():
		var found := _find_world_environment(child)
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
