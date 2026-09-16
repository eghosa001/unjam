extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var manager: Node = get_root().get_node_or_null("RetentionManager")
	var multi: Node = get_root().get_node_or_null("MultiGameManager")
	var save_manager: Node = get_root().get_node_or_null("SaveManager")
	if manager == null:
		errors.append("RetentionManager autoload was not available in runtime validation")
	if multi == null:
		errors.append("MultiGameManager autoload was not available in runtime validation")
	if save_manager == null:
		errors.append("SaveManager autoload was not available in runtime validation")
	if not errors.is_empty():
		_finish(errors)
		return

	manager.call("ensure_state")
	var missions: Array = manager.call("daily_missions")
	if missions.size() != 3:
		errors.append("Expected exactly 3 daily missions")
	var seen: Dictionary = {}
	for mission_value in missions:
		var mission: Dictionary = mission_value
		var id: String = String(mission.get("id", ""))
		if id.is_empty():
			errors.append("Daily mission missing id")
		if seen.has(id):
			errors.append("Duplicate daily mission: %s" % id)
		seen[id] = true
		if int(mission.get("target", 0)) <= 0:
			errors.append("Daily mission has invalid target: %s" % id)
	var shop: Array = manager.call("event_shop")
	if shop.size() < 4:
		errors.append("Event shop should expose at least 4 cosmetics")
	var rivals: Array = manager.call("weekly_rivals")
	if rivals.size() != 9:
		errors.append("Weekly league should contain 9 seeded rivals")
	var profile: Dictionary = manager.call("profile_snapshot")
	for key in ["title", "prestige", "achievement_points", "levels", "perfects", "best_streak", "variants", "badges"]:
		if not profile.has(key):
			errors.append("Profile snapshot missing %s" % key)
	for method in ["today_key", "week_key", "season_key", "event_key"]:
		if String(manager.call(method)).is_empty():
			errors.append("Retention period key was empty: %s" % method)

	var multi_source := FileAccess.get_file_as_string("res://scripts/core/multi_game_manager.gd")
	if not multi_source.contains("DAILY_HISTORY_LIMIT"):
		errors.append("Daily completion/task history has no retention bound")
	if not multi_source.contains("_is_previous_calendar_day"):
		errors.append("Daily streak logic has no consecutive-calendar-day helper")
	if not multi_source.contains('SaveManager.data.get("achievements"'):
		errors.append("Rescue achievements are not read from the canonical achievements field")

	var original_data: Dictionary = save_manager.data.duplicate(true)
	# Exercise real behavior only when the helper exists so a RED run reports the
	# missing contract cleanly instead of failing with an invalid-method error.
	if multi.has_method("_is_previous_calendar_day"):
		if not bool(multi.call("_is_previous_calendar_day", "2026-09-14", "2026-09-15")):
			errors.append("Consecutive dates do not continue a daily streak")
		if bool(multi.call("_is_previous_calendar_day", "2026-09-13", "2026-09-15")):
			errors.append("A skipped day incorrectly continues a daily streak")
		if not bool(multi.call("_is_previous_calendar_day", "2025-12-31", "2026-01-01")):
			errors.append("Daily streak continuity breaks across a year boundary")

	# Canonical achievement schema must be used, with a compatibility fallback
	# for installs that ever wrote the legacy rescue_achievements field.
	save_manager.data["achievements"] = ["canonical_badge"]
	save_manager.data["rescue_achievements"] = []
	var rescue_progress: Dictionary = multi.call("progress_for", "rescue_rush")
	if "canonical_badge" not in rescue_progress.get("achievements", []):
		errors.append("Rescue progress ignores canonical achievements")
	save_manager.data["achievements"] = []
	save_manager.data["rescue_achievements"] = ["legacy_badge"]
	rescue_progress = multi.call("progress_for", "rescue_rush")
	if "legacy_badge" not in rescue_progress.get("achievements", []):
		errors.append("Legacy rescue achievements are not preserved by compatibility fallback")

	# A stale streak must reset to one, not increment forever, and completion
	# history must remain bounded after adding today's result.
	multi.call("ensure_state")
	var all_progress: Dictionary = save_manager.data.get("game_progress", {})
	var water: Dictionary = all_progress.get("water_sort", {})
	water["daily_streak"] = 9
	water["daily_best_streak"] = 12
	water["daily_last_date"] = "2000-01-01"
	var old_daily: Array = []
	for i in range(60):
		old_daily.append("1999-%02d-%02d" % [1 + int(i / 28), 1 + posmod(i, 28)])
	water["daily_completed"] = old_daily
	all_progress["water_sort"] = water
	save_manager.data["game_progress"] = all_progress
	multi.call("complete_daily", "water_sort", 0)
	water = (save_manager.data.get("game_progress", {}) as Dictionary).get("water_sort", {})
	if int(water.get("daily_streak", 0)) != 1:
		errors.append("Daily streak does not reset after a missed day")
	if int(water.get("daily_best_streak", 0)) != 12:
		errors.append("Resetting a stale daily streak regressed the best streak")
	if (water.get("daily_completed", []) as Array).size() > 45:
		errors.append("Daily completion history grows without the 45-day bound")

	# Seed more than the allowed number of dated task buckets; asking for today's
	# tasks must prune old buckets without touching current gameplay state.
	var seeded_tasks: Dictionary = {}
	for i in range(60):
		var year := 2010 + int(i / 12)
		var month := 1 + posmod(i, 12)
		var date := "%04d-%02d-01" % [year, month]
		for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
			seeded_tasks[date + ":" + game_id] = []
	save_manager.data["daily_tasks"] = seeded_tasks
	multi.call("daily_tasks", "water_sort")
	var task_store: Dictionary = save_manager.data.get("daily_tasks", {})
	if task_store.size() > 45 * 3:
		errors.append("Daily task history grows without the 45-day bound")

	# Restore the exact incoming state so validation never contaminates a later
	# test in the same runner or a developer's local save.
	save_manager.data = original_data
	save_manager.save()
	_finish(errors)

func _finish(errors: Array[String]) -> void:
	if not errors.is_empty():
		for error in errors:
			printerr(error)
		printerr("Retention validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Retention systems validated: daily missions, streak continuity, bounded history, achievement migration, weekly league, season/event periods, event shop and profile.")
	quit(0)
