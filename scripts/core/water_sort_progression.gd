extends RefCounted
class_name WaterSortProgression

const MAX_LEVEL := 10000
const WORLD_SIZE := 500
const WORLD_COUNT := 20
const CAPACITY := 4
const GENERATOR_VERSION := 4

const SCORE_BANDS := [
	[15, 55], [45, 60], [50, 63], [54, 66], [57, 69],
	[60, 72], [62, 74], [64, 76], [66, 78], [68, 80],
	[70, 82], [72, 84], [74, 86], [75, 87], [76, 88],
	[78, 90], [80, 91], [81, 92], [83, 94], [86, 98]
]

const MOVE_BANDS := [
	[6, 30], [24, 36], [28, 40], [30, 42], [32, 46],
	[34, 48], [36, 50], [38, 52], [40, 54], [42, 56],
	[44, 58], [45, 60], [46, 62], [47, 64], [48, 66],
	[49, 68], [50, 70], [52, 72], [54, 74], [56, 80]
]

const COLOR_BANDS := [
	[3, 8], [7, 9], [8, 10], [9, 10], [9, 11],
	[10, 11], [10, 12], [10, 12], [11, 12], [11, 12],
	[12, 12], [12, 12], [12, 12], [12, 12], [12, 12],
	[12, 12], [12, 12], [12, 12], [12, 12], [12, 12]
]

static func profile(raw_level: int) -> Dictionary:
	var level := clampi(raw_level, 1, MAX_LEVEL)
	var band := clampi(int((level - 1) / WORLD_SIZE), 0, WORLD_COUNT - 1)
	var world := band + 1
	var world_level := posmod(level - 1, WORLD_SIZE) + 1
	var retention_role := _retention_role(level)
	var rank := _difficulty_rank(level)
	var milestone := milestone_kind(level)
	if milestone == "boss":
		rank = maxi(rank, 4)
	elif milestone in ["world_finale", "mastery", "finale"]:
		rank = 5
	elif milestone == "mini_boss":
		rank = maxi(rank, 3)
	elif milestone == "hard":
		rank = maxi(rank, 2)
	elif milestone == "challenge":
		rank = maxi(rank, 1)

	var score_band: Array = SCORE_BANDS[band]
	var move_band: Array = MOVE_BANDS[band]
	var score_fraction := _rank_fraction(rank)
	var local_progress := float(world_level - 1) / float(maxi(1, WORLD_SIZE - 1))
	var target_score := roundi(lerpf(float(score_band[0]), float(score_band[1]), clampf(score_fraction + local_progress * 0.06, 0.0, 1.0)))
	var target_moves := roundi(lerpf(float(move_band[0]), float(move_band[1]), clampf(score_fraction + local_progress * 0.04, 0.0, 1.0)))

	if level <= 10:
		# Teach one idea at a time. Keep the move target rising steadily without
		# making level 10 harder than the first post-tutorial boards.
		target_score = 15 + (level - 1)
		target_moves = [6, 7, 8, 9, 10, 11, 12, 13, 15, 16][level - 1]
	elif level <= 100:
		# Early campaign progression should feel like a controlled ramp with small
		# relief levels, not the former 24 -> 18 -> 13 move-budget cliff. Difficulty
		# rank still creates meaningful challenge variation, but within a bounded arc.
		var early_progress: float = float(level - 11) / 89.0
		var early_base: int = roundi(lerpf(16.0, 26.0, early_progress))
		var early_bonus: int = int([0, 2, 4, 6, 8, 10][clampi(rank, 0, 5)])
		target_moves = clampi(early_base + early_bonus, 16, 36)

	if level == MAX_LEVEL:
		target_score = 98
		target_moves = 80

	var colors := _colors_for_level(level, band, local_progress)
	var empty_bottles := _empty_bottles_for_level(level, retention_role)
	var three_star_limit := maxi(target_moves, 6)
	var two_star_limit := three_star_limit + maxi(5, ceili(float(three_star_limit) * 0.15))
	var scramble_steps := clampi(target_moves, 4, 80)
	if level <= 10:
		scramble_steps = clampi(3 + level, 4, 14)
	elif retention_role == "recovery":
		scramble_steps = maxi(4, roundi(float(scramble_steps) * 0.84))
	elif retention_role in ["confidence", "learn", "practice"]:
		scramble_steps = maxi(4, roundi(float(scramble_steps) * 0.92))
	elif retention_role == "peak":
		scramble_steps = mini(80, scramble_steps + 3)

	var flags: Array[String] = []
	if empty_bottles == 1:
		flags.append("space_pressure")
	if level >= 4000 and level % 10 == 0:
		flags.append("efficiency_challenge")
	if milestone != "normal":
		flags.append(milestone)
	if level == MAX_LEVEL:
		flags.append("final_mastery")

	return {
		"level_id": level,
		"seed": level * 104729 + GENERATOR_VERSION * 8191,
		"generator_version": GENERATOR_VERSION,
		"world": world,
		"world_level": world_level,
		"colors": colors,
		"capacity": CAPACITY,
		"empty_bottles": empty_bottles,
		"difficulty_floor": int(score_band[0]),
		"difficulty_ceiling": int(score_band[1]),
		"target_difficulty": target_score,
		"difficulty_label": _difficulty_label(rank, level),
		"milestone": milestone,
		"retention_role": retention_role,
		"first_attempt_target": _first_attempt_target(retention_role, rank, milestone),
		"target_moves_min": int(move_band[0]),
		"target_moves_max": int(move_band[1]),
		"target_moves": target_moves,
		"three_star_limit": three_star_limit,
		"two_star_limit": two_star_limit,
		"scramble_steps": scramble_steps,
		"mechanic_flags": flags,
		"hidden_information": false
	}

