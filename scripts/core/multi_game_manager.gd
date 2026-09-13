extends Node

const CAMPAIGN_LEVELS := 10000
const LEVELS_PER_WORLD := 100
const WORLD_COUNT := 100
const GAME_IDS := ["rescue_rush", "water_sort", "block_puzzle"]
const GAME_NAMES := {
	"rescue_rush": "RESCUE RUSH",
	"water_sort": "WATER SORT",
	"block_puzzle": "BLOCK PUZZLE"
}

func _ready() -> void:
	ensure_state()

func ensure_state() -> void:
	if not SaveManager.data.get("game_progress", {}) is Dictionary:
		SaveManager.data["game_progress"] = {}
	var progress: Dictionary = SaveManager.data.game_progress
	for game_id in GAME_IDS:
		if game_id == "rescue_rush":
			continue
		if not progress.get(game_id, {}) is Dictionary:
			progress[game_id] = {}
		var game: Dictionary = progress[game_id]
		game["highest_level"] = clampi(int(game.get("highest_level", 1)), 1, CAMPAIGN_LEVELS + 1)
		if not game.get("stars", {}) is Dictionary:
			game["stars"] = {}
		game["levels_completed"] = maxi(0, int(game.get("levels_completed", 0)))
		game["perfect_clears"] = maxi(0, int(game.get("perfect_clears", 0)))
		game["perfect_streak"] = maxi(0, int(game.get("perfect_streak", 0)))
		game["best_perfect_streak"] = maxi(int(game.get("best_perfect_streak", 0)), int(game.perfect_streak))
		if not game.get("milestone_chests", []) is Array:
			game["milestone_chests"] = []
		if not game.get("world_badges", []) is Array:
			game["world_badges"] = []
		if not game.get("daily_completed", []) is Array:
			game["daily_completed"] = []
		game["daily_streak"] = maxi(0, int(game.get("daily_streak", 0)))
		game["daily_best_streak"] = maxi(int(game.get("daily_best_streak", 0)), int(game.daily_streak))
		game["daily_last_date"] = String(game.get("daily_last_date", ""))
		progress[game_id] = game
	SaveManager.data.game_progress = progress
	if not SaveManager.data.get("multi_active_runs", {}) is Dictionary:
		SaveManager.data["multi_active_runs"] = {}
	SaveManager.save()

func display_name(game_id: String) -> String:
	return String(GAME_NAMES.get(game_id, game_id.to_upper()))

func progress_for(game_id: String) -> Dictionary:
	ensure_state()
	if game_id == "rescue_rush":
		return {
			"highest_level": int(SaveManager.data.get("highest_level", 1)),
			"stars": SaveManager.data.get("stars", {}),
			"levels_completed": int(SaveManager.data.get("total_levels_completed", 0)),
			"perfect_clears": int(SaveManager.data.get("perfect_clears", 0)),
			"perfect_streak": int(SaveManager.data.get("perfect_streak", 0)),
			"best_perfect_streak": int(SaveManager.data.get("best_perfect_streak", 0)),
			"milestone_chests": SaveManager.data.get("milestone_chests", []),
			"world_badges": SaveManager.data.get("world_badges", []),
			"daily_streak": int(SaveManager.data.get("daily_streak", 0)),
			"daily_best_streak": int(SaveManager.data.get("daily_best_streak", 0))
		}
	return (SaveManager.data.game_progress as Dictionary).get(game_id, {}).duplicate(true)

func highest_level(game_id: String) -> int:
	return clampi(int(progress_for(game_id).get("highest_level", 1)), 1, CAMPAIGN_LEVELS + 1)

func get_stars(game_id: String, level_number: int) -> int:
	var stars: Dictionary = progress_for(game_id).get("stars", {})
	return int(stars.get(str(level_number), 0))

func total_stars(game_id: String) -> int:
	var total := 0
	var stars: Dictionary = progress_for(game_id).get("stars", {})
	for value in stars.values():
		total += int(value)
	return total

