extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene could not be loaded")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(5)
	main.call("build_daily_games")
	await _frames(3)

	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var title := main.find_child("DailyTitle/%s" % game_id, true, false) as Label
		var play := main.find_child("DailyPlay/%s" % game_id, true, false) as Button
		var status := main.find_child("DailyProgressLabel/%s" % game_id, true, false) as Label
		if title == null or title.get_theme_font_size("font_size") < 18:
			return _fail("Daily title is too small for %s" % game_id)
		if title.get_theme_constant("outline_size") < 2:
			return _fail("Daily title lost its high-contrast outline for %s" % game_id)
		if play == null or play.get_theme_font_size("font_size") < 14:
			return _fail("Daily primary action is too small for %s" % game_id)
		if status == null or status.get_theme_font_size("font_size") < 12:
			return _fail("Daily progress status is too small for %s" % game_id)

	main.queue_free()
	await process_frame
	print("DAILY_READABILITY_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
