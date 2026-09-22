extends Node

signal retention_reward(payload: Dictionary)
signal retention_updated

const DAILY_MISSION_REWARD: int = 45
const DAILY_ALL_BONUS: int = 120
const WEEKLY_TARGETS: Array[int] = [100, 250, 450, 700, 1000]
const WEEKLY_REWARDS: Array[int] = [75, 125, 175, 250, 400]
const SEASON_TARGETS: Array[int] = [100, 250, 500, 850, 1300, 1900, 2600, 3400]
const SEASON_REWARDS: Array[int] = [50, 75, 100, 150, 200, 250, 350, 500]
const LOGIN_REWARDS: Array[int] = [40, 55, 70, 90, 120, 160, 250]
const EVENT_DURATION_DAYS: int = 14

const ACHIEVEMENT_REWARDS := {
	"first_rescue": {"title":"FIRST RESCUE", "coins":75},
	"perfect_10": {"title":"PRECISION TEN", "coins":125},
	"perfect_streak_10": {"title":"FLAWLESS RUN", "coins":175},
	"levels_100": {"title":"CENTURY RESCUER", "coins":250},
	"world_10": {"title":"MASTER OF TEN WORLDS", "coins":400},
	"levels_1000": {"title":"UNJAM LEGEND", "coins":750}
}

func _ready() -> void:
	process_login()

func ensure_state() -> void:
	var defaults: Dictionary = {
		"last_login_date":"", "login_cycle_day":0, "login_claim_date":"", "comeback_claimed_date":"",
		"daily_mission_date":"", "daily_mission_progress":{}, "daily_mission_claimed":[], "daily_all_claimed":false,
		"win_streak":0, "best_win_streak":0,
		"weekly_key":"", "weekly_points":0, "weekly_claimed_tiers":[], "weekly_best_rank":0,
		"season_key":"", "season_points":0, "season_claimed_tiers":[],
		"event_key":"", "event_currency":0, "event_shop_owned":[], "event_levels_completed":0,
		"rescue_variants":[], "profile_title":"Rookie Rescuer", "missions_completed":0,
		"achievement_reward_claimed":[]
	}
	var changed := false
	for key in defaults:
		if not SaveManager.data.has(key):
			var default_value = defaults[key]
			SaveManager.data[key] = default_value.duplicate(true) if default_value is Array or default_value is Dictionary else default_value
			changed = true
	changed = _roll_periods() or changed
	if changed:
		SaveManager.save()

func today_key() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func week_key() -> String:
	return "W%d" % int(int(Time.get_unix_time_from_system()) / 604800)

func season_key() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%04d-S%02d" % [int(d.year), int((int(d.month) - 1) / 2) + 1]

func event_key() -> String:
	return "E%d" % int(int(Time.get_unix_time_from_system()) / (EVENT_DURATION_DAYS * 86400))

func _roll_periods() -> bool:
	var changed := false
	var today := today_key()
	if String(SaveManager.data.daily_mission_date) != today:
		SaveManager.data.daily_mission_date = today
		SaveManager.data.daily_mission_progress = {}
		SaveManager.data.daily_mission_claimed = []
		SaveManager.data.daily_all_claimed = false
		changed = true
	var current_week := week_key()
	if String(SaveManager.data.weekly_key) != current_week:
		SaveManager.data.weekly_key = current_week
		SaveManager.data.weekly_points = 0
		SaveManager.data.weekly_claimed_tiers = []
		changed = true
	var current_season := season_key()
	if String(SaveManager.data.season_key) != current_season:
		SaveManager.data.season_key = current_season
		SaveManager.data.season_points = 0
		SaveManager.data.season_claimed_tiers = []
		changed = true
	var current_event := event_key()
	if String(SaveManager.data.event_key) != current_event:
		SaveManager.data.event_key = current_event
		SaveManager.data.event_currency = 0
		SaveManager.data.event_shop_owned = []
		SaveManager.data.event_levels_completed = 0
		changed = true
	return changed

