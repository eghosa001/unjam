extends SceneTree

func _initialize() -> void:
	var motion_file := FileAccess.open("res://scripts/game/block_puzzle_ultra_motion.gd", FileAccess.READ)
	var piece_file := FileAccess.open("res://scripts/ui/block_piece_button.gd", FileAccess.READ)
	if motion_file == null or piece_file == null:
		push_error("Block Puzzle touch sources are missing")
		quit(1)
		return
	var motion := motion_file.get_as_text()
	var piece := piece_file.get_as_text()
	if not motion.contains("set_process_input(false)"):
		push_error("Active Block Puzzle scene-wide touch handler is still enabled")
		quit(1)
		return
	if not piece.contains("func _gui_input(") or not piece.contains("accept_event()"):
		push_error("Block piece does not own and consume its touch drag")
		quit(1)
		return
	print("Block Puzzle has one active mobile touch owner.")
	quit(0)
