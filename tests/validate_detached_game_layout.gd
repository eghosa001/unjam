extends SceneTree
# Rapid game close, viewport resize, and deferred layout work must never
# access a detached control or leave external size_changed callbacks connected.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	for path in ["res://scenes/Game.tscn","res://scenes/BlockPuzzle.tscn"]:
		var packed := load(path) as PackedScene
		if not _check(packed != null,"Missing game: "+path):return
		var game := packed.instantiate() as Control
		if not _check(game != null,"Cannot instantiate: "+path):return
		root.add_child(game)
		await _frames(3)
		var fit := Callable(game,"_queue_board_fit")
		if not _check(root.size_changed.is_connected(fit),
				"Game did not register its viewport layout observer: "+path):return
		game.call("_queue_board_fit")
		game.call("_queue_board_fit")
		if not _check(bool(game.get("_board_fit_pending")),
				"Resize bursts did not coalesce: "+path):return
		root.remove_child(game)
		if not _check(not root.size_changed.is_connected(fit),
				"Detached game retained viewport resize connection: "+path):return
		# Exercise the queued callback while the scene has no viewport.
		game.call("_flush_board_fit")
		if not _check(not bool(game.get("_board_fit_pending")),
				"Detached game retained queued work: "+path):return
		game.call("_queue_board_fit")
		if not _check(not bool(game.get("_board_fit_pending")),
				"Detached game accepted new layout work: "+path):return
		if path.ends_with("Game.tscn"):
			game.call("_fit_board_to_viewport")
			game.call("_show_level_intro")
		else:
			game.call("_fit_3d_board_layout")
		game.queue_free()
		await _frames(4)
	print("DETACHED_GAME_LAYOUT_OK viewport connections cleaned; no off-tree layout")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
