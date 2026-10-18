extends SceneTree

# User-reported navigation/UI consistency across Home, game chooser, Levels
# and Settings. Validate real surfaces and touch regions, not only static text.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("UNJAM main scene missing")
	var main := scene.instantiate() as Control
	root.add_child(main)
	current_scene = main
	await _frames(10)
	main.call("build_home")
	await _frames(4)
	var home := main.find_child("HomeResumeAction",true,false) as Button
	var choose := main.find_child("HomePrimaryAction",true,false) as Button
	if home == null or choose == null:
		return _fail("Home must expose separate Choose and Quick Play actions")
	if home.get_global_rect().intersects(choose.get_global_rect()):
		return _fail("Home gameplay and selection actions overlap")
	if home.size.y < 48.0 or choose.size.y < 48.0 or home.pressed.get_connections().is_empty():
		return _fail("Home has a misleading or undersized action")
	if not home.accessibility_name.begins_with("Play "):
		return _fail("Home quick action must disclose the game to screen readers")

	main.call("_open_games_surface")
	await _frames(5)
	if String(main.get("current_surface")) != "live":
		return _fail("Games menu was not opened")
	for id in ["rescue_rush","water_sort","block_puzzle"]:
		var cue := main.find_child("SelectorBrowseCue_%s" % id,true,false) as Label
		var play := main.find_child("SelectorPlay_%s" % id,true,false) as Button
		var card := main.find_child("SelectorCardHit_%s" % id,true,false) as Button
		if cue == null or play == null or card == null:
			return _fail("Selector lacks distinct level browsing and Play for %s" % id)
		if cue.get_global_rect().intersects(play.get_global_rect()):
			return _fail("Level browsing and Play visually overlap for %s" % id)
		if play.size.x < 90 or play.size.y < 48 or not play.text.contains("PLAY"):
			return _fail("Selector Play is not legible and tappable for %s" % id)
		if not card.accessibility_name.contains("levels") or not play.accessibility_name.to_lower().contains("resume"):
			return _fail("Selector hides browsing/resume semantics from TalkBack")

	main.call("build_settings")
	await _frames(5)
	if String(main.get("_settings_return_surface")) != "live":
		return _fail("Settings forgot its Games entry route")
	if not _check_settings(main):
		return
	# Toggle rebuild must not overwrite the route with settings->settings.
	main.call("build_settings")
	await _frames(3)
	if String(main.get("_settings_return_surface")) != "live":
		return _fail("Preference rebuild lost Settings origin")
	var settings_back := main.find_child("FigmaBack",true,false) as Button
	if settings_back == null or settings_back.pressed.get_connections().is_empty():
		return _fail("Settings lacks a functional Back control")
	settings_back.emit_signal("pressed")
	await _frames(5)
	if String(main.get("current_surface")) != "live":
		return _fail("Settings Back did not return to Games")

	main.call("open_game_campaign","water_sort")
	await _frames(5)
	if String(main.get("current_surface")) != "levels":
		return _fail("Water Sort level browser did not open")
	if not _check_level_browser(main,"water_sort"):
		return
	main.call("_figma_switch_level_game","block_puzzle")
	await _frames(3)
	if not _check_level_browser(main,"block_puzzle"):
		return
	main.call("_figma_switch_level_game","water_sort")
	await _frames(3)
	if not _check_level_browser(main,"water_sort"):
		return
	main.call("build_settings")
	await _frames(3)
	if String(main.get("_settings_return_surface")) != "levels":
		return _fail("Settings did not remember the level browser")
	main.call("_return_from_settings")
	await _frames(5)
	if String(main.get("current_surface")) != "levels" or String(main.get("selected_game_id")) != "water_sort":
		return _fail("Returning from Settings lost the selected campaign")

	main.call("build_daily_games")
	await _frames(4)
	main.call("build_settings")
	await _frames(3)
	if String(main.get("_settings_return_surface")) != "daily":
		return _fail("Settings failed to remember Daily Games")
	# Exercise exactly the Android/system Back handler used by the shell.
	var shell := main.get_node_or_null("UXShell")
	if shell == null or not shell.has_method("_handle_back"):
		return _fail("System Back handler missing")
	shell.call("_handle_back")
	await _frames(5)
	if String(main.get("current_surface")) != "daily":
		return _fail("System Back from Settings did not restore Daily Games: surface=%s origin=%s tutorial=%s" % [String(main.get("current_surface")),String(main.get("_settings_return_surface")),str(shell.get("tutorial_panel") != null and shell.get("tutorial_panel").visible)])
	main.queue_free()
	await _frames(2)
	print("UNJAM_NAVIGATION_SETTINGS_HIERARCHY_OK")
	quit(0)

