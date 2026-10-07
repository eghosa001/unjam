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
	if not ui.contains("RankingGame_rescue_rush") or not ui.contains("RankingGame_water_sort") or not ui.contains("RankingGame_block_puzzle"):
		failures.append("Compete does not expose all three game rankings")
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

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("CAMPAIGN_COMPETITION_GLOSS_OK")
	quit(0)
