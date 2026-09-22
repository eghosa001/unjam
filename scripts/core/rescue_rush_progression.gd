extends RefCounted
class_name RescueRushProgression

const TOTAL_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100

const OBJECTIVE_RESCUE_ROUTE := "rescue_route"
const OBJECTIVE_FULL_ESCAPE := "full_escape"
const OBJECTIVE_KEY_RESCUE := "key_rescue"
const OBJECTIVE_CHAIN_RESCUE := "chain_rescue"
const OBJECTIVE_PERFECT_RESCUE := "perfect_rescue"
const OBJECTIVE_BOMB_ROUTE := "bomb_route"
const OBJECTIVE_GATE_RUN := "gate_run"

static func profile(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, TOTAL_LEVELS)
	var world := int((n - 1) / LEVELS_PER_WORLD) + 1
	var local := posmod(n - 1, LEVELS_PER_WORLD) + 1
	var role := _level_role(n, local)
	var difficulty_target := _difficulty_target(n, local, role)
	var piece_range := _piece_range(n)
	var piece_target := _paced_range_target(piece_range, local, role, n, 17)
	var board_size := _board_size(n)
	var dependency_range := _dependency_range(n)
	var dependency_target := _paced_range_target(dependency_range, local, role, n, 7)
	if n <= 10:
		difficulty_target = [10, 16, 22, 30, 36, 42, 48, 54, 58, 62][n - 1]
		piece_target = [7, 8, 9, 10, 11, 11, 12, 12, 13, 14][n - 1]
		dependency_target = [2, 2, 3, 3, 3, 4, 4, 4, 4, 4][n - 1]
	var frontier_range := _frontier_range(n)
	var objective := _objective_for_level(n, local)
	var mechanic_count := _mechanic_count(n, difficulty_target)
	var mistake_limit := _mistake_limit(n, role)
	var action_budget := maxi(2, dependency_target + 2 + int(float(piece_target) * 0.16))
	if role in ["recovery", "learn", "practice"]:
		action_budget += 2
	return {
		"level": n,
		"world": world,
		"local_level": local,
		"level_role": role,
		"retention_role": role,
		"milestone": _milestone_name(local),
		"first_attempt_target": _first_attempt_target(role),
		"difficulty_target": difficulty_target,
		"difficulty_label": _difficulty_label(difficulty_target, role),
		"board_size": board_size,
		"piece_target": mini(piece_target, board_size * board_size - 1),
		"dependency_target": dependency_target,
		"frontier_min": int(frontier_range[0]),
		"frontier_max": int(frontier_range[1]),
		"mechanic_count": mechanic_count,
		"mechanics": _mechanics_for_level(n, mechanic_count),
		"objective": objective,
		"mistake_limit": mistake_limit,
		"action_budget": action_budget,
		"required_chain": clampi(2 + int(difficulty_target / 25), 2, 5),
	}

static func _difficulty_target(n: int, local: int, role: String) -> int:
	var band := _difficulty_band(n)
	var start_level := int((n - 1) / 1000) * 1000 + 1
	var end_level := mini(start_level + 999, TOTAL_LEVELS)
	var progress := 0.0 if end_level == start_level else float(n - start_level) / float(end_level - start_level)
	var score := int(round(lerpf(float(band[0]), float(band[1]), progress)))
	match role:
		"tutorial": score -= 6
		"recovery": score -= 6
		"confidence": score -= 4
		"learn": score -= 6
		"practice": score -= 4
		"build": score -= 1
		"challenge": score += 3
		"stretch": score += 5
		"hard": score += 4
		"very_hard": score += 6
		"expert": score += 7
		"peak": score += 7
		"world_boss": score += 10
	return clampi(score, int(band[0]), 99)

static func _difficulty_band(n: int) -> Array[int]:
	if n <= 1000: return [10, 60]
	if n <= 2000: return [48, 67]
	if n <= 3000: return [55, 72]
	if n <= 4000: return [60, 77]
	if n <= 5000: return [65, 81]
	if n <= 6000: return [69, 85]
	if n <= 7000: return [73, 88]
	if n <= 8000: return [77, 91]
	if n <= 9000: return [81, 94]
	return [85, 99]

static func _board_size(n: int) -> int:
	if n <= 1000:
		return 7
	if n <= 2000:
		return 7 if posmod(n, 4) == 0 else 8
	return 8

