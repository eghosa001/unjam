extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	if not _check(save != null, "SaveManager missing"): return
	var previous: Dictionary = save.data.duplicate(true)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Main scene could not load"): return
	var main := packed.instantiate() as Control
	root.size = Vector2i(540, 960)
	root.add_child(main)
	await _frames(7)

	# A queued level should never reopen once the player chooses Home in the
	# same frame as a victory, regardless of which of the three games finished.
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		main.set("selected_game_id",game_id)
		main.set("current_surface","game")
		if game_id == "rescue_rush":
			main.call("_on_rescue_finished",1,false)
		else:
			main.call("_on_multi_finished",1,game_id,false)
		main.call("build_home")
		await _frames(4)
		if not _check(main.get("active_game") == null and main.get("current_surface") == "home", "Stale %s win callback reopened gameplay after Home" % game_id):return

	# A pending result must also be invalidated when a different game wins the
	# foreground: no old callback may overwrite the next selected campaign.
	main.set("selected_game_id","water_sort")
	main.set("current_surface","game")
	main.call("_on_multi_finished",1,"water_sort",false)
	main.set("selected_game_id","block_puzzle")
	main.set("current_surface","levels")
	await _frames(4)
	if not _check(main.get("active_game") == null and main.get("current_surface") == "levels","Older Water win stole Block's navigation"):return

	# A legitimate win still advances; two completion signals in the same frame
	# must not instantiate the next level twice.
	main.set("selected_game_id","water_sort")
	main.set("current_surface","game")
	main.call("_on_multi_finished",1,"water_sort",false)
	main.call("_on_multi_finished",1,"water_sort",false)
	await _frames(6)
	var game := main.get("active_game") as Control
	if not _check(game != null and is_instance_valid(game) and int(game.get("level_number")) == 2, "Valid Water completion did not open exactly level 2"):return
	var game_count := 0
	for child in main.get_children():
		if child.name == "ActiveGame" and not child.is_queued_for_deletion():
			game_count += 1
	if not _check(game_count == 1, "Repeated win callback instantiated multiple active games"):return
	main.call("build_home")
	await _frames(4)
	if not _check(main.get("active_game") == null and main.get("current_surface") == "home", "Finished game was not released on Home"):return

	main.queue_free()
	await process_frame
	save.data = previous
	save.save()
	print("DEFERRED_WIN_NAVIGATION_OK: 3-game Back cancellation, cross-game races and repeat completion")
	quit(0)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _check(ok: bool, why: String) -> bool:
	if ok:return true
	push_error(why)
	quit(1)
	return false
