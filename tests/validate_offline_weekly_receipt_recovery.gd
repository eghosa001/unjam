extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save = root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	# Use an actual Monday two weeks before this test's current week.
	# A hardcoded 2026 date would make the release test fail next year.
	var current_unix := int(Time.get_unix_time_from_datetime_string("%sT12:00:00" % root.get_node("DailyChallenge").date_key()))
	var weekday := int(Time.get_datetime_dict_from_unix_time(current_unix).get("weekday", 1))
	var past_monday_unix := current_unix - (posmod(weekday - 1, 7) + 14) * 86400
	var period := Time.get_date_string_from_unix_time(past_monday_unix)
	var ticket := "cd".repeat(16)
	var key := "%s:block_puzzle" % period
	save.data["cloud_save_id"] = "b".repeat(64)
	save.data["coins"] = 50
	save.data["purchase_coin_debt"] = 0
	save.data["competition_claimed_periods"] = []
	save.data["competition_pending_weekly_receipts"] = {key: ticket}
	var fake = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(fake)
	await process_frame
	fake.snapshot = {"game_rankings":{
		"block_puzzle":{"previous_week_reward":{"eligible":true,"claimed":false,"period_key":Time.get_date_string_from_unix_time(past_monday_unix + 7 * 86400)}}
	}}
	fake.call("_retry_pending_weekly_claims")
	await process_frame
	await process_frame
	var requests: Array = fake.get("pending_requests")
	if not _check(requests.size() == 1, "Old pending weekly claim was not retried"):return
	var payload: Dictionary = requests[0].get("payload", {})
	if not _check(String(payload.get("claim_period_key","")) == period
		and String(payload.get("claim_receipt","")) == ticket,
		"Historical claim used current period or discarded its original receipt"):return
	fake.claim_weekly_reward("water_sort", period)
	if not _check((fake.get("pending_requests") as Array).size() == 1,
		"Client invented a claim for a game with no persisted receipt"):return
	fake.call("_retry_pending_weekly_claims")
	await process_frame
	if not _check((fake.get("pending_requests") as Array).size() == 1,
		"Repeated reconnect overlapped pending historical reward claims"):return
	var callback: Callable = requests[0].get("callback")
	callback.call(true,200,{
		"ok":true,"already_claimed":true,"receipt_matches":true,
		"period_key":period,"game_id":"block_puzzle","rank":7,
		"coins":200,"crowns":3,
	})
	if not _check(int(save.data.get("coins",0)) == 250
		and key in save.data.get("competition_claimed_periods", []),
		"Offline payout could not be recovered from an older league period"):return
	fake.call("_retry_pending_weekly_claims")
	await process_frame
	if not _check((fake.get("pending_requests") as Array).size() == 1
		and int(save.data.get("coins",0)) == 250,
		"Recovered old reward was claimed or credited twice"):return
	fake.queue_free()
	await process_frame
	save.data = original
	save.save()
	print("OFFLINE_WEEKLY_RECEIPT_OK: historical claim survived week rollover without double payout")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
