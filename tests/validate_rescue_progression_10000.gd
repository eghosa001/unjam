extends SceneTree

const Progression = preload("res://scripts/core/rescue_rush_progression.gd")
const Generator = preload("res://scripts/core/campaign_generator.gd")
const Solver = preload("res://scripts/core/puzzle_solver.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var samples: Array[int] = [1, 20, 25, 50, 75, 100, 500, 501, 1000, 1001, 2000, 2001, 5000, 5001, 7500, 9000, 9500, 10000]
	var signatures := {}
	for n in samples:
		var profile: Dictionary = Progression.profile(n)
		var level: Dictionary = Generator.generate(n)
		if int(level.get("world", 0)) != int((n - 1) / 100) + 1:
			failures.append("%d world mapping" % n)
		if int(level.get("width", 0)) not in [7, 8]:
			failures.append("%d board size" % n)
		if n <= 1000 and int(level.get("width", 0)) != 7:
			failures.append("%d should remain 7x7" % n)
		if n > 2000 and int(level.get("width", 0)) != 8:
			failures.append("%d should be 8x8" % n)
		if int(level.get("difficulty_score", -1)) != int(profile.get("difficulty_target", -2)):
			failures.append("%d target score mismatch" % n)
		if not bool(level.get("solver_verified", false)) or not Solver.has_solution(level, 6000):
			failures.append("%d solver verification" % n)
		var sig := String(level.get("structural_signature", ""))
		if sig.is_empty() or signatures.has(sig):
			failures.append("%d structural duplicate in milestone sample" % n)
		signatures[sig] = true
	if String(Generator.generate(25).get("milestone", "")) != "challenge":
		failures.append("25 challenge role")
	if String(Generator.generate(50).get("milestone", "")) != "mini_boss":
		failures.append("50 mini-boss role")
	if String(Generator.generate(75).get("milestone", "")) != "major_challenge":
		failures.append("75 major challenge role")
	var final_level := Generator.generate(10000)
	if String(final_level.get("milestone", "")) != "world_finale":
		failures.append("10000 finale role")
	if int(final_level.get("difficulty_score", 0)) < 98:
		failures.append("10000 difficulty below 98")
	if int(final_level.get("actual_piece_count", 0)) < 42:
		failures.append("10000 object density below grandmaster target")
	if int(Generator.generate(20).get("mistake_limit", -1)) != 0:
		failures.append("tutorial blocked-tap safety")
	if int(Generator.generate(501).get("mistake_limit", 0)) < 4:
		failures.append("gate introduction should have extra mistake forgiveness")
	if int(Generator.generate(504).get("mistake_limit", 0)) != 3:
		failures.append("post-introduction three-mistake rule")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("RESCUE_PROGRESSION_10000_OK")
	quit(0)
