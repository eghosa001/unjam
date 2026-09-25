extends SceneTree

const Catalog = preload("res://scripts/core/block_puzzle_authored_catalog.gd")
const Progression = preload("res://scripts/core/block_puzzle_progression.gd")

const TOTAL := 10000
const INTRODUCTIONS := {
	11: "clear_lines",
	26: "clear_columns",
	41: "row_column",
	76: "double_clear",
	101: "combo",
	151: "limited_moves",
	251: "marked_cells",
	401: "designated_rows",
	601: "crates",
	1001: "ice",
	1401: "locks",
	1751: "steel",
	2101: "layered_obstacle",
	2401: "preserve_cells",
	2501: "dual_objective",
	4001: "triple_objective",
	6001: "conditional_chain",
	7001: "constraint_combo",
	8001: "pressure_mastery",
	9001: "grandmaster_conditional",
}

func _initialize() -> void:
	var failures: Array[String] = []
	var seeds := {}
	var milestone_counts := {}
	var chapter_sums: Array[float] = []
	var chapter_counts: Array[int] = []
	var world_objectives: Array[Dictionary] = []
	var world_biases: Array[Dictionary] = []
	chapter_sums.resize(20)
	chapter_counts.resize(20)
	world_objectives.resize(20)
	world_biases.resize(20)
	for i in range(20):
		world_objectives[i] = {}
		world_biases[i] = {}

	var previous_difficulty := -1
	var previous_milestone := "normal"
	var hard_run := 0
	var max_hard_run := 0
	var max_delta := 0

	for n in range(1, TOTAL + 1):
		var raw := Catalog.recipe(n)
		if raw.is_empty():
			failures.append("%d missing authored Block recipe" % n)
			break
		if int(raw.get("level", 0)) != n:
			failures.append("%d authored index mismatch" % n)
		if String(raw.get("design_intent", "")).is_empty():
			failures.append("%d has no design intent" % n)

		var p := Progression.profile(n)
		if not bool(p.get("authored", false)):
			failures.append("%d did not use the authored catalog" % n)
		if int(p.get("level_id", 0)) != n:
			failures.append("%d runtime profile mismatch" % n)
		if int(p.get("authored_chapter", 0)) != int((n - 1) / 500) + 1:
			failures.append("%d authored chapter mismatch" % n)

		var seed := int(p.get("seed", 0))
		if seed <= 0 or seeds.has(seed):
			failures.append("%d duplicate/invalid authored seed" % n)
		seeds[seed] = true

		var difficulty := int(p.get("difficulty_score", 0))
		if difficulty < int(p.get("difficulty_floor", 0)) or difficulty > int(p.get("difficulty_ceiling", 100)):
			failures.append("%d authored difficulty escaped its band" % n)
		if previous_difficulty >= 0:
			var delta := absi(difficulty - previous_difficulty)
			max_delta = maxi(max_delta, delta)
			if delta > 13:
				failures.append("%d adjacent difficulty cliff is %d" % [n, delta])
		if String(p.get("milestone", "normal")) in ["boss", "world_finale", "mastery", "finale"] and previous_difficulty >= 0 and difficulty < previous_difficulty:
			failures.append("%d boss is easier than its lead-in" % n)

		var role := String(p.get("retention_role", ""))
		if role in ["challenge", "stretch", "peak"]:
			hard_run += 1
			max_hard_run = maxi(max_hard_run, hard_run)
		else:
			hard_run = 0
		if role in ["recovery", "confidence", "learn", "practice"] and String(p.get("milestone", "normal")) not in ["boss", "world_finale", "mastery", "finale"]:
			if bool(p.get("move_limited", false)):
				failures.append("%d recovery/learning level is move-limited" % n)
		if previous_milestone in ["boss", "world_finale", "mastery"] and role not in ["recovery", "confidence", "learn", "practice"]:
			failures.append("%d is not a recovery beat after a major milestone" % n)

		var milestone := String(p.get("milestone", "normal"))
		milestone_counts[milestone] = int(milestone_counts.get(milestone, 0)) + 1
		previous_milestone = milestone
		previous_difficulty = difficulty

		var chapter := int((n - 1) / 500)
		chapter_sums[chapter] += difficulty
		chapter_counts[chapter] += 1
		world_objectives[chapter][String(p.get("objective", ""))] = true
		world_biases[chapter][String(p.get("shape_bias", ""))] = true

		var first_attempt: Vector2 = p.get("first_attempt_target", Vector2.ZERO)
		if first_attempt.x <= 0.0 or first_attempt.y > 1.0 or first_attempt.x >= first_attempt.y:
			failures.append("%d invalid first-attempt target" % n)

		if INTRODUCTIONS.has(n):
			var expected := String(INTRODUCTIONS[n])
			for offset in range(3):
				var intro_profile := Progression.profile(n + offset)
				if String(intro_profile.get("objective", "")) != expected:
					failures.append("%d introduction window changed objective from %s" % [n + offset, expected])
				var expected_role := "learn" if offset == 0 else "practice"
				if String(intro_profile.get("retention_role", "")) != expected_role:
					failures.append("%d introduction window role should be %s" % [n + offset, expected_role])

		if failures.size() >= 100:
			break

	if int(milestone_counts.get("challenge", 0)) != 800:
		failures.append("expected 800 challenge levels")
	if int(milestone_counts.get("hard_challenge", 0)) != 200:
		failures.append("expected 200 hard challenge levels")
	if int(milestone_counts.get("mini_boss", 0)) != 100:
		failures.append("expected 100 mini-boss levels")
	if int(milestone_counts.get("boss", 0)) != 80:
		failures.append("expected 80 boss levels")
	if int(milestone_counts.get("world_finale", 0)) != 10:
		failures.append("expected 10 world finales")
	if int(milestone_counts.get("mastery", 0)) != 9:
		failures.append("expected 9 mastery bosses")
	if int(milestone_counts.get("finale", 0)) != 1:
		failures.append("expected one final boss")
	if max_hard_run > 2:
		failures.append("too many hard roles in a row: %d" % max_hard_run)
	if max_delta > 13:
		failures.append("adjacent difficulty cliff too large: %d" % max_delta)

	for chapter in range(1, 20):
		var previous_mean := chapter_sums[chapter - 1] / float(maxi(1, chapter_counts[chapter - 1]))
		var current_mean := chapter_sums[chapter] / float(maxi(1, chapter_counts[chapter]))
		if current_mean + 0.01 < previous_mean:
			failures.append("authored chapter %d average difficulty regressed" % (chapter + 1))

	for world in range(20):
		var min_objectives := 3 if world < 5 else 5
		if world_objectives[world].size() < min_objectives:
			failures.append("World %d has only %d objective families" % [world + 1, world_objectives[world].size()])
		if world_biases[world].size() < 5:
			failures.append("World %d has only %d shape-bias families" % [world + 1, world_biases[world].size()])

	var finale := Progression.profile(10000)
	if int(finale.get("difficulty_score", 0)) != 98:
		failures.append("finale difficulty must be exactly 98")
	if int(finale.get("planning_horizon", 0)) != 12:
		failures.append("finale planning horizon must be 12")
	if int(finale.get("piece_tier", 0)) != 6:
		failures.append("finale must use the full piece library")
	if not bool(finale.get("move_limited", false)):
		failures.append("finale must be move-limited")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("BLOCK_AUTHORED_10000_OK max_delta=%d max_hard_run=%d" % [max_delta, max_hard_run])
	quit(0)