func _check_level_browser(main: Control, game_id: String) -> bool:
	var play := main.find_child("LevelPlayCurrent",true,false) as Button
	var find_level := main.find_child("LevelCurrent",true,false) as Button
	var world := main.find_child("LevelWorldName",true,false) as Label
	var panel := main.find_child("LevelPageProgressCard",true,false) as Control
	if play == null or find_level == null or world == null or panel == null:
		return _fail("Missing clear Play/Find/World UI for %s" % game_id)
	if not play.text.contains("PLAY") or play.size.y < 48 or play.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
		return _fail("Play Current Level action not clear and release-triggered for %s" % game_id)
	var current := int(main.call("_highest_level_for_game",game_id))
	if not play.accessibility_name.contains("level %d" % current):
		return _fail("Play Current accessible label does not name the actual level")
	if find_level.text != "MY LEVEL" or not find_level.tooltip_text.contains("Does not start"):
		return _fail("Find My Level is misleadingly presented as a play button")
	if find_level.pressed.get_connections().is_empty() or play.pressed.get_connections().is_empty():
		return _fail("Levels action buttons are not functional")
	if play.get_global_rect().intersects(world.get_global_rect()):
		return _fail("Level Play button overlaps the world name")
	var expected_end := 745.0 if game_id == "block_puzzle" else 746.0
	if absf(panel.position.y + panel.size.y - expected_end) > 1.5:
		return _fail("Level progress rail not inside safe area for %s: %.1f" % [game_id,panel.position.y+panel.size.y])
	# The authored tile names may be slash-sanitized by Godot; the rail's
	# viewport-safe position is the invariant that protects all layouts.
	if panel.position.y + panel.size.y > 750.0:
		return _fail("Level progress extends underneath the system gesture zone")
	return true

func _check_settings(main: Control) -> bool:
	var appearance := main.find_child("SettingsCard*Appearance",true,false) as Control
	var support := main.find_child("HelpPrivacy",true,false) as Control
	var purchases := main.find_child("SettingsCard*Purchases",true,false) as Control
	var theme := main.find_child("SettingsThemeToggle",true,false) as Button
	var language := main.find_child("SettingsLanguageToggle",true,false) as Button
	if appearance == null or support == null or purchases == null or theme == null or language == null:
		return _fail("Settings is missing appearance/help/account groups")
	var nav := main.find_child("StdNav*Bar",true,false) as Control
	if nav == null:
		return _fail("Settings bottom navigation missing")
	if appearance.get_global_rect().intersects(support.get_global_rect()) or support.get_global_rect().intersects(purchases.get_global_rect()):
		return _fail("Settings section panels overlap")
	if purchases.get_global_rect().intersects(nav.get_global_rect()):
		return _fail("Settings account controls collide with the bottom tabs")
	if not appearance.get_global_rect().encloses(theme.get_global_rect()) or not appearance.get_global_rect().encloses(language.get_global_rect()):
		return _fail("Appearance options leave their own settings card")
	if theme.get_global_rect().intersects(language.get_global_rect()):
		return _fail("Theme and language are stacked on top of each other")
	if theme.size.x < 100 or language.size.x < 100 or theme.size.y < 44 or language.size.y < 44:
		return _fail("Appearance actions too small for Android")
	for name in ["SettingsHowToPlay","SettingsHowToPlayGame","SettingsPrivacy","SettingsPurchases","SettingsCloudBackup"]:
		var control := main.find_child(name,true,false) as Button
		if control == null or control.size.y < 44 or control.pressed.get_connections().is_empty():
			return _fail("Settings support or purchase action is unusable: %s" % name)
		if control.accessibility_name.is_empty() and control.tooltip_text.is_empty():
			return _fail("Settings action is not accessible: %s" % name)
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
