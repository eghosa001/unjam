extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var analytics = root.get_node("AnalyticsManager")
	var original: bool = bool(root.get_node("SaveManager").data.get("analytics_opt_in", false))
	analytics.call("set_analytics_opt_in", false)
	analytics.call("track", "level_complete", {"level": 230, "game_id": "water_sort", "player_id": "secret"})
	if not _check((analytics.call("pending_telemetry_for_test") as Array).is_empty(), "Telemetry ran without user opt-in"):return

	analytics.call("set_analytics_opt_in", true)
	analytics.call("track", "level_complete", {"level": 230, "game_id": "water_sort", "player_id": "secret", "purchase_token": "private"})
	var events: Array = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() == 2, "Expected one session and one whitelisted event"):return
	var item: Dictionary = events[1]
	if not _check(item.size() == 3 and item["name"] == "level_complete" and item["game"] == "water_sort" and item["level_band"] == 100, "Telemetry payload includes extra data or incorrect broad level band"):return
	for i in range(45):
		analytics.call("track", "hint_used", {"level": i + 1})
	events = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() <= 24, "Telemetry buffering exceeds 24-event privacy bound"):return
	analytics.call("set_analytics_opt_in", false)
	if not _check((analytics.call("pending_telemetry_for_test") as Array).is_empty(), "Opt-out did not discard pending events"):return

	var ui = load("res://scripts/ui/privacy_analytics_sheet.gd").new()
	root.add_child(ui)
	await process_frame
	var toggle := ui.find_child("PrivacySettingsCard", true, false) as PanelContainer
	if not _check(toggle != null, "Privacy controls are missing"):return
	var action_count := 0
	for node in ui.find_children("*", "Button", true, false):
		var button := node as Button
		action_count += 1
		if not _check(button.custom_minimum_size.y >= 44.0 and button.focus_mode == Control.FOCUS_ALL, "Privacy touch/focus regression on %s: min=%s focus=%d" % [button.name, str(button.custom_minimum_size), button.focus_mode]):return
	if not _check(action_count >= 4, "Privacy sheet is missing analytics, ads, policy or close actions"):return
	ui.queue_free()
	await process_frame

	analytics.call("set_analytics_opt_in", original)
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	print("OPT_IN_TELEMETRY_OK: off by default, anonymous payload, bounded buffer, opt-out, accessible privacy")
	quit(0)

func _check(value: bool, message: String) -> bool:
	if value:return true
	push_error(message)
	quit(1)
	return false
