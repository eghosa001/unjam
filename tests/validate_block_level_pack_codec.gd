extends SceneTree

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")
const LevelPack = preload("res://scripts/core/block_puzzle_level_pack.gd")

func _initialize() -> void:
	var profile := Progression.profile(2500)
	var plan := Generator.generate(profile)
	if plan.is_empty():
		return _fail("Codec fixture generator returned no plan")
	var encoded := LevelPack.encode_plan(plan)
	var decoded := LevelPack._decode_plan(encoded)
	if decoded.is_empty():
		return _fail("Block level-pack codec could not decode its own plan")
	if _board_signature(plan.get("initial_cells", [])) != _board_signature(decoded.get("initial_cells", [])):
		return _fail("Block level-pack codec changed the opening board")
	if JSON.stringify(plan.get("trays", [])) != JSON.stringify(decoded.get("trays", [])):
		return _fail("Block level-pack codec changed the deterministic trays")
	if JSON.stringify(plan.get("special_plan", {})) != JSON.stringify(decoded.get("special_plan", {})):
		return _fail("Block level-pack codec changed objective data")
	print("BLOCK_LEVEL_PACK_CODEC_OK")
	quit(0)

func _board_signature(board: Variant) -> String:
	var out := ""
	if board is Array:
		for row_value in board:
			for value in (row_value as Array):
				out += "1" if bool(value) else "0"
	return out

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
