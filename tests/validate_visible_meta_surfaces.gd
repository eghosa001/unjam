extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _run() -> void:
	var failures: Array[String] = []
	var save = root.get_node("SaveManager")
	var meta = root.get_node("MetaProgressionManager")
	var economy = root.get_node("EconomyManager")
	var original: Dictionary = save.data.duplicate(true)

	save.data["coins"] = 1000
	save.data["crown_tokens"] = 0
	save.data["meta_progression"] = {}
	meta.ensure_state()

	var login := meta.daily_login_info()
	if bool(login.get("claimed", true)):
		failures.append("Fresh meta state must expose today's login reward")
	var before_login := economy.balance()
	if meta.claim_daily_login() <= 0 or economy.balance() <= before_login:
		failures.append("Daily login reward did not grant coins")

	meta.record_campaign_complete("rescue_rush", 3, true)
	meta.record_campaign_complete("water_sort", 3, true)
	meta.record_daily_complete("block_puzzle", 3)

	var daily_rows := meta.daily_goals()
	var ready_ids: Array[String] = []
	for raw in daily_rows:
		var row: Dictionary = raw
		if bool(row.get("claimable", false)):
			ready_ids.append(String(row.get("id", "")))
	for expected in ["play2", "stars6", "daily1"]:
		if expected not in ready_ids:
			failures.append("Daily goal did not become claimable: %s" % expected)

	var before_goal := economy.balance()
	if not meta.claim_goal("daily", "play2") or economy.balance() <= before_goal:
		failures.append("Claimable Daily goal did not grant reward")
	if meta.claim_goal("daily", "play2"):
		failures.append("Daily goal reward was claimable twice")

	for _i in range(8):
		meta.record_campaign_complete("rescue_rush", 3, true)
	var season := meta.season_info()
	if int(season.get("points", 0)) < 100 or int(season.get("ready", 0)) <= 0:
		failures.append("Season Journey did not progress from successful play")
	if not meta.claim_next_ready_season_tier():
		failures.append("Ready Season Journey tier could not be claimed")

	var home := _read("res://scripts/ui/premium_home_casual.gd")
	var main := _read("res://scripts/ui/premium_main_casual.gd")
	var selector := _read("res://scripts/ui/premium_live_hub_3d.gd")
	var cloud := _read("res://scripts/systems/cloud_save_manager.gd")
	var edge := _read("res://supabase/functions/unjam-cloud-save/index.ts")

	for token in ["HomeProfileButton", "HomeGoalsButton", "HomeSeasonJourneyButton", "HomeSidekickButton", "LIVE NOW"]:
		if not home.contains(token):
			failures.append("Home is missing visible meta entry: %s" % token)
	for token in ["func build_goals()", "func build_profile()", "CollectionAchievementsView", "DAILY CHECK-IN", "SEASON JOURNEY", "ACHIEVEMENTS"]:
		if not main.contains(token):
			failures.append("Goals/Profile surface contract missing: %s" % token)
	if not selector.contains('"COMPETE" if String(item[0]) == "DAILY"'):
		failures.append("Games selector does not visibly relabel Daily as Compete")
	if not cloud.contains('"meta_progression"') or not edge.contains('"meta_progression"'):
		failures.append("Meta progression is not protected by cloud save")

	save.data = original
	save.save()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("VISIBLE_META_SURFACES_OK")
	quit(0)
