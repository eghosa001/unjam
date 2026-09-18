extends SceneTree

const VIEWPORTS := [
	Vector2i(540, 960),
	Vector2i(720, 1280),
	Vector2i(1080, 1920),
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_source_contracts():
		return
	if not await _validate_shape_sanitizing():
		return
	for viewport_size in VIEWPORTS:
		if not await _validate_runtime(viewport_size):
			return
	print("BLOCK_VISUAL_INTEGRITY_OK")
	quit(0)

func _validate_source_contracts() -> bool:
	var cell_source := _read("res://scripts/ui/block_cell_button.gd")
	var motion_source := _read("res://scripts/game/block_puzzle_ultra_motion.gd")
	var piece_source := _read("res://scripts/ui/block_piece_button.gd")
	if cell_source.is_empty() or motion_source.is_empty() or piece_source.is_empty():
		return _fail("Block Puzzle visual sources are missing")
	var footprint_start := cell_source.find("if footprint_active:")
	var footprint_end := cell_source.find("if clear_phase", footprint_start)
	if footprint_start < 0 or footprint_end < 0:
		return _fail("Block Puzzle footprint rendering contract is missing")
	var footprint_block := cell_source.substr(footprint_start, footprint_end - footprint_start)
	if footprint_block.contains("_draw_block("):
		return _fail("Drag footprint still renders a second full 3D brick")
	if not motion_source.contains("Keep exactly one stable control per tray slot"):
		return _fail("Piece tray still uses destructive full rebuilds")
	if not piece_source.contains("_sanitize_shape") or not piece_source.contains("Detach synchronously"):
		return _fail("Piece visual deduplication/orphan-preview cleanup is missing")
	return true

func _validate_shape_sanitizing() -> bool:
	var button := SmoothBlockPieceButton.new()
	root.add_child(button)
	button.configure([
		Vector2i(0, 0),
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 0),
	], false, Color.WHITE, 0)
	await process_frame
	var visual_shape: Array = button.shape
	if visual_shape.size() != 3:
		button.queue_free()
		return _fail("Duplicate brick coordinates are still retained by the tray renderer")
	button.queue_free()
	await process_frame
	return true

func _validate_runtime(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		return _fail("BlockPuzzle.tscn could not be loaded")
	var game := packed.instantiate() as Control
	game.level_number = 1800
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)

	var viewport_rect := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var critical_names := [
		"BlockHeader", "BlockScoreCard", "BlockObjectiveCard", "BlockBoardHolder",
		"BlockTray", "BlockPieceRow", "CampaignBoosters", "BlockStatus", "BlockHint"
	]
	for node_name in critical_names:
		var control := game.find_child(node_name, true, false) as Control
		if control == null:
			game.queue_free()
			return _fail("Missing Block Puzzle visual control %s" % node_name)
		if not _inside(control.get_global_rect(), viewport_rect):
			var bad_rect := control.get_global_rect()
			game.queue_free()
			return _fail("%s spills outside %s: %s" % [node_name, str(viewport_size), str(bad_rect)])

	var piece_row = game.get("piece_row") as HBoxContainer
	if piece_row == null or piece_row.get_child_count() != 3:
		game.queue_free()
		return _fail("Block Puzzle tray does not contain exactly three visual slots")
	var original_ids: Array[int] = []
	for child in piece_row.get_children():
		if not child is SmoothBlockPieceButton:
			game.queue_free()
			return _fail("Block Puzzle tray contains a retired/non-smooth piece renderer")
		original_ids.append(child.get_instance_id())
		if not _inside((child as Control).get_global_rect(), viewport_rect):
			game.queue_free()
			return _fail("Piece tray control spills outside %s" % str(viewport_size))

	for _i in range(6):
		game.call("render_pieces")
	await _frames(2)
	if piece_row.get_child_count() != 3:
		game.queue_free()
		return _fail("Repeated tray renders changed the number of visible piece controls")
	for i in range(3):
		if piece_row.get_child(i).get_instance_id() != original_ids[i]:
			game.queue_free()
			return _fail("Repeated tray render replaced slot %d instead of reusing it" % i)

	var first := piece_row.get_child(0) as SmoothBlockPieceButton
	var effects = game.get("effects_layer") as Control
	if first == null or effects == null:
		game.queue_free()
		return _fail("Tray preview fixture is incomplete")
	var screen_point := first.get_global_rect().get_center()
	for _i in range(4):
		first.call("_show_touch_preview", screen_point)
	await process_frame
	if _drag_preview_count(effects) != 1:
		game.queue_free()
		return _fail("One tray piece created multiple simultaneous floating previews")
	var preview = first.touch_preview as BlockDragPreview
	if preview == null:
		game.queue_free()
		return _fail("Floating preview was not created")
	var cells = game.get("cell_buttons") as Array
	if cells.is_empty():
		game.queue_free()
		return _fail("Block board has no cells")
	var board_cell := cells[0] as Control
	if board_cell == null or absf(preview.board_cell_size - minf(board_cell.size.x, board_cell.size.y)) > 1.0:
		game.queue_free()
		return _fail("Floating preview does not scale from the live board cell size")
	first.call("dispose_visuals")
	if _drag_preview_count(effects) != 0:
		game.queue_free()
		return _fail("Floating preview remained after tray visual disposal")

	game.target_rows_pending.clear()
	game.target_rows_pending.append(2)
	game.target_cols_pending.clear()
	game.target_cols_pending.append(4)
	game.campaign_special_cells.clear()
	game.call("_render_special_cells")
	var row_cell = cells[2 * 8 + 1]
	var col_cell = cells[1 * 8 + 4]
	var cross_cell = cells[2 * 8 + 4]
	if String(row_cell.special_kind) != "row_target" or String(col_cell.special_kind) != "col_target" or String(cross_cell.special_kind) != "cross_target":
		game.queue_free()
		return _fail("Designated row/column markers are visually ambiguous")

	game.queue_free()
	await _frames(2)
	return true

func _drag_preview_count(root_control: Control) -> int:
	var count := 0
	for child in root_control.get_children():
		if child is BlockDragPreview:
			count += 1
	return count

func _inside(rect: Rect2, viewport_rect: Rect2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= viewport_rect.position.x - epsilon \
		and rect.position.y >= viewport_rect.position.y - epsilon \
		and rect.end.x <= viewport_rect.end.x + epsilon \
		and rect.end.y <= viewport_rect.end.y + epsilon

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
