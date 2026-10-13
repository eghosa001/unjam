extends SceneTree

func _initialize() -> void:
	var backend := FileAccess.get_file_as_string("res://supabase/functions/unjam-competition/index.ts")
	var sql := FileAccess.get_file_as_string("res://supabase/migrations/20261013_atomic_ranked_progress.sql")
	var errors: Array[String] = []
	for token in [
		'sb.rpc("unjam_record_progress"',
		'Number.isInteger(body.level_number)',
		'Number.isInteger(body.stars)',
		'new_clear: Boolean(update.new_clear)',
		'stars_upgraded: Boolean(update.stars_upgraded)',
	]:
		if not backend.contains(token):
			errors.append("Client score still bypasses atomic progress contract: %s" % token)
	for banned in [
		'async function upsertAllTimeProgress',
		'async function recordProgressEvent',
		'async function refreshWeeklyProgress',
		'await sb.from("progression_level_events").insert',
	]:
		if backend.contains(banned):
			errors.append("Race-prone progression SQL still called directly: %s" % banned)
	for required in [
		'pg_advisory_xact_lock',
		'date \'1970-01-01\'',
		'created_at >= now() - interval \'1 hour\'',
		'on conflict (player_hash,game_id,level_number) do nothing',
		'v_stars + p_stars - v_prior_best',
		'first_clear_week=p_week',
		'grant execute on function public.unjam_record_progress',
		'to service_role',
	]:
		if not sql.contains(required):
			errors.append("Atomic ranked completion SQL missing: %s" % required)
	if not errors.is_empty():
		for item in errors:
			push_error(item)
		quit(1)
		return
	print("ATOMIC_LEAGUE_CONTRACT_OK: locked unique clears, replay star delta, service-only RPC")
	quit(0)
