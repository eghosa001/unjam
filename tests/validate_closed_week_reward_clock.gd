extends SceneTree

func _initialize() -> void:
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	# A user can legitimately submit Daily results for adjacent local-UTC
	# calendar dates, but those inputs cannot unlock a WEEKLY payout early.
	for token in [
		"function authoritativeWeekStart(): Date",
		"nowUtc.setUTCHours(0, 0, 0, 0)",
		"return weekStart(nowUtc)",
		"previousReward(sb, hash, authoritativeWeekStart())",
		"previousProgressReward(sb, playerHash, gameId, authoritativeWeekStart())",
		"const currentWeek = authoritativeWeekStart();",
		"isoDay(new Date(authoritativeWeekStart().getTime() - 7 * DAY_MS))",
	]:
		if not server.contains(token):
			push_error("Reward period is not settled by the server UTC clock: " + token)
			quit(1)
			return
	for unsafe in [
		"const currentWeek = weekStart(day);",
		"previousReward(sb, hash, weekStart(day))",
		"previousProgressReward(sb, playerHash, gameId, weekStart(day))",
		"isoDay(new Date(weekStart(day).getTime() - 7 * DAY_MS))",
	]:
		if server.contains(unsafe):
			push_error("User-supplied future competition_day can end a week early: " + unsafe)
			quit(1)
			return

	# Regression scenario: Sunday UTC and a forged local Monday.
	# Both must settle the previous *completed* UTC week (the one ending
	# before this Sunday), not the still-active week ending tomorrow.
	var utc_sunday := Time.get_unix_time_from_datetime_string("2026-10-18T23:30:00")
	var request_monday := "2026-10-19"
	var server_week := _server_week_key(utc_sunday)
	var forged_week := _server_week_key(Time.get_unix_time_from_datetime_string(request_monday + "T00:00:00"))
	if server_week == forged_week:
		push_error("Sunday-to-Monday simulated boundary fixture is invalid")
		quit(1)
		return
	if server_week != "2026-10-12" or forged_week != "2026-10-19":
		push_error("Incorrect UTC week calculation for claim safety")
		quit(1)
		return
	print("CLOSED_WEEK_REWARD_CLOCK_OK: future Daily dates cannot unlock unfinished weekly rewards")
	quit(0)

func _server_week_key(timestamp: float) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(int(timestamp))
	var monday_offset := posmod(int(dt.get("weekday", 1)) - 1, 7)
	var monday_unix := int(timestamp) - monday_offset * 86400
	return Time.get_date_string_from_unix_time(monday_unix)
