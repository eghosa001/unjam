extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(6)

	main.call("start_multi_level", "water_sort", 7, false)
	await _frames(5)
	main.set("selected_game_id", "block_puzzle")
	main.call("force_back_from_game")
	await _frames(4)
	if String(main.get("selected_game_id")) != "water_sort" or String(main.get("current_surface")) != "levels":
		return _fail("Back from Water Sort followed stale game selection")

	main.call("start_level", 3)
	await _frames(5)
	var exited_rescue := main.get("active_game") as Control
	if exited_rescue == null:
		return _fail("Rescue scene not yet active for route ownership regression")
	var exited_rescue_id := exited_rescue.get_instance_id()
	main.set("selected_game_id", "water_sort")
	main.call("force_back_from_game")
	await _frames(4)
	if String(main.get("selected_game_id")) != "rescue_rush" or String(main.get("current_surface")) != "levels":
		return _fail("Back from Rescue Rush followed stale game selection")
	# Android can dispatch a delayed button/quit/finished signal after a screen
	# replacement. A second Back on the newly visible level page is a no-op.
	main.call("force_back_from_game")
	if String(main.get("selected_game_id")) != "rescue_rush" or String(main.get("current_surface")) != "levels":
		return _fail("Double Back unexpectedly changed Rescue's return destination")
	main.call("_figma_switch_level_game","block_puzzle")
	await _frames(3)
	if String(main.get("selected_game_id")) != "block_puzzle" or String(main.get("current_surface")) != "levels":
		return _fail("Explicit Rescue -> Block tab navigation did not target Block levels")
	# Simulate late Rescue signals AFTER the Block page appears. None may
	# redirect, close, launch a level or change the selected-game identity.
	main.call("_on_rescue_quit",exited_rescue,false)
	main.call("_on_rescue_finished",3,false,exited_rescue_id)
	if String(main.get("selected_game_id")) != "block_puzzle" or String(main.get("current_surface")) != "levels":
		return _fail("Stale Rescue exit/win stole Block Puzzle's level screen")
	main.call("start_multi_level","block_puzzle",1,false)
	await _frames(8)
	if String(main.get("current_surface")) not in ["game","game_loading"]:
		return _fail("Could not launch Block Puzzle from its own level screen")
	main.call("_figma_switch_level_game","rescue_rush")
	if String(main.get("selected_game_id")) != "block_puzzle":
		return _fail("Old level tab redirected a running Block game into Rescue")
	main.call("_on_rescue_quit",exited_rescue,false)
	main.call("_on_rescue_finished",3,false,exited_rescue_id)
	if String(main.get("selected_game_id")) != "block_puzzle":
		return _fail("Stale Rescue callback changed the active Block game")
	main.call("force_back_from_game")
	await _frames(3)
	if String(main.get("selected_game_id")) != "block_puzzle" or String(main.get("current_surface")) != "levels":
		return _fail("Leaving Block game routed back into the wrong campaign")

	var block_source := _read("res://scripts/game/block_puzzle.gd")
	var water_source := _read("res://scripts/game/water_sort_casual.gd")
	var rescue_source := _read("res://scripts/game/rescue_rush_casual.gd")
	if not block_source.contains("back.text = \"←\""):
		return _fail("Block Puzzle back glyph is inconsistent")
	if not water_source.contains("premium_button(\"←\""):
		return _fail("Water Sort back glyph is inconsistent")
	if not rescue_source.contains("premium_button(\"←\""):
		return _fail("Rescue Rush back glyph is inconsistent")

	var level_ui := _read("res://scripts/ui/premium_main_casual.gd")
	for needle in [
		"button.button_down.connect(",
		"card.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE",
		"button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE",
		'if current_surface != "levels" or game_id not in MultiGameManager.GAME_IDS',
	]:
		if not level_ui.contains(needle):
			return _fail("Lag-free and release-safe cross-game routing contract missing: " + needle)
	print("GAME_BACK_CONSISTENCY_OK including rapid Rescue / Block routing, stale signals and immediate finger feedback")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
