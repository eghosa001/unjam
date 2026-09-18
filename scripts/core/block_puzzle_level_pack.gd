class_name BlockPuzzleLevelPack
extends RefCounted

const Progression = preload("res://scripts/core/block_puzzle_progression.gd")
const Generator = preload("res://scripts/core/block_puzzle_campaign_generator.gd")

const PACK_VERSION := 1
const ROOT := "res://data/block_puzzle_campaign"
const MANIFEST_PATH := ROOT + "/manifest.json"

static var _world_cache: Dictionary = {}
static var _manifest_cache: Dictionary = {}

static func has_production_pack() -> bool:
	return FileAccess.file_exists(MANIFEST_PATH)

static func plan_for_level(raw_level: int, profile_override: Dictionary = {}) -> Dictionary:
	var level := clampi(raw_level, 1, Progression.MAX_LEVEL)
	var packed := _packed_plan(level)
	if not packed.is_empty():
		return packed
	var profile := profile_override.duplicate(true) if not profile_override.is_empty() else Progression.profile(level)
	return Generator.generate(profile)

static func clear_cache() -> void:
	_world_cache.clear()
	_manifest_cache.clear()

static func manifest() -> Dictionary:
	if not _manifest_cache.is_empty():
		return _manifest_cache.duplicate(true)
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest_cache = (parsed as Dictionary).duplicate(true)
	return _manifest_cache.duplicate(true)

static func _packed_plan(level: int) -> Dictionary:
	if not has_production_pack():
		return {}
	var world := int((level - 1) / Progression.WORLD_SIZE) + 1
	var world_data := _load_world(world)
	if world_data.is_empty():
		return {}
	var key := str(level)
	var levels = world_data.get("levels", {})
	if not levels is Dictionary or not (levels as Dictionary).has(key):
		return {}
	var raw = (levels as Dictionary)[key]
	if not raw is Dictionary:
		return {}
	return _decode_plan(raw as Dictionary)

static func _load_world(world: int) -> Dictionary:
	if _world_cache.has(world):
		return (_world_cache[world] as Dictionary).duplicate(true)
	var path := "%s/world_%02d.json" % [ROOT, world]
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var data := (parsed as Dictionary).duplicate(true)
	if int(data.get("pack_version", -1)) != PACK_VERSION:
		return {}
	if int(data.get("generator_version", -1)) != Generator.GENERATOR_VERSION:
		return {}
	_world_cache[world] = data
	return data.duplicate(true)

static func encode_plan(plan: Dictionary) -> Dictionary:
	var board_bits := ""
	for row_value in (plan.get("initial_cells", []) as Array):
		for value in (row_value as Array):
			board_bits += "1" if bool(value) else "0"
	var trays: Array = []
	for tray_value in (plan.get("trays", []) as Array):
		var packed_tray: Array[int] = []
		for value in (tray_value as Array):
			packed_tray.append(int(value))
		trays.append(packed_tray)
	var proof_origins: Array[int] = []
	for value in (plan.get("proof_origins", []) as Array):
		proof_origins.append(int(value))
	var proof_shapes: Array[int] = []
	for value in (plan.get("proof_shapes", []) as Array):
		proof_shapes.append(int(value))
	return {
		"b": board_bits,
		"t": trays,
		"po": proof_origins,
		"ps": proof_shapes,
		"sp": plan.get("special_plan", {}),
		"m": plan.get("metadata", {}),
	}

static func _decode_plan(raw: Dictionary) -> Dictionary:
	var bits := String(raw.get("b", ""))
	if bits.length() != 64:
		return {}
	var board: Array = []
	for y in range(8):
		var row: Array = []
		for x in range(8):
			row.append(bits[y * 8 + x] == "1")
		board.append(row)
	var shapes: Array[int] = []
	for value in (raw.get("ps", []) as Array):
		shapes.append(int(value))
	var origins: Array[int] = []
	for value in (raw.get("po", []) as Array):
		origins.append(int(value))
	return {
		"initial_cells": board,
		"trays": (raw.get("t", []) as Array).duplicate(true),
		"proof_shapes": shapes,
		"proof_origins": origins,
		"special_plan": (raw.get("sp", {}) as Dictionary).duplicate(true),
		"metadata": (raw.get("m", {}) as Dictionary).duplicate(true),
	}
