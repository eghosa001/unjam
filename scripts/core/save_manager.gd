extends Node

signal premium_reward(reward: Dictionary)

const SAVE_PATH := "user://unjam_save.json"
const RESET_PRESERVED_KEYS := [
	# Coins from gameplay and Play purchases share one wallet, so a gameplay reset
	# must never destroy that balance. Decorations are sold as permanent unlocks.
	"coins",
	"decorations",
	# Resetting progression must not silently rewrite accessibility/preferences or
	# force the privacy flow back to an unknown local state.
	"sound",
	"vibration",
	"music",
	"reduce_motion",
	"fast_animation",
	"privacy_consent_status",
	# Monetization history and Play-owned state survive gameplay resets.
	"rewarded_ads_watched",
	"remove_ads",
	"starter_pack_purchased",
	"purchased_products",
	"processed_purchase_tokens",
	"purchase_claim_ids",
	"lifetime_purchased_coins",
	"garden_last_gift_date",
	"garden_gifts_claimed"
]

const DEFAULT_DATA := {
	"highest_level": 1,
	"stars": {},
	"rescued": [],
	"coins": 0,
	"sound": true,
	"vibration": true,
	"music": true,
	"reduce_motion": false,
	"fast_animation": false,
	"decorations": [],
	"garden_last_gift_date": "",
	"garden_gifts_claimed": 0,
	"daily_last_date": "",
	"daily_streak": 0,
	"daily_best_streak": 0,
	"daily_completed": [],
	"hints_used": 0,
	"undos_used": 0,
	"remove_ads": false,
	"starter_pack_purchased": false,
	"purchased_products": [],
	"rewarded_ads_watched": 0,
	"lifetime_purchased_coins": 0,
	"processed_purchase_tokens": [],
	"purchase_claim_ids": {},
	"privacy_consent_status": "unknown",
	"total_levels_completed": 0,
	"total_rescues": 0,
	"perfect_clears": 0,
	"perfect_streak": 0,
	"best_perfect_streak": 0,
	"milestone_chests": [],
	"world_badges": [],
	"prestige_points": 0,
	"achievements": [],
	"achievement_points": 0
}

var data: Dictionary = DEFAULT_DATA.duplicate(true)

func _ready() -> void:
	load_save()

func load_save() -> void:
	data = DEFAULT_DATA.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed:
			data[key] = parsed[key]
	_migrate()

func _migrate() -> void:
	for key in DEFAULT_DATA:
		if not data.has(key):
			data[key] = DEFAULT_DATA[key]
	save()

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func complete_level(level_number: int, stars: int, rescue_id: String, coin_reward: int = 25) -> Dictionary:
	var rewards := {"perfect": false, "perfect_streak": 0, "milestone": false, "world_badge": false, "world": 0, "bonus_coins": 0, "prestige": 0, "achievements": []}
	var key := str(level_number)
	var previous_stars := int(data.stars.get(key, 0))
	data.stars[key] = max(previous_stars, stars)
	data.highest_level = max(int(data.highest_level), level_number + 1)
	data.coins = int(data.coins) + coin_reward
	data.total_levels_completed = int(data.total_levels_completed) + 1
	if not rescue_id.is_empty() and not rescue_id in data.rescued:
		data.rescued.append(rescue_id)
		data.total_rescues = int(data.total_rescues) + 1
	if stars == 3:
		rewards.perfect = true
		data.perfect_clears = int(data.perfect_clears) + 1
		data.perfect_streak = int(data.perfect_streak) + 1
		data.best_perfect_streak = max(int(data.best_perfect_streak), int(data.perfect_streak))
		rewards.perfect_streak = int(data.perfect_streak)
		if int(data.perfect_streak) % 5 == 0:
			rewards.bonus_coins = 50; rewards.prestige = 1; data.coins = int(data.coins) + 50; data.prestige_points = int(data.prestige_points) + 1
	else:
		data.perfect_streak = 0
	if level_number % 10 == 0:
		var chest_key := str(level_number)
		if not chest_key in data.milestone_chests:
			data.milestone_chests.append(chest_key); rewards.milestone = true; rewards.bonus_coins = int(rewards.bonus_coins) + 100; data.coins = int(data.coins) + 100
	if level_number % 100 == 0:
		var world := int(level_number / 100); var badge_key := str(world)
		if not badge_key in data.world_badges:
			data.world_badges.append(badge_key); rewards.world_badge = true; rewards.world = world; rewards.prestige = int(rewards.prestige) + 5; data.prestige_points = int(data.prestige_points) + 5; data.coins = int(data.coins) + 250; rewards.bonus_coins = int(rewards.bonus_coins) + 250
	_check_achievement("first_rescue", int(data.total_levels_completed) >= 1, "FIRST RESCUE", 10, rewards)
	_check_achievement("perfect_10", int(data.perfect_clears) >= 10, "PRECISION TEN", 20, rewards)
	_check_achievement("perfect_streak_10", int(data.best_perfect_streak) >= 10, "FLAWLESS RUN", 30, rewards)
	_check_achievement("levels_100", int(data.total_levels_completed) >= 100, "CENTURY RESCUER", 40, rewards)
	_check_achievement("world_10", data.world_badges.size() >= 10, "MASTER OF TEN WORLDS", 50, rewards)
	_check_achievement("levels_1000", int(data.total_levels_completed) >= 1000, "UNJAM LEGEND", 100, rewards)
	save()
	if Engine.has_singleton("RetentionManager"):
		pass
	elif get_node_or_null("/root/RetentionManager") != null:
		RetentionManager.record_level_complete(level_number, stars, 0, 0, 0, rescue_id, -1)
	if bool(rewards.perfect) or bool(rewards.milestone) or bool(rewards.world_badge) or int(rewards.prestige) > 0 or not rewards.achievements.is_empty(): premium_reward.emit(rewards)
	return rewards

