extends "res://scripts/systems/daily_challenge.gd"

func build_today() -> Dictionary:
	return _build_for_key(date_key())

func _build_for_key(key: String) -> Dictionary:
	# Daily competition must offer the same puzzle to every player, not one
	# scaled to the player's highest level. Older in-progress days keep the
	# previous personal daily selection to avoid swapping a live puzzle.
	if key >= DAILY_EXPANSION_START:
		var scheduled: Dictionary = super._build_for_key(key)
		if bool(scheduled.get("solver_verified", false)):
			return scheduled
		# Rare generator fallback: keep the Daily playable rather than
		# publishing an unsolved board. The choice remains deterministic.
		var safe := CampaignGenerator.generate(51)
		safe["id"] = -1
		safe["daily"] = true
		safe["daily_key"] = key
		safe["daily_source_level"] = 51
		return safe
	var seed_value := int(key.replace("-", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var progress_level := clampi(int(SaveManager.data.get("highest_level", 1)), 1, 10000)
	var center_level := clampi(maxi(20, progress_level + 12), 20, 10000)
	var chosen: Dictionary = {}
	var source_level := center_level
	for attempt in range(24):
		var spread := mini(60, 12 + attempt * 2)
		var candidate := clampi(center_level + rng.randi_range(-spread, spread), 11, 10000)
		var generated := CampaignGenerator.generate(candidate)
		if PuzzleSolver.has_solution(generated, 6000):
			chosen = generated
			source_level = candidate
			break
	if chosen.is_empty():
		source_level = 11
		chosen = CampaignGenerator.generate(source_level)
	var solution: Array[int] = PuzzleSolver.find_solution(chosen, [], 6000)
	var fair_par := int(chosen.get("par_moves", 8))
	if not solution.is_empty():
		fair_par = maxi(fair_par, solution.size() + 1)
	chosen["id"] = -1
	chosen["daily"] = true
	chosen["daily_key"] = key
	chosen["daily_source_level"] = source_level
	chosen["par_moves"] = fair_par
	var rescues: Array[String] = ["chick", "puppy", "kitten", "robot", "panda", "fox", "alien"]
	chosen["rescue_id"] = rescues[rng.randi_range(0, rescues.size() - 1)]
	return chosen
