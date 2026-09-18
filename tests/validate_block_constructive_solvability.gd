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

		if not _objective_plan_is_proof_safe(plan):
			return _fail("Block Puzzle level %d objective plan is not supported by its proof" % level)
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

func _objective_plan_is_proof_safe(plan: Dictionary) -> bool:
	var cleared_counts := {}
	var placed := {}
	var rows := {}
	var cols := {}
	var doubles := 0
	for event in (plan.get("proof_events", []) as Array):
		for raw in (event.get("cleared_indices", []) as Array):
			var idx := int(raw)
			cleared_counts[idx] = int(cleared_counts.get(idx, 0)) + 1
		for raw in (event.get("placed_indices", []) as Array):
			placed[int(raw)] = true
		for raw in (event.get("rows", []) as Array):
			rows[int(raw)] = true
		for raw in (event.get("cols", []) as Array):
			cols[int(raw)] = true
		if int(event.get("line_count", 0)) >= 2:
			doubles += 1
	var initial: Array = plan.get("initial_cells", [])
	var objective: Dictionary = plan.get("special_plan", {})
	for raw in (objective.get("specials", []) as Array):
		var special: Dictionary = raw
		var idx := int(special.get("index", -1))
		var kind := String(special.get("kind", ""))
		var layers := int(special.get("layers", 1))
		if kind == "preserve":
			if placed.has(idx) or cleared_counts.has(idx):
				return false
		elif int(cleared_counts.get(idx, 0)) < layers:
			return false
		if kind == "crate":
			var y := int(idx / 8)
			var x := idx % 8
			if y < 0 or y >= initial.size() or x < 0 or x >= (initial[y] as Array).size() or not bool(initial[y][x]):
				return false
	for raw in (objective.get("target_rows", []) as Array):
		if not rows.has(int(raw)):
			return false
	for raw in (objective.get("target_cols", []) as Array):
		if not cols.has(int(raw)):
			return false
	return doubles >= int(objective.get("required_double_clears", 0))

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
