extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/game/block_puzzle.gd", FileAccess.READ)
	if file == null:
		push_error("Block Puzzle source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["_clear_transition_active", "_plan_line_clear", "await _animate_line_clear", "_commit_line_clear"]:
		if not source.contains(needle):
			push_error("Block Puzzle clear transition is missing: " + needle)
			quit(1)
			return
	var await_pos := source.find("await _animate_line_clear")
	var commit_pos := source.find("_commit_line_clear", await_pos)
	if await_pos < 0 or commit_pos <= await_pos:
		push_error("Block Puzzle commits cleared cells before the clear animation finishes")
		quit(1)
		return
	print("Block Puzzle clear ordering validated.")
	quit(0)
