extends SceneTree

const VIEWPORT := Vector2i(540,960)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		return _fail("Block Puzzle scene failed to load")
	var game := packed.instantiate() as Control
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(10)

	var canvas := game.find_child("FigmaBlock390x844",true,false) as Control
	var board := game.find_child("BlockBoardShell",true,false) as Control
	var tray := game.find_child("BlockTray",true,false) as Control
	var boosters := game.find_child("CampaignBoosters",true,false) as Control
	var status := game.find_child("BlockStatus",true,false) as Control
	var hint := game.find_child("BlockHint",true,false) as Control
	if canvas == null or board == null or tray == null or boosters == null or status == null or hint == null:
		return _fail("Figma Block gameplay hierarchy is incomplete")
	if not _rect_eq(Rect2(board.position,board.size),Rect2(29,179,330,330)):
		return _fail("Block board drifted from Figma 330x330 geometry")
	if not _rect_eq(Rect2(tray.position,tray.size),Rect2(17,534,354,104)):
		return _fail("Block tray drifted from Figma 354x104 geometry")
	if not _rect_eq(Rect2(boosters.position,boosters.size),Rect2(17,649,349,54)):
		return _fail("Block booster row drifted from Figma geometry")
	if not _rect_eq(Rect2(status.position,status.size),Rect2(18,712,354,20)):
		return _fail("Block status row drifted from Figma geometry")
	if not _rect_eq(Rect2(hint.position,hint.size),Rect2(18,734,354,20)):
		return _fail("Block hint row drifted from Figma geometry")

	var screen := Rect2(Vector2.ZERO,root.get_visible_rect().size)
	for control in [board,tray,boosters,status,hint]:
		if not _inside((control as Control).get_global_rect(),screen):
			return _fail("%s spills outside the viewport" % control.name)

	game.call("_fit_3d_board_layout")
	await _frames(3)
	if not _rect_eq(Rect2(board.position,board.size),Rect2(30,180,330,330)):
		return _fail("Responsive fitter overwrote audited Figma Block board geometry")

	game.queue_free()
	await process_frame
	print("BLOCK_FIGMA_FIT_OK: board, tray, boosters and feedback preserve audited geometry.")
	quit(0)

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
