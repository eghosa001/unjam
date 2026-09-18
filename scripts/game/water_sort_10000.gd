extends "res://scripts/game/water_sort_assisted.gd"

const Progression = preload("res://scripts/core/water_sort_progression.gd")

var level_profile: Dictionary = {}
var generation_meta: Dictionary = {}
var two_star_moves := 0

func difficulty() -> String:
	return String(_profile().get("difficulty_label", "normal-hard"))

func campaign_tier() -> int:
	return clampi(int(_profile().get("world", 1)) - 1, 0, Progression.WORLD_COUNT - 1)

func level_config() -> Dictionary:
	var p := _profile()
	return {
		"colors": int(p.get("colors", 4)),
		"par": int(p.get("three_star_limit", 20)),
		"tier": campaign_tier(),
		"world": int(p.get("world", 1)),
		"empty_bottles": int(p.get("empty_bottles", 2)),
		"target_difficulty": int(p.get("target_difficulty", 20))
	}

func load_level() -> void:
	level_profile = Progression.profile(level_number)
	generation_meta = {}
	two_star_moves = 0
	super.load_level()

	var proof_moves := int(generation_meta.get("proof_moves", 0))
	var requested_three_star := int(level_profile.get("three_star_limit", par_moves))
	if proof_moves > 0:
		# The constructive path is a verified upper bound, not a claim of true
		# optimality. Keep the 3-star target close to that proof rather than
		# pretending a level-10,000 target number is already solver-optimal.
		var proof_margin := maxi(2, ceili(float(proof_moves) * 0.08))
		par_moves = mini(requested_three_star, proof_moves + proof_margin)
		par_moves = maxi(par_moves, proof_moves)
	else:
		par_moves = requested_three_star
	two_star_moves = maxi(
		par_moves + 4,
		mini(
			int(level_profile.get("two_star_limit", par_moves + 6)),
			par_moves + maxi(5, ceili(float(par_moves) * 0.15))
		)
	)

	if title_label != null:
		title_label.text = "DAILY SORT" if daily_mode else "WATER SORT · %d" % level_number
	if meta_label != null:
		var measured := int(generation_meta.get("difficulty_score", -1))
		var measured_text := " • SCORE %d" % measured if measured >= 0 else ""
		meta_label.text = "%s • WORLD %d/20%s" % [
			difficulty().to_upper(),
			int(level_profile.get("world", 1)),
			measured_text
		]
	render_board()
	_refresh_extra_tube_button()

func render_board() -> void:
	super.render_board()
	if move_label != null:
		move_label.text = "MOVES %d   •   3★ ≤ %d   •   %d COLORS" % [moves, par_moves, color_count]

func generate_tubes_with_solution(seed_value: int, colors: int) -> Dictionary:
	var p := Progression.profile(level_number)
	var target_score := int(p.get("target_difficulty", 20))
	var empty_bottles := int(p.get("empty_bottles", 2))
	var base_steps := int(p.get("scramble_steps", 8))
	var candidate_count := 2 if level_number <= 10 else (3 if level_number <= 1000 else 5)
	var best: Dictionary = {}
	var best_error := 100000
	var best_score := -1

	for attempt in range(candidate_count):
		var step_delta := attempt - int(candidate_count / 2)
		var requested_steps := clampi(base_steps + step_delta * 2, 4, colors * CAPACITY)
		var candidate := _construct_progression_candidate(
			seed_value,
			colors,
			empty_bottles,
			requested_steps,
			attempt
		)
		var candidate_tubes: Array = candidate.get("tubes", [])
		var candidate_solution: Array = candidate.get("solution", [])
		if candidate_tubes.is_empty() or candidate_solution.is_empty():
			continue
		var metrics := Progression.score_board(candidate_tubes, candidate_solution.size())
		var score := int(metrics.get("difficulty_score", 0))
		var error := absi(score - target_score)
		# Prefer the closer board. On a tie, prefer the more demanding board so
		# late-game candidate pools do not quietly drift toward filler levels.
		if best.is_empty() or error < best_error or (error == best_error and score > best_score):
			best_error = error
			best_score = score
			best = candidate.duplicate(true)
			best["metadata"] = metrics.duplicate(true)

	if best.is_empty():
		# Defensive fallback: the parent constructive generator remains a valid
		# proof-producing path if a future profile accidentally over-constrains
		# candidate construction.
		best = super.generate_tubes_with_solution(seed_value, colors)
		var fallback_tubes: Array = best.get("tubes", [])
		var fallback_solution: Array = best.get("solution", [])
		best["metadata"] = Progression.score_board(fallback_tubes, fallback_solution.size())

	generation_meta = (best.get("metadata", {}) as Dictionary).duplicate(true)
	generation_meta["target_difficulty"] = target_score
	generation_meta["difficulty_floor"] = int(p.get("difficulty_floor", 0))
	generation_meta["difficulty_ceiling"] = int(p.get("difficulty_ceiling", 100))
	generation_meta["empty_bottles"] = empty_bottles
	generation_meta["generator_version"] = int(p.get("generator_version", 1))
	generation_meta["milestone"] = String(p.get("milestone", "normal"))
	return best

