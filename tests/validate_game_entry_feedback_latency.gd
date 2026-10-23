extends SceneTree
# Cold and warm game taps must always expose a cancellable loading state
# synchronously. Never block on first-use imported art or GDScript compilation
# before the first Android loading frame is drawn.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null, "Main scene missing"):return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(7)
	var start_us := Time.get_ticks_usec()
	main.call("start_multi_level","block_puzzle",1,false)
	var tap_us := Time.get_ticks_usec() - start_us
	if not _check(String(main.get("current_surface")) == "game_loading",
			"Tapped game did not immediately display the loading state"):return
	if not _check(main.find_child("GameLoadingCancel",true,false) != null,
			"Immediate loader has no cancel button"):return
	if not _check(tap_us < 300000,
			"Game tap spent over 300ms constructing resources before feedback: %d us" % tap_us):return
	main.call("force_back_from_game")
	await _frames(4)
	if not _check(String(main.get("current_surface")) == "levels",
			"Cancelled loading stole navigation"):return
	# Returning to the level list may warm selected dependencies, but a
	# second tap must still show its loading state before scene instantiation.
	main.call("start_multi_level","block_puzzle",1,false)
	if not _check(String(main.get("current_surface")) == "game_loading",
			"Repeat launch blocked the tap and bypassed immediate feedback"):return
	var active: Control = null
	for i in range(300):
		var maybe = main.get("active_game")
		if maybe != null and is_instance_valid(maybe):
			active = maybe
			break
		await process_frame
	if not _check(active != null and String(main.get("current_surface")) == "game",
			"Async game never finished loading"):return
	main.call("force_back_from_game")
	await _frames(8)
	main.queue_free()
	await _frames(10)
	print("GAME_ENTRY_FEEDBACK_OK immediate_loader_us=%d" % tap_us)
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
