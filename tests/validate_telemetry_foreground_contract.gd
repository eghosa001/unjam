extends SceneTree

func _initialize() -> void:
	var client := FileAccess.get_file_as_string("res://scripts/systems/analytics_manager.gd")
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-telemetry/index.ts")
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261013_aggregate_foreground_interruptions.sql")
	for token in [
		'"session_interrupted"',
		"TELEMETRY_FOREGROUND_KEY",
		"NOTIFICATION_APPLICATION_PAUSED",
		"NOTIFICATION_APPLICATION_RESUMED",
		"SaveManager.data.erase(TELEMETRY_FOREGROUND_KEY)",
		'_queue_telemetry("session_interrupted", {})',
	]:
		if not client.contains(token):
			push_error("Missing private session diagnostic guard: " + token)
			quit(1)
			return
	for token in [
		'"session_interrupted"',
		'game_id !== "all"',
		'level_band !== 0',
		'body.consent !== true',
	]:
		if not edge.contains(token):
			push_error("Backend does not constrain stability event: " + token)
			quit(1)
			return
	for token in [
		"security invoker",
		"revoke all on function",
		"to service_role",
		"unclean_foreground_starts",
		"session_interrupted",
	]:
		if not sql.contains(token):
			push_error("Missing private aggregate or privilege: " + token)
			quit(1)
			return
	print("FOREGROUND_STABILITY_CONTRACT_OK: aggregate, consent, service-only")
	quit(0)
