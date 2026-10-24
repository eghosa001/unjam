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

	# Cold scene loading is internal: the already rendered Home/Level screen
	# stays on display. The old fullscreen GameLoadingCard is forbidden.
	main.call("start_multi_level","water_sort",1,false)
	var state := String(main.get("current_surface"))
	if not _check(state in ["home", "levels", "game"], "Cold game unexpectedly navigated to a placeholder"):return
	if not _check(main.find_child("GameLoadingCard",true,false) == null, "Game launch created a fullscreen loading page"):return
	if not _check(not source.contains('current_surface = "game_loading"') and not source.contains("GameLoadingCard"),
			"Fullscreen/blank game-loading route is still present in the launcher"):return
	main.call("force_back_from_game")
	await _frames(12)
	if not _check(main.get("active_game") == null and String(main.get("current_surface")) == "levels", "Cancelled cold load must return to the game's levels"):return
	# A pending Play request can also be cancelled without creating a screen.
	main.set("_pending_game_launch",{"game_id":"water_sort","level":1,"daily":false})
	main.call("force_back_from_game")
	if not _check(String(main.get("current_surface")) == "levels" and main.get("active_game") == null,
			"Pending invisible load did not return to the level browser"):return
	if not _check((main.get("_pending_game_launch") as Dictionary).is_empty(), "Cancelled launch retained pending request"):return

	# The second request supersedes the first, even if the two different
	# resource threads finish in the opposite order.
	main.call("start_multi_level","water_sort",3,false)
	main.call("start_multi_level","block_puzzle",4,false)
	var game := await _wait_for_active(main,300)
	if not _check(game != null and String(game.get_meta("unjam_game_id","")) == "block_puzzle" and int(game.get("level_number")) == 4, "Older scene completion stole latest Block request"):return
	if not _check(String(main.get("current_surface")) == "game", "Game launcher never settled into gameplay"):return
	main.call("force_back_from_game")
	await _frames(4)
	if not _check(main.get("active_game") == null and String(main.get("current_surface")) == "levels", "Back after async game launch failed to land on Block levels"):return

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
	print("ASYNC_GAME_SCENE_LAUNCH_OK: seamless loading, cancellation, concurrent requests, route recovery and rapid navigation")
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
