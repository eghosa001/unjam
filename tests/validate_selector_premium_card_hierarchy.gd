extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene could not be loaded")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set("current_surface", "live")
	if main.has_signal("surface_changed"):
		main.emit_signal("surface_changed", "live")
	await process_frame
	await process_frame

	var failures: Array[String] = []
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var card := _find_node_named(main, "GameCard3D_%s" % game_id) as PanelContainer
		if card == null:
			failures.append("Selector card missing for %s" % game_id)
			continue
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null or style.shadow_size < 16:
			failures.append("Selector card lacks premium depth for %s" % game_id)
		var shell := _find_node_named(card, "GameArtShell_%s" % game_id) as PanelContainer
		if shell == null:
			failures.append("Selector 3D preview has no framed display shell for %s" % game_id)
		var play := _find_button_with(card, "PLAY")
		if play == null or play.custom_minimum_size.x < 116.0:
			failures.append("Selector play CTA is not explicit/readable for %s" % game_id)
		var desc := _find_label_with(card, _description_fragment(game_id))
		if desc == null or desc.get_theme_font_size("font_size") < 22:
			failures.append("Selector description is too small for %s" % game_id)

	main.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Selector premium card hierarchy validated.")
	quit(0)

func _description_fragment(game_id: String) -> String:
	match game_id:
		"water_sort": return "Sort the colors"
		"block_puzzle": return "Drag. Place. Clear."
		_: return "Clear the lane."

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

func _find_button_with(node: Node, fragment: String) -> Button:
	if node is Button and fragment in (node as Button).text:
		return node as Button
	for child in node.get_children():
		var found := _find_button_with(child, fragment)
		if found != null:
			return found
	return null
