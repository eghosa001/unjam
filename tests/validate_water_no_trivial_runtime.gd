extends SceneTree

# Regression of user-reported six-pour levels at 200, 1000 and 2000.
# A constructive solution can contain detours; therefore check both the
# recorded replayable solution AND the mathematically unavoidable minimum.
const Progression = preload("res://scripts/core/water_sort_progression.gd")
const Catalog = preload("res://scripts/core/water_sort_curated_catalog.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var samples: Array[int] = []
	for n in range(4, 11):
		samples.append(n)
	for n in range(101, 111):
		samples.append(n)
	for n in range(190, 215):
		samples.append(n)
	for n in range(240, 256):
		samples.append(n)
	for n in range(495, 506):
		samples.append(n)
	for n in range(995, 1006):
		samples.append(n)
	for n in range(1995, 2007):
		samples.append(n)
	for n in [11,25,50,51,75,99,100,125,150,165,175,200,201,225,300,400,500,501,750,1000,1001,1422,1656,1792,2000,2001,2002,2121,2709,3000,3494,3801,4352,4572,5000,5132,5919,6202,7066,7399,7661,8109,8299,8829,9000,9491,9556,9569,9999,10000]:
		if n not in samples:
			samples.append(n)
	samples.sort()
	if OS.get_environment("WATER_FULL_DEPTH_AUDIT") == "1":
		samples.clear()
		for n in range(4, 10001):
			samples.append(n)
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	if scene == null:
		return _fail("Missing Water Sort runtime scene")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var min_proof_observed := 100000
	var min_lower_observed := 100000
	var weakest: Array = []
	var remasters := 0
	var violations := 0
	for n in samples:
		game.level_number = n
		var profile: Dictionary = Progression.profile(n)
		var board: Dictionary = game.call("generate_tubes_with_solution", n, int(profile.get("colors", 4)))
		var tubes: Array = board.get("tubes", [])
		var solution: Array = board.get("solution", [])
		if tubes.is_empty() or solution.is_empty():
			return _fail("Water level %d has no playable constructed solution" % n)
		var metrics: Dictionary = Progression.score_board(tubes, solution.size())
		var unavoidable := int(metrics.get("unavoidable_pours_lower_bound", -1))
		var required := Progression.minimum_required_pours(n, int(profile.get("empty_bottles",2)))
		var proof_required := Progression.minimum_proof_moves(n, int(profile.get("empty_bottles",2)))
		if solution.size() < proof_required or unavoidable < required:
			violations += 1
			print("WATER_TRIVIAL_RUNTIME level=%d proof=%d expected_proof=%d lower=%d required_lower=%d source=%s" % [
				n, solution.size(), proof_required, unavoidable, required,
				String((board.get("metadata", {}) as Dictionary).get("source", "generated"))])
			var viable := 0
			var best_floor := -1
			var best_proof := -1
			var base_steps := int(profile.get("scramble_steps", 8))
			var empty_bottles := int(profile.get("empty_bottles", 2))
			for attempt in range(32):
				var request := clampi(base_steps + (attempt - 8) * 2, 4, int(profile.get("three_star_limit", 80)))
				var candidate: Dictionary = game.call("_construct_progression_candidate", n, int(profile.get("colors",4)), empty_bottles, request, attempt)
				var candidate_proof: Array = candidate.get("solution", [])
				var cm: Dictionary = Progression.score_board(candidate.get("tubes", []), candidate_proof.size())
				var floor_value := int(cm.get("unavoidable_pours_lower_bound", 0))
				best_floor = maxi(best_floor, floor_value)
				best_proof = maxi(best_proof, candidate_proof.size())
				if floor_value >= required and candidate_proof.size() >= proof_required:
					viable += 1
			print("WATER_REMASTER_DIAGNOSTIC level=%d attempts=32 passing_floor_and_proof=%d max_floor=%d max_proof=%d target_moves=%d scramble=%d empties=%d" % [n,viable,best_floor,best_proof,int(profile.get("target_moves",0)),base_steps,empty_bottles])
		if n >= 200:
			min_proof_observed = mini(min_proof_observed, solution.size())
			min_lower_observed = mini(min_lower_observed, unavoidable)
		if String((board.get("metadata", {}) as Dictionary).get("source", "")) == "verified_challenge_remaster":
			remasters += 1
		if n in [4, 5, 6, 10, 100, 101, 106, 199, 200, 201, 202, 250, 500, 1000, 1001, 1422, 1656, 2000, 2001, 2002, 5000, 10000]:
			print("WATER_DEPTH_SAMPLE level=%d proof=%d lower=%d minimum=%d source=%s" % [
				n,solution.size(),unavoidable,required,
				String((board.get("metadata", {}) as Dictionary).get("source", "generated"))])
		if n % 1000 == 0:
			print("WATER_DEPTH_PROGRESS %d / 10000 violations=%d" % [n, violations])
		if violations > 15:
			break
	print("WATER_NO_TRIVIAL_REPORT samples=%d violations=%d remasters=%d min_proof_200plus=%d min_mathematical_pours_200plus=%d" % [
		samples.size(),violations,remasters,min_proof_observed,min_lower_observed])
	game.queue_free()
	await process_frame
	Catalog.clear_cache()
	if violations > 0:
		return _fail("Found %d player-facing levels below provable minimum difficulty" % violations)
	print("WATER_NO_TRIVIAL_LEVELS_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error("WATER_NO_TRIVIAL_FAILED: " + reason)
	quit(1)
