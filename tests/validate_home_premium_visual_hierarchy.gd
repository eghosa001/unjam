extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene could not be loaded")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var home := _find_node_named(main, "PremiumHomeCasual")
	if home == null:
		home = _find_node_with_method(main, "build_home_launcher")
	if home == null:
		failures.append("Premium Home surface is missing")
	else:
		if _find_node_named(home, "ExplorerSignStack") != null:
			failures.append("Home still contains the cluttered explorer sign stack")
		var mascot := _find_node_named(home, "HomeMascot3D") as Control
		var mascot_min_width := 420.0 if root.size.x < 700 else 640.0
		if mascot == null or mascot.custom_minimum_size.x < mascot_min_width:
			failures.append("Home mascot is not the dominant centered hero")
		var hero := _find_node_named(home, "HomeHero3D") as Control
		if hero == null or hero.custom_minimum_size.y > 480.0:
			failures.append("Home hero is still too tall/crowded")
		var strip := _find_node_named(home, "HomeGameStrip")
		if strip == null or strip.get_child_count() != 3:
			failures.append("Home does not have the clean three-game strip")
		var nav := _find_node_named(home, "HomeBottomNav3D") as Control
		var motto := _find_node_named(home, "HomeMottoStone") as Control
		var primary := _find_node_named(home, "HomePrimaryAction") as Button
		if nav == null or motto == null or primary == null:
			failures.append("Compact Home responsive structure is incomplete")
		else:
			if motto.get_global_rect().end.y > nav.get_global_rect().position.y + 2.0:
				failures.append("Compact Home content still runs behind the bottom navigation")
			if primary.get_theme_font_size("font_size") < 23:
				failures.append("Compact Home primary action text became too small")
		if _find_label_with(home, "Small\nPuzzles") != null:
			failures.append("Home still contains the competing right-side quote card")

	main.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Home premium visual hierarchy validated.")
	quit(0)

func _find_node_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, wanted)
		if found != null:
			return found
	return null

func _find_node_with_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
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
