extends SceneTree

func _initialize() -> void:
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261013_weekly_claim_recovery_receipts.sql")
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var client := FileAccess.get_file_as_string("res://scripts/systems/competition_manager.gd")
	var wallet := FileAccess.get_file_as_string("res://scripts/systems/economy_manager.gd")
	for token in ["claim_receipt_hash text", "^[0-9a-f]{64}$", "from public,anon,authenticated"]:
		if not sql.contains(token):
			push_error("Hashed service-only weekly receipt missing: " + token)
			quit(1)
			return
	for token in [
		"sha256Hex(claimReceipt)", "receipt_matches: receiptMatches",
		"claim_receipt_hash: receiptHash", "existing?.claim_receipt_hash === receiptHash",
	]:
		if not edge.contains(token):
			push_error("Server cannot distinguish same-receipt recovery from duplicate: " + token)
			quit(1)
			return
	for token in ["competition_pending_weekly_receipts", "generate_random_bytes(16)", "receipt_matches", "_weekly_claim_in_flight"]:
		if not client.contains(token):
			push_error("Weekly receipt is not safely persisted or retried: " + token)
			quit(1)
			return
	for token in ["credit_weekly_progression_once", "purchase_coin_debt", "competition_claimed_periods", "SaveManager.save()"]:
		if not wallet.contains(token):
			push_error("Atomic local weekly wallet settlement missing: " + token)
			quit(1)
			return
	print("WEEKLY_RECEIPT_CONTRACT_OK: hashed server receipt, durable client retry and one wallet save")
	quit(0)
