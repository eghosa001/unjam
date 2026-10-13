extends SceneTree

func _initialize() -> void:
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var modal := FileAccess.get_file_as_string("res://scripts/ui/leaderboard_modal.gd")
	var panel := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	for check in [
		'function rankTies<T extends Record<string, any>>',
		'if (index === 0 || score !== previousScore) place = index + 1',
		'rankTies(rows ?? [], "score")',
		'rankTies(rows ?? [], "rank_score")',
		'rankTies(weekly, "score")',
	]:
		if not server.contains(check):
			push_error("Rank consistency server contract missing: " + check)
			quit(1)
			return
	if not modal.contains('row.get("rank", i + 1)'):
		push_error("Full-screen leaderboard loses shared tied places")
		quit(1)
		return
	if not panel.contains('row.get("rank",i+1)'):
		push_error("Compact leaderboard loses shared tied places")
		quit(1)
		return
	print("TIED_RANKING_CONTRACT_OK: Daily, campaign and friends share equal-place display")
	quit(0)
