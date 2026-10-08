extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := _read("res://scripts/ui/robust_main.gd")
	if not _check(not source.contains("if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:\n\t\treturn ResourceLoader.load_threaded_get(path)"), "The UI thread still blocks inside a threaded scene load"): return
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null, "Main scene unavailable"):return
	var main := packed.instantiate() as Control
	root.size = Vector2i(540,960)
	root.add_child(main)
	await _frames(6)

	# Start a cold game, immediately leave and confirm any pending thread never
	# teleports the player back into the previous game after it completes.
	main.call("start_multi_level","water_sort",1,false)
	var state := String(main.get("current_surface"))
	if not _check(state in ["game_loading","game"],"Cold game request vanished"):return
	if state == "game_loading":
		var loader := main.find_child("GameLoadingCard",true,false)
		var cancel := main.find_child("GameLoadingCancel",true,false) as Button
		if not _check(loader != null and cancel != null and cancel.size.y >= 48, "Cold scene has no accessible cancellable loader"):return
	main.call("force_back_from_game")
	await _frames(12)
	if not _check(main.get("active_game") == null and String(main.get("current_surface")) == "levels", "Cancelled load reopened an unwanted game"):return

	# The second request supersedes the first, even if the two different
	# resource threads finish in the opposite order.
	main.call("start_multi_level","water_sort",3,false)
	main.call("start_multi_level","block_puzzle",4,false)
	var game := await _wait_for_active(main,300)
	if not _check(game != null and String(game.get_meta("unjam_game_id","")) == "block_puzzle" and int(game.get("level_number")) == 4, "Older scene completion stole latest Block request"):return
	if not _check(String(main.get("current_surface")) == "game", "Game launcher never settled into gameplay"):return
	main.call("force_back_from_game")
	await _frames(4)
	if not _check(main.get("active_game") == null and String(main.get("current_surface")) == "levels", "Back after async game launch failed"):return

	# Navigation churn must not leak active games or leave a "game_loading"
	# overlay across subsequent home/selector transitions.
	for i in range(10):
		main.call("start_multi_level","water_sort",i + 1,false)
		main.call("force_back_from_game")
		main.call("build_home")
		await _frames(2)
		if not _check(main.get("active_game") == null and String(main.get("current_surface")) == "home", "Rapid Back/Home race failed at cycle %d" % i):return
	await _frames(10)
	if not _check(main.get("active_game") == null and main.find_child("GameLoadingCard",true,false) == null, "Stale loader survived Home"):return
	main.queue_free()
	# Let queued-free gameplay effects, detached loaders and deferred intro
	# callbacks settle before SceneTree teardown and leak accounting.
	await _frames(12)
	print("ASYNC_GAME_SCENE_LAUNCH_OK: loading cancellation, concurrent requests, route recovery and rapid navigation")
	quit(0)

func _wait_for_active(main: Control, max_frames: int) -> Control:
	for _i in range(max_frames):
		var active = main.get("active_game")
		if active != null and is_instance_valid(active):
			return active as Control
		await process_frame
	return null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _read(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _check(value: bool, reason: String) -> bool:
	if value:return true
	push_error(reason)
	quit(1)
	return false