static func _piece_range(n: int) -> Array[int]:
	if n <= 50: return [7, 14]
	if n <= 200: return [10, 18]
	if n <= 500: return [14, 22]
	if n <= 1000: return [18, 28]
	if n <= 2000: return [22, 34]
	if n <= 3500: return [28, 38]
	if n <= 5000: return [32, 42]
	if n <= 7000: return [36, 46]
	if n <= 9000: return [40, 50]
	return [42, 54]

static func _dependency_range(n: int) -> Array[int]:
	if n <= 500: return [2, 4]
	if n <= 2000: return [5, 10]
	if n <= 5000: return [10, 18]
	if n <= 8000: return [18, 25]
	if n <= 9500: return [22, 30]
	return [28, 35]

static func _frontier_range(n: int) -> Array[int]:
	if n <= 100: return [4, 9]
	if n <= 1000: return [3, 7]
	if n <= 5000: return [3, 6]
	return [2, 5]

static func _mechanic_count(n: int, score: int) -> int:
	if _mechanic_intro_age(n) in [0, 1, 2]:
		return 1
	if n <= 200: return 0
	if n <= 500: return 1
	if n <= 1000: return 1 if score < 58 else 2
	if n <= 3000: return 1 if score < 68 else 2
	if n <= 7000: return 2
	return 3 if score >= 86 else 2

static func _mechanics_for_level(n: int, count: int) -> Array[String]:
	var intro := _mechanic_intro(n)
	if not intro.is_empty() and _mechanic_intro_age(n) in [0, 1, 2]:
		return [intro]
	var unlocked: Array[String] = []
	if n >= 201: unlocked.append("rotate")
	if n >= 501: unlocked.append("gate")
	if n >= 1001: unlocked.append("linked")
	if n >= 2001: unlocked.append("bomb")
	if unlocked.is_empty() or count <= 0:
		return []
	var result: Array[String] = []
	var start := posmod(n * 13, unlocked.size())
	for i in range(mini(count, unlocked.size())):
		result.append(unlocked[(start + i) % unlocked.size()])
	if n >= 7000 and "gate" in unlocked and "gate" not in result:
		result[0] = "gate"
	return result

static func _mechanic_intro(n: int) -> String:
	if n in [201, 202, 203]: return "rotate"
	if n in [501, 502, 503]: return "gate"
	if n in [1001, 1002, 1003]: return "linked"
	if n in [2001, 2002, 2003]: return "bomb"
	return ""

static func _mechanic_intro_age(n: int) -> int:
	for start in [201, 501, 1001, 2001]:
		var age := n - int(start)
		if age >= 0 and age <= 2:
			return age
	return -1

static func _objective_for_level(n: int, local: int) -> String:
	if _mechanic_intro_age(n) in [0, 1, 2]:
		return OBJECTIVE_RESCUE_ROUTE
	if n <= 500:
		return OBJECTIVE_RESCUE_ROUTE
	if local == 100:
		return OBJECTIVE_RESCUE_ROUTE
	if n <= 5000:
		return OBJECTIVE_FULL_ESCAPE if local in [25, 75] and n >= 1200 else OBJECTIVE_RESCUE_ROUTE
	var options: Array[String] = [
		OBJECTIVE_RESCUE_ROUTE,
		OBJECTIVE_FULL_ESCAPE,
		OBJECTIVE_KEY_RESCUE,
		OBJECTIVE_CHAIN_RESCUE,
		OBJECTIVE_PERFECT_RESCUE,
		OBJECTIVE_BOMB_ROUTE,
		OBJECTIVE_GATE_RUN,
	]
	var objective := options[posmod(int(n / 25) + local, options.size())]
	if objective == OBJECTIVE_KEY_RESCUE and n < 501:
		return OBJECTIVE_RESCUE_ROUTE
	if objective == OBJECTIVE_BOMB_ROUTE and n < 2001:
		return OBJECTIVE_RESCUE_ROUTE
	return objective

static func _mistake_limit(n: int, role: String) -> int:
	if n <= 20: return 0
	if role in ["learn", "practice", "recovery"]:
		return 5 if n <= 1000 else 4
	if n <= 100: return 5
	if n <= 500: return 4
	if role == "world_boss" and n >= 3000: return 2
	return 3

