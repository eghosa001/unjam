extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_all_10000_profiles():
		return
	if not _validate_retention_curve():
		return
	if not _validate_world_diversity():
		return
	if not _validate_constructive_samples():
		return
	print("BLOCK_HANDCRAFTED_10000_OK")
	quit(0)

func _validate_all_10000_profiles() -> bool:
	var seeds := {}
	for level in range(1, 10001):
		var p := Progression.profile(level)
		if int(p.get("level_id", -1)) != level:
			return _fail("Curated profile id mismatch at %d" % level)
		if not bool(p.get("curated_source", false)):
			return _fail("Level %d fell back to procedural progression" % level)
		if int(p.get("curation_version", 0)) < 1:
			return _fail("Level %d has no curation version" % level)
		if String(p.get("shape_bias", "")).is_empty():
			return _fail("Level %d has no handcrafted shape bias" % level)
		var seed := int(p.get("seed", -1))
		if seeds.has(seed):
			return _fail("Duplicate curated seed at %d" % level)
		seeds[seed] = true
		var first_attempt: Vector2 = p.get("first_attempt_target", Vector2.ZERO)
		if first_attempt.x <= 0.0 or first_attempt.y > 1.0 or first_attempt.x >= first_attempt.y:
			return _fail("Invalid first-attempt target at %d" % level)
		if bool(p.get("booster_required", true)):
			return _fail("Level %d requires a booster" % level)
	return true

func _validate_retention_curve() -> bool:
	var hard_streak := 0
	var max_hard_streak := 0
	for level in range(1, 10001):
		var p := Progression.profile(level)
		var role := String(p.get("retention_role", ""))
		var milestone := String(p.get("milestone", "normal"))
		var score := int(p.get("difficulty_score", 0))
		if role in ["challenge", "stretch", "peak"]:
			hard_streak += 1
		else:
			hard_streak = 0
		max_hard_streak = maxi(max_hard_streak, hard_streak)
		if role in ["recovery", "confidence", "learn", "practice"] and milestone not in ["boss", "world_finale", "mastery", "finale"]:
			if bool(p.get("move_limited", false)):
				return _fail("Recovery/learning level %d is move-limited" % level)
		if level > 1:
			var previous := Progression.profile(level - 1)
			var jump := absi(score - int(previous.get("difficulty_score", 0)))
			var previous_milestone := String(previous.get("milestone", "normal"))
			if jump > 13:
				return _fail("Difficulty cliff at %d -> %d is %d points" % [level - 1, level, jump])
			if milestone in ["boss", "world_finale", "mastery", "finale"] and score < int(previous.get("difficulty_score", 0)):
				return _fail("Boss %d is easier than its lead-in" % level)
			if previous_milestone in ["boss", "world_finale", "mastery"] and role not in ["recovery", "confidence", "learn", "practice"]:
				return _fail("Boss %d has no immediate recovery level" % (level - 1))
	if max_hard_streak > 2:
		return _fail("Hard-role streak exceeded two consecutive levels")
	return true

func _validate_world_diversity() -> bool:
	for world in range(1, 21):
		var objectives := {}
		var biases := {}
		var start := (world - 1) * 500 + 1
		var finish := world * 500
		for level in range(start, finish + 1):
			var p := Progression.profile(level)
			objectives[String(p.get("objective", ""))] = true
			biases[String(p.get("shape_bias", ""))] = true
		var min_objectives := 3 if world <= 5 else 5
		if objectives.size() < min_objectives:
			return _fail("World %d has only %d objective families" % [world, objectives.size()])
		if biases.size() < 5:
			return _fail("World %d has only %d shape-bias families" % [world, biases.size()])
	var finale := Progression.profile(10000)
	if int(finale.get("difficulty_score", 0)) != 98:
		return _fail("Finale difficulty is not pinned to 98")
	if int(finale.get("planning_horizon", 0)) != 12:
		return _fail("Finale planning horizon is not 12")
	if not bool(finale.get("move_limited", false)):
		return _fail("Finale is not move-limited")
	return true

func _validate_constructive_samples() -> bool:
	var samples: Array[int] = []
	for level in range(250, 10001, 250):
		samples.append(level)
	for level in [1, 5, 10, 11, 25, 50, 100, 500, 1000, 2500, 4000, 6000, 7000, 8000, 9000, 9500, 10000]:
		if level not in samples:
			samples.append(level)
	for level in samples:
		var p := Progression.profile(level)
		var plan := Generator.generate(p)
		if plan.is_empty():
			return _fail("Curated level %d could not construct a solvable plan" % level)
		var replay := Generator.replay_proof(plan, int(p.get("target_lines", 1)), int(p.get("target_score", 1)))
		if not bool(replay.get("solved", false)):
			return _fail("Curated level %d failed constructive proof replay" % level)
		if String((plan.get("metadata", {}) as Dictionary).get("shape_bias", "")) != String(p.get("shape_bias", "")):
			return _fail("Curated level %d lost its shape-bias metadata" % level)
	for level in [100, 2500, 5000, 7500, 9500, 10000]:
		var p := Progression.profile(level)
		var a := Generator.generate(p)
		var b := Generator.generate(p)
		if (a.get("proof_shapes", []) as Array) != (b.get("proof_shapes", []) as Array):
			return _fail("Curated level %d is not deterministic" % level)
		if (a.get("proof_origins", []) as Array) != (b.get("proof_origins", []) as Array):
			return _fail("Curated level %d origin proof is not deterministic" % level)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
