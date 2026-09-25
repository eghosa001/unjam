class_name BlockPuzzleCuratedCampaign
extends RefCounted

const MAX_LEVEL := 10000
const SHARD_SIZE := 1000
const CURATION_VERSION := 1

const ROLE_NAMES := ["tutorial","recovery","confidence","learn","practice","build","challenge","stretch","peak"]
const OBJECTIVE_NAMES := ["score","clear_lines","clear_columns","row_column","double_clear","combo","limited_moves","marked_cells","designated_rows","crates","ice","locks","steel","layered_obstacle","preserve_cells","dual_objective","triple_objective","conditional_chain","constraint_combo","pressure_mastery","grandmaster_conditional"]
const MILESTONE_NAMES := ["normal","challenge","hard_challenge","mini_boss","boss","world_finale","mastery","finale"]
const BOSS_NAMES := ["","precision","obstacle","combo","preservation","mastery_mix"]
const BIAS_NAMES := ["balanced","compact","lines","corners","advanced","large","precision","mixed","clearance","endurance"]

static var _cache: Dictionary = {}

static func profile(raw_level: int) -> Dictionary:
	var level := clampi(raw_level, 1, MAX_LEVEL)
	var shard_index := int((level - 1) / SHARD_SIZE)
	var rows: Array = _load_shard(shard_index)
	var row_index := level - shard_index * SHARD_SIZE - 1
	if row_index < 0 or row_index >= rows.size():
		return {}
	var row: Array = rows[row_index]
	if row.size() < 18 or int(row[0]) != level:
		return {}
	var milestone := MILESTONE_NAMES[clampi(int(row[11]), 0, MILESTONE_NAMES.size() - 1)]
	var role := ROLE_NAMES[clampi(int(row[2]), 0, ROLE_NAMES.size() - 1)]
	var score := int(row[1])
	var world := int((level - 1) / 500) + 1
	var level_in_world := posmod(level - 1, 500) + 1
	var chapter_global := int((level - 1) / 50) + 1
	var chapter_in_world := int((level_in_world - 1) / 50) + 1
	return {
		"level_id": level,
		"seed": int(row[16]),
		"generator_version": 2,
		"curation_version": CURATION_VERSION,
		"curated_source": true,
		"board_size": 8,
		"world": world,
		"level_in_world": level_in_world,
		"chapter_global": chapter_global,
		"chapter_in_world": chapter_in_world,
		"milestone": milestone,
		"boss_archetype": BOSS_NAMES[clampi(int(row[12]), 0, BOSS_NAMES.size() - 1)],
		"retention_role": role,
		"objective_intro_age": int(row[17]),
		"difficulty_score": score,
		"difficulty_floor": _difficulty_floor(level),
		"difficulty_ceiling": _difficulty_ceiling(level),
		"difficulty_class": _difficulty_class(score, milestone, role),
		"piece_tier": int(row[4]),
		"planning_horizon": int(row[5]),
		"initial_occupancy": float(row[6]) / 1000.0,
		"target_lines": int(row[7]),
		"target_score": int(row[8]),
		"par": int(row[9]),
		"move_limited": int(row[10]) > 0,
		"move_limit": int(row[10]),
		"objective": OBJECTIVE_NAMES[clampi(int(row[3]), 0, OBJECTIVE_NAMES.size() - 1)],
		"shape_bias": BIAS_NAMES[clampi(int(row[13]), 0, BIAS_NAMES.size() - 1)],
		"first_attempt_target": Vector2(float(row[14]) / 100.0, float(row[15]) / 100.0),
		"deterministic_trays": true,
		"fixed_orientation": true,
		"booster_required": false,
		"free_rotation": false,
	}

static func _load_shard(index: int) -> Array:
	if _cache.has(index):
		return _cache[index]
	var start_level := index * SHARD_SIZE + 1
	var end_level := mini(MAX_LEVEL, start_level + SHARD_SIZE - 1)
	var path := "res://data/block_puzzle_curated/block_%04d_%04d.json" % [start_level, end_level]
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		_cache[index] = []
		return _cache[index]
	var rows = (parsed as Dictionary).get("levels", [])
	_cache[index] = rows if rows is Array else []
	return _cache[index]

static func _difficulty_floor(level: int) -> int:
	if level <= 500: return 10
	if level <= 1000: return 40
	if level <= 1500: return 48
	if level <= 2000: return 52
	if level <= 2500: return 56
	if level <= 3000: return 59
	if level <= 3500: return 61
	if level <= 4000: return 64
	if level <= 4500: return 66
	if level <= 5000: return 68
	if level <= 5500: return 70
	if level <= 6000: return 72
	if level <= 6500: return 74
	if level <= 7000: return 75
	if level <= 7500: return 77
	if level <= 8000: return 79
	if level <= 8500: return 80
	if level <= 9000: return 82
	if level <= 9500: return 84
	return 86

static func _difficulty_ceiling(level: int) -> int:
	if level <= 500: return 55
	if level <= 1000: return 60
	if level <= 1500: return 64
	if level <= 2000: return 67
	if level <= 2500: return 70
	if level <= 3000: return 72
	if level <= 3500: return 74
	if level <= 4000: return 76
	if level <= 4500: return 78
	if level <= 5000: return 80
	if level <= 5500: return 82
	if level <= 6000: return 84
	if level <= 6500: return 86
	if level <= 7000: return 87
	if level <= 7500: return 89
	if level <= 8000: return 90
	if level <= 8500: return 92
	if level <= 9000: return 93
	if level <= 9500: return 95
	return 98

static func _difficulty_class(score: int, milestone: String, role: String) -> String:
	if milestone == "finale": return "finale"
	if milestone in ["boss","mastery"] and score >= 70: return "boss"
	if role == "tutorial": return "tutorial"
	if score < 35: return "normal"
	if score < 65: return "hard"
	if score < 75: return "very_hard"
	if score < 84: return "expert"
	if score < 94: return "extreme"
	return "grandmaster"
