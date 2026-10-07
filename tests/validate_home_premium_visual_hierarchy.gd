extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene could not be loaded")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(6)

	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("Premium Home surface is missing")
	var canvas := home.find_child("FigmaHome390x844", true, false) as Control
	var hero := home.find_child("FigmaHomeHero", true, false) as Control
	var hero_art := home.find_child("HomeHeroFlatGameLogo", true, false) as Control
	var primary := home.find_child("HomePrimaryAction", true, false) as Button
	var choose := home.find_child("HomeChooseGameButton", true, false) as Button
	var showcase := home.find_child("HomeWorldProgress", true, false) as Control
	var showcase_mark := home.find_child("HomeWorldFlatGameLogo", true, false) as Control
	var nav := home.find_child("HomeBottomNav3D", true, false) as Control
	if canvas == null or hero == null or hero_art == null or primary == null or choose == null or showcase == null or showcase_mark == null or nav == null:
		return _fail("Figma Home hierarchy is incomplete")
	if not _rect_eq(Rect2(hero.position, hero.size), Rect2(21,121,346,224)):
		return _fail("Home hero drifted from Figma 346x224 reference")
	if not _rect_eq(Rect2(hero_art.position, hero_art.size), Rect2(174,129,184,204)):
		return _fail("Home illustrated game art is not large enough to dominate the hero")
	if not _rect_eq(Rect2(primary.position, primary.size), Rect2(37,285,172,48)):
		return _fail("Home primary action drifted from Figma reference")
	if not _rect_eq(Rect2(choose.position, choose.size), Rect2(21,365,166,52)):
		return _fail("Home Choose Game action drifted from Figma reference")
	if not _rect_eq(Rect2(showcase.position, showcase.size), Rect2(21,582,346,150)):
		return _fail("Home world showcase does not fill the lower dead-space region")
	if not _rect_eq(Rect2(showcase_mark.position, showcase_mark.size), Rect2(32,590,52,48)):
		return _fail("Home compact world game mark drifted from its approved frame")
	if showcase_mark.get_script() == null or not String(showcase_mark.get_script().resource_path).ends_with("unjam_2d_game_art.gd"):
		return _fail("Home world showcase is not using the shared illustrated 2D renderer")
	if hero_art.get_script() == null or not String(hero_art.get_script().resource_path).ends_with("unjam_2d_game_art.gd"):
		return _fail("Home hero is missing the illustrated selected-game art")
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var quick_mark := home.find_child("HomeQuickSwitchFlatLogo_%s" % game_id, true, false) as Control
		if quick_mark == null or quick_mark.get_script() == null or not String(quick_mark.get_script().resource_path).ends_with("unjam_2d_game_art.gd"):
			return _fail("Home Quick Switch illustrated art is missing for %s" % game_id)
	if showcase.get_rect().end.y >= nav.position.y - 8.0:
		return _fail("Home world showcase crowds the bottom navigation")
	var world_title := home.find_child("HomeWorldProgressTitle", true, false) as Label
	var world_value := home.find_child("HomeWorldProgressValue", true, false) as Label
	var completion := home.find_child("HomeWorldProgressRoot", true, false) as Control
	if world_title == null or world_value == null or completion == null:
		return _fail("Home world journey typography nodes are missing")
	var goals := home.find_child("HomeGoalsButton", true, false) as Button
	var daily := home.find_child("HomeDailyChallengeButton", true, false) as Button
	var friends := home.find_child("HomeFriendsButton", true, false) as Button
	var profile := home.find_child("HomeProfileButton", true, false) as Button
	if goals == null or daily == null or friends == null or profile == null:
		return _fail("Home live/meta destinations are missing")
	for action in [daily, goals, friends]:
		if action.size.x < 88.0 or action.size.y < 40.0:
			return _fail("Home Live Now action is too small for touch")
	if world_title.get_theme_font_size("font_size") < 12 or world_value.get_theme_font_size("font_size") < 12:
		return _fail("Home world journey primary metadata fell below 12px reference size")
	if "/" not in world_value.text or world_value.get_theme_font_size("font_size") < 12:
		return _fail("Home world journey completion progress is missing or too small")
	if not _rect_eq(Rect2(nav.position, nav.size), Rect2(13,757,362,70)):
		return _fail("Home bottom nav drifted from Figma reference")
	var collection_label := home.find_child("HomeNavLabel_COLLECT", true, false) as Label
	if collection_label == null or collection_label.text != "COLLECT":
		return _fail("Home bottom nav no longer uses the compact Collection label")
	if collection_label.get_theme_font_size("font_size") < 13:
		return _fail("Home Collection navigation label became too small")
	var daily_label := home.find_child("HomeNavLabel_DAILY", true, false) as Label
	var settings_label := home.find_child("HomeNavLabel_SETTINGS", true, false) as Label
	if daily_label == null or settings_label == null:
		return _fail("Home Daily/Settings navigation labels are missing")
	if daily_label.text != "DAILY":
		return _fail("Home Daily destination is mislabeled")
	if daily_label.get_global_rect().end.x >= collection_label.get_global_rect().position.x:
		return _fail("Home Daily label overlaps Collection")
	if collection_label.get_global_rect().end.x >= settings_label.get_global_rect().position.x:
		return _fail("Home Collection label overlaps Settings")
	if home.find_child("HomeMascot3D", true, false) != null:
		return _fail("Retired giant mascot returned to Figma Home")
	if home.find_child("HomeGameStrip", true, false) != null:
		return _fail("Retired oversized game strip returned to Figma Home")
	var wide_stage_phone := home.find_child("HomeWideStage", true, false) as Control
	if wide_stage_phone == null or wide_stage_phone.visible:
		return _fail("Phone Home must keep the wide tablet stage hidden")

	# Landscape tablets must use their extra canvas rather than centering a narrow
	# phone surface inside empty letterbox space.
	root.size = Vector2i(2560, 1600)
	await _frames(8)
	var wide_stage := home.find_child("HomeWideStage", true, false) as Control
	var wide_art := home.find_child("HomeWideSelectedGameArt", true, false) as Control
	var wide_cta := home.find_child("HomeWideContinueAction", true, false) as Button
	if wide_stage == null or not wide_stage.visible or wide_art == null or wide_cta == null:
		return _fail("Landscape Home is missing its authored split-stage composition")
	if wide_art.size.x < 700.0 or wide_art.size.y < 700.0:
		return _fail("Landscape Home selected-game artwork is not visually dominant")
	if canvas.get_global_rect().get_center().x >= 1280.0:
		return _fail("Landscape Home phone panel was not biased left for the wide art stage")
	if wide_art.get_global_rect().position.x <= canvas.get_global_rect().end.x + 40.0:
		return _fail("Landscape Home art stage crowds the interactive phone panel")

	main.queue_free()
	await _frames(2)
	print("HOME_ILLUSTRATED_2D_VISUAL_HIERARCHY_OK")
	quit(0)

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
