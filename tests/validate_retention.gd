extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	RetentionManager.ensure_state()
	var missions := RetentionManager.daily_missions()
	if missions.size() != 3:
		errors.append("Expected exactly 3 daily missions")
	var seen := {}
	for mission in missions:
		var id := String(mission.get("id", ""))
		if id.is_empty(): errors.append("Daily mission missing id")
		if seen.has(id): errors.append("Duplicate daily mission: %s" % id)
		seen[id] = true
		if int(mission.get("target", 0)) <= 0: errors.append("Daily mission has invalid target: %s" % id)
	if RetentionManager.WEEKLY_TARGETS.size() != RetentionManager.WEEKLY_REWARDS.size():
		errors.append("Weekly target/reward counts do not match")
	if RetentionManager.SEASON_TARGETS.size() != RetentionManager.SEASON_REWARDS.size():
		errors.append("Season target/reward counts do not match")
	if RetentionManager.LOGIN_REWARDS.size() != 7:
		errors.append("Login reward cycle must contain 7 days")
	if RetentionManager.event_shop().size() < 4:
		errors.append("Event shop should expose at least 4 cosmetics")
	if RetentionManager.weekly_rivals().size() != 9:
		errors.append("Weekly league should contain 9 seeded rivals")
	var profile := RetentionManager.profile_snapshot()
	for key in ["title", "prestige", "achievement_points", "levels", "perfects", "best_streak", "variants", "badges"]:
		if not profile.has(key): errors.append("Profile snapshot missing %s" % key)
	if String(RetentionManager.today_key()).is_empty() or String(RetentionManager.week_key()).is_empty() or String(RetentionManager.season_key()).is_empty() or String(RetentionManager.event_key()).is_empty():
		errors.append("Retention period keys must not be empty")
	if not errors.is_empty():
		for error in errors: printerr(error)
		printerr("Retention validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Retention systems validated: daily missions, login cycle, weekly league, season track, event shop and profile.")
	quit(0)
