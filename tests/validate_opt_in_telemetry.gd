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
	var first_receipt := String(analytics.call("_new_telemetry_batch_id"))
	var second_receipt := String(analytics.call("_new_telemetry_batch_id"))
	if not _check(first_receipt.length() == 32 and second_receipt.length() == 32 and first_receipt != second_receipt, "Telemetry batch receipt not random/valid"):return
	analytics.call("set_analytics_opt_in", true)
	if not _check((analytics.call("pending_telemetry_for_test") as Array).size() == 1, "Repeated opt-in generated duplicate session event"):return
	analytics.call("track", "level_complete", {"level": 230, "game_id": "water_sort", "player_id": "secret", "purchase_token": "private"})
	var events: Array = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() == 2, "Expected one session and one whitelisted event"):return
	var item: Dictionary = events[1]
	if not _check(item.size() == 3 and item["name"] == "level_complete" and item["game"] == "water_sort" and item["level_band"] == 100, "Telemetry payload includes extra data or incorrect broad level band"):return
	analytics.call("track", "water_sort_completed", {"level": 77})
	analytics.call("track", "block_puzzle_completed", {"level": 912})
	analytics.call("track", "rescue_attempt_failed", {"level": 12})
	events = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() == 5, "Game-specific milestone events were not normalized"):return
	if not _check(events[2]["name"] == "level_complete" and events[2]["game"] == "water_sort" and events[2]["level_band"] == 50, "Water completion lacks a clean game/level band"):return
	if not _check(events[3]["name"] == "level_complete" and events[3]["game"] == "block_puzzle" and events[3]["level_band"] == 500, "Block completion lacks a clean game/level band"):return
	if not _check(events[4]["name"] == "level_fail" and events[4]["game"] == "rescue_rush", "Rescue failure lacks a clean game ID"):return
	for i in range(45):
		analytics.call("track", "hint_used", {"level": i + 1})
	events = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() <= 24, "Telemetry buffering exceeds 24-event privacy bound"):return
	# Simulate a failed-but-not-yet-acknowledged batch. Revocation must
	# clear the retry receipt and never re-upload prior opt-in data.
	analytics.set("_telemetry_retry_batch", [{"name":"level_complete","game":"water_sort","level_band":100}])
	analytics.set("_telemetry_retry_id", first_receipt)
	analytics.call("set_analytics_opt_in", false)
	if not _check((analytics.call("pending_telemetry_for_test") as Array).is_empty(), "Opt-out did not discard pending events"):return
	if not _check((analytics.get("_telemetry_retry_batch") as Array).is_empty() and String(analytics.get("_telemetry_retry_id")).is_empty(), "Opt-out kept unsent in-flight receipt"):return

	var ui = load("res://scripts/ui/privacy_analytics_sheet.gd").new()
	root.add_child(ui)
	await process_frame
	var toggle := ui.find_child("PrivacySettingsCard", true, false) as PanelContainer
	var scroll := ui.find_child("PrivacySettingsScroll", true, false) as ScrollContainer
	if not _check(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Privacy disclosure cannot scroll safely on landscape phones"):return
	var l10n := root.get_node("LocalizationManager")
	var old_locale := String(l10n.language_code)
	for code in ["en", "es", "fr", "pt", "de", "it", "ha", "yo", "ig"]:
		l10n.call("set_language", code, false)
		var title := String(ui.call("_copy", "heading"))
		var disclosure := String(ui.call("_copy", "disclosure"))
		if not _check(title.length() > 5 and disclosure.length() > 65, "Missing privacy disclosure for %s" % code):return
	l10n.call("set_language", old_locale, false)
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
