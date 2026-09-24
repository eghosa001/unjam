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

	# Runtime economy contract: Collection purchases must have persistent value,
	# cost real shared-wallet coins, and the daily gift must be idempotent.
	save.data["coins"] = 1000
	save.data["decorations"] = []
	save.data["garden_last_gift_date"] = ""
	save.data["garden_gifts_claimed"] = 0

	if economy.collection_daily_bonus() != 0:
		failures.append("Empty Collection must not receive a Daily Game bonus")
	if economy.garden_gift_amount() != 0:
		failures.append("Empty Collection must not generate a garden gift")

	if not economy.unlock_collection_item("cottage", 500):
		failures.append("Collection purchase should succeed when affordable")
	if int(save.data.get("coins", 0)) != 500:
		failures.append("Collection purchase must spend the configured shared-wallet cost")
	if "cottage" not in save.data.get("decorations", []):
		failures.append("Purchased Collection upgrade was not persisted")
	if economy.collection_daily_bonus() != 5:
		failures.append("Each Collection upgrade must add +5 to every Daily Game")
	if economy.garden_gift_amount() != 10:
		failures.append("Each Collection upgrade must add +10 to the daily garden gift")

	save.data["garden_last_gift_date"] = "2000-01-01"
	var gift: int = int(economy.call("claim_garden_gift"))
	if gift != 10 or int(save.data.get("coins", 0)) != 510:
		failures.append("Daily garden gift did not grant its real wallet reward")
	if economy.claim_garden_gift() != 0 or int(save.data.get("coins", 0)) != 510:
		failures.append("Daily garden gift must be claimable only once per calendar day")

	save.data["decorations"] = ["tree", "bench", "fountain", "lanterns", "cottage", "rainbow_bridge"]
	if economy.collection_daily_bonus() != 30:
		failures.append("Full 6/6 Collection should add +30 to every Daily Game")
	if economy.garden_gift_amount() != 80:
		failures.append("Full 6/6 Collection should generate 60 + 20 master gift coins")

	# Navigation/content contracts: Daily Games must be visible in the active
	# premium surfaces rather than existing only as dormant backend methods.
	var home := _read("res://scripts/ui/premium_home_casual.gd")
	var main := _read("res://scripts/ui/premium_main_casual.gd")
	var live := _read("res://scripts/ui/premium_live_hub_3d.gd")
	var rescue := _read("res://scripts/game/game.gd")
	var multi := _read("res://scripts/core/economy_multi_game_manager.gd")
	var save_wrapper := _read("res://scripts/core/economy_save_manager.gd")

	for token in ["HomeDailyGamesButton", "build_daily_games"]:
		if not home.contains(token):
			failures.append("Home is missing Daily Games route token: %s" % token)
	for token in [
		"func build_daily_games",
		"\"daily\":166.0, \"collection\":238.0, \"settings\":310.0",
		"nav_label.clip_text = true",
		"DailyCard/",
		"\"PLAY\"",
		"COMPLETED",
		"if _daily_done(game_id)",
		"collection_daily_bonus()",
		"Proto/ScrollToUpgrades",
		"CollectionOpenUpgrades",
		"func build_collection_upgrades",
		"CollectionScroll/Upgrade/",
		"CollectionUpgradePreview/",
		"GardenUpgradePreviewScene",
		"+5 DAILY",
		"+10 GIFT",
		"rainbow_bridge"
	]:
		if not main.contains(token):
			failures.append("Premium main is missing Figma Collection/Daily contract token: %s" % token)
	if not live.contains("build_daily_games"):
		failures.append("Game selector navigation must expose Daily Games")
	if not rescue.contains("collection_daily_bonus"):
		failures.append("Rescue daily result must display Collection bonus value")
	if not multi.contains("effective_reward := safe_reward if id == \"rescue_rush\" else safe_reward + bonus"):
		failures.append("Water Sort / Block Puzzle daily rewards must include Collection bonus")
	if not save_wrapper.contains("var total_reward := safe_reward + bonus"):
		failures.append("Rescue Rush daily reward must include Collection bonus")

	save.data = original
	save.save()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("COLLECTION_DAILY_VALUE_OK")
	quit(0)
