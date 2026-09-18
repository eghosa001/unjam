extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const Auditor = preload("res://scripts/core/block_puzzle_campaign_auditor.gd")
const Solver = preload("res://scripts/core/block_puzzle_exact_solver.gd")

const ROOT := "res://data/block_puzzle_campaign"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var absolute_root := ProjectSettings.globalize_path(ROOT)
	var err := DirAccess.make_dir_recursive_absolute(absolute_root)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return _fail("Could not create Block Puzzle campaign pack directory: %s" % error_string(err))

	var signatures := {}
	var world_hashes := {}
	var human_review: Array[Dictionary] = []
	var total_levels := 0
	for world in range(1, Progression.WORLD_COUNT + 1):
		var levels := {}
		var first := (world - 1) * Progression.WORLD_SIZE + 1
		var last := mini(world * Progression.WORLD_SIZE, Progression.MAX_LEVEL)
		for level in range(first, last + 1):
			var profile := _generation_profile(level)
			var plan := {}
			var signature := ""
			var solver_report := {}
			for attempt in range(8):
				var candidate_profile := profile.duplicate(true)
				if attempt > 0 and level != Progression.MAX_LEVEL:
					candidate_profile["seed"] = int(profile.get("seed", level * 104729)) + attempt * 1000003
				var candidate := Generator.generate(candidate_profile)
				if candidate.is_empty():
					continue
				var proof := Generator.replay_proof(
					candidate,
					int(candidate_profile.get("target_lines", 1)),
					int(candidate_profile.get("target_score", 1))
				)
				if not bool(proof.get("solved", false)):
					continue
				var exact := Solver.find_solution(candidate_profile, candidate, 50000)
				if not bool(exact.get("solved", false)):
					continue
				var candidate_signature := Auditor.canonical_signature(candidate_profile, candidate)
				if signatures.has(candidate_signature):
					continue
				plan = candidate
				profile = candidate_profile
				signature = candidate_signature
				solver_report = exact
				break
			if plan.is_empty():
				return _fail("Could not build unique proof-backed Block Puzzle level %d" % level)
			signatures[signature] = level
			var encoded := LevelPack.encode_plan(plan)
			var metadata: Dictionary = encoded.get("m", {})
			metadata["level_id"] = level
			metadata["seed"] = int(profile.get("seed", 0))
			metadata["difficulty_score"] = int(profile.get("difficulty_score", 0))
			metadata["world"] = int(profile.get("world", world))
			metadata["milestone"] = String(profile.get("milestone", "normal"))
			metadata["signature"] = signature
			metadata["level_hash"] = signature
			metadata["solution_moves"] = int(solver_report.get("moves", metadata.get("proof_moves", 0)))
			metadata["solver_nodes"] = int(solver_report.get("nodes", 0))
			var three_star := maxi(int(profile.get("par", 18)), int(metadata.get("proof_moves", 0)))
			metadata["three_star_limit"] = three_star
			metadata["two_star_limit"] = three_star + 6
			var effective_limit := int(profile.get("move_limit", -1))
			if effective_limit > 0:
				var margin := 3 if level <= 5000 else (2 if level < 9000 else 1)
				effective_limit = maxi(effective_limit, int(metadata.get("proof_moves", 0)) + margin)
			metadata["effective_move_limit"] = effective_limit
			metadata["optimal_moves"] = -1
			metadata["optimal_verified"] = false
			if level <= 10 or level in [25, 50, 100]:
				var optimal := Solver.find_optimal(profile, plan, 350000)
				if bool(optimal.get("solved", false)) and bool(optimal.get("optimal_verified", false)):
					metadata["optimal_moves"] = int(optimal.get("optimal_moves", -1))
					metadata["optimal_verified"] = true
			encoded["m"] = metadata
			if String(profile.get("milestone", "normal")) in ["boss", "world_finale", "mastery", "finale"]:
				var audit := Auditor.audit_plan(profile, plan)
				human_review.append({
					"level": level,
					"world": int(profile.get("world", world)),
					"milestone": String(profile.get("milestone", "")),
					"difficulty": int(profile.get("difficulty_score", 0)),
					"proof_moves": int(metadata.get("proof_moves", 0)),
					"bot_success_rate": float(audit.get("bot_success_rate", -1.0)),
					"calibrated_difficulty": int(audit.get("calibrated_difficulty", -1)),
					"signature": signature
				})
			levels[str(level)] = encoded
			total_levels += 1
			if level % 250 == 0:
				print("BLOCK_PACK_PROGRESS %d/%d" % [level, Progression.MAX_LEVEL])

		var payload := {
			"pack_version": LevelPack.PACK_VERSION,
			"generator_version": Generator.GENERATOR_VERSION,
			"world": world,
			"first_level": first,
			"last_level": last,
			"levels": levels,
		}
		var serialized := JSON.stringify(payload)
		var path := "%s/world_%02d.json" % [ROOT, world]
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return _fail("Could not write %s" % path)
		file.store_string(serialized)
		file.close()
		world_hashes[str(world)] = serialized.sha256_text()

	var review_file := FileAccess.open(ROOT + "/human_review.json", FileAccess.WRITE)
	if review_file == null:
		return _fail("Could not write Block Puzzle human-review queue")
	review_file.store_string(JSON.stringify({
		"generator_version": Generator.GENERATOR_VERSION,
		"levels": human_review,
	}))
	review_file.close()

	var manifest := {
		"pack_version": LevelPack.PACK_VERSION,
		"generator_version": Generator.GENERATOR_VERSION,
		"level_count": total_levels,
		"world_count": Progression.WORLD_COUNT,
		"world_size": Progression.WORLD_SIZE,
		"world_hashes": world_hashes,
		"finale_level": Progression.MAX_LEVEL,
	}
	var manifest_text := JSON.stringify(manifest)
	var manifest_file := FileAccess.open(LevelPack.MANIFEST_PATH, FileAccess.WRITE)
	if manifest_file == null:
		return _fail("Could not write Block Puzzle campaign manifest")
	manifest_file.store_string(manifest_text)
	manifest_file.close()

	if total_levels != Progression.MAX_LEVEL:
		return _fail("Campaign pack contains %d levels instead of %d" % [total_levels, Progression.MAX_LEVEL])
	print("BLOCK_PACK_OK: %d unique proof-backed levels across %d worlds." % [total_levels, Progression.WORLD_COUNT])
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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
