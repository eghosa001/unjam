extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save = root.get_node("SaveManager")
	var cloud_before: Variant = save.data.get("cloud_save_id", "")
	var campaign_before: Variant = save.data.get("competition_pending_campaign_results", [])
	var daily_before: Variant = save.data.get("competition_pending_daily_results", {})
	save.data["cloud_save_id"] = "a".repeat(64)
	save.data["competition_pending_campaign_results"] = []
	save.data["competition_pending_daily_results"] = {}
	var agent: Node = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(agent)
	await process_frame
	agent.call("submit_campaign_progress", "rescue_rush", 3, 2, true)
	agent.call("submit_daily_result", "water_sort", {"stars": 3, "moves": 9, "par": 11})
	if not _check(int(agent.call("pending_sync_count")) == 2, "Two offline results must survive until acknowledged"):return

	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "0")
	agent.call("_on_retry_timeout")
	var requests: Array = agent.get("pending_requests")
	if not _check(requests.size() == 2, "First online flush should start exactly two independent requests"):return
	for i in range(2):
		(requests[i]["callback"] as Callable).call(false, 503, {})
	var timer := agent.get_node("CompetitionSyncRetry") as Timer
	if not _check(timer != null and not timer.is_stopped(), "Failed upload did not schedule a retry"):return
	if not _check(int(agent.call("pending_sync_count")) == 2, "Server outage erased unacknowledged progress"):return
	timer.stop()
	agent.call("_on_retry_timeout")
	if not _check(requests.size() == 4, "Automatic timer retry did not resubmit both results"):return
	for i in range(2,4):
		(requests[i]["callback"] as Callable).call(true, 200, {"ok": true, "snapshot": {"ok": true, "game_rankings": {}}, "score": 100})
	await process_frame
	if not _check(int(agent.call("pending_sync_count")) == 0, "Acknowledged results were not removed"):return
	if not _check(timer.is_stopped(), "Retry timer continues after the queue drains"):return

	agent.queue_free()
	await process_frame
	save.data["cloud_save_id"] = cloud_before
	save.data["competition_pending_campaign_results"] = campaign_before
	save.data["competition_pending_daily_results"] = daily_before
	save.save()
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	print("COMPETITION_SYNC_RETRY_OK: both queues, timed reconnect, no lost results, no spinning")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok: return true
	push_error(message)
	quit(1)
	return false
