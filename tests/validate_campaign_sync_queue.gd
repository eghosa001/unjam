extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save = root.get_node("SaveManager")
	var original_id = save.data.get("cloud_save_id", "")
	var original = save.data.get("competition_pending_campaign_results", [])
	save.data["cloud_save_id"] = "a".repeat(64)
	save.data["competition_pending_campaign_results"] = []
	var agent: Node = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(agent)
	await process_frame

	agent.call("submit_campaign_progress", "rescue_rush", 31, 2, true)
	agent.call("submit_campaign_progress", "rescue_rush", 31, 3, true)
	agent.call("submit_campaign_progress", "water_sort", 8, 2, true)
	var queue: Array = save.data.get("competition_pending_campaign_results", [])
	if not _assert(queue.size() == 2 and int(queue[0]["stars"]) == 3, "Offline first-clears not de-duplicated and preserved"):return

	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "0")
	agent.call("_flush_pending_campaign_results")
	var reqs: Array = agent.get("pending_requests")
	if not _assert(reqs.size() == 1, "Campaign submissions must be serialized"):return
	agent.call("_flush_pending_campaign_results")
	if not _assert(reqs.size() == 1, "Duplicate HTTP requests started"):return
	if not _assert(not (reqs[0]["payload"] as Dictionary).has("progress"), "Untrusted client progress snapshot still submitted"):return

	(reqs[0]["callback"] as Callable).call(false, 503, {})
	if not _assert((save.data["competition_pending_campaign_results"] as Array).size() == 2, "Network failure lost a completion"):return
	agent.call("_flush_pending_campaign_results")
	if not _assert(reqs.size() == 2, "Reconnect did not retry queued campaign progress"):return
	(reqs[1]["callback"] as Callable).call(true, 200, {"ok": true, "snapshot": {"ok": true, "game_rankings": {}}})
	await process_frame
	if not _assert(reqs.size() == 3, "Successful completion did not advance FIFO queue"):return
	if not _assert((save.data["competition_pending_campaign_results"] as Array).size() == 1, "Acknowledged completion not removed"):return
	(reqs[2]["callback"] as Callable).call(true, 200, {"ok": true, "snapshot": {"ok": true, "game_rankings": {}}})
	await process_frame
	if not _assert((save.data["competition_pending_campaign_results"] as Array).is_empty(), "Successful replay did not drain queue"):return

	var backend := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	if not _assert(backend.contains("if (!allowNew) return false"), "Historical levels can be reinserted into weekly rankings"):return
	if not _assert(backend.contains("const verifiedCount = Math.min(10000, previous.levels_completed + 1)"), "Server can accept arbitrary client-side rank jumps"):return
	if not _assert(not backend.contains("await upsertAllTimeProgress(sb, playerHash, displayName, gameId, raw[gameId])"), "Read-only leaderboard still mutates scores"):return

	agent.queue_free()
	await process_frame
	save.data["cloud_save_id"] = original_id
	save.data["competition_pending_campaign_results"] = original
	save.save()
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	print("CAMPAIGN_SYNC_QUEUE_OK: offline persistence, serialized retry, verified server increments")
	quit(0)

func _assert(ok: bool, why: String) -> bool:
	if ok: return true
	push_error(why)
	quit(1)
	return false
