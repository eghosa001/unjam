extends SceneTree

# Focused regression checks for player-reported challenge gaps. No catalog-wide
# audit or device simulation is required for these small generator changes.
const Rescue = preload("res://scripts/core/campaign_generator.gd")
const RescueProgression = preload("res://scripts/core/rescue_rush_progression.gd")
const Solver = preload("res://scripts/core/puzzle_solver.gd")
const Water = preload("res://scripts/game/water_sort_10000.gd")
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

	var early := WaterCatalog.level(100)
	var weak := WaterCatalog.level(103)
	if early.is_empty() or weak.is_empty():
		return _fail("Expected Water curated checkpoints unavailable")
	if Water._needs_curated_challenge_remaster(100, early.get("tubes", []), (early.get("solution", []) as Array).size(), WaterProgression.profile(100)):
		return _fail("Water remaster changed deliberate first-100 campaign")
	if not Water._needs_curated_challenge_remaster(103, weak.get("tubes", []), (weak.get("solution", []) as Array).size(), WaterProgression.profile(103)):
		return _fail("Water failed to detect the trivial post-100 board")

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
