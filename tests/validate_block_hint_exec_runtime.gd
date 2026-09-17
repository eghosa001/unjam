extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	for y in range(8):
		for x in range(8):
			game.cells[y][x] = false
			game.cell_colors[y][x] = Color.TRANSPARENT
	for x in range(7):
		game.cells[0][x] = true
		game.cell_colors[0][x] = Color("466df2")
	game.pieces = [
		[Vector2i(0, 0)],
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
	]
	game.piece_colors = [Color("39df63"), Color("ef4248"), Color("f4b83d")]
	game.selected_piece = -1
	game.render()
	var best: Dictionary = game.call("_best_hint_placement")
	if int(best.get("piece", -1)) != 0 or best.get("origin", Vector2i(-1, -1)) != Vector2i(7, 0):
		push_error("Block hint did not prioritize the immediate line clear: %s" % str(best))
		quit(1)
		return
	var before_placements: int = int(game.placements)
	game.call("show_hint")
	await create_timer(0.8).timeout
	if int(game.placements) != before_placements + 1 or int(game.lines_cleared) < 1:
		push_error("Block hint did not execute the selected best placement")
		quit(1)
		return
	print("BLOCK_HINT_EXEC_OK")
	game.queue_free()
	await process_frame
	quit(0)
