extends SceneTree

# Focused source contract for service-only idempotent Daily write throttling.
func _initialize() -> void:
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261014_limit_ranked_daily_updates.sql")
	var old := FileAccess.get_file_as_string("res://supabase/migrations/20261013_atomic_daily_competition_result.sql")
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var checks := [
		["enable row level security", "Daily submission limit table must be RLS guarded"],
		["revoke all on table public.competition_daily_write_limits from public,anon,authenticated", "Public clients may not access write quota"],
		["grant select,insert,update on table public.competition_daily_write_limits to service_role", "Only backend service may update write quota"],
		["pg_advisory_xact_lock", "Player submissions must be serialized"],
		["p_score <= v_existing_score", "Retry and lower-quality results must bypass rate budget"],
		["'idempotent',true", "Safe replay needs success without recrediting"],
		["accepted_updates < 30", "Daily submission burst limit must be enforced"],
		["'status',429", "Real rate breaches must return a distinguishable temporary rejection"],
		["where player_hash=p_player_hash and competition_day=p_day", "Daily write must still be player/day scoped"],
		["where player_hash=p_player_hash and week_start=p_week", "Rate limit must retain weekly recomputation"],
		["on conflict (period_type,period_key,player_hash)", "Rate limit must preserve transactionally recomputed totals"],
		["revoke all on function public.unjam_record_daily_result", "Daily score RPC must still be service-only"],
	]
	for check in checks:
		if not sql.contains(String(check[0])):
			push_error("Daily scoring anti-abuse regression: " + String(check[1]))
			quit(1)
			return
	if not old.contains("greatest(public.competition_entries.score, excluded.score)") or not sql.contains("greatest(public.competition_entries.score, excluded.score)"):
		push_error("New migration weakened best-score monotonicity")
		quit(1)
		return
	if not edge.contains('sb.rpc("unjam_record_daily_result"') or not edge.contains("[400, 409, 429]"):
		push_error("Daily endpoint no longer propagates rate limiting and atomic result status")
		quit(1)
		return
	print("DAILY_SUBMISSION_RATE_GUARD_OK")
	quit(0)
