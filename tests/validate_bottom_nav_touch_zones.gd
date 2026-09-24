extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(5)

	main.call("build_home")
	await _frames(3)
	if not _check_named(main, ["HomeNavButton","HomeGamesNavButton","HomeDailyNavButton","HomeCollectionNavButton","HomeSettingsNavButton"], "Home"):
		return

	main.call("_open_games_surface")
	await _frames(3)
	if not _check_named(main, ["SelectorNavHit_HOME","SelectorNavHit_GAMES","SelectorNavHit_DAILY","SelectorNavHit_COLLECT","SelectorNavHit_SETTINGS"], "Games"):
		return

	main.call("build_daily_games")
	await _frames(3)
	if not _check_named(main, ["StdNavHit_HOME","StdNavHit_GAMES","StdNavHit_DAILY","StdNavHit_COLLECTION","StdNavHit_SETTINGS"], "Shared"):
		return

	main.queue_free()
	await process_frame
	print("Bottom navigation touch zones are non-overlapping.")
	quit(0)

func _check_named(root_node: Node, names: Array[String], label: String) -> bool:
	var controls: Array[Control] = []
	for wanted in names:
		var node := root_node.find_child(wanted, true, false) as Control
		if node == null:
			return _fail("%s nav hit missing: %s" % [label, wanted])
		controls.append(node)
	return _check_controls(controls, label)

func _check_controls(controls: Array[Control], label: String) -> bool:
	if controls.size() != 5:
		return _fail("%s nav does not expose exactly five touch zones" % label)
	controls.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	for i in range(controls.size()):
		if controls[i].size.x < 70.0 or controls[i].size.y < 70.0:
			return _fail("%s nav touch zone is too small" % label)
		if i > 0 and controls[i - 1].get_global_rect().intersects(controls[i].get_global_rect()):
			return _fail("%s nav touch zones overlap" % label)
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
