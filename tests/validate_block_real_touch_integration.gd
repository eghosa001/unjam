extends SceneTree

# Unlike the magnetic unit fixture, this loads the actual production
# BlockPuzzle.tscn with its Figma layout, full inheritance stack,
# real tray buttons, input routing, campaign state and scoreboard.
const Magnetic = preload("res://scripts/ui/block_magnetic_target.gd")
const SmoothPiece = preload("res://scripts/ui/smooth_block_piece_button.gd")
const GameScene = preload("res://scenes/BlockPuzzle.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, detail: String) -> bool:
	if ok:
		return true
	push_error("REAL_BLOCK_TOUCH_FAILED: " + detail)
	quit(1)
	return false

func _dispatch_touch(point: Vector2, is_pressed: bool, cancelled: bool = false) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = is_pressed
	touch.canceled = cancelled
	Input.parse_input_event(touch)

func _dispatch_drag(point: Vector2, from_point: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point
	drag.relative = point - from_point
	Input.parse_input_event(drag)

func _run() -> void:
	MultiGameManager.clear_checkpoint("block_puzzle")
	var game := GameScene.instantiate() as Control
	root.add_child(game)
	await _frames(6)
	if not _check(game.has_method("place_piece_from_drag"), "The scene did not load the production Block Puzzle class"): return
	# The actual scene can load a generated campaign puzzle. Use a deterministic
	# empty 8x8 board and known real tray shapes to isolate input behavior.
	game.set("campaign_special_cells", {})
	game.set("campaign_failed", false)
	game.set("_clear_transition_active", false)
	game.set("campaign_move_limit", -1)
	game.set("target_score", 999999)
	game.set("target_lines", 999)
	var empty_board: Array = []
	var empty_colors: Array = []
	for y in range(8):
		var row: Array = []
		var colors: Array = []
		for x in range(8):
			row.append(false)
			colors.append(Color.TRANSPARENT)
		empty_board.append(row)
		empty_colors.append(colors)
	game.set("cells", empty_board)
	game.set("cell_colors", empty_colors)
	game.set("pieces", [
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
		[Vector2i(0,0),Vector2i(0,1)],
		[Vector2i(0,0)]
	])
	game.set("piece_colors", [Color("#ffa64b"),Color("#5396fa"),Color("#89d16c")])
	game.set("placements", 0)
	game.call("render")
	await _frames(4)
	var row = game.get("piece_row") as Control
	if not _check(row != null and row.get_child_count() >= 3, "Production tray was not rendered"): return
	var piece = row.get_child(0) as SmoothBlockPieceButton
	if not _check(piece != null, "Production game is not using SmoothBlockPieceButton"): return
	var cells: Array = game.get("cell_buttons")
	var target_cell := cells[56] as Control  # Bottom-left cell: row 7, column 0.
	var target_point := target_cell.get_global_transform_with_canvas() * (target_cell.size * 0.5)
	var geo := Magnetic.geometry(game)
	if not _check(not geo.is_empty(), "Board geometry unavailable in real gameplay"): return
	var cell_step: Vector2 = geo["step"]
	var lift := Magnetic.lift_distance(game, geo)
	var tray_tile := float(piece.call("_tray_cell_size", 2, 0))
	var first_tile_local := (piece.size - Vector2(3.0, 1.0) * tray_tile) * 0.5 + Vector2.ONE * (tray_tile * 0.5)
	var start_point := piece.get_global_transform_with_canvas() * first_tile_local
	var move_point := target_point + Vector2(0.0, lift)
	print("REAL_BLOCK_TOUCH: viewport=", game.get_viewport_rect().size, " tray=", start_point, " board=", target_point, " lift=", lift, " step=", cell_step)
	# True viewport input events exercise both Godot's _input and Control
	# _gui_input paths; unit tests that call piece._input directly missed this.
	_dispatch_touch(start_point, true)
	await _frames(1)
	if not _check(piece.touch_drag_started and piece.is_processing_input(),
			"First physical-style press did not capture a tray piece"): return
	_dispatch_drag(move_point, start_point)
	await _frames(1)
	if not _check(piece.get("_preview_valid") and piece.get("_preview_snap_origin") == Vector2i(0,7),
			"First drag did not show a legal bottom-row snap in production UI"): return
	# Android may also synthesize the native pressed signal. It must NEVER
	# reconfigure the active tray piece and destroy the green preview.
	piece.pressed.emit()
	game.call("render_pieces")
	if not _check(piece.touch_drag_started and piece.get("_preview_valid"),
			"Native pressed/refresh disposed active touch while preview was green"): return
	# The original fault: a visibly legal placement bounced after an UP
	# coordinate outside the former tolerance, despite no red drag frame.
	_dispatch_touch(move_point + Vector2(0.0, cell_step.y * 2.7), false)
	await _frames(3)
	if not _check(int(game.get("placements")) == 1, "Real finger-up rejected the visible green bottom-row placement"): return
	if not _check(bool(game.get("cells")[7][0]) and bool(game.get("cells")[7][1]) and bool(game.get("cells")[7][2]),
			"Production board did not commit the same three cells highlighted in green"): return
	if not _check(game.get("active_touch_piece") == null, "Release leaked tray touch ownership"): return

	# A canceled press never drops a piece even when preview was green.
	var second = row.get_child(1) as SmoothBlockPieceButton
	if not _check(second != null, "Second real tray slot not available"): return
	var second_tile := float(second.call("_tray_cell_size",0,1))
	var second_start_local := (second.size - Vector2(1.0,2.0)*second_tile)*0.5 + Vector2.ONE*(second_tile*0.5)
	var second_start := second.get_global_transform_with_canvas() * second_start_local
	var second_target := (cells[35] as Control).get_global_transform_with_canvas() * ((cells[35] as Control).size*0.5)
	_dispatch_touch(second_start, true)
	await _frames(1)
	_dispatch_drag(second_target + Vector2(0.0, lift), second_start)
	await _frames(1)
	if not _check(second.get("_preview_valid"), "Second legal touch did not show green target"): return
	_dispatch_touch(second_target + Vector2(0.0,lift), false, true)
	await _frames(2)
	if not _check(int(game.get("placements")) == 1, "Canceled input incorrectly placed a piece"): return
	print("REAL_BLOCK_TOUCH_OK: production-scene touchscreen press, green snap, UI refresh guard, Android release jump, board commit and cancel")
	game.queue_free()
	await process_frame
	quit(0)
