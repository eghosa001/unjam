extends "res://scripts/game/water_sort_assisted.gd"

const Progression = preload("res://scripts/core/water_sort_progression.gd")
const PremiumGameplayFeedbackLayer = preload("res://scripts/ui/premium_gameplay_feedback.gd")

var premium_feedback: PremiumGameplayFeedback
var _pour_flow_streak := 0
var _pour_feedback_sequence := 0
var _last_rendered_pour_feedback_sequence := 0
var level_profile: Dictionary = {}
var generation_meta: Dictionary = {}
var two_star_moves := 0
var failed := false

func build_ui() -> void:
	super.build_ui()
	premium_feedback = PremiumGameplayFeedbackLayer.new()
	premium_feedback.name = "WaterPremiumFeedback"
	add_child(premium_feedback)

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
	failed = false
	_pour_flow_streak = 0
	_pour_feedback_sequence = 0
	_last_rendered_pour_feedback_sequence = 0
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
		title_label.text = "WATER SORT"
	if meta_label != null:
		meta_label.text = "DAILY CHALLENGE" if daily_mode else "LEVEL %d • WORLD %d" % [
			level_number,
			int(level_profile.get("world", 1))
		]
	render_board()
	_refresh_extra_tube_button()
	call_deferred("_check_no_legal_pours")
	call_deferred("_show_level_intro")

func _show_level_intro() -> void:
	if daily_mode or premium_feedback == null or not is_instance_valid(premium_feedback):
		return
	var milestone := String(level_profile.get("milestone", "normal"))
	if milestone == "normal":
		return
	var label := milestone.replace("_", " ").to_upper()
	if milestone == "world_finale":
		label = "FINALE"
	var accent := Color("#ffd166") if milestone in ["boss", "world_finale", "mastery", "finale"] else Color("#5da9ff")
	# Dense late-game boards use the header treatment only. A center banner over
	# 11+ tubes blocks the first row and makes the premium intro harm gameplay.
	if tubes.size() > 10:
		return
	var view := get_viewport_rect().size
	premium_feedback.show_banner(label, accent, Vector2(view.x * 0.5, view.y * 0.23), 176.0)

func render_board() -> void:
	super.render_board()
	if move_label != null:
		move_label.text = "MOVES %d   •   3★ ≤ %d" % [moves, par_moves]

func _tube_is_solved(values: Array) -> bool:
	if values.size() != CAPACITY:
		return false
	var first := int(values[0])
	for value in values:
		if int(value) != first:
			return false
	return true

func _play_premium_concurrent_pour(source_values: Array, target_values: Array, from_rect: Rect2, to_rect: Rect2, color_index: int, amount: int, source_index: int, target_index: int) -> void:
	# The logical board is already committed before this async visual starts.
	# Advance streak state now, in move order, rather than when variable-length
	# animations finish. This keeps concurrent disjoint pours deterministic.
	var merged_into_matching_color: bool = not target_values.is_empty()
	var solved_after_commit := false
	if target_index >= 0 and target_index < tubes.size():
		solved_after_commit = _tube_is_solved(tubes[target_index] as Array)
	if solved_after_commit:
		_pour_flow_streak = maxi(2, _pour_flow_streak + 1)
	elif merged_into_matching_color:
		_pour_flow_streak += 1
	else:
		_pour_flow_streak = 0
	var streak_for_feedback := _pour_flow_streak
	_pour_feedback_sequence += 1
	var feedback_sequence := _pour_feedback_sequence
	var accent: Color = MotionTube.PALETTE[clampi(color_index, 0, MotionTube.PALETTE.size() - 1)]

	await super._play_premium_concurrent_pour(source_values, target_values, from_rect, to_rect, color_index, amount, source_index, target_index)
	if not is_inside_tree():
		return
	# A shorter later pour may finish before an earlier longer pour. Never let an
	# older completion overwrite newer flow feedback.
	if feedback_sequence < _last_rendered_pour_feedback_sequence:
		return
	_last_rendered_pour_feedback_sequence = feedback_sequence
	if premium_feedback != null and is_instance_valid(premium_feedback):
		var center: Vector2 = _game_local(to_rect.get_center())
		premium_feedback.show_ring(center, maxf(62.0, minf(to_rect.size.x, to_rect.size.y) * 0.72), accent)
		if solved_after_commit:
			premium_feedback.show_banner("PERFECT TUBE", accent, Vector2(center.x, maxf(184.0, center.y - 86.0)), 194.0)
		elif streak_for_feedback >= 2:
			premium_feedback.show_banner("FLOW ×%d" % streak_for_feedback, accent, Vector2(center.x, maxf(184.0, center.y - 74.0)), 176.0)
	if solved_after_commit or streak_for_feedback >= 2:
		FeedbackManager.combo(streak_for_feedback)
	if move_label != null:
		MotionSystem.local_punch(move_label, 0.72)

