extends Node

signal meta_changed
signal reward_claimed(kind: String, id: String, coins: int, crowns: int)

const LOGIN_REWARDS := [25, 35, 50, 65, 80, 100, 150]
const DAILY_GOALS := [
	{"id":"play2","title":"PLAY 2 PUZZLES","metric":"levels","target":2,"coins":60,"crowns":0},
	{"id":"stars6","title":"EARN 6 STARS","metric":"stars","target":6,"coins":80,"crowns":0},
	{"id":"daily1","title":"ENTER 1 DAILY CUP","metric":"daily_games","target":1,"coins":75,"crowns":1},
]
const WEEKLY_GOALS := [
	{"id":"play15","title":"PLAY 15 PUZZLES","metric":"levels","target":15,"coins":200,"crowns":2},
	{"id":"stars35","title":"EARN 35 STARS","metric":"stars","target":35,"coins":250,"crowns":3},
	{"id":"daily5","title":"PLAY 5 DAILY CUPS","metric":"daily_games","target":5,"coins":250,"crowns":5},
]
const SEASON_TIERS := [
	{"need":100,"coins":100,"crowns":0},
	{"need":250,"coins":150,"crowns":2},
	{"need":500,"coins":250,"crowns":3},
	{"need":800,"coins":350,"crowns":5},
	{"need":1200,"coins":500,"crowns":10},
]

func _ready() -> void:
	ensure_state()

func ensure_state() -> void:
	var state = SaveManager.data.get("meta_progression", {})
	if not state is Dictionary:
		state = {}
	if not state.get("activity", {}) is Dictionary:
		state["activity"] = {}
	if not state.get("mission_claims", []) is Array:
		state["mission_claims"] = []
	if not state.get("season_claimed", []) is Array:
		state["season_claimed"] = []
	state["login_last_claim"] = String(state.get("login_last_claim", ""))
	state["login_day"] = clampi(int(state.get("login_day", 0)), 0, 7)
	state["season_key"] = String(state.get("season_key", ""))
	state["season_points"] = maxi(0, int(state.get("season_points", 0)))
	_ensure_season_state(state)
	_prune_state(state)
	SaveManager.data["meta_progression"] = state

func record_campaign_complete(game_id: String, stars: int, first_clear: bool) -> void:
	_record_activity(game_id, stars, false, first_clear)

func record_daily_complete(game_id: String, stars: int) -> void:
	_record_activity(game_id, stars, true, true)

func _record_activity(game_id: String, stars: int, daily: bool, first_clear: bool) -> void:
	if game_id not in MultiGameManager.GAME_IDS:
		return
	ensure_state()
	var state: Dictionary = SaveManager.data["meta_progression"]
	var activity: Dictionary = state["activity"]
	var key := _date_key()
	var bucket = activity.get(key, {})
	if not bucket is Dictionary:
		bucket = {}
	bucket["levels"] = maxi(0, int(bucket.get("levels", 0))) + 1
	bucket["stars"] = maxi(0, int(bucket.get("stars", 0))) + clampi(stars, 1, 3)
	if stars >= 3:
		bucket["perfects"] = maxi(0, int(bucket.get("perfects", 0))) + 1
	if daily:
		bucket["daily_games"] = maxi(0, int(bucket.get("daily_games", 0))) + 1
	activity[key] = bucket
	state["activity"] = activity
	_ensure_season_state(state)
	var season_gain := 25 if daily else (10 if first_clear else 3)
	state["season_points"] = maxi(0, int(state.get("season_points", 0))) + season_gain
	_prune_state(state)
	SaveManager.data["meta_progression"] = state
	_persist()
	meta_changed.emit()

func daily_login_info() -> Dictionary:
	ensure_state()
	var state: Dictionary = SaveManager.data["meta_progression"]
	var today := _date_key()
	var last := String(state.get("login_last_claim", ""))
	var claimed := last == today
	var current_day := clampi(int(state.get("login_day", 0)), 0, 7)
	var next_day := current_day
	if not claimed:
		next_day = (current_day % 7) + 1 if _is_previous_day(last, today) else 1
	if next_day <= 0:
		next_day = 1
	return {
		"claimed": claimed,
		"day": current_day if claimed else next_day,
		"reward": LOGIN_REWARDS[(current_day if claimed else next_day) - 1]
	}

