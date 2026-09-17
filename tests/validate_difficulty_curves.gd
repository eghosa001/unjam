extends SceneTree

const CampaignGeneratorScript = preload("res://scripts/core/campaign_generator.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_rescue(): return
	if not await _check_water(): return
	if not await _check_block(): return
	print("DIFFICULTY_CURVES_OK: Rescue opening rhythm, Water color bands and Block progression bands are locked.")
	quit(0)

func _check_rescue() -> bool:
	var expected := ["easy", "easy", "medium", "easy", "medium", "medium", "easy", "medium", "medium", "hard"]
	for level in range(1, 11):
		var data: Dictionary = CampaignGeneratorScript.generate(level)
		if String(data.get("difficulty", "")) != expected[level - 1]:
			return _fail("Rescue level %d expected %s, got %s" % [level, expected[level - 1], String(data.get("difficulty", ""))])
	return true

func _check_water() -> bool:
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null: return _fail("WaterSort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var cases := {1:3, 10:3, 11:4, 30:4, 31:5, 130:5, 131:6, 210:6, 211:7, 300:7, 301:8, 10000:8}
	for level in cases.keys():
		game.set("level_number", int(level))
		var cfg: Dictionary = game.call("level_config")
		var actual := int(cfg.get("colors", -1))
		if actual != int(cases[level]):
			game.queue_free()
			return _fail("Water level %d expected %d colors, got %d" % [level, int(cases[level]), actual])
	game.queue_free()
	await process_frame
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
