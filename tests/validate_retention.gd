extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var manager: Node = get_root().get_node_or_null("RetentionManager")
	if manager == null:
		printerr("RetentionManager autoload was not available in runtime validation.")
		quit(1)
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
	if not errors.is_empty():
		for error in errors:
			printerr(error)
		printerr("Retention validation failed with %d issue(s)." % errors.size())
		quit(1)
		return
	print("Retention systems validated: daily missions, weekly league, season/event periods, event shop and profile.")
	quit(0)
