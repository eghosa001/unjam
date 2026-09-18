extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/game/block_puzzle_ultra_motion.gd", FileAccess.READ)
	if file == null:
		push_error("Block Puzzle motion source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func render_pieces()")
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start if finish > start else source.length() - start)
	if not block.contains("one stable control per tray slot"):
		push_error("Block Puzzle tray is not using stable slot renderers")
		quit(1)
		return
	if not block.contains("dispose_visuals"):
		push_error("Block Puzzle tray replacement does not clean external previews")
		quit(1)
		return
	if block.contains("for child in piece_row.get_children():\n\t\tpiece_row.remove_child(child)"):
		push_error("Block Puzzle still destroys the full tray on every render")
		quit(1)
		return
	print("Block Puzzle piece tray uses stable atomic slots.")
	quit(0)
