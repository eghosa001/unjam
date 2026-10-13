extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save = root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	var token := "ab".repeat(16)
	var period := "2026-10-05"
	var key := "%s:rescue_rush" % period
	save.data["cloud_save_id"] = "c".repeat(64)
	save.data["coins"] = 17
	save.data["crown_tokens"] = 3
	save.data["purchase_coin_debt"] = 0
	save.data["competition_claimed_periods"] = []
	save.data["competition_pending_weekly_receipts"] = {key: token}
	save.save()
	var agent = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(agent)
	await process_frame
	agent.snapshot = {"game_rankings": {
		"rescue_rush":{"previous_week_reward":{"eligible":true,"claimed":true,"period_key":period}},
		"block_puzzle":{"previous_week_reward":{"eligible":true,"claimed":true,"period_key":period}},
	}}
	agent.call("_retry_pending_weekly_claims")
	await process_frame
	await process_frame
	var requests: Array = agent.get("pending_requests")
	if not _check(requests.size() == 1, "Resume must only replay the persisted unacknowledged claim"):return
	var payload: Dictionary = requests[0].get("payload", {})
	if not _check(String(payload.get("claim_receipt","")) == token
		and String(payload.get("game_id", "")) == "rescue_rush",
		"Resume lost the original ticket or retried an unrelated game"):return
	# A second rankings refresh while the recovery is in flight must never
	# create two simultaneous claims against the wallet.
	agent.call("_retry_pending_weekly_claims")
	await process_frame
	if not _check((agent.get("pending_requests") as Array).size() == 1, "Repeated refresh sent an overlapping claim"):return
	var callback: Callable = requests[0].get("callback")
	callback.call(true, 200, {
		"ok":true,"already_claimed":true,"receipt_matches":true,
		"period_key":period,"game_id":"rescue_rush","rank":9,
		"coins":150,"crowns":4
	})
	if not _check(int(save.data.get("coins", 0)) == 167
		and key in save.data.get("competition_claimed_periods", []),
		"Already-committed server reward was not recovered on resume"):return
	agent.call("_retry_pending_weekly_claims")
	await process_frame
	if not _check((agent.get("pending_requests") as Array).size() == 1
		and int(save.data.get("coins", 0)) == 167,
		"Recovered wallet credited a second time on refresh"):return
	agent.queue_free()
	await process_frame
	save.data = original
	save.save()
	print("WEEKLY_RESUME_RECOVERY_OK: auto retry preserves receipt and never double-credits")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
