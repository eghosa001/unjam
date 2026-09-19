extends SceneTree

const VIEWPORT := Vector2i(540, 960)

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
	await _frames(8)

	if not _assert_fit(game, "initial"):
		return

	var status := game.find_child("BlockStatus", true, false) as Label
	var hint := game.find_child("BlockHint", true, false) as Label
	var boosters := game.find_child("CampaignBoosters", true, false) as Control
	if status == null or hint == null or boosters == null:
		return _fail("Block compact feedback/booster structure is incomplete")
	if status.text.strip_edges().is_empty() and status.custom_minimum_size.y > 1.0:
		return _fail("Blank Block status row still reserves vertical space on a short phone")
	if hint.get_theme_font_size("font_size") < 20:
		return _fail("Block compact feedback text became unreadably small")

	status.text = "Doesn't fit"
	game.call("_fit_3d_board_layout")
	await _frames(3)
	if not _assert_fit(game, "visible feedback"):
		return

	game.queue_free()
	await _frames(2)
	print("BLOCK_COMPACT_FIT_OK: board, tray, boosters and feedback remain inside 540x960 with readable text.")
	quit(0)

func _assert_fit(game: Control, phase: String) -> bool:
	var screen := Rect2(Vector2.ZERO, Vector2(VIEWPORT))
	for name in ["BlockHeader", "BlockScoreCard", "BlockObjectiveCard", "BlockBoardShell", "BlockTray", "CampaignBoosters", "BlockStatus", "BlockHint"]:
		var control := game.find_child(name, true, false) as Control
		if control == null:
			if name == "BlockBoardShell":
				control = game.get("board_shell") as Control
		if control == null:
			return _fail("%s is missing during Block compact %s audit" % [name, phase])
		var rect := control.get_global_rect()
		if rect.position.x < -2.0 or rect.position.y < -2.0 or rect.end.x > screen.end.x + 2.0 or rect.end.y > screen.end.y + 2.0:
			return _fail("%s spills outside 540x960 during %s: %s" % [name, phase, str(rect)])
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
