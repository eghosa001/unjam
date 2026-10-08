extends SceneTree

func _initialize() -> void:
	var script := load("res://scripts/systems/analytics_manager.gd")
	if script == null:
		_fail("AnalyticsManager unavailable")
		return
	var tracker: Node = script.new()
	tracker.track("level_complete", {
		"game_id":"water_sort", "level":25, "moves":5,
		"purchase_token":"PRIVATE_TOKEN", "display_name":"PRIVATE_NAME",
		"outcome":"success", "reason":"PRIVATE_ERROR"
	})
	var state: Dictionary = tracker.session_snapshot()
	var counts: Dictionary = state.get("counts", {})
	var recent: Array = state.get("recent", [])
	if int(counts.get("level_complete", 0)) != 1 or recent.size() != 1:
		tracker.free()
		_fail("Anonymous session event was not counted")
		return
	var safe: Dictionary = recent[0].get("properties", {})
	if safe.has("purchase_token") or safe.has("display_name") or safe.has("reason"):
		tracker.free()
		_fail("Sensitive event properties reached the diagnostics buffer")
		return
	tracker.track("bad event with spaces", {"level":999})
	if (tracker.session_snapshot().get("recent", []) as Array).size() != 1:
		tracker.free()
		_fail("Invalid event names were retained")
		return
	for index in range(50):
		tracker.track("tap", {"moves":index})
	state = tracker.session_snapshot()
	if (state.get("recent", []) as Array).size() != 24:
		tracker.free()
		_fail("Anonymous telemetry buffer is unbounded")
		return
	tracker.free()
	print("ANONYMOUS_SESSION_DIAGNOSTICS_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
