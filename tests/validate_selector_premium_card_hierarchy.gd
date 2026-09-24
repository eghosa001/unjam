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
		var style := card.get_theme_stylebox("panel")
		if style == null:
			failures.append("Selector card lost its premium material for %s" % game_id)
		if not _has_matching_shadow(main, card):
			failures.append("Selector card lost its composed depth shadow for %s" % game_id)
		var preview_frame := _find_node_named(main, "SelectorGamePreviewFrame_%s" % game_id) as PanelContainer
		if preview_frame == null or preview_frame.get_theme_stylebox("panel") == null:
			failures.append("Selector gameplay preview frame is missing its material treatment for %s" % game_id)
		var play := _find_node_named(main, "SelectorPlay_%s" % game_id) as Button
		if play == null or play.size.x < 72.0 or play.size.y < 42.0 or play.get_theme_font_size("font_size") < 14:
			failures.append("Selector play CTA is not explicit/readable for %s" % game_id)
		var title := _find_node_named(main, "SelectorGameTitle_%s" % game_id) as Label
		if title == null or title.get_theme_font_size("font_size") < 22:
			failures.append("Selector title is too small for %s" % game_id)
		var desc := _find_node_named(main, "SelectorGameSubtitle_%s" % game_id) as Label
		if desc == null or desc.get_theme_font_size("font_size") < 14:
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

func _has_matching_shadow(node: Node, target: Control) -> bool:
	var wanted := Rect2(target.position, target.size)
	for found in node.find_children("FigmaShadow", "PanelContainer", true, false):
		var shadow := found as PanelContainer
		if shadow != null and Rect2(shadow.position, shadow.size).position.distance_to(wanted.position) <= 1.0 and Rect2(shadow.position, shadow.size).size.distance_to(wanted.size) <= 1.0:
			return true
	return false

func _find_node_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, wanted)
		if found != null:
			return found
	return null