func process_login() -> Dictionary:
	ensure_state()
	var today: String = today_key()
	var previous: String = String(SaveManager.data.last_login_date)
	var payload: Dictionary = {}
	if previous == today:
		return payload
	var gap: int = _day_gap(previous, today)
	if previous.is_empty():
		SaveManager.data.login_cycle_day = 1
	elif gap == 1:
		SaveManager.data.login_cycle_day = (int(SaveManager.data.login_cycle_day) % 7) + 1
	else:
		SaveManager.data.login_cycle_day = 1
	SaveManager.data.last_login_date = today
	if gap >= 3 and String(SaveManager.data.comeback_claimed_date) != today:
		var comeback: int = mini(500, 100 + gap * 35)
		SaveManager.add_coins(comeback)
		SaveManager.data.comeback_claimed_date = today
		payload = {"type":"comeback", "coins":comeback, "days":gap, "title":"WELCOME BACK"}
		retention_reward.emit(payload)
	SaveManager.save()
	return payload

func can_claim_login_reward() -> bool:
	return String(SaveManager.data.login_claim_date) != today_key()

func claim_login_reward() -> Dictionary:
	ensure_state()
	if not can_claim_login_reward():
		return {}
	var day: int = clampi(int(SaveManager.data.login_cycle_day), 1, 7)
	var coins: int = LOGIN_REWARDS[day - 1]
	SaveManager.add_coins(coins)
	SaveManager.data.login_claim_date = today_key()
	SaveManager.save()
	var payload: Dictionary = {"type":"login", "day":day, "coins":coins, "title":"DAY %d REWARD" % day}
	retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func daily_missions() -> Array[Dictionary]:
	ensure_state()
	var templates: Array[Dictionary] = [
		{"id":"clear_levels", "title":"RESCUE RUN", "description":"Complete 5 campaign levels", "target":5},
		{"id":"perfects", "title":"PRECISION", "description":"Earn 3 stars on 3 levels", "target":3},
		{"id":"hard_levels", "title":"BRAVE RESCUER", "description":"Complete 2 Hard or Boss levels", "target":2},
		{"id":"coins", "title":"TREASURE HUNT", "description":"Earn 200 coins from level rewards", "target":200}
	]
	var seed_value: int = int(today_key().hash())
	var result: Array[Dictionary] = []
	for i in range(3):
		var idx: int = absi(seed_value + i * 17) % templates.size()
		while _contains_mission(result, String(templates[idx].id)):
			idx = (idx + 1) % templates.size()
		result.append(templates[idx].duplicate(true))
	return result

func _contains_mission(list: Array[Dictionary], id: String) -> bool:
	for mission in list:
		if String(mission.id) == id:
			return true
	return false

func mission_progress(id: String) -> int:
	return int(SaveManager.data.daily_mission_progress.get(id, 0))

func mission_claimed(id: String) -> bool:
	return id in SaveManager.data.daily_mission_claimed

func claim_mission(id: String) -> Dictionary:
	for mission in daily_missions():
		if String(mission.id) == id and mission_progress(id) >= int(mission.target) and not mission_claimed(id):
			SaveManager.data.daily_mission_claimed.append(id)
			SaveManager.data.missions_completed = int(SaveManager.data.missions_completed) + 1
			SaveManager.add_coins(DAILY_MISSION_REWARD)
			SaveManager.data.event_currency = int(SaveManager.data.event_currency) + 10
			SaveManager.save()
			var payload: Dictionary = {"type":"mission", "coins":DAILY_MISSION_REWARD, "event_currency":10, "title":String(mission.title)}
			retention_reward.emit(payload)
			retention_updated.emit()
			return payload
	return {}

func can_claim_daily_all() -> bool:
	if bool(SaveManager.data.daily_all_claimed):
		return false
	for mission in daily_missions():
		if not mission_claimed(String(mission.id)):
			return false
	return true

