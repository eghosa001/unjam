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
	var detach := block.find("piece_row.remove_child(child)")
	var free := block.find("child.queue_free()")
	if detach < 0 or free < 0 or detach > free:
		push_error("Block Puzzle piece tray can overlap old and new drag controls")
		quit(1)
		return
	print("Block Puzzle piece tray rebuild is atomic.")
	quit(0)
