class_name BlockPuzzleProgression
extends RefCounted

const MAX_LEVEL := 10000
const BOARD_SIZE := 8
const WORLD_SIZE := 500
const WORLD_COUNT := 20
const CHAPTER_SIZE := 50
const GENERATOR_VERSION := 1

# [start, end, difficulty_floor, difficulty_ceiling]
const DIFFICULTY_BANDS := [
	[1, 500, 10, 55],
	[501, 1000, 40, 60],
	[1001, 1500, 48, 64],
	[1501, 2000, 52, 67],
	[2001, 2500, 56, 70],
	[2501, 3000, 59, 72],
	[3001, 3500, 61, 74],
	[3501, 4000, 64, 76],
	[4001, 4500, 66, 78],
	[4501, 5000, 68, 80],
	[5001, 5500, 70, 82],
	[5501, 6000, 72, 84],
	[6001, 6500, 74, 86],
	[6501, 7000, 75, 87],
	[7001, 7500, 77, 89],
	[7501, 8000, 79, 90],
	[8001, 8500, 80, 92],
	[8501, 9000, 82, 93],
	[9001, 9500, 84, 95],
	[9501, 10000, 86, 98],
]

static func profile(raw_level: int) -> Dictionary:
	var level := clampi(raw_level, 1, MAX_LEVEL)
	var band := _band_for(level)
	var band_start := int(band[0])
	var band_end := int(band[1])
	var floor_score := int(band[2])
	var ceiling_score := int(band[3])
	var span := maxi(1, band_end - band_start)
	var progress := float(level - band_start) / float(span)
	var base_score := lerpf(float(floor_score), float(ceiling_score), progress)
	var difficulty_score := clampi(int(round(base_score + _sawtooth_offset(level))), floor_score, ceiling_score)

	var world := int((level - 1) / WORLD_SIZE) + 1
	var level_in_world := ((level - 1) % WORLD_SIZE) + 1
	var chapter_global := int((level - 1) / CHAPTER_SIZE) + 1
	var chapter_in_world := int((level_in_world - 1) / CHAPTER_SIZE) + 1
	var milestone := milestone_type(level)
	var horizon := planning_horizon(level)
	var tier := piece_tier(level)
	var occupancy := initial_occupancy(level)
	var target_lines := clampi(2 + int(round(float(difficulty_score) / 9.0)), 2, 14)
	if milestone in ["mini_boss", "boss", "world_finale", "mastery", "finale"]:
		target_lines += 1
	var target_score := 80 + target_lines * 125 + difficulty_score * 10
	var par := maxi(14, target_lines * 2 + horizon + 4)
	var move_limited := is_move_limited(level)
	var move_limit := par + (7 if level <= 2000 else (5 if level <= 7500 else 3)) if move_limited else -1

	return {
		"level_id": level,
		"seed": deterministic_seed(level),
		"generator_version": GENERATOR_VERSION,
		"board_size": BOARD_SIZE,
		"world": world,
		"level_in_world": level_in_world,
		"chapter_global": chapter_global,
		"chapter_in_world": chapter_in_world,
		"milestone": milestone,
		"difficulty_score": difficulty_score,
		"difficulty_floor": floor_score,
		"difficulty_ceiling": ceiling_score,
		"difficulty_class": difficulty_class(difficulty_score, milestone),
		"piece_tier": tier,
		"planning_horizon": horizon,
		"initial_occupancy": occupancy,
		"target_lines": target_lines,
		"target_score": target_score,
		"par": par,
		"move_limited": move_limited,
		"move_limit": move_limit,
		"objective": objective_family(level),
		"first_attempt_target": first_attempt_target(difficulty_score, milestone),
		"deterministic_trays": true,
		"fixed_orientation": true,
		"booster_required": false,
		"free_rotation": false,
	}

static func deterministic_seed(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL) * 104729 + GENERATOR_VERSION * 8191

