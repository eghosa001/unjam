extends SceneTree

# Structural lower bound: every valid pour reduces the number of colour runs
# by at most one; the solved board contains exactly one run per colour.
# A constructive solution is only an upper bound. Tests must never confuse them.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression = load("res://scripts/core/water_sort_progression.gd") as Script
	var sorted: Array = [[0, 0, 0, 0], [1, 1, 1, 1], [], []]
	var interleaved: Array = [[0, 1, 0, 1], [1, 0, 1, 0], [], []]
	var semi_sorted: Array = [[0, 0, 1, 1], [1, 1, 0, 0], [], []]
	var sorted_metrics: Dictionary = progression.score_board(sorted, 16)
	var interleaved_metrics: Dictionary = progression.score_board(interleaved, 16)
	var semi_metrics: Dictionary = progression.score_board(semi_sorted, 16)
	if int(sorted_metrics.get("unavoidable_pours_lower_bound", -1)) != 0:
		return _fail("Solved bottles cannot require further pours")
	if int(semi_metrics.get("unavoidable_pours_lower_bound", -1)) != 2:
		return _fail("Two mixed color barriers must require at least two pours")
	if int(interleaved_metrics.get("unavoidable_pours_lower_bound", -1)) != 6:
		return _fail("Alternating color runs require six necessary pours")
	if int(interleaved_metrics.get("difficulty_score", 0)) <= int(sorted_metrics.get("difficulty_score", 0)):
		return _fail("Real mixed color work does not outweigh sorted bottles")
	if int(interleaved_metrics.get("proof_slack", -1)) != 10:
		return _fail("Proof upper-bound slack was misrepresented")

	var catalog = load("res://scripts/core/water_sort_curated_catalog.gd") as Script
	for level in [1, 7, 10, 25, 50, 100, 101, 103, 106, 107, 150, 250, 500, 1000, 5000, 9556, 9569, 9999, 10000]:
		var entry: Dictionary = catalog.level(level)
		if entry.is_empty():
			return _fail("Missing authored water puzzle %d" % level)
		var tubes: Array = entry.get("tubes", [])
		var proof: Array = entry.get("solution", [])
		var metrics: Dictionary = progression.score_board(tubes, proof.size())
		var minimum := int(metrics.get("unavoidable_pours_lower_bound", -1))
		if minimum < 0 or minimum > proof.size():
			return _fail("Water level %d violates proven lower / upper solution bounds: %d > %d" % [level, minimum, proof.size()])
		print("WATER_POUR_BOUNDS level=%d lower=%d upper=%d score=%d" % [level, minimum, proof.size(), int(metrics.get("difficulty_score", 0))])
	print("WATER_STRUCTURAL_DIFFICULTY_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
