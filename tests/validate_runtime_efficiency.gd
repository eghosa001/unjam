extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _water_controls_are_reused():
		return
	if not await _rescue_refresh_is_settled():
		return
	if not _dead_helpers_are_gone():
		return
	if not _hot_paths_stay_lightweight():
		return
	if not _retention_period_cache_is_isolated():
		return
	print("RUNTIME_EFFICIENCY_OK: stable controls, bounded hot-path allocation, deferred persistence, and isolated period caches.")
	quit(0)

func _water_controls_are_reused() -> bool:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var board = game.get("board") as GridContainer
	if board == null or board.get_child_count() == 0:
		game.queue_free()
		return _fail("Water Sort board did not render")
	var before: Array[int] = []
	for child in board.get_children():
		before.append(child.get_instance_id())
	game.call("render_board")
	var after: Array[int] = []
	for child in board.get_children():
		after.append(child.get_instance_id())
	if before != after:
		game.queue_free()
		return _fail("Water Sort rebuilt bottle controls during an unchanged render")
	game.queue_free()
	await process_frame
	return true

func _rescue_refresh_is_settled() -> bool:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		return _fail("Rescue Rush scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	if not bool(game.get("_board_has_rendered")):
		game.queue_free()
		return _fail("Rescue Rush did not mark initial board render complete")
	var board = game.get("board_grid") as GridContainer
	if board == null:
		game.queue_free()
		return _fail("Rescue Rush board missing")
	# First refresh preserves the existing contract: any in-flight entrance
	# animation is replaced by the settled board presentation.
	game.call("render_board")
	for child in board.get_children():
		if child is Control:
			var control := child as Control
			if control.modulate.a < 0.99 or control.scale.distance_to(Vector2.ONE) > 0.01:
				game.queue_free()
				return _fail("Rescue Rush replayed full-board entrance animation during refresh")
	if not bool(game.get("_board_entrance_settled")):
		game.queue_free()
		return _fail("Rescue Rush did not retire its entrance-settlement scan")
	# Once settled, another unchanged refresh must reuse the exact controls.
	var before: Array[int] = []
	for child in board.get_children():
		before.append(child.get_instance_id())
	game.call("render_board")
	var after: Array[int] = []
	for child in board.get_children():
		after.append(child.get_instance_id())
	if before != after:
		game.queue_free()
		return _fail("Rescue Rush rebuilt settled board controls during an unchanged refresh")
	game.queue_free()
	await process_frame
	return true

func _retention_period_cache_is_isolated() -> bool:
	var retention = root.get_node_or_null("RetentionManager")
	if retention == null:
		return _fail("RetentionManager autoload missing")
	var missions_a: Array[Dictionary] = retention.call("daily_missions")
	var missions_b: Array[Dictionary] = retention.call("daily_missions")
	if missions_a != missions_b or missions_a.is_empty():
		return _fail("Daily mission cache changed deterministic output")
	var original_mission_title := String(missions_b[0].get("title", ""))
	missions_a[0]["title"] = "MUTATED"
	var missions_c: Array[Dictionary] = retention.call("daily_missions")
	if String(missions_c[0].get("title", "")) != original_mission_title:
		return _fail("Daily mission caller mutated the internal period cache")
	var rivals_a: Array[Dictionary] = retention.call("weekly_rivals")
	var rivals_b: Array[Dictionary] = retention.call("weekly_rivals")
	if rivals_a != rivals_b or rivals_a.is_empty():
		return _fail("Weekly rival cache changed deterministic output")
	var original_points := int(rivals_b[0].get("points", -1))
	rivals_a[0]["points"] = -999
	var rivals_c: Array[Dictionary] = retention.call("weekly_rivals")
	if int(rivals_c[0].get("points", -1)) != original_points:
		return _fail("Weekly rival caller mutated the internal period cache")
	return true

func _hot_paths_stay_lightweight() -> bool:
	var manager := FileAccess.get_file_as_string("res://scripts/core/multi_game_manager.gd")
	var water := FileAccess.get_file_as_string("res://scripts/ui/water_tube_3d_motion.gd")
	var water_game := FileAccess.get_file_as_string("res://scripts/game/water_sort.gd")
	var block_game := FileAccess.get_file_as_string("res://scripts/game/block_puzzle_3d.gd")
	var visuals := FileAccess.get_file_as_string("res://scripts/systems/robust_premium_visuals.gd")
	var retention := FileAccess.get_file_as_string("res://scripts/systems/retention_manager.gd")
	var checkpoint_fn := manager.get_slice("func _checkpoint_payload_matches", 1).get_slice("func save_checkpoint", 0)
	if ".duplicate(true)" in checkpoint_fn:
		return _fail("Checkpoint equality regressed to recursive copying")
	var water_process := water.get_slice("func _process", 1).get_slice("func _sync_motion_processing", 0)
	if "_refresh_liquid_3d()" in water_process or not "_refresh_meniscus_3d()" in water_process:
		return _fail("Water arrival ripple regressed to full liquid-run rebuilds")
	var water_checkpoint := water_game.get_slice("func _save_checkpoint", 1).get_slice("func _restore_checkpoint", 0)
	if "history.duplicate(true)" in water_checkpoint:
		return _fail("Water checkpoint regressed to recursive undo-history copying")
	var block_place := block_game.get_slice("func place_selected", 1).get_slice("func undo_move", 0)
	if "\n\trender()\n" in block_place:
		return _fail("Block placement regressed to a full-board render pass")
	if not "_sync_placed_cells" in block_place or not "render_pieces()" in block_place:
		return _fail("Block incremental placement refresh contract is incomplete")
	var quality_fn := visuals.get_slice("func _set_quality", 1).get_slice("func _ambient_count", 0)
	if not "save_deferred" in quality_fn:
		return _fail("Adaptive quality persistence is synchronous again")
	var retention_complete := retention.get_slice("func record_level_complete", 1).get_slice("func record_level_fail", 0)
	var retention_fail := retention.get_slice("func record_level_fail", 1).get_slice("func _persist_gameplay_state_deferred", 0)
	var retention_persist := retention.get_slice("func _persist_gameplay_state_deferred", 1).get_slice("func _increment_mission", 0)
	if "SaveManager.save()" in retention_complete or not "_persist_gameplay_state_deferred()" in retention_complete:
		return _fail("Level-complete retention regressed to a synchronous second save")
	if "SaveManager.save()" in retention_fail or not "_persist_gameplay_state_deferred()" in retention_fail:
		return _fail("Level-fail retention regressed to synchronous persistence")
	if not "save_deferred" in retention_persist:
		return _fail("Retention persistence helper is not using the coalesced save path")
	var weekly_rank_fn := retention.get_slice("func weekly_rank", 1).get_slice("func _weekly_rivals_ref", 0)
	if "weekly_rivals()" in weekly_rank_fn or not "_weekly_rivals_ref()" in weekly_rank_fn:
		return _fail("Weekly rank regressed to rebuilding/copying the rival list")
	return true

func _dead_helpers_are_gone() -> bool:
	var paths := [
		"res://scripts/ui/robust_main.gd",
		"res://scripts/ui/premium_main_casual.gd",
	]
	var retired := [
		"_add_game_card",
		"_change_multi_world",
		"_restyle_secondary_nav",
		"_inject_game_tabs",
		"_add_surface_diorama",
		"_find_page_root",
	]
	var combined := ""
	for path in paths:
		combined += FileAccess.get_file_as_string(path)
	for name in retired:
		if ("func %s(" % name) in combined:
			return _fail("Retired helper still exists: %s" % name)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