func claim_daily_login() -> int:
	var info := daily_login_info()
	if bool(info.get("claimed", false)):
		return 0
	var state: Dictionary = SaveManager.data["meta_progression"]
	var day := clampi(int(info.get("day", 1)), 1, 7)
	var reward := int(LOGIN_REWARDS[day - 1])
	state["login_last_claim"] = _date_key()
	state["login_day"] = day
	SaveManager.data["meta_progression"] = state
	EconomyManager.grant(reward, "daily_login", {"day": day})
	_persist()
	reward_claimed.emit("login", str(day), reward, 0)
	meta_changed.emit()
	return reward

func daily_goals() -> Array:
	return _goal_rows("daily", DAILY_GOALS)

func weekly_goals() -> Array:
	return _goal_rows("weekly", WEEKLY_GOALS)

func _goal_rows(period: String, definitions: Array) -> Array:
	var rows: Array = []
	for raw in definitions:
		var definition: Dictionary = raw
		var progress := _metric_value(period, String(definition.get("metric", "")))
		var target := maxi(1, int(definition.get("target", 1)))
		var id := String(definition.get("id", ""))
		var claimed := _mission_claimed(period, id)
		rows.append({
			"id": id,
			"title": String(definition.get("title", id)),
			"progress": mini(progress, target),
			"target": target,
			"coins": maxi(0, int(definition.get("coins", 0))),
			"crowns": maxi(0, int(definition.get("crowns", 0))),
			"claimed": claimed,
			"claimable": progress >= target and not claimed,
		})
	return rows

func claim_goal(period: String, id: String) -> bool:
	var defs := DAILY_GOALS if period == "daily" else WEEKLY_GOALS
	var found: Dictionary = {}
	for raw in defs:
		var definition: Dictionary = raw
		if String(definition.get("id", "")) == id:
			found = definition
			break
	if found.is_empty() or _mission_claimed(period, id):
		return false
	var progress := _metric_value(period, String(found.get("metric", "")))
	if progress < int(found.get("target", 1)):
		return false
	var state: Dictionary = SaveManager.data["meta_progression"]
	var claims: Array = state.get("mission_claims", [])
	var claim_key := _mission_claim_key(period, id)
	claims.append(claim_key)
	if claims.size() > 256:
		claims = claims.slice(claims.size() - 256)
	state["mission_claims"] = claims
	SaveManager.data["meta_progression"] = state
	var coins := maxi(0, int(found.get("coins", 0)))
	var crowns := maxi(0, int(found.get("crowns", 0)))
	if coins > 0:
		EconomyManager.grant(coins, "%s_goal" % period, {"goal": id})
	_add_crowns(crowns)
	_persist()
	reward_claimed.emit(period, id, coins, crowns)
	meta_changed.emit()
	return true

func season_info() -> Dictionary:
	ensure_state()
	var state: Dictionary = SaveManager.data["meta_progression"]
	var points := maxi(0, int(state.get("season_points", 0)))
	var claimed: Array = state.get("season_claimed", [])
	var ready := 0
	var completed := 0
	var next_target := 0
	for i in range(SEASON_TIERS.size()):
		var tier: Dictionary = SEASON_TIERS[i]
		var tier_id := i + 1
		var need := int(tier.get("need", 0))
		if tier_id in claimed:
			completed += 1
		elif points >= need:
			ready += 1
		elif next_target == 0:
			next_target = need
	return {
		"key": String(state.get("season_key", _month_key())),
		"points": points,
		"completed": completed,
		"ready": ready,
		"tiers": SEASON_TIERS.size(),
		"next_target": next_target,
	}

func claim_season_tier(tier_id: int) -> bool:
	if tier_id < 1 or tier_id > SEASON_TIERS.size():
		return false
	ensure_state()
	var state: Dictionary = SaveManager.data["meta_progression"]
	var claimed: Array = state.get("season_claimed", [])
	if tier_id in claimed:
		return false
	var tier: Dictionary = SEASON_TIERS[tier_id - 1]
	if int(state.get("season_points", 0)) < int(tier.get("need", 0)):
		return false
	claimed.append(tier_id)
	state["season_claimed"] = claimed
	SaveManager.data["meta_progression"] = state
	var coins := maxi(0, int(tier.get("coins", 0)))
	var crowns := maxi(0, int(tier.get("crowns", 0)))
	if coins > 0:
		EconomyManager.grant(coins, "season_journey", {"tier": tier_id, "season": state.get("season_key", "")})
	_add_crowns(crowns)
	_persist()
	reward_claimed.emit("season", str(tier_id), coins, crowns)
	meta_changed.emit()
	return true

