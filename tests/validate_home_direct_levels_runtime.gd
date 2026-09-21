extends SceneTree

var _original_data: Dictionary = {}

func _initialize() -> void:
	_original_data = SaveManager.data.duplicate(true)
	call_deferred("_run")

func _run() -> void:
	_seed_distinct_progress()

	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("Main scene failed to load")
	var main := scene.instantiate()
	root.add_child(main)
	await _frames(3)

	main.call("build_home")
	await _frames(4)
	var home := main.get_node_or_null("PremiumHome")
	if home == null:
		return _fail("Premium Home is missing")

	var previous_world_value := ""
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		var button := home.find_child("HomeDirect_%s" % game_id,true,false) as Button
		if button == null:
			return _fail("Home quick-switch button missing for %s" % game_id)
		button.pressed.emit()
		await _frames(3)

		if String(main.get("current_surface")) != "home":
			return _fail("Home quick switch incorrectly navigated away from Home")
		if String(main.get("selected_game_id")) != game_id:
			return _fail("Home quick switch did not select %s" % game_id)

		var expected := _expected_progress(game_id)
		var hero_title := home.find_child("HomeHeroGameTitle",true,false) as Label
		var hero_meta := home.find_child("HomeHeroGameMeta",true,false) as Label
		var primary := home.find_child("HomePrimaryAction",true,false) as Button
		var world_value := home.find_child("HomeWorldProgressValue",true,false) as Label
		var progress := home.find_child("HomeWorldProgressBar",true,false) as ProgressBar
		var hero_art := home.find_child("HomeHeroGameArt3D",true,false)
		var world_art := home.find_child("HomeWorldShowcase3D",true,false)

		if hero_title == null or hero_title.text != _expected_title(game_id):
			return _fail("Home hero did not update for %s" % game_id)
		if hero_meta == null or hero_meta.text != "LEVEL %d • WORLD %d" % [expected.level, expected.world]:
			return _fail("Home hero level/world stayed stale for %s" % game_id)
		if primary == null or primary.text != "CONTINUE • LEVEL %d" % expected.level:
			return _fail("Home Continue action stayed stale for %s" % game_id)
		if world_value == null or world_value.text != expected.world_text:
			return _fail("Home World Journey text stayed stale for %s" % game_id)
		if progress == null or int(round(progress.max_value)) != expected.total or int(round(progress.value)) != expected.completed:
			return _fail("Home World Journey progress bar stayed stale for %s" % game_id)
		if hero_art == null or String(hero_art.get("game_id")) != game_id:
			return _fail("Home hero 3D preview stayed stale for %s" % game_id)
		if world_art == null or String(world_art.get("game_id")) != game_id:
			return _fail("Home World Journey 3D showcase stayed stale for %s" % game_id)
		if not previous_world_value.is_empty() and world_value.text == previous_world_value:
			return _fail("Home World Journey did not visibly change between games")
		previous_world_value = world_value.text

	var games := home.find_child("HomeGamesNavButton",true,false) as Button
	if games == null:
		return _fail("Home Games navigation is missing")
	games.pressed.emit()
	await _frames(3)
	if String(main.get("current_surface")) != "live":
		return _fail("Games navigation did not open the game selector")

	print("HOME_QUICK_SWITCH_PROGRESS_OK")
	main.queue_free()
	await process_frame
	_restore_save()
	quit(0)

func _seed_distinct_progress() -> void:
	# Distinct worlds make stale cross-game state observable instead of allowing a
	# fresh all-Level-1 profile to pass accidentally.
	SaveManager.data["highest_level"] = 120
	SaveManager.data["total_levels_completed"] = 119
	SaveManager.data["stars"] = {"1": 3, "50": 2, "119": 3}

	var all: Dictionary = SaveManager.data.get("game_progress", {}).duplicate(true)
	all["water_sort"] = {
		"highest_level": 650,
		"levels_completed": 649,
		"stars": {"1": 3, "500": 3, "649": 2},
	}
	all["block_puzzle"] = {
		"highest_level": 1250,
		"levels_completed": 1249,
		"stars": {"1": 3, "500": 2, "1000": 3, "1249": 2},
	}
	SaveManager.data["game_progress"] = all
	MultiGameManager.ensure_state()

func _expected_progress(game_id: String) -> Dictionary:
	var highest := MultiGameManager.highest_level(game_id)
	var level := clampi(highest, 1, MultiGameManager.CAMPAIGN_LEVELS)
	var completed_level := clampi(highest - 1, 0, MultiGameManager.CAMPAIGN_LEVELS)
	var world := MultiGameManager.world_for_game_level(game_id, level)
	var first := MultiGameManager.first_level_in_game_world(game_id, world)
	var last := MultiGameManager.last_level_in_game_world(game_id, world)
	var total := maxi(1, last - first + 1)
	var completed := clampi(completed_level - first + 1, 0, total)
	return {
		"level": level,
		"world": world,
		"total": total,
		"completed": completed,
		"world_text": "LEVEL %d • %d/%d" % [level, completed, total],
	}

func _expected_title(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _restore_save() -> void:
	if not _original_data.is_empty():
		SaveManager.data = _original_data.duplicate(true)
		SaveManager.save()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	_restore_save()
	push_error(message)
	quit(1)
	return false
