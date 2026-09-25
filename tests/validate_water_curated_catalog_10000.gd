# Validation trigger for PR-specific Water catalog CI.
extends SceneTree

const MAX_LEVEL := 10000
const CAPACITY := 4
const Catalog = preload("res://scripts/core/water_sort_curated_catalog.gd")
const Progression = preload("res://scripts/core/water_sort_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Catalog.clear_cache()
	var signatures := {}
	var scores: Array[int] = []
	var max_proof := 0
	for level in range(1, MAX_LEVEL + 1):
		var authored: Dictionary = Catalog.level(level)
		if authored.is_empty():
			return _fail("Curated Water level %d is missing" % level)
		if int(authored.get("authored_level", -1)) != level:
			return _fail("Curated Water level id mismatch at %d" % level)
		var profile: Dictionary = Progression.profile(level)
		var tubes: Array = (authored.get("tubes", []) as Array).duplicate(true)
		var solution: Array = authored.get("solution", [])
		var colors := int(profile.get("colors", 0))
		var expected_empties := int(profile.get("empty_bottles", 0))
		if tubes.size() != colors + expected_empties:
			return _fail("Curated Water level %d tube count mismatch" % level)
		var actual_empties := 0
		var counts := {}
		for raw_tube in tubes:
			var tube: Array = raw_tube
			if tube.is_empty():
				actual_empties += 1
			for raw_color in tube:
				var color := int(raw_color)
				counts[color] = int(counts.get(color, 0)) + 1
		if actual_empties != expected_empties:
			return _fail("Curated Water level %d empty-tube mismatch" % level)
		if counts.size() != colors:
			return _fail("Curated Water level %d color-count mismatch" % level)
		for amount in counts.values():
			if int(amount) != CAPACITY:
				return _fail("Curated Water level %d does not contain four units per color" % level)
		if solution.is_empty():
			return _fail("Curated Water level %d has no proof" % level)
		if solution.size() > int(profile.get("three_star_limit", 0)):
			return _fail("Curated Water level %d proof exceeds 3-star target" % level)
		max_proof = maxi(max_proof, solution.size())
		for move_value in solution:
			var move: Vector2i = move_value
			if not _can_pour(tubes, move.x, move.y):
				return _fail("Curated Water level %d proof contains illegal pour" % level)
			_pour(tubes, move.x, move.y)
		if not _solved(tubes):
			return _fail("Curated Water level %d proof does not solve board" % level)
		var original: Array = authored.get("tubes", [])
		var signature := Progression.canonical_signature(original)
		if signatures.has(signature):
			return _fail("Curated Water duplicate: level %d matches %d" % [level, int(signatures[signature])])
		signatures[signature] = level
		var metrics := Progression.score_board(original, solution.size())
		scores.append(int(metrics.get("difficulty_score", 0)))
		if level > 1:
			var previous_milestone := Progression.milestone_kind(level - 1)
			var current_milestone := Progression.milestone_kind(level)
			if previous_milestone == "normal" and current_milestone == "normal":
				if scores[-1] - scores[-2] >= 30:
					return _fail("Curated Water accidental upward spike at %d: %d -> %d" % [level, scores[-2], scores[-1]])
		if Progression.milestone_kind(level) in ["boss", "world_finale", "mastery", "finale"] and level > 5:
			var prior_total := 0
			for index in range(scores.size() - 6, scores.size() - 1):
				prior_total += scores[index]
			var prior_average := float(prior_total) / 5.0
			if float(scores[-1]) < prior_average - 3.0:
				return _fail("Curated Water boss %d is weaker than its lead-in" % level)
		if level % 1000 == 0:
			print("Curated Water audit: %d/%d" % [level, MAX_LEVEL])
	Catalog.clear_cache()
	print("WATER_CURATED_10000_OK: 10,000 unique authored boards; legal proofs; max proof %d." % max_proof)
	quit(0)

func _can_pour(tubes: Array, from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or from_idx >= tubes.size() or to_idx < 0 or to_idx >= tubes.size() or from_idx == to_idx:
		return false
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	if source.is_empty() or target.size() >= CAPACITY:
		return false
	return target.is_empty() or int(target.back()) == int(source.back())

func _pour(tubes: Array, from_idx: int, to_idx: int) -> void:
	var source: Array = tubes[from_idx]
	var target: Array = tubes[to_idx]
	var color := int(source.back())
	var amount := 0
	for index in range(source.size() - 1, -1, -1):
		if int(source[index]) == color:
			amount += 1
		else:
			break
	amount = mini(amount, CAPACITY - target.size())
	for _index in range(amount):
		target.append(source.pop_back())
	tubes[from_idx] = source
	tubes[to_idx] = target

func _solved(tubes: Array) -> bool:
	for raw_tube in tubes:
		var tube: Array = raw_tube
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY:
			return false
		var color := int(tube[0])
		for value in tube:
			if int(value) != color:
				return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	Catalog.clear_cache()
	quit(1)