func _construct_progression_candidate(
	seed_value: int,
	colors: int,
	empty_bottles: int,
	requested_steps: int,
	attempt: int
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		seed_value * 104729 +
		colors * 1543 +
		int(_profile().get("generator_version", 1)) * 8191 +
		attempt * 99991
	)

	var state: Array = []
	for color in range(colors):
		var tube: Array = []
		for _slot in range(CAPACITY):
			tube.append(color)
		state.append(tube)
	for _empty in range(clampi(empty_bottles, 1, 2)):
		state.append([])
	_shuffle_variant_array(state, rng)

	var inverse_moves: Array[Vector2i] = []
	var successful := 0
	var guard := 0
	var max_guard := maxi(300, requested_steps * 120)
	while successful < requested_steps and guard < max_guard:
		guard += 1
		var donors: Array[int] = []
		for i in range(state.size()):
			if _is_monochrome_nonempty(state[i] as Array):
				donors.append(i)
		if donors.is_empty():
			break

		var donor := donors[rng.randi_range(0, donors.size() - 1)]
		var source: Array = state[donor]
		var donor_color := int(source.back())
		var targets: Array[int] = []
		var preferred: Array[int] = []
		for j in range(state.size()):
			if j == donor:
				continue
			var target: Array = state[j]
			if target.size() >= CAPACITY:
				continue
			# Keep the newly transferred run distinct. This is what makes its
			# recorded inverse a legal forward Water Sort move during replay.
			if not target.is_empty() and int(target.back()) == donor_color:
				continue
			targets.append(j)
			if not target.is_empty():
				preferred.append(j)

		if targets.is_empty():
			continue
		var use_preferred := not preferred.is_empty() and (
			level_number > 10 or rng.randf() < 0.72
		)
		var pool: Array[int] = preferred if use_preferred else targets
		var target_index := pool[rng.randi_range(0, pool.size() - 1)]
		var target_tube: Array = state[target_index]
		var max_amount := mini(source.size(), CAPACITY - target_tube.size())
		if max_amount <= 0:
			continue

		# Single-unit reverse moves create more colour boundaries and choices.
		# Early tutorial boards occasionally move two units to stay readable.
		var amount := 1
		if level_number <= 10 and max_amount > 1 and rng.randf() < 0.38:
			amount = 2
		for _unit in range(amount):
			source.pop_back()
			target_tube.append(donor_color)
		state[donor] = source
		state[target_index] = target_tube
		# One normal forward pour will move the whole contiguous run back.
		inverse_moves.append(Vector2i(target_index, donor))
		successful += 1

	var solution: Array[Vector2i] = []
	for i in range(inverse_moves.size() - 1, -1, -1):
		solution.append(inverse_moves[i])

	return {
		"tubes": state,
		"solution": solution
	}

func complete_level() -> void:
	if completed:
		return
	completed = true
	animating = true
	MultiGameManager.clear_checkpoint(GAME_ID)
	var stars := 3 if moves <= par_moves else (2 if moves <= two_star_moves else 1)
	if daily_mode:
		MultiGameManager.complete_daily(GAME_ID, 100 + stars * 25)
	else:
		MultiGameManager.complete_level(GAME_ID, level_number, stars, 25 + color_count * 2)
	status_label.text = "SORT COMPLETE"
	PremiumVisuals.burst(Vector2(540, 880), Color("5da9ff"), 28)
	AnalyticsManager.track("water_sort_completed", {
		"level": level_number,
		"moves": moves,
		"stars": stars,
		"daily": daily_mode,
		"difficulty": difficulty(),
		"difficulty_score": int(generation_meta.get("difficulty_score", -1)),
		"world_500": int(level_profile.get("world", 1)),
		"generator_version": int(level_profile.get("generator_version", 1))
	})
	await get_tree().create_timer(0.28).timeout
	var result := PremiumResultOverlay.new()
	result.configure(
		"WATER SORT COMPLETE",
		"Every colour is cleanly separated.",
		"%d MOVES   •   3★ ≤ %d   •   2★ ≤ %d\n%d COLOURS SORTED" % [
			moves, par_moves, two_star_moves, color_count
		],
		stars,
		Color("5da9ff"),
		"BACK HOME" if daily_mode else "NEXT PUZZLE"
	)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		finished.emit(-1 if daily_mode else level_number)
		queue_free()
	)

func _profile() -> Dictionary:
	if level_profile.is_empty() or int(level_profile.get("level_id", -1)) != level_number:
		level_profile = Progression.profile(level_number)
	return level_profile
