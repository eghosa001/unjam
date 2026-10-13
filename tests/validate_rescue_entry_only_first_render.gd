extends SceneTree

# A real active Rescue scene should animate its board ONCE per level.
# State updates after a single arrow tap must not launch 25–100 simultaneous
# intro tweens or temporarily hide the newly rebuilt controls.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if not _check(packed != null, "Rescue scene is missing"): return
	var game := packed.instantiate() as Control
	game.level_number = 3
	root.add_child(game)
	for _i in range(8): await process_frame
	var board := game.get("board_grid") as GridContainer
	if not _check(board != null and board.get_child_count() > 10, "Rescue board failed to render"): return
	if not _check(int(game.get("_animated_entry_level")) == 3, "First board entrance was not recorded"):return
	await create_timer(0.65).timeout
	var all_pieces: Array = game.get("pieces")
	if not _check(not all_pieces.is_empty(), "Missing arrow for state refresh"): return
	var first: Dictionary = all_pieces[0]
	first["_quality_probe"] = true
	all_pieces[0] = first
	game.set("pieces", all_pieces)
	game.call("render_board")
	if not _check(board.get_child_count() > 10, "Second board draw was empty"): return
	for child in board.get_children():
		var cell := child as Control
		if not _check(cell != null and is_equal_approx(cell.modulate.a, 1.0)
			and cell.scale.is_equal_approx(Vector2.ONE),
			"Unchanged level restarted a staggered tile entrance"):return
	if not _check(int(game.get("_animated_entry_level")) == 3, "Redrawing game state reset first-entry record"):return
	game.queue_free()
	await process_frame
	print("RESCUE_ENTRY_REUSE_OK: normal gameplay redraw has no grid-wide entrance animation")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok: return true
	push_error(message)
	quit(1)
	return false
