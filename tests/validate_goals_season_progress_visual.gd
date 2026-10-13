extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene unavailable")
	var meta := root.get_node("MetaProgressionManager")
	var season: Dictionary = meta.call("season_info")
	var app := packed.instantiate() as Control
	root.add_child(app)
	for _i in range(5): await process_frame
	app.call("build_goals")
	await process_frame
	var bar := app.find_child("GoalsSeasonProgressBar",true,false) as ProgressBar
	var claim := app.find_child("GoalsSeasonClaim",true,false) as Button
	var login := app.find_child("GoalsLoginClaim",true,false) as Button
	if bar == null or claim == null or login == null:
		return _fail("Goals progress, claim, or Daily check-in control missing")
	var points := maxi(0,int(season.get("points",0)))
	var next_target := int(season.get("next_target",0))
	var cap := maxi(1,next_target if next_target > 0 else points)
	if int(bar.max_value) != cap or int(bar.value) != mini(points,cap):
		return _fail("Goals Season rail does not represent actual points and next-tier target")
	if bar.is_processing() or not bar.accessibility_name.contains("Season Journey"):
		return _fail("Season rail lacks an accessible label or wastes idle frames")
	if not claim.accessibility_name.contains("Season Journey") and not claim.accessibility_name.contains("Season"):
		return _fail("Season CTA does not explain its current state")
	if claim.disabled:
		if not claim.has_theme_stylebox_override("disabled") or not claim.has_theme_color_override("font_disabled_color"):
			return _fail("Locked Season claim is illegible in disabled theme")
	if login.disabled:
		if not login.has_theme_stylebox_override("disabled") or not login.has_theme_color_override("font_disabled_color"):
			return _fail("Claimed check-in is illegible in disabled theme")
	app.queue_free()
	await process_frame
	print("GOALS_SEASON_PROGRESS_VISUAL_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
