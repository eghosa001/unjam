extends "res://scripts/core/save_manager.gd"

const ROBUST_SAVE_PATH := "user://unjam_save.json"
const BACKUP_PATH := "user://unjam_save.backup.json"
const TEMP_PATH := "user://unjam_save.tmp.json"
const SAVE_VERSION := 6

func _ready() -> void:
	load_save()

func load_save() -> void:
	data = DEFAULT_DATA.duplicate(true)
	var loaded := _read_dictionary(ROBUST_SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_dictionary(BACKUP_PATH)
	if not loaded.is_empty():
		for key in loaded:
			data[key] = loaded[key]
	_migrate_robust()
	_sanitize()
	save()

func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _migrate_robust() -> void:
	for key in DEFAULT_DATA:
		if not data.has(key):
			data[key] = DEFAULT_DATA[key]
	data["save_version"] = SAVE_VERSION

func _sanitize() -> void:
	data.highest_level = clampi(int(data.get("highest_level", 1)), 1, 10001)
	data.coins = clampi(int(data.get("coins", 0)), 0, 2000000000)
	data.prestige_points = max(0, int(data.get("prestige_points", 0)))
	data.achievement_points = max(0, int(data.get("achievement_points", 0)))
	data.rewarded_ads_watched = max(0, int(data.get("rewarded_ads_watched", 0)))
	data.lifetime_purchased_coins = max(0, int(data.get("lifetime_purchased_coins", 0)))
	var consent := String(data.get("privacy_consent_status", "unknown"))
	data.privacy_consent_status = consent if consent in ["unknown", "required", "obtained", "not_required"] else "unknown"
	for key in ["sound", "vibration", "music", "remove_ads", "starter_pack_purchased"]:
		data[key] = bool(data.get(key, DEFAULT_DATA.get(key, false)))
	if not data.get("stars", {}) is Dictionary:
		data.stars = {}
	for key in ["rescued", "decorations", "daily_completed", "milestone_chests", "world_badges", "achievements", "purchased_products", "processed_purchase_tokens"]:
		if not data.get(key, []) is Array:
			data[key] = []
	var clean_stars: Dictionary = {}
	var completed_count := 0
	var perfect_count := 0
	var highest_from_stars := 1
	var completed_milestones: Array = []
	var completed_worlds: Array = []
	for key in data.stars:
		var level_number := int(String(key))
		if level_number < 1 or level_number > 10000:
			continue
		var value := clampi(int(data.stars[key]), 0, 3)
		if value <= 0:
			continue
		clean_stars[str(level_number)] = value
		completed_count += 1
		if value == 3:
			perfect_count += 1
		highest_from_stars = max(highest_from_stars, min(10001, level_number + 1))
		if level_number % 10 == 0:
			completed_milestones.append(str(level_number))
		if level_number % 100 == 0:
			completed_worlds.append(str(int(level_number / 100)))
	data.stars = clean_stars
	data.total_levels_completed = completed_count
	data.perfect_clears = perfect_count
	data.highest_level = max(int(data.highest_level), highest_from_stars)
	for milestone in completed_milestones:
		if milestone not in data.milestone_chests:
			data.milestone_chests.append(milestone)
	for world in completed_worlds:
		if world not in data.world_badges:
			data.world_badges.append(world)
	data.perfect_streak = clampi(int(data.get("perfect_streak", 0)), 0, 10000)
	data.best_perfect_streak = max(int(data.perfect_streak), int(data.get("best_perfect_streak", 0)))

func save() -> void:
	data["save_version"] = SAVE_VERSION
	var payload := JSON.stringify(data)
	var temp := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temp == null:
		return
	temp.store_string(payload)
	temp.flush()
	temp = null
	if FileAccess.file_exists(ROBUST_SAVE_PATH):
		var current := FileAccess.open(ROBUST_SAVE_PATH, FileAccess.READ)
		if current != null:
			var current_text := current.get_as_text()
			if JSON.parse_string(current_text) is Dictionary:
				var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
				if backup != null:
					backup.store_string(current_text)
					backup.flush()
	var absolute_main := ProjectSettings.globalize_path(ROBUST_SAVE_PATH)
	var absolute_temp := ProjectSettings.globalize_path(TEMP_PATH)
	if FileAccess.file_exists(ROBUST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_main)
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_main)
	if rename_error != OK:
		var fallback := FileAccess.open(ROBUST_SAVE_PATH, FileAccess.WRITE)
		if fallback != null:
			fallback.store_string(payload)
			fallback.flush()

