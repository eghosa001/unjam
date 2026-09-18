extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const Solver = preload("res://scripts/core/block_puzzle_exact_solver.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var high_board: Array = []
	for y in range(8):
		var row: Array = []
		for x in range(8):
			row.append(x == 7 and y == 7)
		high_board.append(row)
	var mask := Solver.board_to_mask(high_board)
	if (mask & (1 << 63)) == 0:
		return _fail("64-bit Block Puzzle board mask lost cell 63")

	for level in [1, 10, 100, 1000, 5000, 9500, 10000]:
		var profile := _profile(level)
		var plan := Generator.generate(profile)
		if plan.is_empty():
			return _fail("Solver fixture generation failed at level %d" % level)
		var replay := Solver.validate_known_solution(profile, plan)
		if not bool(replay.get("solved", false)):
			return _fail("Exact-state proof replay failed at level %d: %s" % [level, str(replay)])
		var solve := Solver.find_solution(profile, plan, 50000)
		if not bool(solve.get("solved", false)):
			return _fail("64-bit solver could not find a solution at level %d" % level)

	var opening_profile := _profile(1)
	var opening_plan := Generator.generate(opening_profile)
	var optimal := Solver.find_optimal(opening_profile, opening_plan, 250000)
	if not bool(optimal.get("solved", false)):
		return _fail("Optimal solver could not solve Level 1")
	if not bool(optimal.get("optimal_verified", false)):
		return _fail("Level 1 optimal move count was not proven within the test budget")

	print("BLOCK_EXACT_SOLVER_OK")
	quit(0)

func _profile(level: int) -> Dictionary:
	var p := Progression.profile(level)
	if level <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		p["target_score"] = scores[level - 1]
		p["target_lines"] = lines[level - 1]
	return p

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
