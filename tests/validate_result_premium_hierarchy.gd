extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1080, 1920)
	var overlay := PremiumResultOverlay.new()
	overlay.configure(
		"LEVEL COMPLETE",
		"Clean play. Strong route. Keep the streak moving.",
		"7 MOVES   •   PERFECT ≤ 8\n1 RESCUE SECURED",
		3,
		Color("2dd4b6"),
		"NEXT PUZZLE"
	)
	root.add_child(overlay)
	await _frames(5)
	var card := overlay.find_child("ResultCard3D", true, false) as Control
	var primary := overlay.find_child("PrimaryAction", true, false) as Button
	var performance := _find_label_with(overlay, "PERFORMANCE")
	if card == null or not _inside(card.get_global_rect(), root.get_visible_rect().size):
		return _fail("Premium result card does not fit the viewport")
	if card.custom_minimum_size.y > 840.0:
		return _fail("Premium result card reverted to an oversized low-density shell")
	if primary == null or primary.custom_minimum_size.y < 84.0:
		return _fail("Result primary action is not a large mobile touch target")
	if performance == null:
		return _fail("Result screen is missing its performance hierarchy")
	var stars := 0
	for node in _all_nodes(overlay):
		if node is Label and (node as Label).text == "★":
			stars += 1
	if stars != 3:
		return _fail("Result celebration does not render three earned stars")
	overlay.queue_free()
	await process_frame
	print("Premium result hierarchy validated.")
	quit(0)

func _all_nodes(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all_nodes(child))
	return out

func _find_label_with(node: Node, fragment: String) -> Label:
	if node is Label and fragment in (node as Label).text:
		return node as Label
	for child in node.get_children():
		var found := _find_label_with(child, fragment)
		if found != null:
			return found
	return null

func _inside(rect: Rect2, size: Vector2) -> bool:
	return rect.position.x >= -2.0 and rect.position.y >= -2.0 and rect.end.x <= size.x + 2.0 and rect.end.y <= size.y + 2.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
