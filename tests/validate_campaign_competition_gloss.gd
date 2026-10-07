extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _run() -> void:
	var failures: Array[String] = []
	var competition = root.get_node("CompetitionManager")
	var manager := _read("res://scripts/systems/competition_manager.gd")
	var ui := _read("res://scripts/ui/premium_main_casual.gd")
	var home := _read("res://scripts/ui/premium_home_direct_levels.gd")
	var live := _read("res://scripts/ui/premium_live_hub_3d.gd")
	var edge := _read("res://supabase/functions/unjam-competition/index.ts")
	var migration := _read("res://supabase/migrations/20261007_create_campaign_progression_rankings.sql")
	var canvas := _read("res://scripts/ui/figma_reference_canvas.gd")
	var meta := _read("res://scripts/systems/meta_progression_manager.gd")

	if not competition.has_method("submit_campaign_progress"):
		failures.append("Campaign completion is not submitted to CompetitionManager")
	for method_name in ["game_all_time_top", "game_weekly_top", "game_all_time_rank", "game_weekly_rank"]:
		if not competition.has_method(method_name):
			failures.append("CompetitionManager missing progression ranking helper: %s" % method_name)

	for token in ["submit_progress", "progress_snapshot", "progression_rankings", "progression_level_events", "game_rankings"]:
		if not edge.contains(token) and not manager.contains(token) and not migration.contains(token):
			failures.append("Campaign ranking backend contract missing: %s" % token)

	for token in [
		"enable row level security",
		"revoke all on table public.progression_rankings from anon, authenticated",
		"revoke all on table public.progression_level_events from anon, authenticated"
	]:
		if not migration.to_lower().contains(token.to_lower()):
			failures.append("Campaign ranking security contract missing: %s" % token)

	if not ui.contains('current_surface = "compete"'):
		failures.append("Rankings do not own a distinct Compete surface")
	if not ui.contains('"CAMPAIGN RANKINGS"'):
		failures.append("Compete is not labeled as campaign progression rankings")
	if not ui.contains('"DAILY"') or not ui.contains('"Daily check-in'):
		failures.append("Daily retention/reward surface is not clearly separated from rankings")

	if not home.contains('Callable(self, "_open_compete")'):
		failures.append("Home Compete entry still routes to Daily")
	if not home.contains("HomeDailyChallengeButton"):
		failures.append("Daily challenge is not directly discoverable from Home Live Now")
	if not live.contains('call("build_compete_leaderboard")'):
		failures.append("Games bottom nav Compete entry still routes to Daily")

	if not ui.contains("font_placeholder_color"):
		failures.append("Friend-code placeholder does not have explicit readable contrast")
	if not ui.contains("Only your UNJAM name and level rank are visible."):
		failures.append("Friends privacy helper copy is not compact enough for phone width")
	if not ui.contains("Share your code to connect."):
		failures.append("Friends empty-state copy is not phone-safe")

	if not canvas.contains("gloss_strength * 1.35"):
		failures.append("Cached flat gloss has not been strengthened for modern 2D lacquer")
	if not canvas.contains("Premium 2D lacquer"):
		failures.append("Gloss implementation lacks explicit lightweight 2D material contract")

	if meta.contains("ENTER 1 DAILY CUP") or meta.contains("PLAY 5 DAILY CUPS"):
		failures.append("Meta goals still describe Daily as a Cup competition")

	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		failures.append("Main scene is unavailable for competition runtime validation")
	else:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.call("build_compete_leaderboard", false)
		await process_frame
		for game_id in ["rescue_rush","water_sort","block_puzzle"]:
			var tab := main.find_child("RankingGame_%s" % game_id, true, false) as Button
			if tab == null:
				failures.append("Compete missing runtime game tab: %s" % game_id)
			elif tab.size.y < 44.0:
				failures.append("Compete game tab below 44px touch target: %s" % game_id)
		for button_name in ["CompetitionDailyButton","CompetitionFriendsButton","CompetitionRefreshButton"]:
			var action := main.find_child(button_name, true, false) as Button
			if action == null or action.size.y < 44.0:
				failures.append("Compete action missing or below touch floor: %s" % button_name)
		main.call("build_friends", false)
		await process_frame
		for button_name in ["FriendsCopyCode","FriendsRotateCode","FriendsAddButton","FriendsGlobalRanks"]:
			var action := main.find_child(button_name, true, false) as Button
			if action == null or action.size.y < 44.0:
				failures.append("Friends action missing or below touch floor: %s" % button_name)
		var privacy := main.find_child("FriendsLeaderboard", true, false) as Control
		if privacy == null:
			failures.append("Friends leaderboard panel did not render")
		main.queue_free()
		await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("CAMPAIGN_COMPETITION_GLOSS_OK")
	quit(0)
