extends SceneTree

# Focused functional Home navigation: the full game tiles open each game's
# campaign level browser. No direct gameplay or touch-through is permitted.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var competition := root.get_node_or_null("CompetitionManager")
	var old_snapshot: Dictionary = competition.snapshot.duplicate(true)
	competition.snapshot = {
		"ok":true,"game_rankings":{
			"rescue_rush":{"player_weekly":{"rank":4,"levels_completed":23}},
			"water_sort":{"player_weekly":{"rank":8,"levels_completed":7}},
			"block_puzzle":{"player_weekly":{"rank":12,"levels_completed":2}},
		}
	}
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Main scene could not be loaded"):return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if not _check(home != null,"Home missing"):return
	var choose := home.find_child("HomePrimaryAction",true,false) as Button
	var rank := home.find_child("HomeRankValue",true,false) as Label
	var rank_daily := home.find_child("HomeRankDailyValue",true,false) as Label
	var ranking := home.find_child("HomeDailyGamesButton",true,false) as Button
	if not _check(choose != null and choose.text.contains("CHOOSE GAME"),"Choose Game is not the primary Home action"):return
	if not _check(choose.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE,"Choose Game must wait for touch release"):return
	if not _check(rank != null and rank.text == "#4","Home best weekly rank is not visible"):return
	var rank_hint := home.find_child("HomeRankWeeklyHint",true,false) as Label
	if not _check(rank_hint != null and rank_hint.text == "ON THE BOARD","Home rank must confirm placement when genuinely ranked"):return
	if not _check(rank_daily != null and rank_daily.text == "—","Today's rank must not be faked before the daily snapshot"):return
	var today_hint := home.find_child("HomeRankDailyHint",true,false) as Label
	if not _check(today_hint != null and today_hint.text == "PLAY TO JOIN","Home must explain its empty Daily ranking"):return
	if not _check(ranking != null and ranking.text.contains("LEADERBOARD"),"Leaderboard is not visible on Home"):return
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		if not _check(home.find_child("HomeDirect_%s" % game_id,true,false) == null,"Home still contains duplicate game-select cards for %s" % game_id):return
	if not _check(home.find_child("HomeHeroFlatGameLogo",true,false) == null and home.find_child("HomeHeroGameTitle",true,false) == null,"Home still prominently displays selected game artwork/title"):return
	if not _check(home.find_child("HomeWorldProgress",true,false) == null,"Old progress dashboard still crowds Home"):return

	# All three illustrated tiles must open the matching campaign LEVEL browser
	# in one tap, not a static picture, not game selector, and not gameplay.
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		main.call("build_home")
		await _frames(3)
		home = main.get_node_or_null("PremiumHome") as Control
		var shortcut := home.find_child("HomeShowcaseOpenLevels_%s" % game_id,true,false) as Button
		var art := home.find_child("HomeShowcaseArt_%s" % game_id,true,false) as Control
		if not _check(shortcut != null and art != null,"Home game preview is not actionable: %s" % game_id):return
		if not _check(shortcut.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE,"Game preview must respond on touch release: %s" % game_id):return
		var image_bounds := art.get_global_rect()
		var touch_bounds := shortcut.get_global_rect()
		if not _check(touch_bounds.encloses(image_bounds),"Tappable area does not cover game image for %s" % game_id):return
		shortcut.pressed.emit()
		await _frames(4)
		if not _check(String(main.get("current_surface")) == "levels","Tapping %s did not open level selection" % game_id):return
		if not _check(String(main.get("selected_game_id")) == game_id,"Tapping image opened incorrect game levels: %s" % game_id):return
		if not _check(main.get("active_game") == null,"Tapping %s started gameplay instead of showing levels" % game_id):return

	main.call("build_home")
	await _frames(4)
	home = main.get_node_or_null("PremiumHome") as Control
	choose = home.find_child("HomePrimaryAction",true,false) as Button
	if not _check(choose != null,"Choose Game vanished after returning from game levels"):return
	choose.pressed.emit()
	await _frames(4)
	if not _check(String(main.get("current_surface")) == "live","Choose Game did not open the Games screen"):return
	if not _check(main.get("active_game") == null,"Choose Game skipped selector and started gameplay"):return

	main.call("build_home")
	await _frames(4)
	home = main.get_node_or_null("PremiumHome") as Control
	ranking = home.find_child("HomeDailyGamesButton",true,false) as Button
	ranking.pressed.emit()
	await _frames(3)
	var popup := main.get_node_or_null("PremiumLeaderboardPopup")
	if not _check(popup != null and String(main.get("current_surface")) == "home","Rankings should open as a modal over Home"):return
	popup.call("close")
	await _frames(3)

	for entry in [
		["HomeProfileButton","profile"],["HomeDailyChallengeButton","daily"]
	]:
		main.call("build_home")
		await _frames(3)
		home = main.get_node_or_null("PremiumHome") as Control
		var button := home.find_child(String(entry[0]),true,false) as Button
		if not _check(button != null,"Home destination missing: %s" % String(entry[0])):return
		button.pressed.emit()
		await _frames(3)
		if not _check(String(main.get("current_surface")) == String(entry[1]),"Wrong Home destination: %s" % String(entry[1])):return

	main.call("build_home")
	await _frames(3)
	home = main.get_node_or_null("PremiumHome") as Control
	var games := home.find_child("HomeGamesNavButton",true,false) as Button
	if not _check(games != null,"Home bottom Games navigation missing"):return
	games.pressed.emit()
	await _frames(3)
	if not _check(String(main.get("current_surface")) == "live" and main.get("active_game") == null,"Bottom Games navigation must open the selector without launching"):return
	main.queue_free()
	await process_frame
	competition.snapshot = old_snapshot
	print("HOME_CLEAN_LAUNCHER_AND_VISIBLE_RANK_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	push_error(message)
	quit(1)
	return false
