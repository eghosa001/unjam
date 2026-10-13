extends SceneTree

func _initialize() -> void:
	var ui := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	for text in [
		"Weekly prizes finalize Tuesday (UTC), after late results sync.",
		'String(reward.get("period_key", ""))',
		"Claim your %s placement reward for the week starting %s",
		'claim.accessibility_name = claim.tooltip_text',
	]:
		if not ui.contains(text):
			push_error("Weekly prize button or cutoff note is ambiguous: " + text)
			quit(1)
			return
	if ui.contains('"CLAIM LAST WEEK"'):
		push_error("A delayed or older weekly prize is incorrectly called last week")
		quit(1)
		return
	for text in [
		"function settlementReferenceWeekStart(): Date",
		"new Date().getUTCDay() === 1 ? 7 * DAY_MS : 0",
		'"Weekly results are still settling"',
	]:
		if not server.contains(text):
			push_error("UI claims Tuesday UTC settlement but server does not enforce it: " + text)
			quit(1)
			return
	print("WEEKLY_PRIZE_CLARITY_OK: actual week in claim label, Tuesday cutoff matches backend")
	quit(0)
