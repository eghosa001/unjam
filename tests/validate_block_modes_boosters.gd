extends SceneTree

const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")

var save_manager: Node
var economy_manager: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	save_manager = root.get_node_or_null("SaveManager")
	economy_manager = root.get_node_or_null("EconomyManager")
	if save_manager == null or economy_manager == null:
		return _fail("Required economy/save autoloads are unavailable")
	var original_data: Dictionary = (save_manager.get("data") as Dictionary).duplicate(true)
	var working_data: Dictionary = save_manager.get("data")
	working_data["coins"] = 1000
	save_manager.set("data", working_data)
	save_manager.call("save")

	if not await _validate_boosters():
		_restore(original_data)
		return
	if not await _validate_modes():
		_restore(original_data)
		return
	if not await _validate_launcher():
		_restore(original_data)
		return

	_restore(original_data)
	print("BLOCK_MODES_BOOSTERS_OK")
	quit(0)

func _validate_boosters() -> bool:
	var game = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	game.level_number = 5
	game.play_mode = "campaign"
	root.add_child(game)
	await _frames(2)
	if game.booster_buttons.size() != 4:
		game.queue_free()
		return _fail("Block Puzzle does not expose all four boosters")

	var before := int(economy_manager.call("balance"))
	game.call("_use_booster", "shuffle")
	if int(economy_manager.call("balance")) != before - int(game.BOOSTER_COSTS["shuffle"]):
		game.queue_free()
		return _fail("Shuffle booster did not charge the configured coin cost")
	if game.pieces.size() != 3 or (game.pieces[0] as Array).size() != 1:
		game.queue_free()
		return _fail("Shuffle booster did not create a legal rescue tray")

	for y in range(8):
		for x in range(8):
			game.cells[y][x] = false
			game.cell_colors[y][x] = Color.TRANSPARENT
	game.campaign_special_cells.clear()
	game.pieces = [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		Generator.SHAPES[0].duplicate(),
		Generator.SHAPES[0].duplicate()
	]
	game.piece_colors = [Color.WHITE, Color.WHITE, Color.WHITE]
	game.selected_piece = 0
	var before_rotation := String(game.call("_shape_signature", game.pieces[0]))
	before = int(economy_manager.call("balance"))
	game.call("_use_booster", "rotate")
	if int(economy_manager.call("balance")) != before - int(game.BOOSTER_COSTS["rotate"]):
		game.queue_free()
		return _fail("Rotate booster did not charge its coin cost")
	if String(game.call("_shape_signature", game.pieces[0])) == before_rotation:
		game.queue_free()
		return _fail("Rotate booster did not rotate the selected asymmetric block")

	game.cells[0][0] = true
	game.cell_colors[0][0] = Color.WHITE
	before = int(economy_manager.call("balance"))
	game.call("_use_booster", "hammer")
	if int(economy_manager.call("balance")) != before - int(game.BOOSTER_COSTS["hammer"]):
		game.queue_free()
		return _fail("Hammer booster did not charge its coin cost")
	if bool(game.cells[0][0]):
		game.queue_free()
		return _fail("Hammer booster did not remove a blocking cell")

	game.pieces = [
		Generator.SHAPES[0].duplicate(),
		Generator.SHAPES[0].duplicate(),
		Generator.SHAPES[0].duplicate()
	]
	game.piece_colors = [Color.WHITE, Color.WHITE, Color.WHITE]
	game.selected_piece = 0
	var before_placements := int(game.placements)
	game.place_selected(Vector2i(0, 0))
	await process_frame
	if int(game.placements) != before_placements + 1 or game.history.is_empty():
		game.queue_free()
		return _fail("Undo fixture could not create a reversible move")
	before = int(economy_manager.call("balance"))
	game.call("_use_booster", "undo")
	if int(economy_manager.call("balance")) != before - int(game.BOOSTER_COSTS["undo"]):
		game.queue_free()
		return _fail("Undo booster did not charge its coin cost")
	if int(game.placements) != before_placements:
		game.queue_free()
		return _fail("Undo booster did not restore the prior placement count")

	game.queue_free()
	await _frames(2)
	return true

func _validate_modes() -> bool:
	var campaign = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	campaign.level_number = 100
	campaign.play_mode = "campaign"
	root.add_child(campaign)
	await _frames(2)
	if campaign.campaign_move_limit != -1:
		campaign.queue_free()
		return _fail("Normal campaign must not hard-fail on a move limit")
	var tray_count := (campaign.campaign_plan.get("trays", []) as Array).size()
	campaign.piece_batch = tray_count
	campaign.refill_pieces()
	if campaign.pieces.size() != 3:
		campaign.queue_free()
		return _fail("Campaign did not continue after its proof trays were exhausted")
	if not campaign.any_move_available() and campaign.call("_shape_has_legal_move", Generator.SHAPES[0]):
		campaign.queue_free()
		return _fail("Campaign continuation created a false no-move loss while space remained")
	campaign.queue_free()
	await _frames(2)

	var zen = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	zen.level_number = 100
	zen.play_mode = "zen"
	root.add_child(zen)
	await _frames(2)
	zen.score = zen.target_score
	zen.lines_cleared = zen.target_lines
	if zen.campaign_move_limit != -1 or zen.reached_goal():
		zen.queue_free()
		return _fail("Zen mode must have no move limit and no completion target")
	if zen.campaign_plan.size() != 0:
		zen.queue_free()
		return _fail("Zen mode should not consume the finite campaign proof")
	zen.queue_free()
	await _frames(2)

	var endless = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	endless.level_number = 100
	endless.play_mode = "endless"
	root.add_child(endless)
	await _frames(2)
	if endless.pieces.size() != 3 or endless.campaign_move_limit != -1:
		endless.queue_free()
		return _fail("Endless mode did not initialize its survival tray correctly")
	endless.queue_free()
	await _frames(2)

	var extreme = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	extreme.level_number = 1000
	extreme.play_mode = "extreme"
	root.add_child(extreme)
	await _frames(2)
	if extreme.campaign_plan.is_empty():
		extreme.queue_free()
		return _fail("Extreme mode has no constructive solution plan")
	if extreme.campaign_move_limit <= 0:
		extreme.queue_free()
		return _fail("Extreme mode must enforce a proof-based move limit")
	var normal_score := int(extreme.Progression.profile(1000).get("difficulty_score", 0))
	if int(extreme.campaign_profile.get("difficulty_score", 0)) <= normal_score:
		extreme.queue_free()
		return _fail("Extreme mode did not increase the campaign difficulty profile")
	extreme.queue_free()
	await _frames(2)
	return true

func _validate_launcher() -> bool:
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(3)
	main.call("start_block_mode", "zen")
	await _frames(3)
	var game = main.get("active_game")
	if game == null or String(game.get("play_mode")) != "zen":
		main.queue_free()
		return _fail("Main UI did not launch Block Puzzle Zen mode")
	main.queue_free()
	await _frames(2)
	return true

func _restore(data: Dictionary) -> void:
	if save_manager == null:
		return
	save_manager.set("data", data)
	save_manager.call("save")

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
