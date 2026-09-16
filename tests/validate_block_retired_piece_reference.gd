extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/game/block_puzzle_polished.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	var text := "" if file == null else file.get_as_text()
	if text.contains("PolishedBlockPieceButton"):
		push_error("Block Puzzle still references retired PolishedBlockPieceButton")
		quit(1)
		return
	if not text.contains("var button := BlockPieceButton.new()"):
		push_error("Block Puzzle fallback piece renderer must use the maintained BlockPieceButton")
		quit(1)
		return
	print("Block Puzzle retired piece reference cleanup validated.")
	quit(0)
