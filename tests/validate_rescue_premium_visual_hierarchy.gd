extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		push_error("Rescue Rush scene could not be loaded")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var board_panel = game.get("board_panel") as PanelContainer
	if board_panel == null or board_panel.custom_minimum_size.x < 840.0:
		failures.append("Rescue Rush board is still too small for the available play area")
	var status := _find_node_named(game, "CompactStatusStrip") as Control
	if status == null or status.custom_minimum_size.y > 96.0:
		failures.append("Rescue Rush status strip is still taking too much vertical space")
	var objective := _find_label_with(game, "CLEAR")
	if objective == null:
		failures.append("Rescue Rush objective label is missing")
	else:
		if objective.text != "🐥  CLEAR THE LANE • FREE THE CHICK":
			failures.append("Rescue Rush objective copy is still visually overloaded")
		if objective.get_theme_font_size("font_size") < 20:
			failures.append("Rescue Rush objective text is still too small")

	game.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Rescue Rush premium visual hierarchy validated.")
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
