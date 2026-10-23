extends SceneTree
# Actual game entry: cold loads may show cancellable progress, while warmed
# scenes must open directly without allocating or painting a loading screen.
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
	# Cold entry may need an async loader; a scene already in memory must NOT
	# show that loader or wait for extra paint frames on every navigation.
	main.call("start_multi_level","block_puzzle",1,false)
	var first_surface := String(main.get("current_surface"))
	if not _check(first_surface in ["game_loading","game"],
			"First tap neither opened gameplay nor showed cold-load feedback"):return
	if first_surface == "game_loading":
		if not _check(main.find_child("GameLoadingCancel",true,false) != null,
				"Cold scene has no loading cancel button"):return
	main.call("force_back_from_game")
	await _frames(4)
	if not _check(String(main.get("current_surface")) == "levels",
			"Leaving a game or cancelling a cold launch failed"):return
	# Explicitly seed a preloaded scene, as the level browser does in normal
	# use. Measure the COMPLETE synchronous tap-to-game transition, not merely
	# the time required to paint a loading message.
	var warm_scene := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if not _check(warm_scene != null,"Cannot warm the Block Puzzle scene"):return
	var cached_scenes: Dictionary = main.get("_ready_game_scenes")
	cached_scenes["res://scenes/BlockPuzzle.tscn"] = warm_scene
	main.set("_ready_game_scenes",cached_scenes)
	var start_us := Time.get_ticks_usec()
	main.call("start_multi_level","block_puzzle",1,false)
	var tap_to_game_us := Time.get_ticks_usec() - start_us
	if not _check(String(main.get("current_surface")) == "game",
			"Warm game navigation still waits behind a loading screen"):return
	var active = main.get("active_game")
	if not _check(active != null and is_instance_valid(active),
			"Warm game tap did not instantiate gameplay before returning"):return
	if not _check(main.find_child("GameLoadingCard",true,false) == null,
			"Warm navigation still creates an unnecessary loading overlay"):return
	print("GAME_ENTRY_WARM_TAP_TO_GAME_US=%d" % tap_to_game_us)
	main.call("force_back_from_game")
	await _frames(8)
	main.queue_free()
	await _frames(10)
	print("GAME_ENTRY_NAVIGATION_OK warm_tap_to_game_us=%d" % tap_to_game_us)
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