func generate_tubes_with_solution(seed_value: int, colors: int) -> Dictionary:
	var p := Progression.profile(level_number)
	# The first ten levels are deliberately authored rather than sampled from the
	# procedural pool. Tutorial retention depends on visible novelty and a clean
	# one-step-at-a-time difficulty ramp; these boards have replayable proofs and
	# unique canonical structures.
	if level_number <= 10:
		var curated := _curated_opening_level(level_number)
		if not curated.is_empty():
			var curated_tubes: Array = curated.get("tubes", [])
			var curated_solution: Array = curated.get("solution", [])
			var metrics := Progression.score_board(curated_tubes, curated_solution.size())
			generation_meta = metrics.duplicate(true)
			generation_meta["target_difficulty"] = int(p.get("target_difficulty", 20))
			generation_meta["difficulty_floor"] = int(p.get("difficulty_floor", 0))
			generation_meta["difficulty_ceiling"] = int(p.get("difficulty_ceiling", 100))
			generation_meta["empty_bottles"] = int(p.get("empty_bottles", 2))
			generation_meta["generator_version"] = int(p.get("generator_version", 1))
			generation_meta["milestone"] = String(p.get("milestone", "normal"))
			curated["metadata"] = generation_meta.duplicate(true)
			return curated
	var target_score := int(p.get("target_difficulty", 20))
	var empty_bottles := int(p.get("empty_bottles", 2))
	var base_steps := int(p.get("scramble_steps", 8))
	var candidate_count := 2 if level_number <= 10 else (4 if level_number <= 1000 else 8)
	var best: Dictionary = {}
	var best_error := 100000
	var best_score := -1

	for attempt in range(candidate_count):
		var step_delta := attempt - int(candidate_count / 2)
		var requested_steps := clampi(base_steps + step_delta * 2, 4, int(p.get("three_star_limit", 80)))
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
		# Preserve the profile's exact workspace pressure. Falling back to the
		# legacy generator would silently reintroduce two empty bottles on
		# one-empty endgame levels.
		best = _construct_balanced_fallback(seed_value, colors, empty_bottles, 1009)
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


