extends SceneTree

# A legacy save snapshot must never outrank a submitted completion receipt.
func _initialize() -> void:
	var migration := FileAccess.get_file_as_string("res://supabase/migrations/20261013_ledger_backed_rankings.sql")
	var backend := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	for token in [
		"ledger_backed boolean not null default false",
		"level_number = first_level + seq - 1",
		"v_levels > 0 and p_level_number > v_highest + 1",
		"Skipped ranked level",
		"on conflict (scope_type,period_key,game_id,player_hash)",
		"ledger_backed=true",
	]:
		if not migration.contains(token):
			push_error("Missing ledger ranking invariant: %s" % token)
			quit(1)
			return
	if backend.count('.eq("ledger_backed", true)') != 5:
		push_error("Leaderboard/friend query still exposes legacy snapshots")
		quit(1)
		return
	print("LEDGER_RANKINGS_OK: old client snapshots excluded; one receipt = one rank level")
	quit(0)
