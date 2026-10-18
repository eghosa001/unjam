extends SceneTree

# Live candidate diagnostics for the 12-colour, one-empty endgame. Constructive
# proofs are upper bounds, never mathematically certified optimal solutions.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water scene missing")
	var game := packed.instantiate()
	game.set("level_number", 10000)
	root.add_child(game)
	await process_frame
	var profile: Dictionary = game.get("level_profile")
	var candidate_lengths: Array[int] = []
	var candidate_scores: Array[int] = []
	var target_steps := int(profile.get("scramble_steps", 0))
	var target_score := int(profile.get("target_difficulty", 0))
	for attempt in range(8):
		var steps := clampi(target_steps + (attempt - 4) * 2, 4, int(profile.get("three_star_limit", 80)))
		var generated: Dictionary = game.call("_construct_progression_candidate", 10000, 12, 1, steps, attempt)
		var proof: Array = generated.get("solution", [])
		var tubes: Array = generated.get("tubes", [])
		if not tubes.is_empty() and not proof.is_empty():
			candidate_lengths.append(proof.size())
			var metrics: Dictionary = load("res://scripts/core/water_sort_progression.gd").score_board(tubes, proof.size())
			candidate_scores.append(int(metrics.get("difficulty_score", 0)))
	print("WATER_ENDGAME_CANDIDATE_AUDIT lengths=%s scores=%s target_steps=%d target_score=%d selected_proof=%d selected_score=%d" % [
		str(candidate_lengths),str(candidate_scores),target_steps,target_score,
		int((game.get("generation_meta") as Dictionary).get("proof_moves", 0)),
		int((game.get("generation_meta") as Dictionary).get("difficulty_score", 0))
	])
	if candidate_lengths.is_empty():
		game.queue_free()
		return _fail("Endgame constructive generator returned no solvable candidates")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
