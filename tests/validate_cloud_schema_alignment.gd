extends SceneTree

func _initialize() -> void:
	var client := FileAccess.get_file_as_string("res://scripts/systems/cloud_save_manager.gd")
	var server := FileAccess.get_file_as_string("res://supabase/functions/unjam-cloud-save/index.ts")
	var multi := FileAccess.get_file_as_string("res://scripts/core/multi_game_manager.gd")
	for field in ['"game_progress"','"multi_active_runs"','"language_code"','"gentle_effects"']:
		if not client.contains(field) or not server.contains(field):
			push_error("Client/backend backup fields not aligned: %s" % field)
			quit(1)
			return
	for forbidden in ['"purchase_coin_debt"','"processed_purchase_tokens"',
		'"purchase_install_id"','"privacy_consent_status"']:
		# Consent and Google Play transaction credentials stay device-local.
		var allowed_block := server.substr(server.find("const ALLOWED_KEYS"),
			server.find("const MAX_PAYLOAD_BYTES") - server.find("const ALLOWED_KEYS"))
		if allowed_block.contains(forbidden):
			push_error("Backend cloud allows sensitive/device-only field: %s" % forbidden)
			quit(1)
			return
	if not client.contains("512 * 1024") or not server.contains("512 * 1024"):
		push_error("Client/server cloud size caps diverge")
		quit(1)
		return
	if not server.contains("OBJECT_KEYS") or not server.contains('typeof clean[key] !== "object"'):
		push_error("Malformed backed-up game dictionaries are accepted")
		quit(1)
		return
	if not multi.contains("invalidate_cloud_progress_cache"):
		push_error("Multi-game star cache is not reset on restore")
		quit(1)
		return
	print("CLOUD_SCHEMA_ALIGNMENT_OK: complete games, matching byte budgets, no cloud billing/consent")
	quit(0)
