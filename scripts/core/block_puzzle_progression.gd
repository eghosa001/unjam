class_name BlockPuzzleProgression
extends RefCounted

const MAX_LEVEL := 10000
const BOARD_SIZE := 8
const WORLD_SIZE := 500
const WORLD_COUNT := 20
const CHAPTER_SIZE := 50
const GENERATOR_VERSION := 2

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
	var pace_role := retention_role(level)
	var objective := objective_family(level)
	var intro_age := objective_introduction_age(level)
	var intro_modifier := -6.0 if intro_age == 0 else (-4.0 if intro_age in [1, 2] else 0.0)
	var difficulty_score := clampi(
		int(round(base_score + _pacing_offset(level, pace_role) + intro_modifier)),
		floor_score,
		ceiling_score
	)
	if level <= 10:
		difficulty_score = [12, 18, 24, 32, 38, 43, 47, 51, 54, 55][level - 1]
	elif level <= 20:
		# Keep the level-10 -> 11 handoff close to the established challenge band.
		# Recovery/practice levels soften pressure slightly; they never reset to tutorial difficulty.
		difficulty_score = [52, 53, 55, 57, 60, 54, 58, 62, 56, 64][level - 11]

	var world := int((level - 1) / WORLD_SIZE) + 1
	var level_in_world := ((level - 1) % WORLD_SIZE) + 1
	var chapter_global := int((level - 1) / CHAPTER_SIZE) + 1
	var chapter_in_world := int((level_in_world - 1) / CHAPTER_SIZE) + 1
	var milestone := milestone_type(level)
	var horizon := planning_horizon(level)
	var tier := piece_tier(level)
	var occupancy := initial_occupancy(level)
	if pace_role in ["recovery", "confidence", "learn"]:
		horizon = maxi(1, horizon - 1)
		occupancy = maxf(0.0, occupancy - 0.035)
	elif pace_role == "practice":
		occupancy = maxf(0.0, occupancy - 0.02)
	var target_lines := clampi(2 + int(round(float(difficulty_score) / 9.0)), 2, 14)
	if pace_role in ["recovery", "confidence", "learn"]:
		target_lines = maxi(2, target_lines - 1)
	elif pace_role == "peak":
		target_lines = mini(14, target_lines + 1)
	if milestone in ["mini_boss", "boss", "world_finale", "mastery", "finale"]:
		target_lines += 1
	var target_score := 80 + target_lines * 125 + difficulty_score * 10
	var par := maxi(14, target_lines * 2 + horizon + 4)
	var move_limited := is_move_limited(level, pace_role)
	var move_limit := par + (8 if pace_role in ["learn", "practice"] else (7 if level <= 2000 else (5 if level <= 7500 else 3))) if move_limited else -1

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
		"retention_role": pace_role,
		"objective_intro_age": intro_age,
		"difficulty_score": difficulty_score,
		"difficulty_floor": floor_score,
		"difficulty_ceiling": ceiling_score,
		"difficulty_class": difficulty_class(difficulty_score, milestone, pace_role),
		"piece_tier": tier,
		"planning_horizon": horizon,
		"initial_occupancy": occupancy,
		"target_lines": target_lines,
		"target_score": target_score,
		"par": par,
		"move_limited": move_limited,
		"move_limit": move_limit,
		"objective": objective,
		"first_attempt_target": first_attempt_target(difficulty_score, milestone, pace_role),
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
	# New objective families begin on recovery levels immediately after major
	# milestones, so players learn one new rule before it is combined with pressure.
	if level < 10: return "score"
	if level < 26: return "clear_lines"
	if level < 41: return "clear_columns"
	if level < 76: return "row_column"
	if level < 101: return "double_clear"
	if level < 151: return "combo"
	if level < 251: return "limited_moves"
	if level < 401: return "marked_cells"
	if level < 601: return "designated_rows"
	if level < 1001: return "crates"
	if level < 1401: return "ice"
	if level < 1751: return "locks"
	if level < 2101: return "steel"
	if level < 2401: return "layered_obstacle"
	if level < 2501: return "preserve_cells"
	if level < 4001: return "dual_objective"
	if level < 6001: return "triple_objective"
	return "advanced_conditional"

static func objective_introduction_age(level: int) -> int:
	var starts := [10, 26, 41, 76, 101, 151, 251, 401, 601, 1001, 1401, 1751, 2101, 2401, 2501, 4001, 6001]
	for start in starts:
		var age := level - int(start)
		if age >= 0 and age <= 2:
			return age
	return -1

static func retention_role(level: int) -> String:
	if level <= 10:
		return ["tutorial", "tutorial", "tutorial", "build", "challenge", "build", "challenge", "stretch", "build", "learn"][level - 1]
	var intro_age := objective_introduction_age(level)
	if intro_age == 0:
		return "learn"
	if intro_age in [1, 2]:
		return "practice"
	var previous := milestone_type(level - 1)
	if previous in ["hard_challenge", "mini_boss", "boss", "world_finale", "mastery"]:
		return "recovery"
	var slot := posmod(level - 1, 10) + 1
	match slot:
		1: return "recovery"
		2: return "confidence"
		3, 4: return "build"
		5: return "challenge"
		6: return "recovery"
		7: return "build"
		8: return "stretch"
		9: return "recovery"
		_: return "peak"

static func is_move_limited(level: int, role: String = "") -> bool:
	var milestone := milestone_type(level)
	if role.is_empty():
		role = retention_role(level)
	if role in ["recovery", "confidence", "learn", "practice"] and milestone not in ["boss", "world_finale", "mastery", "finale"]:
		return false
	var rate := 10
	if level > 500: rate = 18
	if level > 2000: rate = 23
	if level > 5000: rate = 28
	if level > 7500: rate = 32
	if role in ["stretch", "peak"]:
		rate += 8
	var roll := posmod(level * 73 + int((level - 1) / WORLD_SIZE) * 19, 100)
	return roll < rate or milestone in ["boss", "world_finale", "mastery", "finale"]

static func first_attempt_target(score: int, milestone: String, role: String = "") -> Vector2:
	if milestone == "finale":
		return Vector2(0.16, 0.30)
	if milestone in ["mastery", "world_finale", "boss"]:
		return Vector2(0.22, 0.38)
	if role.is_empty():
		role = "build"
	match role:
		"tutorial", "confidence", "learn":
			return Vector2(0.82, 0.95)
		"recovery", "practice":
			return Vector2(0.72, 0.88)
		"build":
			return Vector2(0.60, 0.78)
		"challenge":
			return Vector2(0.44, 0.62)
		"stretch":
			return Vector2(0.34, 0.52)
		"peak":
			return Vector2(0.28, 0.45)
	if score < 50: return Vector2(0.65, 0.80)
	if score < 70: return Vector2(0.48, 0.66)
	return Vector2(0.30, 0.48)

static func difficulty_class(score: int, milestone: String = "normal", role: String = "") -> String:
	if milestone == "finale": return "finale"
	if milestone in ["boss", "mastery"] and score >= 70: return "boss"
	if role == "tutorial": return "tutorial"
	if score < 35: return "normal"
	if score < 50: return "hard"
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

static func _pacing_offset(level: int, role: String) -> float:
	match role:
		"tutorial": return -6.0
		"recovery": return -6.0
		"confidence": return -4.0
		"learn": return -5.0
		"practice": return -3.0
		"build": return -1.0
		"challenge": return 2.0
		"stretch": return 4.0
		"peak": return 6.0
		_: return 0.0