func claim_daily_all() -> Dictionary:
	if not can_claim_daily_all():
		return {}
	SaveManager.data.daily_all_claimed = true
	SaveManager.add_coins(DAILY_ALL_BONUS)
	SaveManager.data.event_currency = int(SaveManager.data.event_currency) + 25
	SaveManager.save()
	var payload: Dictionary = {"type":"daily_all", "coins":DAILY_ALL_BONUS, "event_currency":25, "title":"DAILY MASTER CHEST"}
	retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func record_level_complete(level_number: int, stars: int, _moves: int, _par_moves: int, chain_count: int, rescue_id: String, _hints_used_this_level: int = -1, game_id: String = "rescue_rush", difficulty_override: String = "") -> Dictionary:
	ensure_state()
	var base_coins: int = 25 * stars
	_increment_mission("clear_levels", 1)
	_increment_mission("coins", base_coins)
	if stars == 3:
		_increment_mission("perfects", 1)
	var difficulty := difficulty_override.to_lower()
	if difficulty.is_empty():
		var level: Dictionary = LevelManager.load_level(level_number)
		difficulty = String(level.get("difficulty", level.get("difficulty_label", "medium"))).to_lower()
	if difficulty in ["hard", "boss"]:
		_increment_mission("hard_levels", 1)

	SaveManager.data.win_streak = int(SaveManager.data.win_streak) + 1
	SaveManager.data.best_win_streak = maxi(int(SaveManager.data.best_win_streak), int(SaveManager.data.win_streak))
	var weekly_gain: int = 10 + stars * 5 + mini(maxi(chain_count, 0), 8) * 2
	SaveManager.data.weekly_points = int(SaveManager.data.weekly_points) + weekly_gain
	SaveManager.data.season_points = int(SaveManager.data.season_points) + weekly_gain
	SaveManager.data.event_currency = int(SaveManager.data.event_currency) + 2 + stars
	SaveManager.data.event_levels_completed = int(SaveManager.data.event_levels_completed) + 1
	var rank: int = weekly_rank()
	if int(SaveManager.data.weekly_best_rank) == 0 or rank < int(SaveManager.data.weekly_best_rank):
		SaveManager.data.weekly_best_rank = rank

	var streak_reward: int = 0
	if int(SaveManager.data.win_streak) in [3, 5, 10, 15, 25]:
		streak_reward = int(SaveManager.data.win_streak) * 10
		SaveManager.add_coins(streak_reward)
	var variant := ""
	if game_id == "rescue_rush" and not rescue_id.is_empty():
		variant = _maybe_unlock_variant(level_number, rescue_id, stars)
	_update_profile_title()
	SaveManager.save()
	var payload: Dictionary = {
		"type":"level_retention",
		"game":game_id,
		"weekly_points":weekly_gain,
		"season_points":weekly_gain,
		"event_currency":2 + stars,
		"win_streak":int(SaveManager.data.win_streak),
		"streak_coins":streak_reward,
		"variant":variant
	}
	if streak_reward > 0 or not variant.is_empty():
		retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func record_level_fail() -> void:
	SaveManager.data.win_streak = 0
	SaveManager.save()
	retention_updated.emit()

func _increment_mission(id: String, amount: int) -> void:
	var progress: Dictionary = SaveManager.data.daily_mission_progress
	progress[id] = int(progress.get(id, 0)) + amount
	SaveManager.data.daily_mission_progress = progress

func weekly_rank() -> int:
	var rank: int = 1
	for rival in weekly_rivals():
		if int(rival.points) > int(SaveManager.data.weekly_points):
			rank += 1
	return rank

func weekly_rivals() -> Array[Dictionary]:
	var seed_value: int = int(week_key().hash())
	var names: Array[String] = ["Nova", "Kai", "Mira", "Jett", "Ayo", "Lina", "Rex", "Zuri", "Tobi"]
	var rivals: Array[Dictionary] = []
	for i in range(9):
		var points: int = 120 + absi(seed_value + i * 733) % 1150
		rivals.append({"name":names[i], "points":points})
	rivals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.points) > int(b.points))
	return rivals

func claim_weekly_tier(index: int) -> Dictionary:
	if index < 0 or index >= WEEKLY_TARGETS.size():
		return {}
	var key: String = str(index)
	if key in SaveManager.data.weekly_claimed_tiers or int(SaveManager.data.weekly_points) < WEEKLY_TARGETS[index]:
		return {}
	SaveManager.data.weekly_claimed_tiers.append(key)
	SaveManager.add_coins(WEEKLY_REWARDS[index])
	SaveManager.save()
	var payload: Dictionary = {"type":"weekly_tier", "coins":WEEKLY_REWARDS[index], "title":"WEEKLY MILESTONE %d" % (index + 1)}
	retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func claim_season_tier(index: int) -> Dictionary:
	if index < 0 or index >= SEASON_TARGETS.size():
		return {}
	var key: String = str(index)
	if key in SaveManager.data.season_claimed_tiers or int(SaveManager.data.season_points) < SEASON_TARGETS[index]:
		return {}
	SaveManager.data.season_claimed_tiers.append(key)
	SaveManager.add_coins(SEASON_REWARDS[index])
	SaveManager.data.event_currency = int(SaveManager.data.event_currency) + 20 + index * 5
	SaveManager.save()
	var payload: Dictionary = {"type":"season_tier", "coins":SEASON_REWARDS[index], "event_currency":20 + index * 5, "title":"SEASON REWARD %d" % (index + 1)}
	retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func achievement_reward_available(id: String) -> bool:
	return id in SaveManager.data.achievements and id not in SaveManager.data.achievement_reward_claimed and ACHIEVEMENT_REWARDS.has(id)

