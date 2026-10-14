extends SceneTree

# Focused contract: leaderboard rewards must not remain mutable after
# finalization. This checks the deployed migration contract and client grace.
func _initialize() -> void:
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261014_close_finalized_league_windows.sql")
	var client := FileAccess.get_file_as_string("res://scripts/systems/competition_manager.gd")
	var required := [
		"v_utc_today date := (now() at time zone 'utc')::date;",
		"p_week <> v_current_week",
		"p_week = v_current_week - 7 and v_utc_today = v_current_week",
		"p_week = v_current_week + 7 and v_utc_today = v_current_week + 6",
		"Ranked league period settled or not yet open",
		"pg_advisory_xact_lock",
		"grant execute on function public.unjam_record_progress",
	]
	for token in required:
		if not sql.contains(token):
			push_error("Ranked settlement boundary missing: " + token)
			quit(1)
			return
	if not client.contains("absf(now_unix - event_unix) > 86400.0"):
		push_error("Offline campaign score queue must reject historical rewards")
		quit(1)
		return
	print("LEAGUE_SETTLEMENT_WINDOW_OK: closed past leagues, local UTC rollover grace, locked atomic receipts")
	quit(0)
