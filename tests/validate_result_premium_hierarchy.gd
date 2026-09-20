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

	var card := overlay.find_child("ResultCard3D",true,false) as Control
	var title := overlay.find_child("ResultTitle",true,false) as Label
	var subtitle := overlay.find_child("ResultSubtitle",true,false) as Label
	var primary := overlay.find_child("PrimaryAction",true,false) as Button
	var secondary := overlay.find_child("SecondaryAction",true,false) as Button
	var secondary_shadow := overlay.find_child("SecondaryActionShadow",true,false) as Control
	var stats := overlay.find_child("ResultStatsText",true,false) as Label
	if card == null or title == null or subtitle == null or primary == null or secondary == null or secondary_shadow == null or stats == null:
		return _fail("Result hierarchy is incomplete")
	if not _rect_eq(Rect2(card.position,card.size),Rect2(27,76,334,570)):
		return _fail("Result card geometry drifted")
	if not _rect_eq(Rect2(primary.position,primary.size),Rect2(47,498,294,58)):
		return _fail("Result primary geometry drifted")
	if not _rect_eq(Rect2(secondary.position,secondary.size),Rect2(47,568,294,48)):
		return _fail("Result secondary geometry drifted")
	if not secondary_shadow.visible:
		return _fail("Visible secondary action lost its shadow")
	if title.get_rect().intersects(subtitle.get_rect()):
		return _fail("Result title overlaps subtitle")
	var stats_panel := overlay.find_child("Stats",true,false) as Control
	var first_star := overlay.find_child("StarCard",true,false) as Control
	if first_star != null and subtitle.get_rect().intersects(first_star.get_rect()):
		return _fail("Result subtitle overlaps star row")
	if stats_panel != null and primary.get_rect().intersects(stats_panel.get_rect()):
		return _fail("Result stats overlap primary action")
	for node in overlay.find_children("StarCard","PanelContainer",true,false):
		if stats_panel != null and (node as Control).get_rect().intersects(stats_panel.get_rect()):
			return _fail("Result stars overlap stats panel")
	if stats.text.is_empty():
		return _fail("Result stats are missing")

	overlay.queue_free()
	await _frames(2)

	var block_result := PremiumResultOverlay.new()
	block_result.configure(
		"BLOCK PUZZLE COMPLETE",
		"Strong placements. Clean lines. Space controlled.",
		"SCORE 640 • 4 LINES\n7 PLACEMENTS",
		3,
		Color("8b7cf6"),
		"NEXT PUZZLE"
	)
	root.add_child(block_result)
	await _frames(5)
	var block_card := block_result.find_child("ResultCard3D",true,false) as Control
	var hidden_secondary := block_result.find_child("SecondaryAction",true,false) as Button
	var hidden_shadow := block_result.find_child("SecondaryActionShadow",true,false) as Control
	if block_card == null or hidden_secondary == null or hidden_shadow == null:
		return _fail("Block result hierarchy is incomplete")
	if not _rect_eq(Rect2(block_card.position,block_card.size),Rect2(27,76,334,500)):
		return _fail("Result without secondary action did not collapse its empty slot")
	if hidden_secondary.visible or hidden_shadow.visible:
		return _fail("Hidden secondary result action still leaves a visible placeholder")

	block_result.queue_free()
	await process_frame
	print("Result hierarchy validated without collisions or empty action slots.")
	quit(0)

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
