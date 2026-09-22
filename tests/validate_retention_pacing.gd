extends SceneTree

const Water = preload("res://scripts/core/water_sort_progression.gd")
const Block = preload("res://scripts/core/block_puzzle_progression.gd")
const Rescue = preload("res://scripts/core/rescue_rush_progression.gd")

const DEMANDING := ["challenge", "stretch", "peak", "world_boss"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_roles(): return
	if not _check_water(): return
	if not _check_block(): return
	if not _check_rescue(): return
	print("RETENTION_PACING_OK: 30,000 profiles keep recovery beats, staged mechanic teaching and bounded hard runs.")
	quit(0)

func _check_roles() -> bool:
	for game in ["water", "block", "rescue"]:
		var run := 0
		for level in range(1, 10001):
			var p := _profile(game, level)
			var role := String(p.get("retention_role", ""))
			if role.is_empty():
				return _fail("%s level %d missing retention role" % [game, level])
			run = run + 1 if role in DEMANDING else 0
			if run > 2:
				return _fail("%s level %d creates >2 demanding levels in a row" % [game, level])
			var target: Vector2 = p.get("first_attempt_target", Vector2.ZERO)
			if target.x <= 0.0 or target.y <= target.x or target.y > 1.0:
				return _fail("%s level %d invalid first-attempt target %s" % [game, level, str(target)])
	return true

func _check_water() -> bool:
	for level in [1009, 2509, 5009, 7509, 9009]:
		var p := Water.profile(level)
		if String(p.retention_role) != "recovery" or int(p.empty_bottles) != 2:
			return _fail("Water level %d must restore a two-bottle recovery workspace" % level)
	for level in [21, 41, 61, 101, 201, 501, 1001, 2501, 5001, 7501]:
		if String(Water.profile(level).retention_role) != "learn":
			return _fail("Water level %d must introduce added colour pressure as a learn level" % level)
	return true

func _check_block() -> bool:
	var starts := [10, 26, 41, 76, 101, 151, 251, 401, 601, 1001, 1401, 1751, 2101, 2401, 2501, 4001, 6001]
	for level in starts:
		var p := Block.profile(level)
		if String(p.retention_role) != "learn" or int(p.objective_intro_age) != 0:
			return _fail("Block level %d is not a clean objective introduction" % level)
		if bool(p.move_limited):
			return _fail("Block level %d teaches a new objective under a move limit" % level)
	if String(Block.profile(100).objective) == String(Block.profile(101).objective):
		return _fail("Block boss 100 should hand off to a new objective on recovery level 101")
	return true

func _check_rescue() -> bool:
	var intros := {
		201:"rotate",
		501:"gate",
		1001:"linked",
		2001:"bomb",
	}
	for level in intros:
		var p := Rescue.profile(int(level))
		var mechanics: Array = p.get("mechanics", [])
		if String(p.retention_role) != "learn" or mechanics != [String(intros[level])]:
			return _fail("Rescue level %d must teach only %s, got %s" % [level, String(intros[level]), str(mechanics)])
		if String(p.objective) != Rescue.OBJECTIVE_RESCUE_ROUTE:
			return _fail("Rescue level %d combines a mechanic intro with a new objective" % level)
	if String(Rescue.profile(1000).retention_role) != "world_boss" or String(Rescue.profile(1001).retention_role) != "learn":
		return _fail("Rescue 1000 -> 1001 must transition boss -> learning recovery")
	return true

func _profile(game: String, level: int) -> Dictionary:
	match game:
		"water": return Water.profile(level)
		"block": return Block.profile(level)
		_: return Rescue.profile(level)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
