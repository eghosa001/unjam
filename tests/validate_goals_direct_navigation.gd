extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	if not source.contains('action.pressed.connect(_open_goal_progress.bind(goal_id))'):
		return _fail("Goals PLAY controls are not wired to the direct mission navigation")
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("Main scene unavailable")
	var app := scene.instantiate() as Control
	root.add_child(app)
	for _i in range(5): await process_frame
	app.call("build_goals")
	for daily_id in ["daily1", "daily5"]:
		app.call("_open_goal_progress",daily_id)
		if String(app.get("current_surface")) != "daily":
			return _fail("Daily mission %s goes to the wrong surface" % daily_id)
	app.call("_open_goal_progress","play2")
	if String(app.get("current_surface")) != "live":
		return _fail("Level mission added an unnecessary Home stop")
	app.call("_open_goal_progress","stars35")
	if String(app.get("current_surface")) != "live":
		return _fail("Star mission does not lead straight to Choose Game")
	app.queue_free()
	await process_frame
	print("GOALS_DIRECT_MISSION_NAVIGATION_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
