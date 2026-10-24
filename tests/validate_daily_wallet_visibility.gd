extends SceneTree
# Reward is a daily COIN wallet credit, not Season Journey PTS.
# Verify the real V3 Home action, live totals, Daily and Goals indicators.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	# SceneTree scripts are not parsed with app Autoload global identifiers;
	# resolve the real configured services by absolute root paths.
	var meta := root.get_node("MetaProgressionManager")
	var save := root.get_node("SaveManager")
	var economy := root.get_node("EconomyManager")
	meta.call("ensure_state")
	var data: Dictionary = save.get("data")
	var saved := data.duplicate(true)
	var state: Dictionary = (data.get("meta_progression",{}) as Dictionary).duplicate(true)
	state["login_last_claim"] = ""
	state["login_day"] = 0
	data["meta_progression"] = state
	data["purchase_coin_debt"] = 0
	var prior_coins := int(economy.call("balance"))
	var prior_season_points := int(meta.call("season_info").get("points",0))
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Cannot open Main for daily wallet UI"):return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(8)
	var home := main.get_node_or_null("PremiumHome") as Control
	if not _check(home != null,"Persistent Home is missing"):return
	home.call("_refresh_home_daily_reward")
	var claim := home.find_child("HomeDailyChallengeButton",true,false) as Button
	if not _check(claim != null and claim.text.begins_with("CLAIM +"),"Daily claim was not exposed as a prominent Home action"):return
	var reward := int(meta.call("daily_login_info").get("reward",0))
	claim.pressed.emit()
	if not _check(int(economy.call("balance")) == prior_coins+reward,"Home check-in did not credit the coin wallet exactly once"):return
	if not _check(claim.text.contains("PLAY TODAY"),"Claimed reward did not switch Home into Play Daily"):return
	if not _check(int(meta.call("season_info").get("points",0)) == prior_season_points,"Daily coin claim unexpectedly changed independent Season PTS"):return
	claim.pressed.emit()
	await _frames(3)
	if not _check(String(main.get("current_surface")) == "daily","Home daily action failed to open Daily after claim"):return
	var wallet := main.find_child("DailyWalletAfterClaim",true,false) as Label
	if not _check(wallet != null and wallet.text.contains(str(prior_coins+reward)),"Daily check-in did not show the updated wallet total"):return
	var badge := main.find_child("FigmaHeaderPill",true,false) as Button
	if not _check(badge != null and badge.text.begins_with("◈") and badge.accessibility_name.contains("coins"),"Daily header did not show a live coin balance"):return
	main.call("build_goals")
	var goals_badge := main.find_child("FigmaHeaderPill",true,false) as Button
	if not _check(goals_badge != null and goals_badge.accessibility_name.contains(str(prior_coins+reward)),"Goals wallet did not reflect newly claimed coins"):return
	var login_claim := main.find_child("GoalsLoginClaim",true,false) as Button
	if not _check(login_claim != null and login_claim.disabled,"Claiming on Home left duplicate payout in Goals"):return
	save.set("data",saved)
	save.call("save")
	main.queue_free()
	await _frames(10)
	print("DAILY_WALLET_VISIBILITY_OK Home claim, one payout, instant visible wallet, Goals, independent Season PTS")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):await process_frame

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
