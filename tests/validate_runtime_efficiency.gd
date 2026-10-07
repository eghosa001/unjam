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
	if not await _navigation_lifecycle_is_bounded():
		return
	print("RUNTIME_EFFICIENCY_OK: stable controls, bounded hot-path allocation, deferred persistence, and leak-resistant repeated navigation.")
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

func _hot_paths_stay_lightweight() -> bool:
	var manager := FileAccess.get_file_as_string("res://scripts/core/multi_game_manager.gd")
	var save_manager := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")
	var water := FileAccess.get_file_as_string("res://scripts/ui/water_tube_3d_motion.gd")
	var water_game := FileAccess.get_file_as_string("res://scripts/game/water_sort.gd")
	var block_game := FileAccess.get_file_as_string("res://scripts/game/block_puzzle_3d.gd")
	var visuals := FileAccess.get_file_as_string("res://scripts/systems/robust_premium_visuals.gd")
	var touch_enhancer := FileAccess.get_file_as_string("res://scripts/ui/ui_touch_enhancer.gd")
	var water_reference := FileAccess.get_file_as_string("res://scripts/game/water_sort_reference_motion.gd")
	var checkpoint_fn := manager.get_slice("func _checkpoint_payload_matches", 1).get_slice("func save_checkpoint", 0)
	if ".duplicate(true)" in checkpoint_fn:
		return _fail("Checkpoint equality regressed to recursive copying")
	var water_process := water.get_slice("func _process", 1).get_slice("func _draw", 0)
	if not "queue_redraw()" in water_process or "_refresh_liquid_3d" in water_process or "_refresh_meniscus_3d" in water_process:
		return _fail("Water arrival feedback is no longer redraw-only 2D")
	if not "ACTIVE_REDRAW_FPS := 30.0" in FileAccess.get_file_as_string("res://scripts/ui/water_tube_reference_button.gd"):
		return _fail("Water 2D bottle redraw budget is no longer capped")
	for forbidden in ["SubViewport", "Camera3D", "MeshInstance3D", "StandardMaterial3D"]:
		if forbidden in water:
			return _fail("Water gameplay renderer reintroduced nested 3D allocation: " + forbidden)
	if not 'extends "res://scripts/ui/water_tube_reference_motion.gd"' in water:
		return _fail("Water compatibility renderer no longer delegates to the lightweight 2D liquid model")
	var touch_added := touch_enhancer.get_slice("func _on_node_added", 1).get_slice("func _queue_enhancements", 0)
	if "_queue_enhancements()" in touch_added or not "_apply_button_size" in touch_added:
		return _fail("Touch enhancer regressed to whole-tree rescans for each new node")
	if not "button.custom_minimum_size != target_tube_size" in water_reference:
		return _fail("Water board still invalidates unchanged tube layout on every tap")
	var water_checkpoint := water_game.get_slice("func _save_checkpoint", 1).get_slice("func _restore_checkpoint", 0)
	if "history.duplicate(true)" in water_checkpoint:
		return _fail("Water checkpoint regressed to recursive undo-history copying")
	var water_restore := water_game.get_slice("func _restore_checkpoint", 1).get_slice("func _quit", 0)
	if "saved_tubes.duplicate(true)" in water_restore or "saved_history.duplicate(true)" in water_restore:
		return _fail("Water checkpoint restore regressed to a second recursive copy")
	var block_restore := FileAccess.get_file_as_string("res://scripts/game/block_puzzle.gd").get_slice("func _restore_checkpoint", 1).get_slice("func _quit", 0)
	if "saved_history.duplicate(true)" in block_restore:
		return _fail("Block checkpoint restore regressed to a second history copy")
	var block_place := block_game.get_slice("func place_selected", 1).get_slice("func undo_move", 0)
	if "\n\trender()\n" in block_place:
		return _fail("Block placement regressed to a full-board render pass")
	if not "_sync_placed_cells" in block_place or not "render_pieces()" in block_place:
		return _fail("Block incremental placement refresh contract is incomplete")
	var quality_fn := visuals.get_slice("func _set_quality", 1).get_slice("func _ambient_count", 0)
	if not "save_deferred" in quality_fn:
		return _fail("Adaptive quality persistence is synchronous again")
	var gameplay_counter_persist := save_manager.get_slice("func _persist_gameplay_counter_deferred", 1).get_slice("func record_hint", 0)
	var hint_fn := save_manager.get_slice("func record_hint", 1).get_slice("func record_undo", 0)
	var undo_fn := save_manager.get_slice("func record_undo", 1).get_slice("func complete_daily", 0)
	if not "save_deferred" in gameplay_counter_persist:
		return _fail("Hint/undo counter persistence is not using the deferred saver")
	if "save()" in hint_fn or "save()" in undo_fn:
		return _fail("Hint or undo regressed to synchronous saving")
	return true

func _navigation_lifecycle_is_bounded() -> bool:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene missing for repeated-navigation efficiency audit")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)

	# Warm every common material/surface once; only growth after the warm cycle is
	# considered a leak/regression because immutable style caches intentionally
	# populate on first use.
	var surfaces := ["build_home","build_settings","build_collection","build_daily_games","build_goals","build_profile"]
	for method in surfaces:
		main.call(method)
		await _frames(2)
	main.call("_open_games_surface")
	await _frames(10)
	var warm_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var warm_tree_nodes := _tree_node_count(root)
	var warm_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("NAV_LIFECYCLE_BASELINE perf=%d tree=%d orphan=%d" % [warm_nodes,warm_tree_nodes,warm_orphans])

	for cycle in range(5):
		for method in surfaces:
			main.call(method)
			await _frames(4)
			print("NAV_LIFECYCLE_SAMPLE cycle=%d surface=%s perf=%d tree=%d orphan=%d" % [cycle,String(method),int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),_tree_node_count(root),int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))])
		main.call("_open_games_surface")
		await _frames(6)
		print("NAV_LIFECYCLE_SAMPLE cycle=%d surface=games perf=%d tree=%d orphan=%d" % [cycle,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),_tree_node_count(root),int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))])
	await _frames(10)

	var final_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var final_tree_nodes := _tree_node_count(root)
	var final_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if final_tree_nodes > warm_tree_nodes + 12:
		main.queue_free()
		await _frames(3)
		return _fail("Repeated navigation leaks scene-tree nodes: warm=%d final=%d" % [warm_tree_nodes,final_tree_nodes])
	if final_nodes > warm_nodes + 24:
		main.queue_free()
		await _frames(3)
		return _fail("Repeated navigation leaks live nodes: warm=%d final=%d" % [warm_nodes,final_nodes])
	if final_orphans > warm_orphans + 6:
		main.queue_free()
		await _frames(3)
		return _fail("Repeated navigation leaks orphan nodes: warm=%d final=%d" % [warm_orphans,final_orphans])

	main.queue_free()
	await _frames(4)
	return true

func _tree_node_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _tree_node_count(child)
	return total

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

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
