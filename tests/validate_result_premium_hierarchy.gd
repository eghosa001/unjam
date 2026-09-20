extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var overlay := PremiumResultOverlay.new()
	overlay.configure(
		"RESCUE COMPLETE",
		"Rescue secured. The path is clear.",
		"9 MOVES • +75 COINS\n3★: 0 ERRORS • NO HINT/UNDO • ≤ 11",
		3,
		Color("2dd4b6"),
		"NEXT RESCUE"
	)
	overlay.configure_secondary("DOUBLE BASE REWARD",true)
	root.add_child(overlay)
	await _frames(6)

	var canvas := overlay.find_child("FigmaResult390x844",true,false) as Control
	var card := overlay.find_child("ResultCard3D",true,false) as Control
	var primary := overlay.find_child("PrimaryAction",true,false) as Button
	var secondary := overlay.find_child("SecondaryAction",true,false) as Button
	var stats := overlay.find_child("ResultStatsText",true,false) as Label
	if canvas == null or card == null or primary == null or secondary == null or stats == null:
		return _fail("Figma result hierarchy is incomplete")
	if not _rect_eq(Rect2(card.position,card.size),Rect2(28,86,334,590)):
		return _fail("Result card drifted from Figma 334x590 geometry")
	if not _rect_eq(Rect2(primary.position,primary.size),Rect2(48,500,294,58)):
		return _fail("Result primary action drifted from Figma geometry")
	if not _rect_eq(Rect2(secondary.position,secondary.size),Rect2(48,570,294,48)):
		return _fail("Result secondary action drifted from Figma geometry")
	if stats.text.is_empty():
		return _fail("Result stats are missing")
	var star_count := 0
	for node in _all_nodes(overlay):
		if node is Label and (node as Label).text == "★":
			star_count += 1
	if star_count != 3:
		return _fail("Result celebration does not render three earned stars")
	var screen := Rect2(Vector2.ZERO,root.get_visible_rect().size)
	if not _inside(card.get_global_rect(),screen):
		return _fail("Figma result card spills outside viewport")

	overlay.queue_free()
	await process_frame
	print("Figma result hierarchy validated.")
	quit(0)

func _all_nodes(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all_nodes(child))
	return out

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _inside(rect: Rect2, viewport: Rect2) -> bool:
	return rect.position.x >= -2.0 and rect.position.y >= -2.0 and rect.end.x <= viewport.end.x + 2.0 and rect.end.y <= viewport.end.y + 2.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
