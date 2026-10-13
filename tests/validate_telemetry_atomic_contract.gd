extends SceneTree

func _initialize() -> void:
	var edge := FileAccess.get_file_as_string("res://supabase/functions/unjam-telemetry/index.ts")
	var migration := FileAccess.get_file_as_string("res://supabase/migrations/20261013_add_atomic_telemetry_funnel.sql")
	var failures: Array[String] = []
	for token in [
		'sb.rpc("unjam_increment_telemetry_batch"',
		'const p_events = [...counts.values()].map(',
		'body.consent !== true',
		'body.events.length > 24',
	]:
		if not edge.contains(token):
			failures.append("Opt-in telemetry batch contract missing: %s" % token)
	if edge.contains('sb.rpc("unjam_increment_telemetry",'):
		failures.append("Telemetry still sends partial one-row RPC writes")
	for token in [
		'jsonb_array_length(p_events) not between 1 and 24',
		'perform public.unjam_increment_telemetry',
		'revoke all on function public.unjam_increment_telemetry_batch(jsonb)',
		'with (security_invoker = true)',
		'grant select on public.unjam_telemetry_daily_funnel to service_role',
		'completion_per_start_pct',
	]:
		if not migration.contains(token):
			failures.append("Analytics SQL trust/summary contract missing: %s" % token)
	var receipts := FileAccess.get_file_as_string("res://supabase/migrations/20261013_idempotent_anonymous_telemetry.sql")
	for term in ["batch_id text primary key", "on conflict do nothing", "v_inserted = 0", "unjam_increment_telemetry_batch(p_events)"]:
		if not receipts.contains(term):
			failures.append("Receipt de-duplication invariant missing: %s" % term)
	for term in ['batchId === undefined', 'unjam_increment_telemetry_batch_v2', 'p_batch_id: batchId']:
		if not edge.contains(term):
			failures.append("Legacy-compatible receipt HTTP contract missing: %s" % term)
	var client := FileAccess.get_file_as_string("res://scripts/systems/analytics_manager.gd")
	if not client.contains("generate_random_bytes(16).hex_encode()"):
		failures.append("No random per-batch receipt")
	if not client.contains("cancel_request()"):
		failures.append("Opt-out fails to cancel pending upload")
	if not failures.is_empty():
		for item in failures:
			push_error(item)
		quit(1)
		return
	print("TELEMETRY_ATOMIC_CONTRACT_OK: bounded opt-in batch, atomic SQL and service-only summary")
	quit(0)