func _check_achievement(id: String, condition: bool, title: String, points: int, rewards: Dictionary) -> void:
	if not condition or id in data.achievements: return
	data.achievements.append(id); data.achievement_points = int(data.achievement_points) + points; data.prestige_points = int(data.prestige_points) + max(1, int(points / 10)); rewards.achievements.append({"id": id, "title": title, "points": points})
func get_stars(level_number: int) -> int: return int(data.stars.get(str(level_number), 0))
func total_stars() -> int:
	var total := 0
	for value in data.stars.values(): total += int(value)
	return total
func is_level_unlocked(level_number: int) -> bool: return level_number <= int(data.highest_level)
func add_coins(amount: int) -> void: data.coins = max(0, int(data.coins) + amount); save()
func spend_coins(amount: int) -> bool:
	if int(data.coins) < amount: return false
	data.coins = int(data.coins) - amount; save(); return true
func unlock_decoration(id: String, cost: int) -> bool:
	if id in data.decorations: return true
	if not spend_coins(cost): return false
	data.decorations.append(id); save(); return true
func record_hint() -> void: data.hints_used = int(data.hints_used) + 1; save()
func record_undo() -> void: data.undos_used = int(data.undos_used) + 1; save()
func complete_daily(date_key: String, reward: int = 100) -> bool:
	if date_key in data.daily_completed: return false
	var previous_date := String(data.daily_last_date); var today := Time.get_date_dict_from_system(); var today_unix := Time.get_unix_time_from_datetime_dict({"year": today.year, "month": today.month, "day": today.day, "hour": 0, "minute": 0, "second": 0}); var consecutive := false
	if not previous_date.is_empty():
		var parts := previous_date.split("-")
		if parts.size() == 3:
			var prev_unix := Time.get_unix_time_from_datetime_dict({"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 0, "minute": 0, "second": 0}); consecutive = int(today_unix - prev_unix) == 86400
	data.daily_streak = int(data.daily_streak) + 1 if consecutive else 1; data.daily_best_streak = max(int(data.daily_best_streak), int(data.daily_streak)); data.daily_last_date = date_key; data.daily_completed.append(date_key)
	if data.daily_completed.size() > 45: data.daily_completed = data.daily_completed.slice(data.daily_completed.size() - 45)
	data.coins = int(data.coins) + reward; save(); return true
func reset_progress() -> void:
	# Reset gameplay progression only. Preserve the shared wallet, permanent
	# unlocks, user preferences/privacy state, monetization history and Play-owned
	# entitlements/transaction ledger.
	var preserved: Dictionary = {}
	for key in RESET_PRESERVED_KEYS:
		var value = data.get(key, DEFAULT_DATA.get(key))
		preserved[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	data = DEFAULT_DATA.duplicate(true)
	for key in RESET_PRESERVED_KEYS:
		data[key] = preserved[key]
	save()
	if get_node_or_null("/root/RetentionManager") != null: RetentionManager.ensure_state()
