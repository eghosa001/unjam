extends SceneTree

# Players complained that Water Sort offers very easy "hard" boards.
# Replacements are accepted only when more colour runs must be resolved;
# known proof length alone cannot justify a new puzzle.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/WaterSort.tscn") as PackedScene
	var catalog := load("res://scripts/core/water_sort_curated_catalog.gd") as Script
	var progression := load("res://scripts/core/water_sort_progression.gd") as Script
	if scene == null or catalog == null or progression == null:
		return _fail("Water Sort comparison resources missing")
	var changed := 0
	for level in [103, 106, 107, 125, 150, 250, 500, 9556, 9569, 10000]:
		var reference: Dictionary = catalog.level(level)
		if reference.is_empty():
			return _fail("Missing curated water level %d" % level)
		var original_metrics: Dictionary = progression.score_board(
			reference.get("tubes", []), (reference.get("solution", []) as Array).size()
		)
		var game := scene.instantiate()
		game.set("level_number", level)
		root.add_child(game)
		await process_frame
		var profile: Dictionary = progression.profile(level)
		var result: Dictionary = game.call("generate_tubes_with_solution", level, int(profile.get("colors", 4)))
		var meta: Dictionary = game.get("generation_meta")
		var source := String(meta.get("source", ""))
		var output: Array = result.get("tubes", [])
		var upper: Array = result.get("solution", [])
		var actual: Dictionary = progression.score_board(output, upper.size())
		var old_floor := int(original_metrics.get("unavoidable_pours_lower_bound", 0))
		var new_floor := int(actual.get("unavoidable_pours_lower_bound", 0))
		if source == "verified_challenge_remaster":
			changed += 1
			if new_floor < old_floor + 2:
				game.queue_free()
				return _fail("Remastered Water level %d was not structurally deeper" % level)
			if upper.size() < (reference.get("solution", []) as Array).size() + 2:
				game.queue_free()
				return _fail("Remastered level %d lost its constructive proof margin" % level)
		elif source == "curated_catalog":
			if progression.canonical_signature(output) != progression.canonical_signature(reference.get("tubes", [])):
				game.queue_free()
				return _fail("Water level %d changed layout without approved remaster" % level)
		else:
			game.queue_free()
			return _fail("Water level %d has unexpected replacement source %s" % [level, source])
		if new_floor > upper.size():
			game.queue_free()
			return _fail("Water level %d has a proof below the mathematical lower bound" % level)
		print("WATER_REMASTER_AUDIT level=%d source=%s lower=%d to=%d proof=%d" %
			[level, source, old_floor, new_floor, upper.size()])
		game.queue_free()
		await process_frame
	print("WATER_REMASTER_STRUCTURAL_GUARD_OK remastered=%d" % changed)
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
