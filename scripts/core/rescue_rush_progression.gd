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
	var difficulty_target := _difficulty_target(n, local)
	var piece_range := _piece_range(n)
	var piece_span := int(piece_range[1]) - int(piece_range[0])
	var piece_target := int(piece_range[0]) + posmod(n * 17 + world * 11, maxi(1, piece_span + 1))
	var board_size := _board_size(n)
	var dependency_range := _dependency_range(n)
	var dependency_span := int(dependency_range[1]) - int(dependency_range[0])
	var dependency_target := int(dependency_range[0]) + posmod(n * 7 + world * 3, maxi(1, dependency_span + 1))
	var frontier_range := _frontier_range(n)
	var objective := _objective_for_level(n, local)
	var role := _level_role(local)
	var mechanic_count := _mechanic_count(n, difficulty_target)
	var mistake_limit := _mistake_limit(n, role)
	var action_budget := maxi(2, dependency_target + 2 + int(float(piece_target) * 0.16))
	return {
		"level": n,
		"world": world,
		"local_level": local,
		"level_role": role,
		"milestone": _milestone_name(local),
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

static func _difficulty_target(n: int, local: int) -> int:
	var band := _difficulty_band(n)
	var start_level := int((n - 1) / 1000) * 1000 + 1
	var end_level := mini(start_level + 999, TOTAL_LEVELS)
	var progress := 0.0 if end_level == start_level else float(n - start_level) / float(end_level - start_level)
	var score := int(round(lerpf(float(band[0]), float(band[1]), progress)))
	# Rising sawtooth: recovery levels dip, but never back to early-game floors.
	if local in range(1, 16):
		score -= 2
	elif local in range(16, 25):
		score += 1
	elif local == 25:
		score += 4
	elif local in range(45, 50):
		score += 3
	elif local == 50:
		score += 6
	elif local == 75:
		score += 7
	elif local in range(90, 95):
		score += 5
	elif local in range(95, 100):
		score += 7
	elif local == 100:
		score += 10
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
	if n <= 500: return 0
	if n <= 1000: return 1
	if n <= 3000: return 1 if score < 68 else 2
	if n <= 7000: return 2
	return 3 if score >= 86 else 2

static func _mechanics_for_level(n: int, count: int) -> Array[String]:
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
	# Late game should favor the dependency-producing systems.
	if n >= 7000 and "gate" in unlocked and "gate" not in result:
		result[0] = "gate"
	return result

static func _objective_for_level(n: int, local: int) -> String:
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
	if n <= 100: return 5
	if n <= 500: return 4
	if role == "world_boss" and n >= 3000: return 2
	return 3

static func _level_role(local: int) -> String:
	if local <= 15: return "progression"
	if local <= 24: return "rising"
	if local == 25: return "challenge"
	if local <= 44: return "progression"
	if local <= 49: return "hard_run"
	if local == 50: return "mini_boss"
	if local <= 74: return "progression"
	if local == 75: return "major_challenge"
	if local <= 89: return "hard"
	if local <= 94: return "very_hard"
	if local <= 99: return "expert_run"
	return "world_boss"

static func _milestone_name(local: int) -> String:
	if local == 25: return "challenge"
	if local == 50: return "mini_boss"
	if local == 75: return "major_challenge"
	if local == 100: return "world_finale"
	return ""

static func _difficulty_label(score: int, role: String) -> String:
	if role == "world_boss": return "boss"
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
