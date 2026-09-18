extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const Auditor = preload("res://scripts/core/block_puzzle_campaign_auditor.gd")
const Solver = preload("res://scripts/core/block_puzzle_exact_solver.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not LevelPack.has_production_pack():
		return _fail("Production Block Puzzle pack is missing")

	var manifest := LevelPack.manifest()
	if int(manifest.get("level_count", 0)) != Progression.MAX_LEVEL:
		return _fail("Manifest does not contain 10,000 levels")

	var signatures := {}
	var calibrated := 0
	var tolerance_failures := 0
	var bot_sample_count := 0
	for level in range(1, Progression.MAX_LEVEL + 1):
		var profile := _generation_profile(level)
		var plan := LevelPack.plan_for_level(level, profile)
		if plan.is_empty():
			return _fail("Packed Block Puzzle level %d is missing" % level)
		var proof := Generator.replay_proof(
			plan,
			int(profile.get("target_lines", 1)),
			int(profile.get("target_score", 1))
		)
		if not bool(proof.get("solved", false)):
			return _fail("Packed Block Puzzle level %d failed its proof replay" % level)
		var exact := Solver.find_solution(profile, plan, 50000)
		if not bool(exact.get("solved", false)):
			return _fail("Packed Block Puzzle level %d failed exact-state solver validation" % level)
		var signature := Auditor.canonical_signature(profile, plan)
		if signatures.has(signature):
			return _fail("Packed duplicate: level %d matches level %d" % [level, int(signatures[signature])])
		signatures[signature] = level

		if _should_bot_audit(level):
			var report := Auditor.audit_plan(profile, plan)
			if not bool(report.get("valid", false)):
				return _fail("Bot audit invalid at level %d" % level)
			bot_sample_count += 1
			calibrated += int(report.get("calibrated_difficulty", 0))
			if not bool(report.get("within_tolerance", false)):
				tolerance_failures += 1

		if level % 1000 == 0:
			print("BLOCK_RELEASE_AUDIT %d/%d" % [level, Progression.MAX_LEVEL])

	var allowed_tolerance_failures := maxi(4, int(ceil(float(bot_sample_count) * 0.16)))
	if tolerance_failures > allowed_tolerance_failures:
		return _fail("Difficulty calibration drifted on %d/%d bot samples" % [tolerance_failures, bot_sample_count])

	var average_calibrated := float(calibrated) / float(maxi(1, bot_sample_count))
	print("BLOCK_RELEASE_AUDIT_OK: 10000 proof replays, 10000 unique signatures, %d multi-bot samples, avg %.1f difficulty." % [
		bot_sample_count,
		average_calibrated
	])
	quit(0)

func _should_bot_audit(level: int) -> bool:
	if level <= 10:
		return true
	if level % 25 == 0:
		return true
	if level in [501, 1001, 2501, 5001, 7501, 9001, 9501, 9999, 10000]:
		return true
	return false

func _generation_profile(level: int) -> Dictionary:
	var profile := Progression.profile(level)
	if level <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		var i := level - 1
		profile["target_score"] = scores[i]
		profile["target_lines"] = lines[i]
	return profile

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
