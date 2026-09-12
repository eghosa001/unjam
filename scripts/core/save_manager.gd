extends Node

signal premium_reward(reward: Dictionary)

const SAVE_PATH := "user://unjam_save.json"
const DEFAULT_DATA := {
	"highest_level": 1,
	"stars": {},
	"rescued": [],
	"coins": 0,
	"sound": true,
	"vibration": true,
	"music": true,
	"decorations": [],
	"daily_last_date": "",
	"daily_streak": 0,
	"daily_best_streak": 0,
	"daily_completed": [],
	"hints_used": 0,
	"undos_used": 0,
	"remove_ads": false,
	"total_levels_completed": 0,
	"total_rescues": 0,
	"perfect_clears": 0,
	"perfect_streak": 0,
	"best_perfect_streak": 0,
	"milestone_chests": [],
	"world_badges": [],
	"prestige_points": 0
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
	var rewards := {
		"perfect": false,
		"perfect_streak": 0,
		"milestone": false,
		"world_badge": false,
		"world": 0,
		"bonus_coins": 0,
		"prestige": 0
	}
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
			rewards.bonus_coins = 50
			rewards.prestige = 1
			data.coins = int(data.coins) + 50
			data.prestige_points = int(data.prestige_points) + 1
	else:
		data.perfect_streak = 0

	if level_number % 10 == 0:
		var chest_key := str(level_number)
		if not chest_key in data.milestone_chests:
			data.milestone_chests.append(chest_key)
			rewards.milestone = true
			rewards.bonus_coins = int(rewards.bonus_coins) + 100
			data.coins = int(data.coins) + 100

	if level_number % 100 == 0:
		var world := int(level_number / 100)
		var badge_key := str(world)
		if not badge_key in data.world_badges:
			data.world_badges.append(badge_key)
			rewards.world_badge = true
			rewards.world = world
			rewards.prestige = int(rewards.prestige) + 5
			data.prestige_points = int(data.prestige_points) + 5
			data.coins = int(data.coins) + 250
			rewards.bonus_coins = int(rewards.bonus_coins) + 250

	save()
	if bool(rewards.perfect) or bool(rewards.milestone) or bool(rewards.world_badge) or int(rewards.prestige) > 0:
		premium_reward.emit(rewards)
	return rewards

func get_stars(level_number: int) -> int:
	return int(data.stars.get(str(level_number), 0))

func total_stars() -> int:
	var total := 0
	for value in data.stars.values():
		total += int(value)
	return total

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= int(data.highest_level)

func add_coins(amount: int) -> void:
	data.coins = max(0, int(data.coins) + amount)
	save()

func spend_coins(amount: int) -> bool:
	if int(data.coins) < amount:
		return false
	data.coins = int(data.coins) - amount
	save()
	return true

func unlock_decoration(id: String, cost: int) -> bool:
	if id in data.decorations:
		return true
	if not spend_coins(cost):
		return false
	data.decorations.append(id)
	save()
	return true

func record_hint() -> void:
	data.hints_used = int(data.hints_used) + 1
	save()

func record_undo() -> void:
	data.undos_used = int(data.undos_used) + 1
	save()

func complete_daily(date_key: String, reward: int = 100) -> bool:
	if date_key in data.daily_completed:
		return false
	var previous_date := String(data.daily_last_date)
	var today := Time.get_date_dict_from_system()
	var today_unix := Time.get_unix_time_from_datetime_dict({"year": today.year, "month": today.month, "day": today.day, "hour": 0, "minute": 0, "second": 0})
	var consecutive := false
	if not previous_date.is_empty():
		var parts := previous_date.split("-")
		if parts.size() == 3:
			var prev_unix := Time.get_unix_time_from_datetime_dict({"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 0, "minute": 0, "second": 0})
			consecutive = int(today_unix - prev_unix) == 86400
	data.daily_streak = int(data.daily_streak) + 1 if consecutive else 1
	data.daily_best_streak = max(int(data.daily_best_streak), int(data.daily_streak))
	data.daily_last_date = date_key
	data.daily_completed.append(date_key)
	if data.daily_completed.size() > 45:
		data.daily_completed = data.daily_completed.slice(data.daily_completed.size() - 45)
	data.coins = int(data.coins) + reward
	save()
	return true

func reset_progress() -> void:
	data = DEFAULT_DATA.duplicate(true)
	save()