func is_level_unlocked(game_id: String, level_number: int) -> bool:
	return level_number >= 1 and level_number <= CAMPAIGN_LEVELS and level_number <= highest_level(game_id)

func world_for_level(level_number: int) -> int:
	return clampi(int((maxi(level_number, 1) - 1) / LEVELS_PER_WORLD) + 1, 1, WORLD_COUNT)

func first_level_in_world(world: int) -> int:
	return (clampi(world, 1, WORLD_COUNT) - 1) * LEVELS_PER_WORLD + 1

func last_level_in_world(world: int) -> int:
	return mini(first_level_in_world(world) + LEVELS_PER_WORLD - 1, CAMPAIGN_LEVELS)

func highest_unlocked_world(game_id: String) -> int:
	return world_for_level(highest_level(game_id))

func world_name(game_id: String, world: int) -> String:
	var themes: Dictionary = {
		"rescue_rush": ["Garden Escape", "Locks & Keys", "Chain Reaction", "Blast Lab", "Linked Zone", "Chaos Rescue", "Portal Works", "Crystal Circuit", "Neon Factory", "Rescue Nexus"],
		"water_sort": ["Color Springs", "Glass Garden", "Prism Bay", "Liquid Lab", "Neon Pour", "Spectrum Works", "Crystal Flow", "Chromatic Vault", "Aurora Mix", "Master Distillery"],
		"block_puzzle": ["Starter Grid", "Brick Yard", "Shape Works", "Line Factory", "Pattern City", "Block Forge", "Grid Nexus", "Combo Circuit", "Master Matrix", "Infinite Board"]
	}
	var set: Array = themes.get(game_id, themes["rescue_rush"])
	var base := String(set[(world - 1) % set.size()])
	var chapter := int((world - 1) / set.size()) + 1
	return "%s %d" % [base, chapter] if chapter > 1 else base

func difficulty_for_level(level_number: int) -> String:
	if level_number % 100 == 0:
		return "boss"
	if level_number % 25 == 0:
		return "milestone"
	var mixed := posmod(level_number * 37 + int(level_number / 7) * 11, 10)
	if mixed <= 2:
		return "easy"
	if mixed <= 6:
		return "medium"
	return "hard"

func daily_level(game_id: String) -> int:
	var date := Time.get_date_dict_from_system()
	var salt := GAME_IDS.find(game_id) * 997
	return posmod(int(date.year) * 372 + int(date.month) * 31 + int(date.day) + salt, CAMPAIGN_LEVELS) + 1

func date_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func is_daily_completed(game_id: String) -> bool:
	if game_id == "rescue_rush":
		return date_key() in SaveManager.data.get("daily_completed", [])
	var game := progress_for(game_id)
	return date_key() in game.get("daily_completed", [])

func complete_daily(game_id: String, reward := 100) -> bool:
	if game_id == "rescue_rush":
		return SaveManager.complete_daily(date_key(), reward)
	ensure_state()
	var progress: Dictionary = SaveManager.data.game_progress
	var game: Dictionary = progress[game_id]
	var key := date_key()
	if key in game.daily_completed:
		return false
	var consecutive := false
	var previous := String(game.get("daily_last_date", ""))
	if not previous.is_empty():
		var prev_parts := previous.split("-")
		if prev_parts.size() == 3:
			var prev_unix := Time.get_unix_time_from_datetime_dict({"year": int(prev_parts[0]), "month": int(prev_parts[1]), "day": int(prev_parts[2]), "hour": 0, "minute": 0, "second": 0})
			var now := Time.get_date_dict_from_system()
			var now_unix := Time.get_unix_time_from_datetime_dict({"year": now.year, "month": now.month, "day": now.day, "hour": 0, "minute": 0, "second": 0})
			consecutive = int(now_unix - prev_unix) == 86400
	game.daily_streak = int(game.daily_streak) + 1 if consecutive else 1
	game.daily_best_streak = maxi(int(game.daily_best_streak), int(game.daily_streak))
	game.daily_last_date = key
	game.daily_completed.append(key)
	if game.daily_completed.size() > 45:
		game.daily_completed = game.daily_completed.slice(game.daily_completed.size() - 45)
	progress[game_id] = game
	SaveManager.data.game_progress = progress
	SaveManager.add_coins(reward)
	return true

