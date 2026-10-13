extends SceneTree

# Contract for the server transaction; no broad offline puzzle suites needed.
func _initialize() -> void:
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261013_atomic_daily_competition_result.sql")
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	for token in [
		"unjam_record_daily_result(",
		"pg_advisory_xact_lock",
		"greatest(public.competition_entries.score, excluded.score)",
		"p_week <> p_day - (extract(isodow from p_day)::integer - 1)",
		"on conflict (period_type,period_key,player_hash)",
		"where player_hash=p_player_hash and competition_day=p_day",
		"where player_hash=p_player_hash and week_start=p_week",
		"revoke all on function public.unjam_record_daily_result",
		"to service_role",
	]:
		if not sql.contains(token):
			push_error("Daily atomic score invariant missing: %s" % token)
			quit(1)
			return
	if not edge.contains('sb.rpc("unjam_record_daily_result"'):
		push_error("Daily endpoint bypasses its transactional score guard")
		quit(1)
		return
	if edge.contains("await refreshTotals("):
		push_error("Daily endpoint still runs stale non-atomic tally writes")
		quit(1)
		return
	print("DAILY_ATOMIC_RANKINGS_OK: monotonic best score, atomic day/week totals, service-only RPC")
	quit(0)
