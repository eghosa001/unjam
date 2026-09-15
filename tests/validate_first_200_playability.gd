extends SceneTree

const LAST_LEVEL := 200

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _rescue_200(): return
	if not await _water_200(): return
	if not await _block_200(): return
	print("PLAYABILITY_200_OK: executed one legal gameplay action on levels 1-200 in Rescue Rush, Water Sort and Block Puzzle.")
	quit(0)

func _rescue_200() -> bool:
	for level in range(1, LAST_LEVEL + 1):
		var game = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
		game.level_number = level
		game.custom_level_data = root.get_node("LevelManager").call("load_level", level)
		root.add_child(game)
		await process_frame
		if game == null or not is_instance_valid(game):
			return _fail("Rescue Rush level %d did not instantiate" % level)
		var pieces: Array = game.get("pieces")
		var legal_index := -1
		for i in range(pieces.size()):
			if bool(game.call("is_path_clear", i)):
				legal_index = i
				break
		if legal_index < 0:
			return _fail("Rescue Rush level %d has no legal first action" % level)
		var before := 0
		for piece in pieces:
			if bool(piece.get("active", true)): before += 1
		game.call("escape_piece", legal_index, false)
		var after := 0
		for piece in game.get("pieces"):
			if bool(piece.get("active", true)): after += 1
		if after != before - 1:
			return _fail("Rescue Rush level %d did not execute its legal escape" % level)
		game.free()
		if level % 25 == 0:
			print("Rescue Rush playability: %d/%d" % [level, LAST_LEVEL])
	return true

func _water_200() -> bool:
	var game = (load("res://scenes/WaterSort.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	for level in range(1, LAST_LEVEL + 1):
		game.level_number = level
		game.daily_mode = false
		game.call("load_level")
		var tubes: Array = game.get("tubes")
		var from_idx := -1
		var to_idx := -1
		for a in range(tubes.size()):
			for b in range(tubes.size()):
				if a != b and bool(game.call("can_pour", a, b)):
					from_idx = a
					to_idx = b
					break
			if from_idx >= 0: break
		if from_idx < 0:
			game.free()
			return _fail("Water Sort level %d has no legal first pour" % level)
		var before_tubes: Array = game.get("tubes").duplicate(true)
		game.call("pour", from_idx, to_idx)
		if game.get("tubes") == before_tubes:
			game.free()
			return _fail("Water Sort level %d legal pour did not change state" % level)
		if level % 25 == 0:
			print("Water Sort playability: %d/%d" % [level, LAST_LEVEL])
		await process_frame
	game.free()
	return true

func _block_200() -> bool:
	var game = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	for level in range(1, LAST_LEVEL + 1):
		game.level_number = level
		game.daily_mode = false
		game.call("load_level")
		game.set("target_score", 999999)
		game.set("target_lines", 999999)
		var pieces: Array = game.get("pieces")
		var legal_piece := -1
		var legal_origin := Vector2i(-1, -1)
		for piece_index in range(pieces.size()):
			var shape: Array = pieces[piece_index]
			for y in range(8):
				for x in range(8):
					if bool(game.call("can_place", shape, Vector2i(x, y))):
						legal_piece = piece_index
						legal_origin = Vector2i(x, y)
						break
				if legal_piece >= 0: break
			if legal_piece >= 0: break
		if legal_piece < 0:
			game.free()
			return _fail("Block Puzzle level %d has no legal first placement" % level)
		var before_placements := int(game.get("placements"))
		game.call("select_piece", legal_piece)
		game.call("place_selected", legal_origin)
		if int(game.get("placements")) != before_placements + 1:
			game.free()
			return _fail("Block Puzzle level %d legal placement did not execute" % level)
		# Clear transient effect nodes to keep a 200-level soak bounded.
		var fx = game.get("effects_layer")
		if fx != null and is_instance_valid(fx):
			for child in fx.get_children():
				child.free()
		if level % 25 == 0:
			print("Block Puzzle playability: %d/%d" % [level, LAST_LEVEL])
		await process_frame
	game.free()
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
