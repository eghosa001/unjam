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
		var title := main.find_child("DailyTitle_%s" % game_id, true, false) as Label
		var play := main.find_child("DailyPlay_%s" % game_id, true, false) as Button
		var status := main.find_child("DailyProgressLabel_%s" % game_id, true, false) as Label
		if title == null or title.get_theme_font_size("font_size") < 18:
			return _fail("Daily title is too small for %s" % game_id)
		if title.get_theme_constant("outline_size") < 2:
			return _fail("Daily title lost its high-contrast outline for %s" % game_id)
		if play == null or play.get_theme_font_size("font_size") < 14:
			return _fail("Daily primary action is too small for %s" % game_id)
		if status == null or status.get_theme_font_size("font_size") < 12:
			return _fail("Daily progress status is too small for %s" % game_id)
		if status.accessibility_name.is_empty() or status.text.contains("GO"):
			return _fail("Daily pill is misleading or inaccessible for %s" % game_id)
		var art := main.find_child("DailyGameArt_%s" % game_id, true, false) as Unjam2DGameArt
		if art == null or not art.compact or art.is_processing():
			return _fail("Daily %s is missing static game identity art" % game_id)
		if play.accessibility_name.is_empty():
			return _fail("Daily play action is inaccessible for %s" % game_id)

	var daily_progress := main.find_child("DailyProgressBar", true, false) as ProgressBar
	if daily_progress == null or not daily_progress.accessibility_name.contains("3 daily challenges"):
		return _fail("Daily progress does not announce the current completion count")

	# A completed Daily should visibly say DONE without making other games
	# unplayable. Exercise the actual saved multi-game daily state.
	var save := root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	var games := root.get_node("MultiGameManager")
	games.call("complete_daily","water_sort",0)
	main.call("build_daily_games")
	await _frames(2)
	var completed_water := main.find_child("DailyPlay_water_sort",true,false) as Button
	var ready_rescue := main.find_child("DailyPlay_rescue_rush",true,false) as Button
	var ready_block := main.find_child("DailyPlay_block_puzzle",true,false) as Button
	if completed_water == null or not completed_water.disabled or completed_water.text != "COMPLETED":
		return _fail("Completed Water Daily is not visibly distinguished")
	if not completed_water.accessibility_name.contains("completed"):
		return _fail("Completed Water Daily does not have an accessible description")
	if (ready_rescue != null and ready_rescue.disabled) or (ready_block != null and ready_block.disabled):
		return _fail("Completed Water Daily disabled another game's challenge")
	save.data = original
	save.save()
	main.call("build_daily_games")
	await _frames(2)

	var tip_title := main.find_child("DailyTipTitle", true, false) as Label
	var tip_detail := main.find_child("DailyTipDetail", true, false) as Label
	if tip_title == null or tip_title.get_theme_font_size("font_size") < 14:
		return _fail("Daily reminder title is missing or too small")
	if tip_detail == null or tip_detail.get_theme_font_size("font_size") < 12:
		return _fail("Daily reminder detail is missing or too small")

	main.call("build_collection")
	await _frames(2)
	var collection_title := main.find_child("CollectionTipTitle", true, false) as Label
	var collection_detail := main.find_child("CollectionTipDetail", true, false) as Label
	if collection_title == null or collection_title.get_theme_font_size("font_size") < 14:
		return _fail("Collection value title is missing or too small")
	if collection_detail == null or collection_detail.get_theme_font_size("font_size") < 12:
		return _fail("Collection value detail is missing or too small")

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