func _curated_opening_level(level: int) -> Dictionary:
	match level:
		1:
			return {
				"tubes": [[1,1,0,0], [], [2,2,2,2], [], [1,1,0,0]],
				"solution": [Vector2i(0,1), Vector2i(4,1), Vector2i(0,4)]
			}
		2:
			return {
				"tubes": [[], [2,2,2,2], [], [0,1,0,0], [1,1,1,0]],
				"solution": [Vector2i(3,2), Vector2i(4,2), Vector2i(3,4), Vector2i(2,3)]
			}
		3:
			return {
				"tubes": [[3,3,3,0], [2,2,2,3], [], [], [0,0,0,2], [1,1,1,1]],
				"solution": [Vector2i(4,3), Vector2i(0,4), Vector2i(1,2), Vector2i(3,1), Vector2i(2,0)]
			}
		4:
			return {
				"tubes": [[2,1,0,0], [1,1,1,0], [3,3,3,0], [], [], [3,2,2,2]],
				"solution": [Vector2i(0,4), Vector2i(1,4), Vector2i(0,1), Vector2i(5,0), Vector2i(2,4), Vector2i(5,2)]
			}
		5:
			return {
				"tubes": [[], [], [1,1,0,3], [0,2,2,2], [1,1,0,0], [3,3,3,2]],
				"solution": [Vector2i(2,0), Vector2i(3,1), Vector2i(5,1), Vector2i(2,3), Vector2i(5,0), Vector2i(4,3), Vector2i(4,2)]
			}
		6:
			return {
				"tubes": [[3,0,2,2], [2,1,1,3], [], [0,0,0,2], [3,3,1,1], []],
				"solution": [Vector2i(4,2), Vector2i(1,5), Vector2i(1,2), Vector2i(5,4), Vector2i(3,1), Vector2i(0,1), Vector2i(0,3), Vector2i(4,0)]
			}
		7:
			return {
				"tubes": [[1,1,1,3], [], [], [2,3,3,3], [0,0,2,0], [1,2,2,0]],
				"solution": [Vector2i(5,1), Vector2i(4,2), Vector2i(4,5), Vector2i(1,2), Vector2i(4,2), Vector2i(0,1), Vector2i(3,1), Vector2i(5,3), Vector2i(5,0)]
			}
		8:
			return {
				"tubes": [[1,3,3,3], [4,4,4,3], [2,2,2,2], [1,1,0,4], [], [0,0,0,1], []],
				"solution": [Vector2i(0,6), Vector2i(5,4), Vector2i(0,4), Vector2i(1,6), Vector2i(3,0), Vector2i(0,1), Vector2i(3,0), Vector2i(5,0), Vector2i(3,4)]
			}
		9:
			return {
				"tubes": [[1,4,2,2], [1,3,0,0], [0,0,2,4], [], [], [3,3,3,4], [1,1,2,4]],
				"solution": [Vector2i(0,3), Vector2i(2,4), Vector2i(2,3), Vector2i(6,4), Vector2i(1,2), Vector2i(5,4), Vector2i(1,5), Vector2i(6,3), Vector2i(0,4), Vector2i(1,6), Vector2i(6,0)]
			}
		10:
			return {
				"tubes": [[0,0,0,3], [1,2,3,0], [], [1,1,2,3], [4,4,4,2], [4,2,1,3], []],
				"solution": [Vector2i(0,6), Vector2i(1,0), Vector2i(5,6), Vector2i(3,2), Vector2i(1,6), Vector2i(2,6), Vector2i(1,3), Vector2i(3,2), Vector2i(5,1), Vector2i(1,3), Vector2i(4,5), Vector2i(5,2), Vector2i(4,5)]
			}
	return {}

