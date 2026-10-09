extends SceneTree

# Focused quality gate for live Block Puzzle drag scale, precise placement
# preview, accessibility and low-idle-cost mobile footprint feedback.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview := BlockDragPreview.new()
	root.add_child(preview)
	preview.configure([Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1)],Color("8b7cf6"),35.0)
	await process_frame
	var cell_size := float(preview.call("_display_cell_size",2,1))
	if not _check(absf(cell_size - 35.0) < 0.1,"Touch preview geometry ignores real 35px board cells"): return
	var centroid: Vector2 = preview.call("shape_centroid_local")
	# For the four-tile L, the occupied-cell mean should align with those
	# same 35px tiles, not a separate 88px drawing geometry.
	var origin := (preview.size - Vector2(3.0,2.0)*cell_size)*0.5
	var expected := origin + Vector2(1.75,0.75)*cell_size
	if not _check(centroid.distance_to(expected) < 0.1,"Block ghost centroid does not match visual layout"):return
	var source := FileAccess.get_file_as_string("res://scripts/ui/block_drag_preview.gd")
	var drawing := source.substr(source.find("func _draw() -> void:"),source.find("func _draw_block(")-source.find("func _draw() -> void:"))
	if not _check(drawing.contains("var cell := _display_cell_size(max_x, max_y)"),"Drawn preview uses a different cell size than placement centroid"):return
	if not _check(preview.target_scale == Vector2.ONE,"Block drag preview remains permanently magnified against live cells"):return
	preview.queue_free()

	var cell := BlockCellButton.new()
	root.add_child(cell)
	await process_frame
	if not _check(not cell.is_processing(),"Idle board cell needlessly processes frames"):return
	for _i in range(64):
		cell.set_drag_footprint(false,false)
	if not _check(not cell.is_processing(),"Inactive drag footprint woke a cell repeatedly"):return
	cell.set_drag_footprint(true,true,Color("8b7cf6"))
	if not _check(cell.footprint_active and cell.footprint_valid,"Valid drag footprint failed to appear"):return
	cell.set_drag_footprint(true,false,Color("8b7cf6"))
	if not _check(cell.footprint_active and not cell.footprint_valid,"Invalid drag footprint did not update validity"):return
	cell.set_drag_footprint(false,false)
	await _frames(4)
	if not _check(not cell.footprint_active,"Released footprint remained visible"):return
	cell.queue_free()

	var piece := BlockPieceButton.new()
	root.add_child(piece)
	piece.configure([Vector2i(0,0),Vector2i(1,0),Vector2i(1,1)],false,Color("8b7cf6"),1)
	if not _check(piece.focus_mode == Control.FOCUS_ALL,"Painted tray piece cannot receive keyboard/TalkBack focus"):return
	if not _check(piece.accessibility_name.contains("Block piece 2") and piece.accessibility_name.contains("3 tiles") and piece.accessibility_name.contains("2 columns by 2 rows"),"Tray piece accessibility does not convey shape"):return
	piece.configure([],false,Color("8b7cf6"),1)
	if not _check(piece.disabled and piece.accessibility_name.contains("Empty"),"Consumed tray slot still exposes stale piece narration"):return
	piece.queue_free()
	await process_frame

	var smooth_source := FileAccess.get_file_as_string("res://scripts/ui/smooth_block_piece_button.gd")
	var target_begin := smooth_source.find("func _update_touch_preview_position")
	var target_end := smooth_source.find("func _finish_touch_drag",target_begin)
	var target_block := smooth_source.substr(target_begin,target_end-target_begin)
	if not _check(target_block.contains("desired = _preview_position_for_origin(game, origin)"),"Floating ghost does not align with actual legal placement preview"):return
	print("BLOCK_DRAG_PREMIUM_ALIGNMENT_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, failure: String) -> bool:
	if ok: return true
	push_error(failure)
	quit(1)
	return false
