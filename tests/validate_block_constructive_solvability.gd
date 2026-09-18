extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var levels: Array[int] = []
	if OS.get_environment("BLOCK_FULL_AUDIT") == "1":
		for level in range(1, Progression.MAX_LEVEL + 1):
			levels.append(level)
	else:
		for level in range(1, 11):
			levels.append(level)
		for level in [25, 50, 100, 250, 500, 501, 1000, 1500, 2500, 5000, 7500, 9000, 9500, 9900, 10000]:
			levels.append(level)

	var signatures := {}
	var max_proof := 0
	for level in levels:
		var profile := _generation_profile(level)
		var plan: Dictionary = Generator.generate(profile)
		if plan.is_empty():
			return _fail("Block Puzzle level %d produced no constructive plan" % level)
		var proof: Dictionary = Generator.replay_proof(
			plan,
			int(profile.get("target_lines", 1)),
			int(profile.get("target_score", 1))
		)
		if not bool(proof.get("solved", false)):
			return _fail("Block Puzzle level %d proof did not reach its goals" % level)
		var moves := int(proof.get("moves", 0))
		if moves <= 0:
			return _fail("Block Puzzle level %d proof is empty" % level)
		max_proof = maxi(max_proof, moves)

		var trays: Array = plan.get("trays", [])
		if trays.is_empty():
			return _fail("Block Puzzle level %d generated no trays" % level)
		for tray_value in trays:
			if (tray_value as Array).size() != 3:
				return _fail("Block Puzzle level %d has a tray that is not three pieces" % level)

		var repeat: Dictionary = Generator.generate(profile)
		var signature := _signature(plan)
		if signature != _signature(repeat):
			return _fail("Block Puzzle level %d generation is not deterministic" % level)
		if signatures.has(signature):
			return _fail("Block Puzzle sampled duplicate: level %d matches %d" % [level, int(signatures[signature])])
		signatures[signature] = level

	print("BLOCK_CONSTRUCTIVE_OK: %d proof-backed deterministic levels sampled; max proof %d moves." % [levels.size(), max_proof])
	quit(0)

func _generation_profile(level: int) -> Dictionary:
	var profile := Progression.profile(level)
	if level <= 10:
		var scores := [100, 130, 165, 190, 220, 255, 285, 315, 350, 390]
		var lines := [2, 2, 3, 3, 3, 4, 4, 4, 5, 5]
		var i := level - 1
		profile["target_score"] = scores[i]
		profile["target_lines"] = lines[i]
	return profile

func _signature(plan: Dictionary) -> String:
	var parts := PackedStringArray()
	for row_value in (plan.get("initial_cells", []) as Array):
		var row := ""
		for value in (row_value as Array):
			row += "1" if bool(value) else "0"
		parts.append(row)
	for tray_value in (plan.get("trays", []) as Array):
		var values := PackedStringArray()
		for value in (tray_value as Array):
			values.append(str(int(value)))
		parts.append(",".join(values))
	return "|".join(parts).sha256_text()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