func _construct_progression_candidate(
	seed_value: int,
	colors: int,
	empty_bottles: int,
	requested_steps: int,
	attempt: int
) -> Dictionary:
	var desired_empties := clampi(empty_bottles, 1, 2)
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
	for _empty in range(desired_empties):
		state.append([])
	_shuffle_variant_array(state, rng)

	var inverse_moves: Array[Vector2i] = []
	var best_state: Array = []
	var best_inverse: Array[Vector2i] = []
	var best_distance := 100000
	var seen := {_raw_state_key(state): true}
	var guard := 0
	var max_guard := maxi(600, requested_steps * 180)

	while inverse_moves.size() < requested_steps and guard < max_guard:
		guard += 1
		var current_empties := _count_empty_tubes(state)
		var options: Array[Dictionary] = []
		var preferred: Array[Dictionary] = []

		for donor in range(state.size()):
			var source: Array = state[donor]
			if source.is_empty():
				continue
			var color := int(source.back())
			var run := _top_run_size(source)
			var amounts: Array[int] = []
			# Removing less than the top run leaves the same colour exposed, so
			# the recorded inverse remains a legal forward pour.
			for amount in range(1, run):
				amounts.append(amount)
			# A uniform donor may also be emptied completely; its inverse then
			# pours into an empty bottle, which is also legal.
			if run == source.size():
				amounts.append(run)

			for amount in amounts:
				for target_index in range(state.size()):
					if target_index == donor:
						continue
					var target: Array = state[target_index]
					if target.size() + amount > CAPACITY:
						continue
					if target.is_empty() and amount == source.size():
						# Moving a whole uniform bottle into an empty bottle only
						# renames the workspace and adds no puzzle information.
						continue
					# The added run must be distinct from the old target top so the
					# inverse pour later transfers exactly this recorded chunk.
					if not target.is_empty() and int(target.back()) == color:
						continue
					var empties_delta := 0
					if target.is_empty():
						empties_delta -= 1
					if amount == source.size():
						empties_delta += 1
					var option := {
						"donor": donor,
						"target": target_index,
						"amount": amount,
						"color": color,
						"empty_delta": empties_delta,
						"mixes": not target.is_empty()
					}
					options.append(option)
					if current_empties < desired_empties and empties_delta > 0:
						preferred.append(option)
					elif current_empties > desired_empties and empties_delta < 0:
						preferred.append(option)
					elif current_empties == desired_empties and empties_delta == 0 and not target.is_empty():
						preferred.append(option)

		if options.is_empty():
			break
		var pool: Array[Dictionary] = preferred if not preferred.is_empty() else options
		# Late levels benefit from creating reusable two/three-unit top runs.
		var deep_options: Array[Dictionary] = []
		if level_number >= 1000:
			for option in pool:
				if int(option.get("amount", 1)) >= 2:
					deep_options.append(option)
		if not deep_options.is_empty() and rng.randf() < 0.58:
			pool = deep_options
		var choice: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var donor := int(choice.get("donor", -1))
		var target_index := int(choice.get("target", -1))
		var amount := int(choice.get("amount", 1))
		var color := int(choice.get("color", 0))
		var source: Array = state[donor]
		var target: Array = state[target_index]
		for _unit in range(amount):
			source.pop_back()
			target.append(color)
		state[donor] = source
		state[target_index] = target

		var key := _raw_state_key(state)
		if seen.has(key):
			# Undo a cycle immediately. Long constructive proofs should represent
			# genuinely new states rather than padded back-and-forth moves.
			for _unit in range(amount):
				target.pop_back()
				source.append(color)
			state[donor] = source
			state[target_index] = target
			continue
		seen[key] = true
		inverse_moves.append(Vector2i(target_index, donor))

		if _count_empty_tubes(state) == desired_empties and not _is_solved_state(state):
			var distance := absi(inverse_moves.size() - requested_steps)
			if distance <= best_distance:
				best_distance = distance
				best_state = state.duplicate(true)
				best_inverse = inverse_moves.duplicate()
			if inverse_moves.size() >= requested_steps:
				break

	if best_state.is_empty():
		return _construct_balanced_fallback(seed_value, colors, desired_empties, attempt)

	var solution: Array[Vector2i] = []
	for i in range(best_inverse.size() - 1, -1, -1):
		solution.append(best_inverse[i])
	return {"tubes": best_state, "solution": solution}

