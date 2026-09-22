extends SceneTree

const Water = preload("res://scripts/core/water_sort_progression.gd")
const Block = preload("res://scripts/core/block_puzzle_progression.gd")
const Rescue = preload("res://scripts/core/rescue_rush_progression.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for level in range(1, 4):
		if String(Water.profile(level).retention_role) != "tutorial":
			return _fail("Water onboarding must cover levels 1-3")
		if String(Block.profile(level).retention_role) != "tutorial":
			return _fail("Block onboarding must cover levels 1-3")
		if String(Rescue.profile(level).retention_role) != "tutorial":
			return _fail("Rescue onboarding must cover levels 1-3")
	for level in range(4, 11):
		if "tutorial" in [String(Water.profile(level).retention_role), String(Block.profile(level).retention_role), String(Rescue.profile(level).retention_role)]:
			return _fail("Level %d must be post-tutorial in all games" % level)
	if int(Water.profile(10).target_difficulty) <= int(Water.profile(3).target_difficulty) + 20:
		return _fail("Water first-ten ramp is too flat")
	if int(Block.profile(10).difficulty_score) <= int(Block.profile(3).difficulty_score) + 20:
		return _fail("Block first-ten ramp is too flat")
	if int(Rescue.profile(10).difficulty_target) <= int(Rescue.profile(3).difficulty_target) + 25:
		return _fail("Rescue first-ten ramp is too flat")

	var water9 := int(Water.profile(9).target_difficulty)
	var water10 := int(Water.profile(10).target_difficulty)
	var water11 := int(Water.profile(11).target_difficulty)
	var block9 := int(Block.profile(9).difficulty_score)
	var block10 := int(Block.profile(10).difficulty_score)
	var block11 := int(Block.profile(11).difficulty_score)
	var rescue9 := int(Rescue.profile(9).difficulty_target)
	var rescue10 := int(Rescue.profile(10).difficulty_target)
	var rescue11 := int(Rescue.profile(11).difficulty_target)

	if water9 - water11 > 4 or water10 - water11 > 6:
		return _fail("Water level 11 falls too far below levels 9-10")
	if block9 - block11 > 4 or block10 - block11 > 6:
		return _fail("Block level 11 falls too far below levels 9-10")
	if rescue9 - rescue11 > 4 or rescue10 - rescue11 > 6:
		return _fail("Rescue level 11 falls too far below levels 9-10")
	if int(Rescue.profile(11).piece_target) < 13 or int(Rescue.profile(11).dependency_target) < 3:
		return _fail("Rescue level 11 loses too much structural pressure")

	print("OPENING_PACING_OK: three onboarding levels, meaningful challenge from level 4, smooth 10 -> 11 handoff.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