static func milestone_kind(level: int) -> String:
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
		return "hard"
	if level % 10 == 0:
		return "challenge"
	return "normal"

static func score_board(tubes: Array, proof_moves: int) -> Dictionary:
	var color_count := 0
	var color_tubes := {}
	var color_breaks := 0
	var burial_total := 0.0
	var empty_count := 0
	var legal_moves := 0
	var empty_target_moves := 0

	for tube_index in range(tubes.size()):
		var tube: Array = tubes[tube_index]
		if tube.is_empty():
			empty_count += 1
			continue
		for i in range(tube.size()):
			var color := int(tube[i])
			color_count = maxi(color_count, color + 1)
			if not color_tubes.has(color):
				color_tubes[color] = {}
			(color_tubes[color] as Dictionary)[str(tube_index)] = true
			if i > 0 and int(tube[i]) != int(tube[i - 1]):
				color_breaks += 1
			burial_total += float(tube.size() - 1 - i)

	for from_idx in range(tubes.size()):
		var source: Array = tubes[from_idx]
		if source.is_empty():
			continue
		for to_idx in range(tubes.size()):
			if from_idx == to_idx:
				continue
			var target: Array = tubes[to_idx]
			if target.size() >= CAPACITY:
				continue
			if not target.is_empty() and int(target.back()) != int(source.back()):
				continue
			legal_moves += 1
			if target.is_empty():
				empty_target_moves += 1

	var fragmentation := 0
	for locations in color_tubes.values():
		fragmentation += maxi(0, (locations as Dictionary).size() - 1)

	var safe_colors := maxi(1, color_count)
	var break_norm := clampf(float(color_breaks) / float(safe_colors * 3), 0.0, 1.0)
	var fragmentation_norm := clampf(float(fragmentation) / float(safe_colors * 3), 0.0, 1.0)
	var solution_norm := clampf(float(proof_moves) / 70.0, 0.0, 1.0)
	var trap_ratio := 0.0 if legal_moves <= 0 else clampf(float(empty_target_moves) / float(legal_moves), 0.0, 1.0)
	var empty_pressure := 1.0 if empty_count <= 1 else (0.35 if empty_count == 2 else 0.10)
	var ambiguity := clampf(float(maxi(0, legal_moves - 2)) / 10.0, 0.0, 1.0)
	var burial_norm := clampf(burial_total / float(maxi(1, safe_colors * CAPACITY * 3)), 0.0, 1.0)
	var search_proxy := clampf(break_norm * 0.55 + fragmentation_norm * 0.45, 0.0, 1.0)

	var difficulty := roundi(
		solution_norm * 24.0 +
		search_proxy * 22.0 +
		fragmentation_norm * 16.0 +
		trap_ratio * 14.0 +
		empty_pressure * 10.0 +
		ambiguity * 8.0 +
		burial_norm * 6.0
	)

	var signature := canonical_signature(tubes)
	return {
		"difficulty_score": clampi(difficulty, 0, 100),
		"proof_moves": proof_moves,
		"color_breaks": color_breaks,
		"fragmentation": fragmentation,
		"legal_moves": legal_moves,
		"trap_ratio": trap_ratio,
		"empty_pressure": empty_pressure,
		"branching_score": ambiguity,
		"burial_score": burial_norm,
		"canonical_signature": signature,
		"level_hash": signature.sha256_text()
	}

