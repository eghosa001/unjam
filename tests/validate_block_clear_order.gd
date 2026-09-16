extends SceneTree

func _initialize() -> void:
	var scene_file := FileAccess.open("res://scenes/BlockPuzzle.tscn", FileAccess.READ)
	if scene_file == null:
		push_error("Block Puzzle scene is missing")
		quit(1)
		return
	var scene_source := scene_file.get_as_text()
	if not scene_source.contains("block_puzzle_3d.gd") or scene_source.contains("block_puzzle_3d_clear.gd"):
		push_error("Block Puzzle clear transaction is not consolidated into the active 3D layer")
		quit(1)
		return
	var file := FileAccess.open("res://scripts/game/block_puzzle_3d.gd", FileAccess.READ)
	if file == null:
		push_error("Block Puzzle 3D source is missing")
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
	print("Block Puzzle clear ordering validated in the active 3D layer.")
	quit(0)
