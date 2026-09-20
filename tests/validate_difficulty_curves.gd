extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")
const WaterProgression = preload("res://scripts/core/water_sort_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_rescue(): return
	if not await _check_water(): return
	if not await _check_block(): return
	print("DIFFICULTY_CURVES_OK: Rescue sawtooth progression, Water color bands and Block progression bands are locked.")
	quit(0)

func _check_rescue() -> bool:
	var samples := [1, 100, 1000, 3000, 5000, 7500, 9000, 10000]
	var previous_floor := -1
	for level in samples:
		var data: Dictionary = CampaignGeneratorScript.generate(level)
		var score := int(data.get("difficulty_score", -1))
		if score < 10 or score > 99:
			return _fail("Rescue level %d invalid 0-99 difficulty score: %d" % [level, score])
		if level == 10000 and (score < 98 or String(data.get("difficulty", "")) != "boss"):
			return _fail("Rescue level 10000 must finish at grandmaster boss difficulty")
		if previous_floor >= 0 and score + 15 < previous_floor:
			return _fail("Rescue sampled difficulty falls too sharply at level %d" % level)
		previous_floor = score
	for level in [25, 50, 75, 100]:
		var data: Dictionary = CampaignGeneratorScript.generate(level)
		if String(data.get("milestone", "")).is_empty():
			return _fail("Rescue level %d missing quarter-world milestone" % level)
	return true

func _check_water() -> bool:
	# Difficulty progression is data-owned by WaterSortProgression. Test that
	# production source directly; scene loading/UI inheritance is covered by
	# import, gameplay, viewport, motion and visual-audit gates.
	var cases := {
		1:[3,3], 3:[4,4], 8:[5,5], 20:[5,5],
		100:[6,7], 500:[7,8], 1000:[7,9], 2500:[9,11],
		5000:[11,12], 7500:[12,12], 10000:[12,12]
	}
	for level in cases.keys():
		var cfg: Dictionary = WaterProgression.profile(int(level))
		var actual := int(cfg.get("colors", -1))
		var expected: Array = cases[level]
		if actual < int(expected[0]) or actual > int(expected[1]):
			return _fail("Water level %d expected %d..%d colors, got %d" % [level, int(expected[0]), int(expected[1]), actual])
	return true

func _check_block() -> bool:
	var packed := load("res://scenes/BlockPuzzle.tscn") as PackedScene
	if packed == null: return _fail("BlockPuzzle scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var cases := {1:"starter", 2:"standard", 5:"standard", 6:"challenge", 10:"challenge", 11:"medium", 30:"medium", 31:"hard", 130:"hard", 131:"expert", 10000:"expert"}
	for level in cases.keys():
		game.set("level_number", int(level))
		var actual := String(game.call("block_progression_band", int(level)))
		if actual != String(cases[level]):
			game.queue_free()
			return _fail("Block level %d expected band %s, got %s" % [level, String(cases[level]), actual])
	var scores: Array[int] = []
	var lines: Array[int] = []
	for level in range(1, 11):
		game.set("level_number", level)
		var cfg: Dictionary = game.call("level_config")
		scores.append(int(cfg.get("target_score", 0)))
		lines.append(int(cfg.get("target_lines", 0)))
	if scores[9] <= scores[0] * 3 or lines[9] < 5 or lines[0] < 2:
		game.queue_free()
		return _fail("Block opening objectives do not escalate enough: scores=%s lines=%s" % [str(scores), str(lines)])
	game.queue_free()
	await process_frame
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
