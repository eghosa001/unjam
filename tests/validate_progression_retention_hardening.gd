extends SceneTree

const Rescue = preload("res://scripts/core/rescue_rush_progression.gd")
const Water = preload("res://scripts/core/water_sort_progression.gd")
const Block = preload("res://scripts/core/block_puzzle_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_rescue():
		return
	if not _check_water():
		return
	if not _check_block():
		return
	if not _check_attempt_telemetry():
		return
	var multi := root.get_node_or_null("MultiGameManager")
	if multi == null or String(multi.call("progression_scope_label", "rescue_rush")) != "ZONE":
		return _fail("Rescue 100-level navigation scope must be labelled ZONE")
	if String(multi.call("progression_scope_label", "water_sort")) != "WORLD" or String(multi.call("progression_scope_label", "block_puzzle")) != "WORLD":
		return _fail("Water and Block navigation scopes must remain WORLD")
	print("PROGRESSION_RETENTION_HARDENING_OK")
	quit(0)

func _check_rescue() -> bool:
	if Rescue.CHAPTER_SIZE != 500 or Rescue.CHAPTER_COUNT != 20:
		return _fail("Rescue major progression must be 20 x 500-level chapters")
	if String(Rescue.profile(100).get("milestone", "")) != "zone_boss":
		return _fail("Rescue 100 must be a zone boss")
	if String(Rescue.profile(500).get("milestone", "")) != "chapter_finale":
		return _fail("Rescue 500 must be a chapter finale")
	if String(Rescue.profile(10000).get("milestone", "")) != "finale":
		return _fail("Rescue 10000 must be the finale")
	var objectives := {}
	for level in range(500, 10001, 500):
		var p := Rescue.profile(level)
		objectives[String(p.get("objective", ""))] = true
		if int(p.get("chapter", 0)) != int((level - 1) / 500) + 1:
			return _fail("Rescue chapter mapping failed at %d" % level)
	if objectives.size() < 4:
		return _fail("Rescue chapter bosses do not rotate enough objective recipes")
	return true

func _check_water() -> bool:
	var archetypes := {}
	for level in range(2500, 10001):
		var p := Water.profile(level)
		if bool(p.get("hidden_information", true)):
			return _fail("Water introduced hidden information at %d" % level)
		var archetype := String(p.get("challenge_archetype", ""))
		if not archetype.is_empty():
			archetypes[archetype] = true
	for expected in ["fragmentation", "narrow_solution", "space_pressure", "efficiency", "buried_colors"]:
		if not archetypes.has(expected):
			return _fail("Water archetype missing: %s" % expected)
	return true

func _check_block() -> bool:
	if String(Block.profile(10).get("objective", "")) != "score":
		return _fail("Block level 10 must remain opening mastery")
	if String(Block.profile(11).get("objective", "")) != "clear_lines":
		return _fail("Block first new objective must begin at 11")
	var previous := Block.initial_occupancy(1)
	for level in range(2, Block.MAX_LEVEL + 1):
		var current := Block.initial_occupancy(level)
		if current + 0.0001 < previous:
			return _fail("Block occupancy reset at %d" % level)
		previous = current
	var families := [
		String(Block.profile(6500).get("objective", "")),
		String(Block.profile(7500).get("objective", "")),
		String(Block.profile(8500).get("objective", "")),
		String(Block.profile(9500).get("objective", "")),
	]
	for expected in ["conditional_chain", "constraint_combo", "pressure_mastery", "grandmaster_conditional"]:
		if expected not in families:
			return _fail("Block endgame family missing: %s" % expected)
	return true

func _check_attempt_telemetry() -> bool:
	var rescue := FileAccess.get_file_as_string("res://scripts/game/game.gd")
	var water := FileAccess.get_file_as_string("res://scripts/game/water_sort_10000.gd")
	var block := FileAccess.get_file_as_string("res://scripts/game/block_puzzle_10000.gd")
	for pair in [
		[rescue, "rescue_attempt_started"], [rescue, "rescue_attempt_finished"],
		[water, "water_sort_attempt_started"], [water, "water_sort_attempt_finished"],
		[block, "block_puzzle_attempt_started"], [block, "block_puzzle_attempt_finished"],
	]:
		if String(pair[1]) not in String(pair[0]):
			return _fail("Attempt telemetry missing: %s" % String(pair[1]))
	for key in ["first_attempt_success", "elapsed_seconds", "difficulty_score"]:
		if key not in rescue or key not in water or key not in block:
			return _fail("Cross-game telemetry field missing: %s" % key)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
