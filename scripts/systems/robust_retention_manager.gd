extends "res://scripts/systems/retention_manager.gd"

const EVENT_DAILY_CAP := 80

func ensure_state() -> void:
	_ensure_robust_fields()
	_settle_previous_week_if_needed()
	super.ensure_state()
	_ensure_robust_fields()
	_roll_robust_tracking()
	SaveManager.save()

func _ensure_robust_fields() -> void:
	var defaults := {
		"weekly_settlement_key": "",
		"last_week_result": {},
		"weekly_played_levels": [],
		"weekly_tracking_key": "",
		"daily_unique_levels": [],
		"daily_unique_date": "",
		"event_daily_key": "",
		"event_daily_earned": 0
	}
	for key in defaults:
		if not SaveManager.data.has(key):
			SaveManager.data[key] = defaults[key]

func _roll_robust_tracking() -> void:
	var current_week := week_key()
	if String(SaveManager.data.weekly_tracking_key) != current_week:
		SaveManager.data.weekly_tracking_key = current_week
		SaveManager.data.weekly_played_levels = []
	var today := today_key()
	if String(SaveManager.data.daily_unique_date) != today:
		SaveManager.data.daily_unique_date = today
		SaveManager.data.daily_unique_levels = []
	if String(SaveManager.data.event_daily_key) != today:
		SaveManager.data.event_daily_key = today
		SaveManager.data.event_daily_earned = 0

func _settle_previous_week_if_needed() -> void:
	var old_key := String(SaveManager.data.get("weekly_key", ""))
	if old_key.is_empty() or old_key == week_key() or String(SaveManager.data.weekly_settlement_key) == old_key:
		return
	var points := max(0, int(SaveManager.data.get("weekly_points", 0)))
	var rank := _rank_for_week(old_key, points)
	var coins := 100
	var prestige := 0
	if rank == 1:
		coins = 500
		prestige = 5
	elif rank <= 3:
		coins = 300
		prestige = 3
	elif rank <= 5:
		coins = 180
		prestige = 1
	SaveManager.data.coins = int(SaveManager.data.coins) + coins
	SaveManager.data.prestige_points = int(SaveManager.data.prestige_points) + prestige
	SaveManager.data.weekly_settlement_key = old_key
	SaveManager.data.last_week_result = {"week": old_key, "rank": rank, "points": points, "coins": coins, "prestige": prestige}
	retention_reward.emit({"type":"weekly_settlement", "title":"WEEKLY LEAGUE #%d" % rank, "coins":coins, "prestige":prestige})

func _rank_for_week(key: String, points: int) -> int:
	var rank := 1
	var seed_value := key.hash()
	for i in range(9):
		var rival_points := 120 + absi(seed_value + i * 733) % 1150
		if rival_points > points:
			rank += 1
	return rank

func record_level_complete(level_number: int, stars: int, moves: int, par_moves: int, chain_count: int, rescue_id: String, hints_used_this_level: int = -1) -> Dictionary:
	ensure_state()
	var level_key := str(level_number)
	var duplicate_today: bool = level_key in SaveManager.data.daily_unique_levels
	var duplicate_week: bool = level_key in SaveManager.data.weekly_played_levels
	var mission_before: Dictionary = SaveManager.data.daily_mission_progress.duplicate(true)
	var weekly_before := int(SaveManager.data.weekly_points)
	var season_before := int(SaveManager.data.season_points)
	var event_before := int(SaveManager.data.event_currency)
	var streak_before := int(SaveManager.data.win_streak)
	var payload: Dictionary = super.record_level_complete(level_number, stars, moves, par_moves, chain_count, rescue_id, hints_used_this_level)

	if duplicate_today:
		SaveManager.data.daily_mission_progress = mission_before
	else:
		SaveManager.data.daily_unique_levels.append(level_key)

	var weekly_gained := max(0, int(SaveManager.data.weekly_points) - weekly_before)
	var season_gained := max(0, int(SaveManager.data.season_points) - season_before)
	if duplicate_week:
		var allowed_weekly := maxi(2, int(weekly_gained * 0.2))
		var allowed_season := maxi(2, int(season_gained * 0.2))
		SaveManager.data.weekly_points = weekly_before + allowed_weekly
		SaveManager.data.season_points = season_before + allowed_season
		SaveManager.data.win_streak = streak_before
		payload.weekly_points = allowed_weekly
		payload.season_points = allowed_season
	else:
		SaveManager.data.weekly_played_levels.append(level_key)

	var event_gained := max(0, int(SaveManager.data.event_currency) - event_before)
	var remaining := maxi(0, EVENT_DAILY_CAP - int(SaveManager.data.event_daily_earned))
	var allowed_event := mini(event_gained, remaining)
	SaveManager.data.event_currency = event_before + allowed_event
	SaveManager.data.event_daily_earned = int(SaveManager.data.event_daily_earned) + allowed_event
	payload.event_currency = allowed_event
	SaveManager.save()
	retention_updated.emit()
	return payload

func profile_snapshot() -> Dictionary:
	var result: Dictionary = super.profile_snapshot()
	var last_result = SaveManager.data.get("last_week_result", {})
	result["last_week_result"] = last_result if last_result is Dictionary else {}
	result["event_daily_earned"] = int(SaveManager.data.get("event_daily_earned", 0))
	result["event_daily_cap"] = EVENT_DAILY_CAP
	return result
