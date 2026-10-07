extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _run() -> void:
	var failures: Array[String] = []
	var save = root.get_node("SaveManager")
	var economy = root.get_node("EconomyManager")
	var original: Dictionary = save.data.duplicate(true)

	save.data["coins"] = 10000
	save.data["decorations"] = []
	save.data["collection_levels"] = {}
	save.data["garden_last_gift_date"] = ""
	save.data["reward_double_claims"] = []

	if economy.collection_total_levels() != 0 or economy.collection_daily_bonus() != 0:
		failures.append("Empty Collection must start at zero progression/value")
	if not economy.upgrade_collection_item("tree", 100):
		failures.append("Tree level 1 purchase failed")
	if economy.collection_item_level("tree") != 1 or economy.collection_daily_bonus() != 5:
		failures.append("Tree level 1 must persist and add its Daily specialization")
	if economy.collection_level_cost("tree", 100) <= 100:
		failures.append("Higher Collection levels must cost more than level 1")
	if not economy.upgrade_collection_item("bench", 150) or economy.hint_cost(25) >= 25:
		failures.append("Bench must permanently reduce normal hint cost")
	if not economy.upgrade_collection_item("fountain", 250) or economy.collection_campaign_reward(100) <= 100:
		failures.append("Fountain must increase campaign coin value")
	if not economy.upgrade_collection_item("cottage", 500) or economy.garden_gift_amount() <= 0:
		failures.append("Cottage must increase the Garden gift")

	if not economy.claim_reward_double("qa:double", 50):
		failures.append("First reward-double claim should grant")
	var doubled_balance := int(save.data.get("coins", 0))
	if economy.claim_reward_double("qa:double", 50) or int(save.data.get("coins", 0)) != doubled_balance:
		failures.append("Reward-double claim must be idempotent")

	var home := _read("res://scripts/ui/premium_home_casual.gd")
	var main := _read("res://scripts/ui/premium_main_casual.gd")
	var competition := _read("res://scripts/systems/competition_manager.gd")
	var rescue := _read("res://scripts/game/game.gd")
	var water := _read("res://scripts/game/water_sort_10000.gd")
	var water_base := _read("res://scripts/game/water_sort.gd")
	var block := _read("res://scripts/game/block_puzzle.gd")
	var multi := _read("res://scripts/core/economy_multi_game_manager.gd")

	for token in ["build_daily_games"]:
		if not home.contains(token):
			failures.append("Home Daily retention contract missing: %s" % token)
	for token in ["daily\":\"COMPETE", "build_compete_leaderboard", "CAMPAIGN RANKINGS", "collection_item_level", "L%d/%d"]:
		if not main.contains(token):
			failures.append("Compete/Collection UI contract missing: %s" % token)
	for token in ["submit_campaign_progress", "claim_weekly_reward", "game_all_time_top", "game_weekly_top", "already_claimed"]:
		if not competition.contains(token):
			failures.append("Campaign competition manager contract missing: %s" % token)
	for source in [rescue, water, block]:
		if source.contains("CompetitionManager.submit_daily_result"):
			failures.append("Daily challenge still submits obsolete ranked Daily points")
	if not multi.contains("CompetitionManager.submit_campaign_progress"):
		failures.append("Campaign completion does not submit progression to rankings")
	if not multi.contains('rewards["base_coins"] = safe_reward if bool(rewards.get("first_clear", false)) else 0'):
		failures.append("Water/Block first-clear rewards are not exposed for safe campaign doubling")
	for source in [rescue, water_base, block]:
		if not source.contains("Undo is disabled in this Daily challenge."):
			failures.append("Daily challenge assist restriction lost its clear player-facing explanation")

	save.data = original
	save.save()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("COLLECTION_DAILY_VALUE_OK")
	quit(0)
