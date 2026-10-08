extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	var save = root.get_node("SaveManager")
	var original_id: String = String(save.data.get("cloud_save_id",""))
	var original_pending = save.data.get("competition_pending_daily_results",{})
	save.data["cloud_save_id"] = "a".repeat(64)
	save.data["competition_pending_daily_results"] = {}

	var agent: Node = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(agent)
	await process_frame

	var rescue = {"stars":3,"moves":5,"par":7}
	agent.call("submit_daily_result","rescue_rush",rescue)
	var pending: Dictionary = save.data.get("competition_pending_daily_results",{})
	if not _check(pending.size() == 1,"Daily score not saved before HTTP"):return
	var key := "%s:rescue_rush" % DailyChallenge.date_key()
	if not _check(pending.has(key),"Daily submission key is not stable"):return
	agent.call("submit_daily_result","rescue_rush",{"stars":2,"moves":8,"par":7})
	pending = save.data.get("competition_pending_daily_results",{})
	if not _check(pending.size() == 1,"Repeated game completion duplicated the queued Daily entry"):return
	agent.call("submit_daily_result","water_sort",{"stars":3,"moves":9,"par":10})
	pending = save.data.get("competition_pending_daily_results",{})
	if not _check(pending.size() == 2,"Independent Daily games did not queue separately"):return

	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","0")
	agent.call("_flush_pending_daily_results")
	if not _check((agent.get("pending_requests") as Array).size() == 2,"Reconnect did not retry both queued games"):return
	agent.call("_flush_pending_daily_results")
	if not _check((agent.get("pending_requests") as Array).size() == 2,"Duplicate concurrent network submissions are possible"):return

	var first: Dictionary = (agent.get("pending_requests") as Array)[0]
	var first_payload: Dictionary = first["payload"]
	if not _check(first_payload.has("competition_day") and first_payload.has("metrics"),"Persisted Daily payload lost game stats or date"):return
	(first["callback"] as Callable).call(false,503,{})
	if not _check((save.data.get("competition_pending_daily_results",{}) as Dictionary).size() == 2,"Network failure dropped earned Daily scores"):return
	agent.call("_flush_pending_daily_results")
	if not _check((agent.get("pending_requests") as Array).size() == 3,"Offline result did not retry after a failure"):return

	var second: Dictionary = (agent.get("pending_requests") as Array)[1]
	var second_payload: Dictionary = second["payload"]
	(second["callback"] as Callable).call(true,200,{"ok":true,"score":980,"snapshot":{"ok":true,"day":DailyChallenge.date_key(),"daily_top":[]}})
	var retry: Dictionary = (agent.get("pending_requests") as Array)[2]
	(retry["callback"] as Callable).call(true,200,{"ok":true,"score":960,"snapshot":{"ok":true,"day":DailyChallenge.date_key(),"daily_top":[]}})
	if not _check((save.data.get("competition_pending_daily_results",{}) as Dictionary).is_empty(),"Successful server acknowledgements did not drain the queue"):return
	if not _check((agent.get("daily_snapshot") as Dictionary).has("day"),"Leaderboard state did not refresh when offline results synced"):return

	agent.queue_free()
	await process_frame
	save.data["cloud_save_id"] = original_id
	save.data["competition_pending_daily_results"] = original_pending
	save.save()
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	print("DAILY_SUBMISSION_RELIABILITY_OK: durable results, retry and no concurrent duplicates")
	quit(0)

func _check(ok: bool, error_text: String) -> bool:
	if ok:
		return true
	push_error(error_text)
	quit(1)
	return false