func _construct_balanced_fallback(seed_value: int, colors: int, empty_bottles: int, attempt: int) -> Dictionary:
	# Guaranteed exact-empty fallback. Each 3-step reverse cycle scrambles two
	# solved colours and returns the workspace bottle to empty.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 65537 + attempt * 4099 + colors * 257
	var state: Array = []
	for color in range(colors):
		state.append([color, color, color, color])
	for _empty in range(empty_bottles):
		state.append([])
	_shuffle_variant_array(state, rng)
	var color_indices: Array[int] = []
	var empty_index := -1
	for i in range(state.size()):
		if (state[i] as Array).is_empty() and empty_index < 0:
			empty_index = i
		elif (state[i] as Array).size() == CAPACITY:
			color_indices.append(i)
	_shuffle_int_array(color_indices, rng)
	var inverse_moves: Array[Vector2i] = []
	while color_indices.size() >= 2 and empty_index >= 0:
		var a: int = int(color_indices.pop_back())
		var b: int = int(color_indices.pop_back())
		var a_tube: Array = state[a]
		var b_tube: Array = state[b]
		var empty_tube: Array = state[empty_index]
		var color_a := int(a_tube.back())
		var color_b := int(b_tube.back())
		a_tube.pop_back()
		empty_tube.append(color_a)
		inverse_moves.append(Vector2i(empty_index, a))
		b_tube.pop_back()
		a_tube.append(color_b)
		inverse_moves.append(Vector2i(a, b))
		empty_tube.pop_back()
		b_tube.append(color_a)
		inverse_moves.append(Vector2i(b, empty_index))
		state[a] = a_tube
		state[b] = b_tube
		state[empty_index] = empty_tube
	var solution: Array[Vector2i] = []
	for i in range(inverse_moves.size() - 1, -1, -1):
		solution.append(inverse_moves[i])
	return {"tubes": state, "solution": solution}

func _top_run_size(tube: Array) -> int:
	if tube.is_empty():
		return 0
	var color := int(tube.back())
	var run := 0
	for i in range(tube.size() - 1, -1, -1):
		if int(tube[i]) != color:
			break
		run += 1
	return run

func _count_empty_tubes(state: Array) -> int:
	var count := 0
	for tube_value in state:
		if (tube_value as Array).is_empty():
			count += 1
	return count

func _is_solved_state(state: Array) -> bool:
	for tube_value in state:
		var tube: Array = tube_value
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY:
			return false
		var color := int(tube[0])
		for value in tube:
			if int(value) != color:
				return false
	return true

func _raw_state_key(state: Array) -> String:
	var tubes_encoded: PackedStringArray = []
	for tube_value in state:
		var values: PackedStringArray = []
		for value in (tube_value as Array):
			values.append(str(int(value)))
		tubes_encoded.append(",".join(values))
	return "|".join(tubes_encoded)

func _shuffle_int_array(values: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp

func _has_any_legal_pour() -> bool:
	for from_idx in range(tubes.size()):
		for to_idx in range(tubes.size()):
			if from_idx != to_idx and can_pour(from_idx, to_idx):
				return true
	return false

func _refresh_idle_status_after_pours() -> void:
	super._refresh_idle_status_after_pours()
	_check_no_legal_pours()

func _check_no_legal_pours() -> void:
	if failed or completed or pending_completion or _has_active_pours():
		return
	if is_complete() or _has_any_legal_pour():
		return
	_show_no_legal_pours_failure()

func _show_no_legal_pours_failure() -> void:
	if failed or completed:
		return
	failed = true
	selected = -1
	status_label.text = "NO LEGAL POURS"
	FeedbackManager.blocked()
	MultiGameManager.clear_checkpoint(GAME_ID)
	if not daily_mode:
		RetentionManager.record_level_fail()
	AnalyticsManager.track("water_sort_attempt_failed", {"level": level_number, "moves": moves, "daily": daily_mode, "reason": "no_legal_pours"})
	var result := PremiumResultOverlay.new()
	result.configure(
		"WATER SORT FAILED",
		"No valid pour remains.",
		"%d MOVES   •   %d COLOURS\nUNDO OR RETRY EARLIER NEXT TIME" % [moves, color_count],
		0,
		Color("5da9ff"),
		"RETRY",
		"NO POURS"
	)
	result.configure_secondary("BACK HOME" if daily_mode else "BACK TO LEVELS", true)
	add_child(result)
	result.continue_requested.connect(func() -> void:
		if is_instance_valid(result): result.queue_free()
		failed = false
		restart_level()
	)
	result.secondary_requested.connect(func() -> void:
		if daily_mode:
			finished.emit(-1)
		else:
			quit_requested.emit()
		queue_free()
	)

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
