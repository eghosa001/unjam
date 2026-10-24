extends SceneTree

# Replays the actual Water Sort runtime selector, including the challenge
# remaster that can replace overly-easy chapter data. A raw-catalog spike
# is NOT a player-facing regression if the remaster smooths its predecessor.
const Progression = preload("res://scripts/core/water_sort_progression.gd")
const Catalog = preload("res://scripts/core/water_sort_curated_catalog.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var candidates: Array[int] = []
	var preceding: Dictionary = {}
	var previous_score := -1
	for level in range(1, 10001):
		var entry: Dictionary = Catalog.level(level)
		if entry.is_empty():
			return _fail("Missing authored level %d" % level)
		var metrics: Dictionary = Progression.score_board(entry.get("tubes", []), (entry.get("solution",[]) as Array).size())
		var score := int(metrics.get("difficulty_score",0))
		if previous_score >= 0 and score - previous_score >= 25 and Progression.milestone_kind(level) == "normal" and Progression.milestone_kind(level-1) == "normal":
			candidates.append(level)
			preceding[level] = previous_score
		previous_score = score
	print("WATER_RAW_SPIKE_SURVEY candidates=%d" % candidates.size())
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Live Water Sort scene missing")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var remastered := 0
	var unresolved: Array[int] = []
	var max_actual_jump := 0
	var biggest: Array = []
	for level in candidates:
		var actual: Array[int] = []
		var sources: Array[String] = []
		for current in [level-1, level]:
			var p: Dictionary = Progression.profile(current)
			game.level_number = current
			var board: Dictionary = game.call("generate_tubes_with_solution",current,int(p.get("colors",3)))
			var proof: Array = board.get("solution",[])
			var tubes: Array = board.get("tubes",[])
			if proof.is_empty() or tubes.is_empty():
				game.queue_free()
				return _fail("Water runtime missing playable proof at %d" % current)
			if proof.size() > int(p.get("three_star_limit",0)):
				game.queue_free()
				return _fail("Water runtime proof exceeds 3-star allowance at %d" % current)
			var metrics: Dictionary = Progression.score_board(tubes,proof.size())
			actual.append(int(metrics.get("difficulty_score",0)))
			var metadata: Dictionary = board.get("metadata",{})
			sources.append(String(metadata.get("source","generated")))
		var jump := actual[1] - actual[0]
		max_actual_jump = maxi(max_actual_jump,jump)
		if jump >= 25:
			biggest.append({"level":level,"jump":jump,"scores":actual,"sources":sources})
		if jump >= 30:
			unresolved.append(level)
		if actual[0] > int(preceding[level]):
			remastered += 1
		if level in [1657,4604,9557,9493,9703] or jump >= 30:
			print("WATER_SPIKE_RUNTIME level=%d raw_before=%d actual_before=%d actual_after=%d actual_jump=%d source_before=%s source_after=%s" % [
				level,int(preceding[level]),actual[0],actual[1],jump,sources[0],sources[1]])
	print("WATER_RUNTIME_SPIKE_REPORT raw_candidates=%d remastered_predecessors=%d max_player_facing_jump=%d jump25plus=%d unresolved_jump30plus=%d largest=%s" % [
		candidates.size(),remastered,max_actual_jump,biggest.size(),unresolved.size(),str(biggest.slice(0,12))])
	# Compare the *played* milestone board against the five preceding levels.
	# Two raw curated bosses, 4300 and 9000, were below their lead-ins.
	# The production selector should remaster them instead of weakening the boss.
	var boss_failures: Array[int] = []
	for boss_level in [4300, 9000]:
		var lead_score := 0.0
		for earlier in range(boss_level - 5, boss_level):
			var earlier_profile: Dictionary = Progression.profile(earlier)
			game.level_number = earlier
			var earlier_board: Dictionary = game.call("generate_tubes_with_solution", earlier, int(earlier_profile.get("colors", 3)))
			var earlier_solution: Array = earlier_board.get("solution", [])
			if earlier_solution.is_empty():
				return _fail("Water boss lead-in missing proof at %d" % earlier)
			var earlier_metrics: Dictionary = Progression.score_board(earlier_board.get("tubes", []), earlier_solution.size())
			lead_score += float(earlier_metrics.get("difficulty_score", 0))
		lead_score /= 5.0
		var boss_profile: Dictionary = Progression.profile(boss_level)
		game.level_number = boss_level
		var boss_board: Dictionary = game.call("generate_tubes_with_solution", boss_level, int(boss_profile.get("colors", 3)))
		var boss_proof: Array = boss_board.get("solution", [])
		if boss_proof.is_empty():
			return _fail("Water boss %d missing playable proof" % boss_level)
		var boss_metrics: Dictionary = Progression.score_board(boss_board.get("tubes", []), boss_proof.size())
		var boss_score := float(boss_metrics.get("difficulty_score", 0))
		print("WATER_BOSS_RUNTIME level=%d lead_in_avg=%.2f boss_score=%.2f source=%s" % [boss_level, lead_score, boss_score, String((boss_board.get("metadata", {}) as Dictionary).get("source", "generated"))])
		if boss_score < lead_score - 3.0:
			boss_failures.append(boss_level)
	game.queue_free()
	await process_frame
	Catalog.clear_cache()
	if not boss_failures.is_empty():
		return _fail("Water weak player-facing boss levels: %s" % str(boss_failures))
	if not unresolved.is_empty():
		return _fail("Water actual runtime still has jumps of 30+ difficulty points at %s" % str(unresolved))
	print("WATER_RUNTIME_DIFFICULTY_SPIKES_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error("WATER_RUNTIME_SPIKE_FAILED: "+message)
	quit(1)
