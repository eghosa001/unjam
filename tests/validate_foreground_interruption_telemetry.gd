extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	var save := root.get_node("SaveManager")
	var analytics := root.get_node("AnalyticsManager")
	var previous_optin := bool(save.data.get("analytics_opt_in", false))
	var previous_marker: Variant = save.data.get("telemetry_foreground_active", null)
	analytics.call("set_analytics_opt_in", false)
	save.data.erase("telemetry_foreground_active")
	save.save()
	analytics.call("_begin_foreground_telemetry_session")
	if not _check(not save.data.has("telemetry_foreground_active"), "Stability signal tracked without consent"):return
	analytics.call("set_analytics_opt_in", true)
	if not _check(bool(save.data.get("telemetry_foreground_active", false)), "Consent did not mark an active foreground session"):return
	var before := (analytics.call("pending_telemetry_for_test") as Array).size()
	analytics.call("_close_foreground_telemetry_session")
	if not _check(not bool(save.data.get("telemetry_foreground_active", true)), "Normal Android backgrounding was marked as crash"):return
	analytics.call("_resume_foreground_telemetry_session")
	if not _check(bool(save.data.get("telemetry_foreground_active", false)), "Resume failed to mark active foreground"):return
	if not _check((analytics.call("pending_telemetry_for_test") as Array).size() == before, "Normal pause/resume produced false stability event"):return
	# Deliberately leave the foreground Boolean active to mimic a killed app
	# before the OS delivered the usual pause or close notification.
	analytics.call("_begin_foreground_telemetry_session")
	var events: Array = analytics.call("pending_telemetry_for_test")
	if not _check(events.size() == before + 1, "Previous foreground interruption not counted"):return
	var last_event: Dictionary = events.back()
	if not _check(last_event == {"name":"session_interrupted","game":"all","level_band":0}, "Interruption event contains identifiers or puzzle-level detail"):return
	analytics.call("set_analytics_opt_in", false)
	if not _check(not save.data.has("telemetry_foreground_active"), "Opting out did not erase the local stability marker"):return
	if not _check((analytics.call("pending_telemetry_for_test") as Array).is_empty(), "Opt-out retained interruption telemetry"):return
	analytics.call("set_analytics_opt_in", previous_optin)
	if previous_marker == null:
		save.data.erase("telemetry_foreground_active")
	else:
		save.data["telemetry_foreground_active"] = previous_marker
	save.save()
	print("FOREGROUND_STABILITY_TELEMETRY_OK: consent only, no false pause counts, no identifiers")
	quit(0)

func _check(ok: bool, detail: String) -> bool:
	if ok:
		return true
	push_error(detail)
	quit(1)
	return false