static func _level_role(n: int, local: int) -> String:
	if n <= 10:
		return ["tutorial", "tutorial", "tutorial", "build", "challenge", "build", "challenge", "stretch", "build", "peak"][n - 1]
	var intro_age := _mechanic_intro_age(n)
	if intro_age == 0:
		return "learn"
	if intro_age in [1, 2]:
		return "practice"
	if local == 100: return "world_boss"
	if local == 25: return "challenge"
	if local == 50: return "peak"
	if local == 75: return "peak"
	if local in [26, 51, 76] or posmod(n - 1, 100) == 0:
		return "recovery"
	var slot := posmod(local - 1, 10) + 1
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

static func _paced_range_target(bounds: Array[int], local: int, role: String, n: int, salt: int) -> int:
	var minimum := int(bounds[0])
	var maximum := int(bounds[1])
	if minimum >= maximum:
		return minimum
	var progress := float(local - 1) / float(LEVELS_PER_WORLD - 1)
	var center := int(round(lerpf(float(minimum), float(maximum), progress)))
	var jitter := posmod(n * salt + 11, 3) - 1
	var modifier := 0
	match role:
		"tutorial", "recovery", "learn": modifier = -2
		"confidence", "practice": modifier = -1
		"stretch", "challenge": modifier = 1
		"peak", "world_boss": modifier = 2
	return clampi(center + jitter + modifier, minimum, maximum)

static func _first_attempt_target(role: String) -> Vector2:
	match role:
		"tutorial", "confidence", "learn": return Vector2(0.84, 0.96)
		"recovery", "practice": return Vector2(0.74, 0.90)
		"build": return Vector2(0.60, 0.78)
		"challenge": return Vector2(0.44, 0.62)
		"stretch": return Vector2(0.34, 0.52)
		"peak": return Vector2(0.28, 0.45)
		"world_boss": return Vector2(0.20, 0.36)
		_: return Vector2(0.55, 0.75)

static func _milestone_name(local: int) -> String:
	if local == 25: return "challenge"
	if local == 50: return "mini_boss"
	if local == 75: return "major_challenge"
	if local == 100: return "world_finale"
	return ""

static func _difficulty_label(score: int, role: String) -> String:
	if role == "world_boss": return "boss"
	if role == "tutorial": return "tutorial"
	if score < 30: return "easy"
	if score < 55: return "medium"
	if score < 75: return "hard"
	if score < 90: return "expert"
	return "grandmaster"

static func canonical_signature(level: Dictionary) -> String:
	var size := int(level.get("width", 0))
	if size <= 0 or int(level.get("height", 0)) != size:
		return ""
	var rescue_raw: Array = level.get("rescue", [])
	if rescue_raw.size() != 2:
		return ""
	var variants: Array[String] = []
	for transform in range(8):
		var parts: PackedStringArray = []
		var rescue := _transform_point(Vector2i(int(rescue_raw[0]), int(rescue_raw[1])), size, transform)
		parts.append("R:%d:%d" % [rescue.x, rescue.y])
		for raw in level.get("pieces", []):
			if not raw is Dictionary:
				continue
			var p: Dictionary = raw
			var pos := _transform_point(Vector2i(int(p.get("x", -1)), int(p.get("y", -1))), size, transform)
			var dir := _transform_direction(String(p.get("direction", "right")), transform)
			parts.append("%s:%d:%d:%s:%s:%s" % [
				String(p.get("type", "normal")), pos.x, pos.y, dir,
				String(p.get("key_id", "")), String(p.get("link_id", ""))
			])
		parts.sort()
		variants.append("|".join(parts))
	variants.sort()
	return variants[0]

static func _transform_point(pos: Vector2i, size: int, transform: int) -> Vector2i:
	var p := pos
	var mirror := transform >= 4
	var turns := transform % 4
	if mirror:
		p.x = size - 1 - p.x
	for _i in range(turns):
		p = Vector2i(size - 1 - p.y, p.x)
	return p

static func _transform_direction(direction: String, transform: int) -> String:
	var v := _direction_vector(direction)
	if transform >= 4:
		v.x = -v.x
	for _i in range(transform % 4):
		v = Vector2i(-v.y, v.x)
	return _direction_name(v)

static func _direction_vector(direction: String) -> Vector2i:
	match direction:
		"up": return Vector2i.UP
		"down": return Vector2i.DOWN
		"left": return Vector2i.LEFT
		_: return Vector2i.RIGHT

static func _direction_name(direction: Vector2i) -> String:
	if direction == Vector2i.UP: return "up"
	if direction == Vector2i.DOWN: return "down"
	if direction == Vector2i.LEFT: return "left"
	return "right"