func complete_level(level_number: int, stars: int, rescue_id: String, coin_reward: int = 25) -> Dictionary:
	level_number = clampi(level_number, 1, 10000)
	stars = clampi(stars, 1, 3)
	var key := str(level_number)
	var previous_stars := int(data.stars.get(key, 0))
	var first_clear := previous_stars == 0
	var improved := stars > previous_stars
	var newly_perfect := stars == 3 and previous_stars < 3
	var earned_coins := coin_reward if first_clear else (10 * (stars - previous_stars) if improved else 0)
	var rewards := {
		"perfect": newly_perfect,
		"perfect_streak": int(data.get("perfect_streak", 0)),
		"milestone": false,
		"world_badge": false,
		"world": 0,
		"bonus_coins": 0,
		"base_coins": earned_coins,
		"prestige": 0,
		"achievements": [],
		"first_clear": first_clear,
		"improved": improved
	}
	data.stars[key] = max(previous_stars, stars)
	data.highest_level = max(int(data.highest_level), min(10001, level_number + 1))
	data.coins = int(data.coins) + earned_coins
	if first_clear:
		data.total_levels_completed = min(10000, int(data.total_levels_completed) + 1)
	if first_clear and not rescue_id.is_empty() and not rescue_id in data.rescued:
		data.rescued.append(rescue_id)
		data.total_rescues = int(data.total_rescues) + 1
	if newly_perfect:
		data.perfect_clears = min(10000, int(data.perfect_clears) + 1)
		data.perfect_streak = int(data.perfect_streak) + 1
		data.best_perfect_streak = max(int(data.best_perfect_streak), int(data.perfect_streak))
		rewards.perfect_streak = int(data.perfect_streak)
		if int(data.perfect_streak) % 5 == 0:
			rewards.bonus_coins = 50
			rewards.prestige = 1
			data.coins = int(data.coins) + 50
			data.prestige_points = int(data.prestige_points) + 1
	elif stars < 3 and first_clear:
		data.perfect_streak = 0
	if first_clear and level_number % 10 == 0:
		var chest_key := str(level_number)
		if not chest_key in data.milestone_chests:
			data.milestone_chests.append(chest_key)
			rewards.milestone = true
			rewards.bonus_coins = int(rewards.bonus_coins) + 100
			data.coins = int(data.coins) + 100
	if first_clear and level_number % 100 == 0:
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
	_check_achievement("first_rescue", int(data.total_levels_completed) >= 1, "FIRST RESCUE", 10, rewards)
	_check_achievement("perfect_10", int(data.perfect_clears) >= 10, "PRECISION TEN", 20, rewards)
	_check_achievement("perfect_streak_10", int(data.best_perfect_streak) >= 10, "FLAWLESS RUN", 30, rewards)
	_check_achievement("levels_100", int(data.total_levels_completed) >= 100, "CENTURY RESCUER", 40, rewards)
	_check_achievement("world_10", data.world_badges.size() >= 10, "MASTER OF TEN WORLDS", 50, rewards)
	_check_achievement("levels_1000", int(data.total_levels_completed) >= 1000, "UNJAM LEGEND", 100, rewards)
	save()
	if bool(rewards.perfect) or bool(rewards.milestone) or bool(rewards.world_badge) or int(rewards.prestige) > 0 or not rewards.achievements.is_empty():
		premium_reward.emit(rewards)
	return rewards
