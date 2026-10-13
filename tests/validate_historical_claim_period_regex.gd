extends SceneTree

func _initialize() -> void:
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var slash := "\\"
	var correct := "!/^" + slash + "d{4}-" + slash + "d{2}-" + slash + "d{2}$/.test(requestedPeriod)"
	var broken := "!/^" + slash + slash + "d{4}-" + slash + slash + "d{2}-" + slash + slash + "d{2}$/.test(requestedPeriod)"
	if not edge.contains(correct):
		push_error("Weekly receipt recovery rejects every valid YYYY-MM-DD period")
		quit(1)
		return
	if edge.contains(broken):
		push_error("Literal double-backslash regex matches the text \\d, not a date")
		quit(1)
		return
	for required in [
		"claim_receipt_hash === receiptHash",
		"ageWeeks < 1 || ageWeeks > 52",
		"periodDate.getUTCDay() !== 1",
		"if (ageWeeks > 8)",
	]:
		if not edge.contains(required):
			push_error("Historical weekly award recovery guard missing: " + required)
			quit(1)
			return
	print("HISTORICAL_CLAIM_PERIOD_OK: YYYY-MM-DD is accepted; dates are bounded to Mondays and safe receipt replay")
	quit(0)
