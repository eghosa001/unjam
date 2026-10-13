extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save = root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	var period := "2026-10-05"
	var claim_key := "%s:rescue_rush" % period
	save.data["cloud_save_id"] = "a".repeat(64)
	save.data["coins"] = 100
	save.data["crown_tokens"] = 10
	save.data["purchase_coin_debt"] = 15
	save.data["competition_claimed_periods"] = []
	save.data["competition_pending_weekly_receipts"] = {}
	var fake = load("res://tests/fake_daily_competition_transport.gd").new()
	root.add_child(fake)
	await process_frame
	fake.snapshot = {"game_rankings": {
		"rescue_rush":{"previous_week_reward":{"eligible":true,"claimed":false,"period_key":period}},
		"water_sort":{"previous_week_reward":{"eligible":true,"claimed":false,"period_key":period}}
	}}

	fake.claim_weekly_reward("rescue_rush")
	var requests: Array = fake.get("pending_requests")
	if not _check(requests.size() == 1, "First weekly receipt request missing"):return
	var first: Dictionary = requests[0]
	var receipt := String((first.get("payload", {}) as Dictionary).get("claim_receipt", ""))
	if not _check(receipt.length() == 32 and String((save.data.get("competition_pending_weekly_receipts", {}) as Dictionary).get(claim_key, "")) == receipt,
		"Weekly claim receipt not durably persisted before HTTP"):return
	fake.claim_weekly_reward("rescue_rush")
	if not _check((fake.get("pending_requests") as Array).size() == 1, "Two concurrent claims submitted for same week"):return
	(first.get("callback") as Callable).call(false, 503, {})
	if not _check((save.data.get("competition_pending_weekly_receipts", {}) as Dictionary).has(claim_key),
		"Lost server acknowledgement discarded the only recovery receipt"):return

	fake.claim_weekly_reward("rescue_rush")
	requests = fake.get("pending_requests")
	if not _check(requests.size() == 2, "Weekly claim is not retriable"):return
	var retry: Dictionary = requests[1]
	if not _check(String((retry.get("payload", {}) as Dictionary).get("claim_receipt", "")) == receipt,
		"Retried claim created a new receipt and lost its recovery right"):return
	(retry.get("callback") as Callable).call(true, 200, {
		"ok":true,"already_claimed":true,"receipt_matches":true,
		"period_key":period,"game_id":"rescue_rush","coins":250,"crowns":7,"rank":2
	})
	var expected_crowns := root.get_node("EconomyManager").competition_crown_reward(7)
	if not _check(int(save.data.get("coins", 0)) == 335, "Recovery failed to settle refund debt and credit earned coins"):return
	if not _check(int(save.data.get("purchase_coin_debt", 0)) == 0, "Coin purchase refund debt was ignored"):return
	if not _check(int(save.data.get("crown_tokens", 0)) == 10 + expected_crowns, "Collection crown reward was not credited"):return
	if not _check(claim_key in save.data.get("competition_claimed_periods", []) and
		not (save.data.get("competition_pending_weekly_receipts", {}) as Dictionary).has(claim_key),
		"One-save receipt/claim settlement missing"):return
	if not _check(not fake.can_claim_weekly_reward("rescue_rush"), "Paid reward is offered again"):return
	var result: Dictionary = root.get_node("EconomyManager").credit_weekly_progression_once(period,"rescue_rush",2,250,7)
	if not _check(not bool(result.get("credited", false)) and int(save.data.get("coins", 0)) == 335,
		"Replayed valid claim duplicated wallet credit"):return

	# A different device/claim ticket must NOT turn an existing claimed row
	# into a new payout, even if this installation has never seen that claim.
	fake.claim_weekly_reward("water_sort")
	requests = fake.get("pending_requests")
	if not _check(requests.size() >= 3, "Another game did not acquire its own receipt"):return
	var other: Dictionary = requests[2]
	(other.get("callback") as Callable).call(true, 200, {
		"ok":true,"already_claimed":true,"receipt_matches":false,
		"period_key":period,"game_id":"water_sort","coins":350,"crowns":10,"rank":1
	})
	if not _check(int(save.data.get("coins", 0)) == 335, "Mismatched receipt created a duplicated claim"):return

	fake.queue_free()
	await process_frame
	save.data = original
	save.save()
	print("WEEKLY_REWARD_RECOVERY_OK: lost ack reconciliation, duplicate/foreign receipt rejection and single-save wallet")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:return true
	push_error(reason)
	quit(1)
	return false
