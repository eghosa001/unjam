extends SceneTree

const Catalog = preload("res://scripts/core/rescue_rush_authored_catalog.gd")
const Progression = preload("res://scripts/core/rescue_rush_progression.gd")

const TOTAL := 10000
const OBJECTIVE_REQUIREMENTS := {
	"key_rescue": "gate",
	"gate_run": "gate",
	"chain_rescue": "linked",
	"bomb_route": "bomb",
}
const INTRODUCTIONS := {
	201: "rotate",
	501: "gate",
	1001: "linked",
	2001: "bomb",
}

func _initialize() -> void:
	var failures: Array[String] = []
	var seeds := {}
	var milestone_counts := {}
	var objective_counts := {}
	var chapter_sums: Array[float] = []
	var chapter_counts: Array[int] = []
	var high_run := 0
	var max_high_run := 0
	var previous_difficulty := -1
	var max_delta := 0
	chapter_sums.resize(20)
	chapter_counts.resize(20)

	for n in range(1, TOTAL + 1):
		var raw := Catalog.recipe(n)
		if raw.is_empty():
			failures.append("%d missing authored recipe" % n)
			break
		var p := Progression.profile(n)
		if not bool(p.get("authored", false)):
			failures.append("%d did not use authored profile" % n)
		if int(p.get("level", 0)) != n:
			failures.append("%d authored index mismatch" % n)
		var chapter := int(p.get("chapter", 0))
		if chapter != int((n - 1) / 500) + 1:
			failures.append("%d chapter mismatch" % n)
		var seed := int(p.get("authored_seed", 0))
		if seed <= 0 or seeds.has(seed):
			failures.append("%d duplicate/invalid authored seed" % n)
		seeds[seed] = true
		var objective := String(p.get("objective", ""))
		objective_counts[objective] = int(objective_counts.get(objective, 0)) + 1
		var required := String(OBJECTIVE_REQUIREMENTS.get(objective, ""))
		var mechanics: Array = p.get("mechanics", [])
		if not required.is_empty() and required not in mechanics:
			failures.append("%d objective %s missing %s" % [n, objective, required])
		if n < 201 and not mechanics.is_empty():
			failures.append("%d unlocks mechanics too early" % n)
		for intro_level in INTRODUCTIONS.keys():
			var age := n - int(intro_level)
			if age >= 0 and age <= 2:
				var mechanic := String(INTRODUCTIONS[intro_level])
				if mechanics != [mechanic] or objective != "rescue_route":
					failures.append("%d mechanic introduction is not isolated" % n)
		var milestone := String(p.get("milestone", ""))
		milestone_counts[milestone] = int(milestone_counts.get(milestone, 0)) + 1
		if String(p.get("layout_archetype", "")).is_empty():
			failures.append("%d missing layout archetype" % n)
		var difficulty := int(p.get("difficulty_target", 0))
		if difficulty < 10 or difficulty > 99:
			failures.append("%d difficulty out of range" % n)
		if previous_difficulty >= 0:
			max_delta = maxi(max_delta, absi(difficulty - previous_difficulty))
		previous_difficulty = difficulty
		if difficulty >= 90:
			high_run += 1
			max_high_run = maxi(max_high_run, high_run)
		else:
			high_run = 0
		var cidx := chapter - 1
		chapter_sums[cidx] += difficulty
		chapter_counts[cidx] += 1
		var first_attempt: Vector2 = p.get("first_attempt_target", Vector2.ZERO)
		if first_attempt.x <= 0.0 or first_attempt.y > 1.0 or first_attempt.x >= first_attempt.y:
			failures.append("%d invalid first-attempt target" % n)
		if failures.size() >= 100:
			break

	if int(milestone_counts.get("zone_boss", 0)) != 80:
		failures.append("expected 80 zone bosses")
	if int(milestone_counts.get("chapter_finale", 0)) != 19:
		failures.append("expected 19 chapter finales")
	if int(milestone_counts.get("finale", 0)) != 1:
		failures.append("expected one final boss")
	if max_delta > 20:
		failures.append("adjacent difficulty cliff too large: %d" % max_delta)
	if max_high_run > 4:
		failures.append("too many 90+ difficulty levels in a row: %d" % max_high_run)
	for chapter in range(1, 20):
		var previous_mean := chapter_sums[chapter - 1] / float(maxi(1, chapter_counts[chapter - 1]))
		var current_mean := chapter_sums[chapter] / float(maxi(1, chapter_counts[chapter]))
		if current_mean + 0.01 < previous_mean:
			failures.append("chapter %d average difficulty regressed" % (chapter + 1))
	for objective in ["rescue_route", "full_escape", "key_rescue", "chain_rescue", "perfect_rescue", "bomb_route", "gate_run"]:
		if int(objective_counts.get(objective, 0)) <= 0:
			failures.append("objective family never appears: %s" % objective)

	for n in range(1, TOTAL):
		var p := Progression.profile(n)
		var milestone := String(p.get("milestone", ""))
		if milestone in ["challenge", "elite", "major_challenge", "zone_boss", "chapter_finale"]:
			var next := Progression.profile(n + 1)
			if not INTRODUCTIONS.has(n + 1) and String(next.get("level_role", "")) != "recovery":
				failures.append("level %d has no recovery after milestone" % n)
				break

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("RESCUE_AUTHORED_10000_OK max_delta=%d max_90_run=%d" % [max_delta, max_high_run])
	quit(0)