func claim_next_ready_season_tier() -> bool:
	var state: Dictionary = SaveManager.data.get("meta_progression", {})
	var claimed: Array = state.get("season_claimed", [])
	var points := maxi(0, int(state.get("season_points", 0)))
	for i in range(SEASON_TIERS.size()):
		var tier_id := i + 1
		if tier_id not in claimed and points >= int((SEASON_TIERS[i] as Dictionary).get("need", 0)):
			return claim_season_tier(tier_id)
	return false

func ready_claim_count() -> int:
	var count := 0
	if not bool(daily_login_info().get("claimed", false)):
		count += 1
	for row in daily_goals():
		if bool((row as Dictionary).get("claimable", false)):
			count += 1
	for row in weekly_goals():
		if bool((row as Dictionary).get("claimable", false)):
			count += 1
	count += int(season_info().get("ready", 0))
	return count

func player_level() -> int:
	return maxi(1, 1 + int(total_levels_completed() / 10))

func total_levels_completed() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	return total

func total_stars() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.total_stars(game_id)
	return total

func total_achievements() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.unlocked_achievements(game_id).size()
	return total

func total_achievement_slots() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.achievement_definitions(game_id).size()
	return total

func current_daily_streak() -> int:
	var best := int(SaveManager.data.get("daily_streak", 0))
	for game_id in ["water_sort", "block_puzzle"]:
		best = maxi(best, int(MultiGameManager.progress_for(game_id).get("daily_streak", 0)))
	return best

func _metric_value(period: String, metric: String) -> int:
	ensure_state()
	var state: Dictionary = SaveManager.data["meta_progression"]
	var activity: Dictionary = state.get("activity", {})
	var total := 0
	var today := _date_key()
	var week_start := _week_start_key()
	for raw_key in activity.keys():
		var key := String(raw_key)
		var include := key == today if period == "daily" else (key >= week_start and key <= today)
		if not include:
			continue
		var bucket = activity.get(key, {})
		if bucket is Dictionary:
			total += maxi(0, int(bucket.get(metric, 0)))
	return total

func _mission_claimed(period: String, id: String) -> bool:
	var state: Dictionary = SaveManager.data.get("meta_progression", {})
	var claims = state.get("mission_claims", [])
	return claims is Array and _mission_claim_key(period, id) in claims

func _mission_claim_key(period: String, id: String) -> String:
	var period_key := _date_key() if period == "daily" else _week_start_key()
	return "%s:%s:%s" % [period.left(1).to_upper(), period_key, id]

func _ensure_season_state(state: Dictionary) -> void:
	var key := _month_key()
	if String(state.get("season_key", "")) == key:
		return
	state["season_key"] = key
	state["season_points"] = 0
	state["season_claimed"] = []

func _prune_state(state: Dictionary) -> void:
	var activity = state.get("activity", {})
	if activity is Dictionary:
		var keys: Array = activity.keys()
		keys.sort()
		while keys.size() > 35:
			activity.erase(keys.pop_front())
		state["activity"] = activity
	var claims = state.get("mission_claims", [])
	if claims is Array and claims.size() > 256:
		state["mission_claims"] = claims.slice(claims.size() - 256)

func _add_crowns(amount: int) -> void:
	if amount <= 0:
		return
	SaveManager.data["crown_tokens"] = maxi(0, int(SaveManager.data.get("crown_tokens", 0))) + amount

func _persist() -> void:
	# CloudSaveManager already listens to SaveManager.save_committed and
	# debounces uploads, so one local save is the only persistence call needed.
	SaveManager.save()

func _date_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _month_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d" % [d.year, d.month]

func _week_start_key() -> String:
	var d := Time.get_date_dict_from_system()
	var weekday := int(d.weekday)
	var monday_offset := weekday - 1 if weekday >= 1 else 6
	var unix := int(Time.get_unix_time_from_datetime_dict({
		"year": int(d.year), "month": int(d.month), "day": int(d.day),
		"hour": 0, "minute": 0, "second": 0
	}))
	var monday := Time.get_datetime_dict_from_unix_time(unix - monday_offset * 86400)
	return "%04d-%02d-%02d" % [monday.year, monday.month, monday.day]

func _is_previous_day(previous: String, current: String) -> bool:
	if previous.is_empty() or current.is_empty():
		return false
	var p := _date_unix(previous)
	var c := _date_unix(current)
	return p > 0 and c > 0 and c - p == 86400

func _date_unix(value: String) -> int:
	var parts := value.split("-")
	if parts.size() != 3:
		return 0
	return int(Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 0, "minute": 0, "second": 0
	}))
