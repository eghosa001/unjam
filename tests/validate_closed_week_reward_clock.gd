extends SceneTree

func _initialize() -> void:
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	# A user can legitimately submit Daily results for adjacent local-UTC
	# calendar dates, but those inputs cannot unlock a WEEKLY payout early.
	for token in [
		"function authoritativeWeekStart(): Date",
		"nowUtc.setUTCHours(0, 0, 0, 0)",
		"return weekStart(nowUtc)",
		"function settlementReferenceWeekStart(): Date",
		"new Date().getUTCDay() === 1 ? 7 * DAY_MS : 0",
		"if (periodDate.getTime() >= settledReferenceWeek.getTime())",
		"previousReward(sb, hash, settlementReferenceWeekStart())",
		"previousProgressReward(sb, playerHash, gameId, settlementReferenceWeekStart())",
		"const currentWeek = authoritativeWeekStart();",
		"isoDay(new Date(settlementReferenceWeekStart().getTime() - 7 * DAY_MS))",
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
	# Monday is a grace period for late Sunday submissions: last week's
	# prizes only become final on Tuesday, not at Monday's midnight.
	var monday_utc := Time.get_unix_time_from_datetime_string("2026-10-19T16:00:00")
	var tuesday_utc := Time.get_unix_time_from_datetime_string("2026-10-20T00:01:00")
	if _settled_week_key(monday_utc) != "2026-10-05":
		push_error("Late Sunday results were not protected during Monday's grace")
		quit(1)
		return
	if _settled_week_key(tuesday_utc) != "2026-10-12":
		push_error("Last week's rewards did not become claimable on Tuesday")
		quit(1)
		return
	print("CLOSED_WEEK_REWARD_CLOCK_OK: no Sunday early claim or Monday grace-day payout")
	quit(0)

func _server_week_key(timestamp: float) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(int(timestamp))
	var monday_offset := posmod(int(dt.get("weekday", 1)) - 1, 7)
	var monday_unix := int(timestamp) - monday_offset * 86400
	return Time.get_date_string_from_unix_time(monday_unix)

func _settled_week_key(timestamp: float) -> String:
	var start_key := _server_week_key(timestamp)
	var server_day := Time.get_datetime_dict_from_unix_time(int(timestamp))
	var base := Time.get_unix_time_from_datetime_string(start_key + "T00:00:00")
	if int(server_day.get("weekday", 0)) == 1:
		base -= 7 * 86400
	return Time.get_date_string_from_unix_time(base - 7 * 86400)
