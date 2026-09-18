extends SceneTree

const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")
const Progression = preload("res://scripts/core/block_puzzle_progression.gd")

func _initialize() -> void:
	if not LevelPack.has_production_pack():
		return _fail("Production Block Puzzle level pack was not generated")
	var manifest := LevelPack.manifest()
	if int(manifest.get("level_count", 0)) != 10000:
		return _fail("Production Block Puzzle manifest does not contain 10,000 levels")
	for level in [1, 500, 501, 5000, 9501, 10000]:
		var plan := LevelPack.plan_for_level(level, Progression.profile(level))
		if plan.is_empty() or (plan.get("trays", []) as Array).is_empty():
			return _fail("Packed Block Puzzle level %d failed runtime loading" % level)
		var metadata: Dictionary = plan.get("metadata", {})
		if int(metadata.get("level_id", level)) != level:
			return _fail("Packed Block Puzzle level %d metadata is mismatched" % level)
		if int(metadata.get("solution_moves", 0)) <= 0:
			return _fail("Packed Block Puzzle level %d has no solver solution length" % level)
		if String(metadata.get("level_hash", "")).is_empty():
			return _fail("Packed Block Puzzle level %d has no canonical hash" % level)
		if int(metadata.get("three_star_limit", 0)) < int(metadata.get("solution_moves", 0)):
			return _fail("Packed Block Puzzle level %d star limit is below its verified solution" % level)
	print("BLOCK_PACK_RUNTIME_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