static func canonical_signature(tubes: Array) -> String:
	# Normalize colour names by first appearance, then sort bottle encodings.
	# This catches colour-renamed duplicates and the majority of bottle-order
	# duplicates without a factorial graph-isomorphism pass on the phone.
	var color_map := {}
	var next_color := 0
	var encoded: Array[String] = []
	for tube_value in tubes:
		var tube: Array = tube_value
		var values := PackedStringArray()
		for raw in tube:
			var color := int(raw)
			if not color_map.has(color):
				color_map[color] = next_color
				next_color += 1
			values.append(str(int(color_map[color])))
		encoded.append(",".join(values))
	encoded.sort()
	return "|".join(encoded)

static func _colors_for_level(level: int, band: int, local_progress: float) -> int:
	if level <= 2:
		return 3
	if level <= 5:
		return 4
	if level <= 10:
		return 4 + (1 if level >= 8 else 0)
	if level <= 20:
		return 5
	if level <= 40:
		return 5 + (1 if _unit_hash(level, 17) > 0.50 else 0)
	if level <= 60:
		return 6
	if level <= 100:
		return 6 + (1 if _unit_hash(level, 19) > 0.45 else 0)
	if level <= 200:
		return 7 + (1 if _unit_hash(level, 23) > 0.55 else 0)
	if level <= 500:
		return 7 + (1 if _unit_hash(level, 29) > 0.40 else 0)

	var bounds: Array = COLOR_BANDS[band]
	var minimum := int(bounds[0])
	var maximum := int(bounds[1])
	if minimum == maximum:
		return minimum
	var spread := maximum - minimum
	var value := minimum + roundi(local_progress * float(spread))
	if _unit_hash(level, 31) > 0.78:
		value += 1
	return clampi(value, minimum, maximum)

static func _empty_bottles_for_level(level: int, retention_role: String) -> int:
	if level <= 1000:
		return 2
	if level == MAX_LEVEL:
		return 1
	# Recovery and mechanic-learning levels deliberately restore workspace.
	# This prevents a hard level from being followed by another hidden pressure spike.
	if retention_role in ["recovery", "learn", "practice"]:
		return 2
	var probability := 0.05
	if level <= 2500:
		probability = 0.05
	elif level <= 5000:
		probability = 0.10
	elif level <= 7500:
		probability = 0.18
	elif level <= 9000:
		probability = 0.23
	else:
		probability = 0.30
	if retention_role in ["stretch", "peak"]:
		probability = minf(0.45, probability + 0.08)
	if milestone_kind(level) in ["world_finale", "mastery", "finale"]:
		probability = minf(0.45, probability + 0.10)
	return 1 if _unit_hash(level, 47) < probability else 2

static func _difficulty_rank(level: int) -> int:
	if level <= 2:
		return 0
	var role := _retention_role(level)
	match role:
		"tutorial", "recovery", "confidence", "learn":
			return 0
		"practice", "build":
			return 1
		"challenge":
			return 2
		"stretch":
			return 3
		"peak":
			return 4
		_:
			return 1

static func _retention_role(level: int) -> String:
	if level <= 10:
		return ["tutorial", "tutorial", "learn", "confidence", "build", "recovery", "build", "learn", "challenge", "peak"][level - 1]
	if _is_color_intro(level):
		return "learn"
	if _is_color_intro(level - 1) or _is_color_intro(level - 2):
		return "practice"
	if milestone_kind(level - 1) in ["hard", "mini_boss", "boss", "world_finale", "mastery"]:
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

static func _is_color_intro(level: int) -> bool:
	return level in [21, 41, 61, 101, 201, 501, 1001, 2501, 5001, 7501]

static func _first_attempt_target(role: String, rank: int, milestone: String) -> Vector2:
	if milestone == "finale":
		return Vector2(0.18, 0.30)
	if milestone in ["mastery", "world_finale", "boss"]:
		return Vector2(0.24, 0.40)
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
			return Vector2(0.28, 0.46)
		_:
			return Vector2(0.55 - float(rank) * 0.04, 0.75 - float(rank) * 0.03)

static func _rank_fraction(rank: int) -> float:
	match rank:
		0: return 0.28
		1: return 0.48
		2: return 0.67
		3: return 0.82
		4: return 0.94
		_: return 1.0

static func _difficulty_label(rank: int, level: int) -> String:
	if level <= 10:
		return "tutorial"
	match rank:
		0: return "normal-hard"
		1: return "hard"
		2: return "very hard"
		3: return "expert"
		4: return "extreme"
		_: return "boss"

static func _unit_hash(level: int, salt: int) -> float:
	var value := posmod(level * 1103515245 + salt * 12345 + GENERATOR_VERSION * 2654435761, 2147483647)
	return float(value) / 2147483647.0
