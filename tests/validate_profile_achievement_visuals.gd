extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene missing")
	var app := packed.instantiate() as Control
	root.add_child(app)
	for _i in range(5): await process_frame
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		app.set("_profile_game",game_id)
		app.call("build_profile")
		await process_frame
		var definitions: Array = MultiGameManager.achievement_definitions(game_id)
		for achievement in definitions:
			var id := String(achievement.get("id",""))
			var need := maxi(1,int(achievement.get("need",1)))
			var actual := maxi(0,int(MultiGameManager.achievement_progress(game_id,id)))
			var bar := app.find_child("ProfileAchievementMeter_%s" % id,true,false) as ProgressBar
			var badge := app.find_child("ProfileAchievementBadge_%s" % id,true,false) as PanelContainer
			var status := app.find_child("ProfileAchievementStatus_%s" % id,true,false) as Label
			if bar == null or badge == null or status == null:
				return _fail("%s %s lacks a progress meter or earned-state medallion" % [game_id,id])
			if int(bar.max_value) != need or int(bar.value) != mini(need,actual):
				return _fail("%s %s meter shows the wrong achievement progress" % [game_id,id])
			if bar.accessibility_name.is_empty() or status.accessibility_name.is_empty():
				return _fail("%s %s badge status not announced to assistive technology" % [game_id,id])
			if status.text != ("✓" if actual >= need else "○"):
				return _fail("%s %s badge symbol contradicts its progression" % [game_id,id])
	app.queue_free()
	await process_frame
	print("PROFILE_ACHIEVEMENT_VISUALS_OK")
	quit(0)

func _fail(reason: String) -> bool:
	push_error(reason)
	quit(1)
	return false
