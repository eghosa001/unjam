extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var games := root.get_node("MultiGameManager")
	var before: Dictionary = save.data.duplicate(true)
	var cloud = load("res://tests/fake_cloud_save_manager.gd").new()
	save.data["cloud_save_id"] = "b".repeat(64)
	save.data["cloud_save_revision"] = 3
	save.data["highest_level"] = 14
	save.data["stars"] = {"1":3, "13":2}
	save.data["rescued"] = ["dog-local"]
	save.data["competition_claimed_periods"] = ["2026-10-05:water_sort"]
	save.data["game_progress"] = {
		"water_sort": {
			"highest_level": 52, "stars": {"1":3, "51":2},
			"levels_completed":2, "perfect_clears":1,
		},
		"block_puzzle": {
			"highest_level": 101, "stars": {"1":3,"100":3},
			"levels_completed":2, "perfect_clears":2,
		},
	}
	save.data["multi_active_runs"] = {"water_sort":{"level":52,"moves":3}}
	save.data["coins"] = 190
	save.save()
	games.invalidate_cloud_progress_cache()
	if not _check(games.total_stars("water_sort") == 5, "Bad local progress fixture"):return
	var server_save: Dictionary = {
		"highest_level":17, "stars":{"1":1,"16":3},
		"rescued":["dog-remote"], "coins":130,
		"competition_claimed_periods":["2026-09-28:rescue_rush"],
		"game_progress":{
			"water_sort":{"highest_level":54,"stars":{"1":2,"53":3},"levels_completed":2,"perfect_clears":1},
		},
		"multi_active_runs":{"block_puzzle":{"level":202,"moves":9}},
	}
	# A 409 response means a newer cloud revision won the transaction. It
	# must NOT silently erase saved level clears made offline on this phone.
	cloud.set("_initial_reconciled", true)
	cloud.fixture = {"ok":false,"status":409,"revision":8,"save":server_save}
	cloud.call("_push_now")
	if not _check(int(save.data.get("cloud_save_revision",0)) == 8,"Conflict revision not advanced"):return
	var rescue: Dictionary = save.data.get("stars",{})
	var water: Dictionary = (save.data.get("game_progress",{}) as Dictionary).get("water_sort",{})
	var block: Dictionary = (save.data.get("game_progress",{}) as Dictionary).get("block_puzzle",{})
	if not _check(int(rescue.get("1",0)) == 3 and int(rescue.get("13",0)) == 2
		and int(rescue.get("16",0)) == 3,"Offline Rescue level clears were destroyed"):return
	if not _check(int((water.get("stars",{}) as Dictionary).get("1",0)) == 3
		and int((water.get("stars",{}) as Dictionary).get("51",0)) == 2
		and int((water.get("stars",{}) as Dictionary).get("53",0)) == 3,
		"Offline Water progress was destroyed on 409"):return
	if not _check(int((block.get("stars",{}) as Dictionary).get("100",0)) == 3,
		"Server backup from an old client erased Block progress"):return
	if not _check(games.total_stars("water_sort") == 8,
		"Restored Water UI score remained stale"):return
	var runs: Dictionary = save.data.get("multi_active_runs",{})
	if not _check(runs.has("water_sort") and runs.has("block_puzzle"),
		"Unrelated unfinished puzzle checkpoint lost"):return
	if not _check("2026-10-05:water_sort" in save.data.get("competition_claimed_periods",[])
		and "2026-09-28:rescue_rush" in save.data.get("competition_claimed_periods",[]),
		"Reconciled device lost a paid-weekly claim marker"):return
	if not _check(int(save.data.get("coins",0)) == 130,
		"Unverified offline wallet totals were added together"):return
	# Fake transport intentionally has no live retry timer. Check the
	# production manager schedules its merged result after the 409 callback.
	var source := FileAccess.get_file_as_string("res://scripts/systems/cloud_save_manager.gd")
	if not _check(source.contains("if combined != remote_value:")
		and source.contains("_pending_push = true"),
		"Merged offline levels are not scheduled for upload"):return

	# Explicit recovery code restore must continue respecting the player's
	# request to replace progress rather than silently merging older stars.
	cloud.call("_apply_remote",{"stars":{"2":1},"highest_level":3},9)
	if not _check(not save.data.get("stars",{}).has("13"),
		"Explicit restore incorrectly merged an unrelated prior campaign"):return
	cloud.free()
	save.data = before
	games.invalidate_cloud_progress_cache()
	save.save()
	print("CLOUD_CONFLICT_MERGE_OK: offline levels survive 409, multiple game checkpoints, no wallet sum")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
