extends Node

# The previous Daily Rescue puzzle picked from only ten fixed campaign boards,
# so long-term players saw frequent repeats. This deterministic schedule gives
# 432 unique, independently authored early-campaign boards before any repeat.
# Skip 25-level milestones so Daily never surprises casual players with a boss.
const DAILY_FIRST_LEVEL := 51
const DAILY_LAST_LEVEL := 500
const DAILY_ROTATION_DAYS := 432
const DAILY_EXPANSION_START := "2026-10-14"

func _daily_source_level(key: String, rng: RandomNumberGenerator) -> int:
	# Preserve the historic 13 October and earlier challenge within its day,
	# even if a player updates the Android app in the middle of a run.
	if key < DAILY_EXPANSION_START:
		return DAILY_FIRST_LEVEL + rng.randi_range(0, 9)
	var absolute_day := int(Time.get_unix_time_from_datetime_string("%sT12:00:00" % key) / 86400.0)
	# 73 and 432 are coprime: every index is visited once per 432 days.
	var desired_slot := posmod(absolute_day * 73 + 29, DAILY_ROTATION_DAYS)
	var slot := 0
	for level_number in range(DAILY_FIRST_LEVEL, DAILY_LAST_LEVEL + 1):
		if level_number % 25 == 0:
			continue
		if slot == desired_slot:
			return level_number
		slot += 1
	return DAILY_FIRST_LEVEL

func date_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func build_today() -> Dictionary:
	var key := date_key()
	var seed_value := int(key.replace("-", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base_level := _daily_source_level(key, rng)
	var data := CampaignGenerator.generate(base_level)
	data["daily_source_level"] = base_level
	data["id"] = -1
	data["daily"] = true
	data["daily_key"] = key
	data["par_moves"] = int(data.get("par_moves", 8)) + rng.randi_range(0, 2)
	data["rescue_id"] = ["chick", "puppy", "kitten", "robot", "panda", "fox", "alien"][rng.randi_range(0, 6)]
	return data

func is_completed_today() -> bool:
	return date_key() in SaveManager.data.daily_completed

func reward_text() -> String:
	return "COMPLETED" if is_completed_today() else "+100 COINS"
