extends SceneTree

# Production contract: Home is a minimalist UNJAM launcher with no individual
# puzzle or Continue foreground feature. Three actions, large breathing room.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene unavailable")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("Home surface unavailable")
	var canvas := home.find_child("FigmaHome390x844",true,false) as Control
	var hero := home.find_child("FigmaHomeHero",true,false) as Control
	var choose := home.find_child("HomePrimaryAction",true,false) as Button
	var emblem := home.find_child("HomeBrandEmblem",true,false) as TextureRect
	var rank_panel := home.find_child("HomeRankSummaryCard",true,false) as Control
	var daily_rank := home.find_child("HomeRankDailyValue",true,false) as Label
	var week_rank := home.find_child("HomeRankValue",true,false) as Label
	var ranks := home.find_child("HomeDailyGamesButton",true,false) as Button
	var daily_panel := home.find_child("HomeDailyFeatureCard",true,false) as Control
	var daily := home.find_child("HomeDailyChallengeButton",true,false) as Button
	var nav := home.find_child("HomeBottomNav3D",true,false) as Control
	if canvas == null or hero == null or choose == null or emblem == null or rank_panel == null or daily_rank == null or week_rank == null or ranks == null or daily_panel == null or daily == null or nav == null:
		return _fail("Minimalist Home is missing required actions or rankings")
	if not _same(hero,Rect2(21,139,346,259)):
		return _fail("Welcome hero layout drifted")
	if not _same(choose,Rect2(39,318,312,62)) or choose.text != "▦  CHOOSE GAME":
		return _fail("Choose Game must dominate the welcome card and be full width")
	if not _same(rank_panel,Rect2(21,420,346,169)):
		return _fail("Today/weekly rank card layout drifted")
	if not _same(daily_panel,Rect2(21,609,346,101)):
		return _fail("Daily feature layout drifted")
	if not _same(nav,Rect2(13,757,362,70)):
		return _fail("Bottom navigation is not stable")
	if hero.position.y+hero.size.y >= rank_panel.position.y or rank_panel.position.y+rank_panel.size.y >= daily_panel.position.y or daily_panel.position.y+daily_panel.size.y >= nav.position.y:
		return _fail("Home panels overlap rather than leaving clear spacing")
	for button in [choose,ranks,daily]:
		if button.size.y < 44 or button.size.x < 125:
			return _fail("Primary Home action is not thumb-sized: %s" % button.name)
	# This is the key previously missed regression. No selected-game title,
	# current level, splash illustration or per-game launch cards on Home.
	for forbidden in ["HomeHeroGameTitle","HomeHeroGameMeta","HomeHeroFlatGameLogo",
		"HomeWideSelectedGameArt","HomeWideGameTitle","HomeSelectedGameLevel",
		"HomeWorldProgress","HomeQuickSwitchFlatLogo_rescue_rush",
		"HomeDirect_rescue_rush","HomeDirect_water_sort","HomeDirect_block_puzzle"]:
		if home.find_child(forbidden,true,false) != null:
			return _fail("Selected game leaked back onto minimalist Home: %s" % forbidden)
	for node in canvas.find_children("*","Label",true,false):
		if node is Label:
			var label := node as Label
			for unwanted in ["RESCUE RUSH","WATER SORT","BLOCK PUZZLE","CONTINUE • LEVEL"]:
				if label.text.to_upper().contains(unwanted):
					return _fail("Home foreground still advertises an individual game: %s" % label.text)
	if home.find_child("HomeSidekick",true,false) != null:
		return _fail("Home has an extra promotional panel")
	# Tablet stage must also show the neutral UNJAM identity, not a selected
	# game mascot the user specifically asked us to remove.
	root.size = Vector2i(2560,1600)
	await _frames(8)
	var wide_stage := home.find_child("HomeWideStage",true,false) as Control
	var wide_mark := home.find_child("HomeWideBrandMark",true,false) as TextureRect
	if wide_stage == null or not wide_stage.visible or wide_mark == null or wide_mark.size.x < 700:
		return _fail("Tablet branding is missing from neutral landscape Home")
	if wide_mark.get_global_rect().position.x <= canvas.get_global_rect().end.x+40:
		return _fail("Tablet branding overlaps the launcher")
	main.queue_free()
	await _frames(2)
	print("HOME_NEUTRAL_MINIMAL_HIERARCHY_OK")
	quit(0)

func _same(node: Control, expected: Rect2) -> bool:
	return node.position.distance_to(expected.position) < 1.0 and node.size.distance_to(expected.size) < 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
