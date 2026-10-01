extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var preset := _read("res://export_presets.cfg")
	var project := _read("res://project.godot")
	var save_manager := _read("res://scripts/core/save_manager.gd")
	var robust_save := _read("res://scripts/core/robust_save_manager.gd")
	var cloud := _read("res://scripts/systems/cloud_save_manager.gd")
	var edge := _read("res://supabase/functions/unjam-cloud-save/index.ts")
	var migration := _read("res://supabase/migrations/20261001_create_player_cloud_saves.sql")

	if not preset.contains("user_data_backup/allow=true"):
		failures.append("Android automatic app-data backup is not enabled")
	if not project.contains('CloudSaveManager="*res://scripts/systems/cloud_save_manager.gd"'):
		failures.append("CloudSaveManager is not autoloaded")

	for token in [
		"signal save_committed",
		'"cloud_save_id": ""',
		'"cloud_save_revision": 0',
	]:
		if not save_manager.contains(token):
			failures.append("SaveManager cloud contract missing: %s" % token)

	for token in [
		"save_committed.emit()",
		"data.cloud_save_revision = max(0",
	]:
		if not robust_save.contains(token):
			failures.append("Robust save cloud contract missing: %s" % token)

	for token in [
		'const FUNCTION_NAME := "unjam-cloud-save"',
		"const CLOUD_ID_BYTES := 32",
		"Crypto.new().generate_random_bytes(CLOUD_ID_BYTES).hex_encode()",
		"SaveManager.save_committed.connect(_on_save_committed)",
		'"action": "pull"',
		'"action": "push"',
		'"base_revision"',
		"status == 409",
	]:
		if not cloud.contains(token):
			failures.append("CloudSaveManager missing: %s" % token)

	var keys_start := cloud.find("const CLOUD_KEYS :=")
	var keys_end := cloud.find("]\n\nvar _sync_timer", keys_start)
	var keys_block := cloud.substr(keys_start, keys_end - keys_start)
	for forbidden in [
		"remove_ads",
		"starter_pack_purchased",
		"purchased_products",
		"processed_purchase_tokens",
		"purchase_claim_ids",
		"purchase_install_id",
		"processed_purchase_revocations",
		"purchase_coin_debt",
	]:
		if keys_block.contains(forbidden):
			failures.append("Paid purchase state must not be restored from cloud save: %s" % forbidden)

	for token in [
		"save_key_hash",
		"revision bigint",
		"enable row level security",
		"revoke all on table public.player_cloud_saves from anon, authenticated",
	]:
		if not migration.contains(token):
			failures.append("Cloud save migration missing: %s" % token)

	for token in [
		"ALLOWED_KEYS",
		"SUPABASE_SERVICE_ROLE_KEY",
		"sha256Hex(cloudId)",
		"baseRevision",
		"conflict: true",
		"MAX_PAYLOAD_BYTES",
	]:
		if not edge.contains(token):
			failures.append("Cloud save edge function missing: %s" % token)

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("CLOUD_SAVE_PROTECTION_OK")
	quit(0)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
