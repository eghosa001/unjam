extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("Main scene failed to load")
	var main := scene.instantiate()
	root.add_child(main)
	await _frames(3)

	main.call("build_home")
	await _frames(3)
	var home := main.get_node_or_null("PremiumHome")
	if home == null:
		return _fail("Premium Home is missing")

	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		var button := home.find_child("HomeDirect_%s" % game_id,true,false) as Button
		if button == null:
			return _fail("Home quick-switch button missing for %s" % game_id)
		button.pressed.emit()
		await _frames(2)
		var hero_title := home.find_child("HomeHeroGameTitle",true,false) as Label
		if String(main.get("current_surface")) != "home":
			return _fail("Home quick switch incorrectly navigated away from Home")
		if String(main.get("selected_game_id")) != game_id:
			return _fail("Home quick switch did not select %s" % game_id)
		if hero_title == null or hero_title.text != _expected_title(game_id):
			return _fail("Home hero did not update for %s" % game_id)

	var games := home.find_child("HomeLevelsNavButton",true,false) as Button
	if games == null:
		return _fail("Home Games navigation is missing")
	games.pressed.emit()
	await _frames(3)
	if String(main.get("current_surface")) != "live":
		return _fail("Games navigation did not open the game selector")

	print("HOME_QUICK_SWITCH_OK")
	main.queue_free()
	await process_frame
	quit(0)

func _expected_title(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
