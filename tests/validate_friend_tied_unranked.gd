extends SceneTree

func _initialize() -> void:
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var ui := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	for piece in [
		'if (!Number.isFinite(score) || score <= 0) return { ...row, rank: 0 };',
		'const sorted = allHashes.map((hash) => {',
		'return rankTies(sorted, "rank_score");',
		'rankTies(weekly, "score")',
	]:
		if not server.contains(piece):
			push_error("Friends rankings still show tied scores as different positions or unranked as #1: " + piece)
			quit(1)
			return
	if server.contains('.map((row, index) => ({ ...row, rank: index + 1 }))'):
		push_error("Positional friends rank remains in server")
		quit(1)
		return
	for piece in [
		'"—" if rank <= 0 else str(rank)',
		'"—" if place <= 0',
		'"Unranked, %s, %d levels, %d stars"',
	]:
		if not ui.contains(piece):
			push_error("Compact ranking still marks no-score friends first: " + piece)
			quit(1)
			return
	print("FRIENDS_TIED_UNRANKED_OK: shared places, zero-score unranked and accessible rows")
	quit(0)
