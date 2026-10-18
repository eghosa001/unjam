extends SceneTree

# Focused regression checks for player-reported challenge gaps. No catalog-wide
# audit or device simulation is required for these small generator changes.
const Rescue = preload("res://scripts/core/campaign_generator.gd")
const RescueProgression = preload("res://scripts/core/rescue_rush_progression.gd")
const Solver = preload("res://scripts/core/puzzle_solver.gd")
const WaterProgression = preload("res://scripts/core/water_sort_progression.gd")
const WaterCatalog = preload("res://scripts/core/water_sort_curated_catalog.gd")
const Block = preload("res://scripts/core/block_puzzle_progression.gd")
const BlockCatalog = preload("res://scripts/core/block_puzzle_authored_catalog.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := RescueProgression.profile(25)
	var selected := Rescue.generate(25)
	if not bool(selected.get("solver_verified", false)):
		return _fail("Rescue challenge level is not solver verified")
	var chosen_score := int(selected.get("challenge_selection_score", -1000000))
	var seed_value := int(profile.get("authored_seed", 25 * 104729))
	for attempt in range(3):
		var candidate := Rescue._build_candidate(profile, seed_value + attempt * 7919)
		var solution: Array[int] = Solver.find_solution(candidate, [], 6000)
		if solution.is_empty():
			continue
		var score := Rescue._challenge_quality(candidate, profile, solution.size())
		if chosen_score < score:
			return _fail("Rescue selected an easier viable candidate")
	if not bool(Rescue.generate(25).get("solver_verified", false)):
		return _fail("Rescue challenge selection is unstable")

	# First-session milestones must challenge real decision making, not just
	# show a more impressive integer in the difficulty chip.
	for opening_level in [5, 7, 8, 10]:
		var recipe: Dictionary = RescueProgression.profile(opening_level)
		var chosen: Dictionary = Rescue.generate(opening_level)
		if not bool(chosen.get("solver_verified", false)):
			return _fail("Early Rescue challenge %d lost its verified proof" % opening_level)
		if int(chosen.get("generation_attempt", 0)) < 1 or int(chosen.get("generation_attempt", 0)) > 3:
			return _fail("Early Rescue %d did not evaluate verified candidate pool" % opening_level)
		var baseline := -1000000
		var base_seed := int(recipe.get("authored_seed", opening_level * 104729))
		for attempt in range(3):
			var option: Dictionary = Rescue._build_candidate(recipe, base_seed + attempt * 7919)
			var proof: Array[int] = Solver.find_solution(option, [], 6000)
			if not proof.is_empty():
				baseline = maxi(baseline, Rescue._challenge_quality(option, recipe, proof.size()))
		if int(chosen.get("challenge_selection_score", -1000000)) < baseline:
			return _fail("Early Rescue %d failed to select strongest solved candidate" % opening_level)

	var early := WaterCatalog.level(100)
	var weak := WaterCatalog.level(103)
	if early.is_empty() or weak.is_empty():
		return _fail("Expected Water curated checkpoints unavailable")
	if WaterProgression.needs_curated_challenge_remaster(100, early.get("tubes", []), (early.get("solution", []) as Array).size(), WaterProgression.profile(100)):
		return _fail("Water remaster changed deliberate first-100 campaign")
	if not WaterProgression.needs_curated_challenge_remaster(103, weak.get("tubes", []), (weak.get("solution", []) as Array).size(), WaterProgression.profile(103)):
		return _fail("Water failed to detect the trivial post-100 board")

	for early_block in [5, 7, 8, 10, 25, 30]:
		var starting_recipe := BlockCatalog.recipe(early_block)
		var stronger := Block.profile(early_block)
		if int(stronger.get("planning_horizon", 0)) <= int(starting_recipe.get("planning_horizon", 0)):
			return _fail("Early Block level %d has no additional planning demand" % early_block)
		if float(stronger.get("initial_occupancy", 0.0)) <= float(starting_recipe.get("initial_occupancy", 0.0)):
			return _fail("Early Block level %d lacks meaningful occupancy pressure" % early_block)
	for onboarding in [1, 2, 3]:
		var original := BlockCatalog.recipe(onboarding)
		var unchanged := Block.profile(onboarding)
		if int(original.get("planning_horizon", 0)) != int(unchanged.get("planning_horizon", -1)):
			return _fail("Block level %d must preserve true tutorial planning" % onboarding)

	var raw := BlockCatalog.recipe(50)
	var hard := Block.profile(50)
	if int(hard.get("planning_horizon", 0)) <= int(raw.get("planning_horizon", 0)):
		return _fail("Block milestone did not gain actual planning depth")
	if float(hard.get("initial_occupancy", 0.0)) <= float(raw.get("initial_occupancy", 0.0)):
		return _fail("Block milestone did not gain board pressure")
	if int(Block.profile(10000).get("planning_horizon", 0)) != 12:
		return _fail("Block finale authored horizon was unexpectedly modified")
	print("PLAYER_FEEDBACK_CHALLENGE_CONTRACT_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
