extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var games := root.get_node("MultiGameManager")
	var cloud := root.get_node("CloudSaveManager")
	var original: Dictionary = save.data.duplicate(true)

	# Simulate meaningful offline Water + Block activity, including a
	# resumable in-progress puzzle. The original cloud whitelist lost it all.
	save.data["language_code"] = "yo"
	save.data["gentle_effects"] = false
	save.data["game_progress"] = {
		"water_sort": {"highest_level": 103, "stars": {"1":3, "2":2, "102":3},
			"levels_completed": 3, "perfect_clears": 2},
		"block_puzzle": {"highest_level": 204, "stars": {"1":3, "202":2, "203":3},
			"levels_completed": 3, "perfect_clears": 2},
	}
	save.data["multi_active_runs"] = {
		"water_sort": {"level":103,"moves":4,"board":[[1,2],[2,1]]}
	}
	games.invalidate_cloud_progress_cache()
	var saved: Dictionary = cloud.call("_snapshot")
	if not _check(saved.has("game_progress") and saved.has("multi_active_runs")
		and saved.has("language_code") and saved.has("gentle_effects"),
		"Cloud snapshot drops Water/Block progress, run, or preferences"):return
	if not _check(int(saved["game_progress"]["water_sort"]["highest_level"]) == 103
		and int(saved["game_progress"]["block_puzzle"]["highest_level"]) == 204,
		"Game snapshots did not include both campaign states"):return
	var expected_water: int = games.total_stars("water_sort")
	if not _check(expected_water == 8, "Pre-restore star total fixture invalid"):return

	# Force a local cached score to be different so restore must invalidate
	# the cached UI totals instead of showing the previous player's values.
	save.data["game_progress"]["water_sort"]["stars"] = {"1":1}
	games.invalidate_cloud_progress_cache()
	if not _check(games.total_stars("water_sort") == 1,
		"Could not seed the stale UI cache"):return
	save.data["multi_active_runs"] = {}
	save.data["language_code"] = "en"
	save.data["gentle_effects"] = true
	cloud.call("_apply_remote",saved,7)
	var restored = save.data.get("game_progress",{})
	if not _check(restored is Dictionary
		and int(restored["water_sort"]["highest_level"]) == 103
		and int(restored["block_puzzle"]["highest_level"]) == 204,
		"Cloud restore did not reinstate all game progression"):return
	if not _check(games.total_stars("water_sort") == 8,
		"Cloud restore left the old star cache visible"):return
	if not _check(save.data["multi_active_runs"].has("water_sort"),
		"Cloud restore dropped an unfinished Water Sort puzzle"):return
	if not _check(save.data.get("language_code") == "yo"
		and not bool(save.data.get("gentle_effects",true)),
		"Cloud restore did not recover language and motion preferences"):return

	# Keep paid Play ownership local: remote snapshots never contain
	# reusable billing tokens or entitlements.
	for forbidden in ["remove_ads","starter_pack_purchased","purchase_install_id",
		"purchase_claim_ids","processed_purchase_tokens","purchase_coin_debt",
		"analytics_opt_in","privacy_consent_status"]:
		if not _check(not saved.has(forbidden), "Unsafe private/billing field in cloud: %s" % forbidden):return
	save.data = original
	games.invalidate_cloud_progress_cache()
	save.save()
	print("COMPLETE_CLOUD_PROGRESSION_OK: three-game state, in-progress puzzle, locale, cache invalidation and purchase exclusion")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:
		return true
	push_error(reason)
	quit(1)
	return false