static func milestone_type(raw_level: int) -> String:
	var level := clampi(raw_level, 1, MAX_LEVEL)
	if level == MAX_LEVEL:
		return "finale"
	if level % 1000 == 0:
		return "mastery"
	if level % 500 == 0:
		return "world_finale"
	if level % 100 == 0:
		return "boss"
	if level % 50 == 0:
		return "mini_boss"
	if level % 25 == 0:
		return "hard_challenge"
	if level % 10 == 0:
		return "challenge"
	return "normal"

static func planning_horizon(level: int) -> int:
	if level <= 100: return 1
	if level <= 500: return 2
	if level <= 1500: return 3
	if level <= 3000: return 4
	if level <= 5000: return 5
	if level <= 7500: return 7
	if level <= 9000: return 8
	if level < 10000: return 10
	return 12

static func piece_tier(level: int) -> int:
	if level <= 100: return 1
	if level <= 500: return 2
	if level <= 2000: return 3
	if level <= 5000: return 4
	if level <= 7500: return 5
	return 6

static func initial_occupancy(level: int) -> float:
	if level <= 50:
		return lerpf(0.0, 0.05, float(level - 1) / 49.0)
	if level <= 500:
		return lerpf(0.05, 0.15, float(level - 51) / 449.0)
	if level <= 2000:
		return lerpf(0.10, 0.25, float(level - 501) / 1499.0)
	if level <= 5000:
		return lerpf(0.15, 0.30, float(level - 2001) / 2999.0)
	if level <= 7500:
		return lerpf(0.20, 0.35, float(level - 5001) / 2499.0)
	return lerpf(0.20, 0.40, float(level - 7501) / 2499.0)

static func objective_family(level: int) -> String:
	if level < 10: return "score"
	if level < 25: return "clear_lines"
	if level < 40: return "clear_columns"
	if level < 75: return "row_column"
	if level < 100: return "double_clear"
	if level < 150: return "combo"
	if level < 250: return "limited_moves"
	if level < 400: return "marked_cells"
	if level < 600: return "designated_rows"
	if level < 1000: return "crates"
	if level < 1500: return "ice"
	if level < 2000: return "layered_obstacle"
	if level < 2500: return "preserve_cells"
	if level < 4000: return "dual_objective"
	if level < 6000: return "triple_objective"
	return "advanced_conditional"

static func is_move_limited(level: int) -> bool:
	var rate := 10
	if level > 500: rate = 20
	if level > 2000: rate = 25
	if level > 5000: rate = 30
	if level > 7500: rate = 35
	var roll := posmod(level * 73 + int((level - 1) / WORLD_SIZE) * 19, 100)
	return roll < rate or milestone_type(level) in ["boss", "world_finale", "mastery", "finale"]

static func first_attempt_target(score: int, milestone: String) -> Vector2:
	if milestone in ["boss", "mastery", "finale"]:
		return Vector2(0.05, 0.20)
	if score < 25: return Vector2(0.80, 0.95)
	if score < 50: return Vector2(0.65, 0.80)
	if score < 65: return Vector2(0.45, 0.65)
	if score < 80: return Vector2(0.30, 0.50)
	if score < 90: return Vector2(0.18, 0.35)
	return Vector2(0.08, 0.20)

static func difficulty_class(score: int, milestone: String = "normal") -> String:
	if milestone == "finale": return "finale"
	if milestone in ["boss", "mastery"] and score >= 70: return "boss"
	if score < 35: return "tutorial"
	if score < 50: return "normal"
	if score < 65: return "hard"
	if score < 75: return "very_hard"
	if score < 84: return "expert"
	if score < 94: return "extreme"
	return "grandmaster"

static func _band_for(level: int) -> Array:
	for band in DIFFICULTY_BANDS:
		if level >= int(band[0]) and level <= int(band[1]):
			return band
	return DIFFICULTY_BANDS.back()

static func _sawtooth_offset(level: int) -> float:
	var slot := ((level - 1) % 100) + 1
	if slot <= 42: return -4.0
	if slot <= 70: return -2.0
	if slot <= 87: return 0.0
	if slot <= 95: return 2.0
	if slot <= 99: return 4.0
	return 6.0
