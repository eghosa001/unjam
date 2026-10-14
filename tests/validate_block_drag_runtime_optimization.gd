extends SceneTree

# Scope: Block Puzzle hot path. Never run broad gameplay suites just to
# verify an idempotent 64-cell highlight and Android update version.
func _initialize() -> void:
	var piece := FileAccess.get_file_as_string("res://scripts/ui/block_piece_button.gd")
	var smooth := FileAccess.get_file_as_string("res://scripts/ui/smooth_block_piece_button.gd")
	var board := FileAccess.get_file_as_string("res://scripts/ui/block_cell_button.gd")
	if piece.is_empty() or smooth.is_empty() or board.is_empty():
		return _fail("Missing Block Puzzle source")
	var drag := piece.substr(piece.find("elif event is InputEventScreenDrag:"),500)
	if drag.count("_update_touch_preview_position(screen_position)") > 0:
		return _fail("Touch drag still updates magnetic preview twice")
	if not smooth.contains("if origin == _last_footprint_origin and valid == _last_footprint_valid:"):
		return _fail("Unchanged target still redraws all 64 cells")
	if not smooth.contains("_last_footprint_origin = Vector2i(-1,-1)"):
		return _fail("Drag cleanup does not reset cached magnet footprint")
	if not board.contains("DRAW_STYLE_CACHE_LIMIT := 24") or not board.contains("_draw_style_cache.clear()"):
		return _fail("Draw style resource cache can grow without bounds")
	print("BLOCK_DRAG_RUNTIME_OPTIMIZATION_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
