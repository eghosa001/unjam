extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene not loadable")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(6)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("Premium Home surface missing")
	var canvas := home.find_child("FigmaHome390x844",true,false) as Control
	var hero := home.find_child("FigmaHomeHero",true,false) as Control
	var art := home.find_child("HomeHeroFlatGameLogo",true,false) as Control
	var choose := home.find_child("HomePrimaryAction",true,false) as Button
	var rank_card := home.find_child("HomeRankSummaryCard",true,false) as Control
	var rank_text := home.find_child("HomeRankValue",true,false) as Label
	var rank_open := home.find_child("HomeDailyGamesButton",true,false) as Button
	var daily_card := home.find_child("HomeDailyFeatureCard",true,false) as Control
	var daily := home.find_child("HomeDailyChallengeButton",true,false) as Button
	var goals := home.find_child("HomeGoalsButton",true,false) as Button
	var friends := home.find_child("HomeFriendsButton",true,false) as Button
	var profile := home.find_child("HomeProfileButton",true,false) as Button
	var nav := home.find_child("HomeBottomNav3D",true,false) as Control
	if canvas == null or hero == null or art == null or choose == null or rank_card == null or rank_text == null or rank_open == null or daily_card == null or daily == null or goals == null or friends == null or profile == null or nav == null:
		return _fail("Clean Home hierarchy is incomplete")
	if not _same(hero,Rect2(21,121,346,224)):
		return _fail("Hero authored geometry regressed")
	if not _same(choose,Rect2(37,285,172,48)) or not choose.text.contains("CHOOSE GAME"):
		return _fail("Primary action must be Choose Game inside hero")
	if not _same(rank_card,Rect2(21,365,346,162)):
		return _fail("Week-rank card has incorrect geometry")
	if not _same(daily_card,Rect2(21,548,346,116)):
		return _fail("Daily feature card geometry drifted")
	if not _same(nav,Rect2(13,757,362,70)):
		return _fail("Bottom navigation does not respect safe area")
	if not (hero.position.y+hero.size.y+16.0 <= rank_card.position.y and rank_card.position.y+rank_card.size.y+16.0 <= daily_card.position.y):
		return _fail("Home premium cards overlap or lack breathing room")
	if daily_card.position.y+daily_card.size.y >= goals.position.y or goals.position.y+goals.size.y >= nav.position.y:
		return _fail("Daily/secondary actions overlap bottom navigation")
	if rank_open.size.y < 44 or choose.size.y < 44 or daily.size.y < 44:
		return _fail("Critical Home actions must be at least 44px tall")
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		if home.find_child("HomeDirect_%s" % game_id,true,false) != null:
			return _fail("Home still draws a duplicate game grid for %s" % game_id)
	if home.find_child("HomeWorldProgress",true,false) != null:
		return _fail("Home still draws the retired crowded World panel")
	if not String(art.get_script().resource_path).ends_with("unjam_2d_game_art.gd"):
		return _fail("Home lacks authored illustrated game artwork")
	var daily_label := home.find_child("HomeNavLabel_DAILY",true,false) as Label
	var collection_label := home.find_child("HomeNavLabel_COLLECT",true,false) as Label
	var settings_label := home.find_child("HomeNavLabel_SETTINGS",true,false) as Label
	if daily_label == null or collection_label == null or settings_label == null:
		return _fail("Bottom navigation labels missing")
	if daily_label.get_global_rect().end.x >= collection_label.get_global_rect().position.x or collection_label.get_global_rect().end.x >= settings_label.get_global_rect().position.x:
		return _fail("Bottom navigation labels overlap")

	root.size = Vector2i(2560,1600)
	await _frames(8)
	var wide_stage := home.find_child("HomeWideStage",true,false) as Control
	var wide_art := home.find_child("HomeWideSelectedGameArt",true,false) as Control
	if wide_stage == null or not wide_stage.visible or wide_art == null or wide_art.size.x < 700.0:
		return _fail("Landscape tablet does not use a premium split stage")
	if wide_art.get_global_rect().position.x <= canvas.get_global_rect().end.x + 40.0:
		return _fail("Landscape artwork overlaps the interactive Home panel")
	main.queue_free()
	await _frames(2)
	print("HOME_MINIMAL_VISUAL_HIERARCHY_OK")
	quit(0)

func _same(node: Control, expected: Rect2) -> bool:
	return Rect2(node.position,node.size).position.distance_to(expected.position) <= 1.0 and node.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
