extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Keep this layout test deterministic and free of live network requests.
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	var competition := root.get_node_or_null("CompetitionManager")
	if not _check(competition != null,"Missing competition autoload"): return
	var previous_progress: Dictionary = competition.snapshot.duplicate(true)
	var previous_daily: Dictionary = competition.daily_snapshot.duplicate(true)
	var daily: Array = []
	var progress: Array = []
	for i in range(20):
		daily.append({"name":"DAILY PLAYER %02d" % i,"score":3000-i*30,"games_count":3})
		progress.append({"name":"CAMPAIGN PLAYER %02d" % i,"levels_completed":200-i,"stars":600-i})
	competition.daily_snapshot = {
		"ok":true, "daily_top":daily, "player_daily":{"rank":7,"score":2250},
		"day":"2026-10-08"
	}
	competition.snapshot = {
		"ok":true, "game_rankings":{
			"rescue_rush":{
				"weekly_top":progress, "all_time_top":progress,
				"player_weekly":{"rank":5,"levels_completed":88},
				"player_all_time":{"rank":12,"levels_completed":215}
			}
		}
	}
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Main scene not loadable"):return
	root.size = Vector2i(540,960)
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(4)
	var home := main.find_child("HomeDailyGamesButton",true,false) as Button
	if not _check(home != null and home.size.y >= 44,"Home has no first-class rankings action"):return
	home.pressed.emit()
	await _frames(3)
	var popup := main.get_node_or_null("PremiumLeaderboardPopup")
	if not _check(popup != null,"Home rankings action did not open modal"):return
	if not _check(_visible_controls(popup),"Modal missing close, period tabs, scroll area, retry or destination"):return
	var ui_scale: float = float(popup.get("_ui_scale"))
	# A real production regression: the global touch enhancer previously
	# inflated 48px modal tabs to 88px+, clipping the leaderboard on phones.
	var enhancer := main.get_node_or_null("UiTouchEnhancer")
	if not _check(enhancer != null,"Global UI enhancer missing"):return
	enhancer.call("_apply_enhancements")
	await _frames(3)
	for name in ["LeaderboardClose","LeaderboardPeriod_today","LeaderboardPeriod_week","LeaderboardPeriod_all",
		"LeaderboardGame_rescue_rush","LeaderboardGame_water_sort","LeaderboardGame_block_puzzle",
		"LeaderboardRetry","LeaderboardPlay"]:
		var action := popup.find_child(name,true,false) as Button
		if not _check(action != null and action.size.y >= 44.0*ui_scale
			and absf(action.custom_minimum_size.y - 48.0*ui_scale) < 3.0
			and absf(float(action.get_theme_font_size("font_size")) - 14.0*ui_scale) < 2.0
			and action.focus_mode == Control.FOCUS_ALL
			and not action.accessibility_name.is_empty(),
			"Leaderboard touch, clipping or screen-reader regression: %s (size=%s, min=%s, font=%d, focus=%d)" % [name,str(action.size if action != null else Vector2.ZERO),str(action.custom_minimum_size if action != null else Vector2.ZERO),action.get_theme_font_size("font_size") if action != null else 0,action.focus_mode if action != null else -1]):return
		if not _check(action.action_mode == BaseButton.ACTION_MODE_BUTTON_RELEASE,
			"Modal tab activates on press instead of release: %s" % name):return
	var scroll := popup.find_child("LeaderboardPlayerScroll",true,false) as ScrollContainer
	if not _check(scroll != null and scroll.get_v_scroll_bar().max_value > scroll.size.y,"20 players must scroll instead of clipping"):return
	if not _check(popup.find_child("LeaderboardPlayer_20",true,false) != null,"20th player is missing"):return
	# The foreground sheet must remain within the visible Android viewport:
	# compact phones, landscape rotations, and tall tablet windows.
	for dimensions in [Vector2i(432,936),Vector2i(960,540),Vector2i(1536,2048)]:
		root.size = dimensions
		await _frames(4)
		var card := popup.find_child("LeaderboardModalCard",true,false) as Control
		if not _check(card != null,"Leaderboard modal card disappeared during resize"):return
		var bounds: Rect2 = card.get_global_rect()
		# CanvasLayer coordinates use the actual visible logical viewport,
		# which may differ from root.size under Godot canvas_items stretch.
		var visible: Rect2 = popup.get_viewport().get_visible_rect()
		if not _check(
			bounds.position.x >= visible.position.x - 1.0
			and bounds.position.y >= visible.position.y - 1.0
			and bounds.end.x <= visible.end.x + 1.0
			and bounds.end.y <= visible.end.y + 1.0,
			"Leaderboard clips logical viewport %s after %s request: %s" % [str(visible),str(dimensions),str(bounds)]
		):return
		if visible.size.y > visible.size.x and visible.size.x >= 750:
			if not _check(bounds.size.x >= visible.size.x*0.87 and bounds.size.y >= visible.size.y*0.89,
				"Leaderboard must be a readable near-full-screen sheet on large Android layouts: %s vs %s" % [str(bounds.size),str(visible.size)]):return
			var big_player := popup.find_child("LeaderboardPlayer_1",true,false)
			if not _check(big_player != null and big_player.custom_minimum_size.y >= 70,
				"Ranked player names are too small at high-density logical resolutions"):return
	root.size = Vector2i(540,960)
	await _frames(4)
	var you := popup.find_child("LeaderboardOwnRank",true,false) as Label
	if not _check(you != null and you.text.contains("#5") and you.accessibility_name.contains("5"),"Weekly player rank is not readable by screen readers"):return
	# Rapid repeated taps must reuse, never stack two modal layers.
	main.call("show_leaderboard_popup","week")
	await _frames(1)
	var count := 0
	for child in main.get_children():
		if child.name == "PremiumLeaderboardPopup" and not child.is_queued_for_deletion():
			count += 1
	if not _check(count == 1,"Repeated leaderboard activation stacked overlays"):return

	popup.call("_set_period","today")
	await _frames(2)
	if not _check(not (popup.find_child("LeaderboardGameTabs",true,false) as Control).visible,"Daily is combined across three puzzles; game tabs should be hidden"):return
	if not _check(you.text.contains("#7") and you.text.contains("2250"),"Daily score/rank is missing"):return
	var daily_row := popup.find_child("LeaderboardPlayer_20",true,false)
	if not _check(daily_row != null,"Daily competitors are not scrollable"):return
	popup.call("_set_period","all")
	await _frames(2)
	if not _check(you.text.contains("#12"),"All-time rank not presented"):return

	popup.call("close")
	await _frames(2)
	if not _check(main.get_node_or_null("PremiumLeaderboardPopup") == null,"Close did not remove modal"):return
	main.call("build_daily_games")
	await _frames(4)
	var daily_button := main.find_child("DailyLeaderboardOpen",true,false) as Button
	if not _check(daily_button != null and daily_button.size.y >= 44,"Daily rankings hidden behind buttons or under footer"):return
	daily_button.pressed.emit()
	await _frames(2)
	popup = main.get_node_or_null("PremiumLeaderboardPopup")
	if not _check(popup != null and not (popup.find_child("LeaderboardGameTabs",true,false) as Control).visible,"Daily button failed to open today's scores"):return
	popup.call("close")
	await _frames(2)
	competition.snapshot = previous_progress
	competition.daily_snapshot = previous_daily
	main.queue_free()
	await _frames(3)
	print("LEADERBOARD_VISIBILITY_OK: Home/Daily one-tap modal, 20 scrollable players, all periods, Back/Close and no stacked overlays")
	quit(0)

func _visible_controls(popup: Node) -> bool:
	for name in ["LeaderboardClose","LeaderboardPeriod_today","LeaderboardPeriod_week",
		"LeaderboardPeriod_all","LeaderboardPlayerScroll","LeaderboardRetry","LeaderboardPlay"]:
		var control := popup.find_child(name,true,false) as Control
		if control == null or control.size.y < 20:
			return false
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(ok: bool, reason: String) -> bool:
	if ok:
		return true
	push_error(reason)
	quit(1)
	return false
