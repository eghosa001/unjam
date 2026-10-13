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
	var arrow: BaseButton
	for cell in board.get_children():
		if cell is BaseButton and not cell.disabled:
			arrow = cell as BaseButton
			break
	if not _check(arrow != null, "Board has no playable keyboard-focusable arrow"):return
	arrow.grab_focus()
	await process_frame
	if not _check(game.get_viewport().gui_get_focus_owner() == arrow, "Keyboard fixture could not focus a Rescue arrow"):return
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
	await process_frame
	var restored_focus := game.get_viewport().gui_get_focus_owner() as BaseButton
	if not _check(restored_focus != null and restored_focus.get_parent() == board
		and restored_focus.focus_mode == Control.FOCUS_ALL
		and not restored_focus.accessibility_name.is_empty(),
		"Board refresh lost keyboard/TalkBack focus instead of transferring it to a playable arrow"):return
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