func claim_achievement_reward(id: String) -> Dictionary:
	if not achievement_reward_available(id):
		return {}
	var reward: Dictionary = ACHIEVEMENT_REWARDS[id]
	SaveManager.data.achievement_reward_claimed.append(id)
	SaveManager.add_coins(int(reward.coins))
	SaveManager.save()
	var payload: Dictionary = {"type":"achievement_claim", "title":String(reward.title), "coins":int(reward.coins)}
	retention_reward.emit(payload)
	retention_updated.emit()
	return payload

func event_shop() -> Array[Dictionary]:
	return [
		{"id":"aurora_trail", "title":"AURORA TRAIL", "cost":120},
		{"id":"gold_rescue_frame", "title":"GOLD RESCUE FRAME", "cost":180},
		{"id":"crystal_garden", "title":"CRYSTAL GARDEN", "cost":260},
		{"id":"royal_piece_skin", "title":"ROYAL PIECE SKIN", "cost":350}
	]

func buy_event_item(id: String) -> bool:
	for item in event_shop():
		if String(item.id) == id:
			if id in SaveManager.data.event_shop_owned or int(SaveManager.data.event_currency) < int(item.cost):
				return false
			SaveManager.data.event_currency = int(SaveManager.data.event_currency) - int(item.cost)
			SaveManager.data.event_shop_owned.append(id)
			SaveManager.save()
			retention_reward.emit({"type":"event_item", "title":String(item.title)})
			retention_updated.emit()
			return true
	return false

func _maybe_unlock_variant(level_number: int, rescue_id: String, stars: int) -> String:
	if rescue_id.is_empty() or stars < 3 or level_number % 25 != 0:
		return ""
	var rarity: String = "silver"
	if level_number % 100 == 0:
		rarity = "royal"
	elif level_number % 50 == 0:
		rarity = "gold"
	var key: String = "%s_%s" % [rescue_id, rarity]
	if key in SaveManager.data.rescue_variants:
		return ""
	SaveManager.data.rescue_variants.append(key)
	return key

func _update_profile_title() -> void:
	var prestige: int = int(SaveManager.data.prestige_points)
	var completed: int = int(SaveManager.data.total_levels_completed)
	if completed >= 5000 or prestige >= 250:
		SaveManager.data.profile_title = "Mythic Unjammer"
	elif completed >= 1000 or prestige >= 100:
		SaveManager.data.profile_title = "Legendary Rescuer"
	elif completed >= 500 or prestige >= 50:
		SaveManager.data.profile_title = "Elite Pathfinder"
	elif completed >= 100 or prestige >= 20:
		SaveManager.data.profile_title = "Master Rescuer"
	elif completed >= 25:
		SaveManager.data.profile_title = "Skilled Rescuer"
	else:
		SaveManager.data.profile_title = "Rookie Rescuer"

func profile_snapshot() -> Dictionary:
	return {
		"title":String(SaveManager.data.profile_title),
		"prestige":int(SaveManager.data.prestige_points),
		"achievement_points":int(SaveManager.data.achievement_points),
		"levels":int(SaveManager.data.total_levels_completed),
		"perfects":int(SaveManager.data.perfect_clears),
		"best_streak":int(SaveManager.data.best_win_streak),
		"variants":SaveManager.data.rescue_variants.size(),
		"badges":SaveManager.data.world_badges.size()
	}

func _day_gap(from_key: String, to_key: String) -> int:
	if from_key.is_empty():
		return 0
	var a: int = _date_unix(from_key)
	var b: int = _date_unix(to_key)
	if a <= 0 or b <= 0:
		return 0
	return maxi(0, int((b - a) / 86400))

func _date_unix(key: String) -> int:
	var parts: PackedStringArray = key.split("-")
	if parts.size() != 3:
		return 0
	return int(Time.get_unix_time_from_datetime_dict({"year":int(parts[0]), "month":int(parts[1]), "day":int(parts[2]), "hour":0, "minute":0, "second":0}))
