extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_all_profiles():
		return
	if not _validate_global_progression_contract():
		return
	if not await _validate_runtime_contract():
		return
	print("BLOCK_10000_OK: 10,000 profiles, deterministic trays, worlds, milestones and finale contract validated.")
	quit(0)

func _validate_all_profiles() -> bool:
	var previous_world := 1
	var previous_seed := -1
	for level in range(1, Progression.MAX_LEVEL + 1):
		var p: Dictionary = Progression.profile(level)
		var score := int(p.get("difficulty_score", -1))
		var floor_score := int(p.get("difficulty_floor", -1))
		var ceiling_score := int(p.get("difficulty_ceiling", -1))
		var world := int(p.get("world", -1))
		if int(p.get("level_id", -1)) != level:
			return _fail("Profile id mismatch at level %d" % level)
		if int(p.get("board_size", -1)) != 8:
			return _fail("Level %d is not using the 8x8 campaign board" % level)
		if score < floor_score or score > ceiling_score:
			return _fail("Level %d difficulty %d escaped %d..%d" % [level, score, floor_score, ceiling_score])
		if world < 1 or world > 20 or world < previous_world:
			return _fail("Invalid world progression at level %d: %d" % [level, world])
		if bool(p.get("booster_required", true)):
			return _fail("Level %d incorrectly requires a booster" % level)
		if not bool(p.get("deterministic_trays", false)):
			return _fail("Level %d lost deterministic trays" % level)
		var seed := int(p.get("seed", -1))
		if seed == previous_seed:
			return _fail("Adjacent levels share a campaign seed at %d" % level)
		previous_seed = seed
		previous_world = world

	var finale: Dictionary = Progression.profile(10000)
	if int(finale.get("world", 0)) != 20:
		return _fail("Level 10000 must be World 20")
	if int(finale.get("level_in_world", 0)) != 500:
		return _fail("Level 10000 must be World 20 level 500")
	if String(finale.get("milestone", "")) != "finale":
		return _fail("Level 10000 must be the finale")
	if int(finale.get("difficulty_score", 0)) < 97:
		return _fail("Level 10000 difficulty must be at least 97")
	if int(finale.get("planning_horizon", 0)) < 12:
		return _fail("Level 10000 must target 12-move planning")
	if int(finale.get("piece_tier", 0)) != 6:
		return _fail("Level 10000 must unlock the full piece library")
	if int(finale.get("move_limit", -1)) <= 0:
		return _fail("Level 10000 must be move-limited")
	return true

func _validate_global_progression_contract() -> bool:
	var multi := root.get_node_or_null("MultiGameManager")
	if multi == null:
		return _fail("MultiGameManager missing")
	if int(multi.call("world_count_for", "block_puzzle")) != 20:
		return _fail("Block Puzzle must expose 20 worlds")
	if int(multi.call("world_for_game_level", "block_puzzle", 500)) != 1:
		return _fail("Level 500 must remain in World 1")
	if int(multi.call("world_for_game_level", "block_puzzle", 501)) != 2:
		return _fail("Level 501 must open World 2")
	if int(multi.call("first_level_in_game_world", "block_puzzle", 20)) != 9501:
		return _fail("World 20 must start at level 9501")
	if int(multi.call("last_level_in_game_world", "block_puzzle", 20)) != 10000:
		return _fail("World 20 must end at level 10000")
	return true

func _validate_runtime_contract() -> bool:
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null:
		return _fail("BlockPuzzle scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var samples := [1, 100, 500, 1000, 2500, 5000, 7500, 9000, 10000]
	for level in samples:
		var p: Dictionary = game.call("campaign_profile_for_level", level)
		if int(p.get("level_id", -1)) != level:
			game.queue_free()
			return _fail("Runtime profile mismatch at %d" % level)
		var a := String(game.call("deterministic_tray_signature", level, 3))
		var b := String(game.call("deterministic_tray_signature", level, 3))
		if a.is_empty() or a != b:
			game.queue_free()
			return _fail("Tray sequence is not deterministic at level %d" % level)
		if a.split("|").size() != 3:
			game.queue_free()
			return _fail("Level %d does not expose exactly three tray pieces" % level)

	var early: Dictionary = game.call("campaign_profile_for_level", 100)
	var late: Dictionary = game.call("campaign_profile_for_level", 9500)
	if int(late.get("difficulty_floor", 0)) <= int(early.get("difficulty_floor", 0)):
		game.queue_free()
		return _fail("Late-game difficulty floor does not rise")
	if float(late.get("initial_occupancy", 0.0)) <= float(early.get("initial_occupancy", 0.0)):
		game.queue_free()
		return _fail("Late-game board pressure does not rise")

	game.queue_free()
	await process_frame
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