func complete_level(game_id: String, level_number: int, stars: int, coin_reward := 25) -> Dictionary:
	if game_id == "rescue_rush":
		return SaveManager.complete_level(level_number, stars, "", coin_reward)
	ensure_state()
	level_number = clampi(level_number, 1, CAMPAIGN_LEVELS)
	stars = clampi(stars, 1, 3)
	var progress: Dictionary = SaveManager.data.game_progress
	var game: Dictionary = progress[game_id]
	var key := str(level_number)
	var previous := int(game.stars.get(key, 0))
	var first_clear := previous == 0
	var improved := stars > previous
	var rewards := {"first_clear": first_clear, "improved": improved, "perfect": stars == 3 and previous < 3, "milestone": false, "world_badge": false, "bonus_coins": 0, "prestige": 0}
	game.stars[key] = maxi(previous, stars)
	game.highest_level = maxi(int(game.highest_level), mini(CAMPAIGN_LEVELS + 1, level_number + 1))
	if first_clear:
		game.levels_completed = mini(CAMPAIGN_LEVELS, int(game.levels_completed) + 1)
		SaveManager.add_coins(coin_reward)
	elif improved:
		SaveManager.add_coins((stars - previous) * 10)
	if bool(rewards.perfect):
		game.perfect_clears = mini(CAMPAIGN_LEVELS, int(game.perfect_clears) + 1)
		game.perfect_streak = int(game.perfect_streak) + 1
		game.best_perfect_streak = maxi(int(game.best_perfect_streak), int(game.perfect_streak))
		if int(game.perfect_streak) % 5 == 0:
			rewards.bonus_coins = 50
			rewards.prestige = 1
			SaveManager.data.coins = int(SaveManager.data.coins) + 50
			SaveManager.data.prestige_points = int(SaveManager.data.prestige_points) + 1
	elif first_clear:
		game.perfect_streak = 0
	if first_clear and level_number % 10 == 0:
		if key not in game.milestone_chests:
			game.milestone_chests.append(key)
			rewards.milestone = true
			rewards.bonus_coins = int(rewards.bonus_coins) + 100
			SaveManager.data.coins = int(SaveManager.data.coins) + 100
	if first_clear and level_number % 100 == 0:
		var world_key := str(int(level_number / 100))
		if world_key not in game.world_badges:
			game.world_badges.append(world_key)
			rewards.world_badge = true
			rewards.prestige = int(rewards.prestige) + 5
			rewards.bonus_coins = int(rewards.bonus_coins) + 250
			SaveManager.data.prestige_points = int(SaveManager.data.prestige_points) + 5
			SaveManager.data.coins = int(SaveManager.data.coins) + 250
	progress[game_id] = game
	SaveManager.data.game_progress = progress
	SaveManager.save()
	AnalyticsManager.track("multi_game_level_complete", {"game": game_id, "level": level_number, "stars": stars, "difficulty": difficulty_for_level(level_number)})
	return rewards

func save_checkpoint(game_id: String, checkpoint: Dictionary) -> void:
	ensure_state()
	var runs: Dictionary = SaveManager.data.multi_active_runs
	var payload := checkpoint.duplicate(true)
	payload["game"] = game_id
	payload["saved_at"] = int(Time.get_unix_time_from_system())
	runs[game_id] = payload
	SaveManager.data.multi_active_runs = runs
	SaveManager.save()

func checkpoint(game_id: String) -> Dictionary:
	ensure_state()
	var raw = (SaveManager.data.multi_active_runs as Dictionary).get(game_id, {})
	return raw.duplicate(true) if raw is Dictionary else {}

func clear_checkpoint(game_id: String) -> void:
	ensure_state()
	var runs: Dictionary = SaveManager.data.multi_active_runs
	runs.erase(game_id)
	SaveManager.data.multi_active_runs = runs
	SaveManager.save()
