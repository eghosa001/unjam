extends Node

signal cloud_status_changed(message: String)

const FUNCTION_NAME := "unjam-cloud-save"
const REQUEST_TIMEOUT_SECONDS := 15.0
const SYNC_DEBOUNCE_SECONDS := 2.5
const SYNC_RETRY_START_SECONDS := 20.0
const SYNC_RETRY_MAX_SECONDS := 300.0
const CLOUD_ID_BYTES := 32
# Three complete 10,000-level campaigns can exceed the legacy 96 KiB cap.
# This limit is shared with the Edge Function; verify before sending.
const MAX_CLOUD_PAYLOAD_BYTES := 512 * 1024

# Paid-entitlement/transaction fields are intentionally absent. Google Play and
# the purchase ledger remain authoritative for Remove Ads, Starter Pack and
# consumable transaction history. The cloud snapshot protects gameplay state,
# settings and the player's current wallet balance.
const CLOUD_KEYS := [
	"highest_level",
	"stars",
	"rescued",
	"coins",
	"sound",
	"vibration",
	"music",
	"reduce_motion",
	"fast_animation",
	"gentle_effects",
	"language_code",
	# Keep all three campaigns and resumable Water/Block runs in a backup.
	"game_progress",
	"multi_active_runs",
	"decorations",
	"collection_levels",
	"crown_tokens",
	"competition_claimed_periods",
	"competition_display_name",
	"reward_double_claims",
	"meta_progression",
	"lantern_shield_month",
	"lantern_shield_uses",
	"garden_last_gift_date",
	"garden_gifts_claimed",
	"daily_last_date",
	"daily_streak",
	"daily_best_streak",
	"daily_completed",
	"daily_game_choices",
	"hints_used",
	"undos_used",
	"rewarded_ads_watched",
	# Consent belongs to the device and current UMP session, never a cloud save.
	"total_levels_completed",
	"total_rescues",
	"perfect_clears",
	"perfect_streak",
	"best_perfect_streak",
	"milestone_chests",
	"world_badges",
	"prestige_points",
	"achievements",
	"achievement_points",
]

var _sync_timer: Timer
var _initial_reconciled := false
var _request_in_flight := false
var _pending_push := false
var _suppress_save_event := false
var _sync_retry_delay := SYNC_RETRY_START_SECONDS
var _cloud_status := "Checking cloud backup..."

func backup_status() -> String:
	return _cloud_status

func _set_cloud_status(message: String) -> void:
	if _cloud_status == message:
		return
	_cloud_status = message
	cloud_status_changed.emit(message)

func _schedule_failed_cloud_retry() -> void:
	# In particular, an offline cold start must retry WITHOUT a new local save.
	_schedule_push(_sync_retry_delay)
	_sync_retry_delay = minf(SYNC_RETRY_MAX_SECONDS, _sync_retry_delay * 2.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_identity()
	_sync_timer = Timer.new()
	_sync_timer.name = "CloudSaveDebounce"
	_sync_timer.one_shot = true
	_sync_timer.wait_time = SYNC_DEBOUNCE_SECONDS
	_sync_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_timer.timeout.connect(_push_now)
	add_child(_sync_timer)
	if SaveManager.has_signal("save_committed") and not SaveManager.save_committed.is_connected(_on_save_committed):
		SaveManager.save_committed.connect(_on_save_committed)
	call_deferred("_initial_reconcile")

func _ensure_identity() -> void:
	var existing := String(SaveManager.data.get("cloud_save_id", "")).strip_edges().to_lower()
	if existing.length() == 64 and _is_hex(existing):
		return
	var generated := Crypto.new().generate_random_bytes(CLOUD_ID_BYTES).hex_encode()
	if generated.length() != 64:
		generated = ("%s:%s:%s" % [
			Time.get_unix_time_from_system(),
			Time.get_ticks_usec(),
			OS.get_unique_id(),
		]).sha256_text()
	SaveManager.data.cloud_save_id = generated
	SaveManager.data.cloud_save_revision = 0
	SaveManager.save()

func _is_hex(value: String) -> bool:
	for index in range(value.length()):
		if "0123456789abcdef".find(value.substr(index, 1).to_lower()) < 0:
			return false
	return true

# The cloud identifier is a secret recovery credential. It is revealed only
# from the explicit Backup screen, never included in analytics or error logs.
func recovery_code() -> String:
	var value := String(SaveManager.data.get("cloud_save_id", "")).strip_edges().to_lower()
	return value if value.length() == 64 and _is_hex(value) else ""

func restore_from_recovery_code(raw_code: String, callback: Callable) -> void:
	# A restore is deliberately read-first. Never replace the working install ID
	# or player progress until the remote backup is confirmed to exist.
	var code := raw_code.strip_edges().replace(" ", "").replace("-", "").to_lower()
	if code.length() != 64 or not _is_hex(code):
		_recovery_finished(callback, false, "Enter a valid 64-character recovery code.")
		return
	if code == recovery_code():
		_recovery_finished(callback, true, "This is already your active backup.")
		return
	if not _initial_reconciled or _request_in_flight:
		_recovery_finished(callback, false, "Cloud sync is busy. Try again shortly.")
		return
	_request_in_flight = true
	_request_json({"action":"pull", "cloud_save_id":code}, func(ok: bool, _status: int, body: Dictionary) -> void:
		_request_in_flight = false
		if not ok or not bool(body.get("exists", false)):
			_recovery_finished(callback, false, "Backup unavailable. Check the code and your connection.")
			return
		var backup: Variant = body.get("save", {})
		if not (backup is Dictionary) or (backup as Dictionary).is_empty():
			_recovery_finished(callback, false, "Backup is incomplete; your current progress was kept.")
			return
		var revision := maxi(0, int(body.get("revision", 0)))
		if _sync_timer != null:
			_sync_timer.stop()
		_pending_push = false
		_initial_reconciled = true
		# Switch identity before applying the validated snapshot. Purchase
		# ownership is intentionally excluded from CLOUD_KEYS.
		_suppress_save_event = true
		SaveManager.data.cloud_save_id = code
		SaveManager.data.cloud_save_revision = revision
		_suppress_save_event = false
		_apply_remote(backup as Dictionary, revision)
		_recovery_finished(callback, true, "Cloud progress recovered. Restart UNJAM to refresh every screen.")
	)

func _recovery_finished(callback: Callable, success: bool, message: String) -> void:
	if callback.is_valid():
		callback.call(success, message)

func _on_save_committed() -> void:
	if _suppress_save_event or not _initial_reconciled:
		return
	_schedule_push()

func _schedule_push(delay: float = SYNC_DEBOUNCE_SECONDS) -> void:
	if _sync_timer == null:
		return
	_sync_timer.wait_time = maxf(0.2, delay)
	_sync_timer.start()

func _initial_reconcile() -> void:
	_set_cloud_status("Checking cloud backup...")
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	_request_json({
		"action": "pull",
		"cloud_save_id": cloud_id,
	}, func(ok: bool, _status: int, body: Dictionary) -> void:
		var local_revision := maxi(0, int(SaveManager.data.get("cloud_save_revision", 0)))
		if ok and bool(body.get("exists", false)):
			var remote_revision := maxi(0, int(body.get("revision", 0)))
			var remote_value: Variant = body.get("save", {})
			if remote_value is Dictionary and remote_revision > local_revision:
				var combined := _merge_progress_on_conflict(remote_value)
				_apply_remote(combined, remote_revision)
				if combined != remote_value:
					_initial_reconciled = true
					_set_cloud_status("Syncing offline progress to cloud...")
					_schedule_push(0.4)
					return
			elif remote_value is Dictionary and remote_value != _snapshot():
				# Local progress changed after the last successful upload.
				_initial_reconciled = true
				_set_cloud_status("Uploading newer phone progress...")
				_schedule_push(0.4)
				return
		_initial_reconciled = true
		if ok:
			_sync_retry_delay = SYNC_RETRY_START_SECONDS
			if not bool(body.get("exists", false)):
				_set_cloud_status("Creating your cloud backup...")
				_schedule_push(0.2)
			else:
				_set_cloud_status("Cloud backup synced.")
		else:
			_pending_push = true
			_set_cloud_status("Cloud is offline. Progress is saved locally; sync will retry.")
			_schedule_failed_cloud_retry()
	)

# Only merge monotonic gameplay achievements on cloud revision conflicts.
# Never sum currencies, paid purchase credits, daily streaks or completed
# transaction markers: those require a proper authoritative economy ledger.
func _merge_stars(a: Variant, b: Variant) -> Dictionary:
	var merged: Dictionary = a.duplicate(true) if a is Dictionary else {}
	if not b is Dictionary:
		return merged
	for key in (b as Dictionary):
		var text_key := String(key)
		if not text_key.is_valid_int():
			continue
		var level := int(text_key)
		if level < 1 or level > 10000:
			continue
		var best := clampi(int((b as Dictionary)[key]), 0, 3)
		if best > clampi(int(merged.get(str(level), 0)), 0, 3):
			merged[str(level)] = best
	return merged

func _merge_unlocks(a: Variant, b: Variant) -> Array:
	var merged: Array = a.duplicate(true) if a is Array else []
	if not b is Array:
		return merged
	var seen := {}
	for value in merged:
		seen[String(value)] = true
	for value in (b as Array):
		var entry := String(value)
		if not seen.has(entry) and merged.size() < 10000:
			merged.append(value)
			seen[entry] = true
	return merged

func _merge_progress_on_conflict(remote: Dictionary) -> Dictionary:
	var merged: Dictionary = remote.duplicate(true)
	var local := _snapshot()
	# Old server backups (created before all three games were supported)
	# must not erase Water/Block progress gained offline.
	merged["stars"] = _merge_stars(remote.get("stars", {}), local.get("stars", {}))
	merged["highest_level"] = maxi(int(remote.get("highest_level", 1)),
		int(local.get("highest_level", 1)))
	for key in ["rescued", "milestone_chests", "world_badges", "achievements",
		"daily_completed", "competition_claimed_periods", "reward_double_claims"]:
		merged[key] = _merge_unlocks(remote.get(key, []), local.get(key, []))
	for key in ["perfect_clears", "total_levels_completed", "best_perfect_streak",
		"daily_best_streak", "prestige_points", "achievement_points"]:
		merged[key] = maxi(int(remote.get(key, 0)), int(local.get(key, 0)))

	var remote_games = remote.get("game_progress", {})
	var local_games = local.get("game_progress", {})
	var games: Dictionary = remote_games.duplicate(true) if remote_games is Dictionary else {}
	if local_games is Dictionary:
		for game_id in ["water_sort", "block_puzzle"]:
			var local_game = (local_games as Dictionary).get(game_id, {})
			if not local_game is Dictionary:
				continue
			var remote_game = games.get(game_id, {})
			var game: Dictionary = remote_game.duplicate(true) if remote_game is Dictionary else {}
			for key in ["highest_level", "levels_completed", "perfect_clears",
				"best_perfect_streak", "daily_best_streak"]:
				game[key] = maxi(int(game.get(key, 0)), int(local_game.get(key, 0)))
			game["stars"] = _merge_stars(game.get("stars", {}), local_game.get("stars", {}))
			for key in ["world_badges", "milestone_chests", "achievements", "daily_completed"]:
				game[key] = _merge_unlocks(game.get(key, []), local_game.get(key, []))
			games[game_id] = game
	merged["game_progress"] = games

	# Active puzzles are not mathematically mergeable. Restore a local run
	# only if the remote side does not already have one for that game.
	var remote_runs = remote.get("multi_active_runs", {})
	var local_runs = local.get("multi_active_runs", {})
	var runs: Dictionary = remote_runs.duplicate(true) if remote_runs is Dictionary else {}
	if local_runs is Dictionary:
		for game_id in ["water_sort", "block_puzzle"]:
			if not runs.has(game_id) and (local_runs as Dictionary).has(game_id):
				runs[game_id] = (local_runs as Dictionary)[game_id].duplicate(true)
	merged["multi_active_runs"] = runs

	for key in ["language_code", "gentle_effects"]:
		if not merged.has(key) and local.has(key):
			merged[key] = local[key]
	return merged

func _apply_remote(remote: Dictionary, revision: int) -> void:
	_suppress_save_event = true
	for key in CLOUD_KEYS:
		if remote.has(key):
			var value: Variant = remote[key]
			SaveManager.data[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	SaveManager.data.cloud_save_revision = max(0, revision)
	if SaveManager.has_method("_sanitize"):
		SaveManager.call("_sanitize")
	# MultiGameManager caches stars; replacing cloud progression must invalidate
	# those values, otherwise the UI displays old scores after restore.
	if MultiGameManager.has_method("invalidate_cloud_progress_cache"):
		MultiGameManager.invalidate_cloud_progress_cache()
	SaveManager.save()
	_suppress_save_event = false

func _snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for key in CLOUD_KEYS:
		var value: Variant = SaveManager.data.get(key)
		snapshot[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return snapshot

func _push_now() -> void:
	if not _initial_reconciled:
		return
	if _request_in_flight:
		_pending_push = true
		return
	_request_in_flight = true
	_pending_push = false
	var save_snapshot := _snapshot()
	if JSON.stringify(save_snapshot).to_utf8_buffer().size() > MAX_CLOUD_PAYLOAD_BYTES:
		# A huge backup is safer kept locally than retried every five seconds.
		# An eventual smaller save will schedule another push normally.
		_request_in_flight = false
		_set_cloud_status("Cloud backup is too large. Your progress is saved on this phone.")
		return
	var payload := {
		"action": "push",
		"cloud_save_id": String(SaveManager.data.get("cloud_save_id", "")),
		"base_revision": maxi(0, int(SaveManager.data.get("cloud_save_revision", 0))),
		"save": save_snapshot,
	}
	_request_json(payload, func(ok: bool, status: int, body: Dictionary) -> void:
		_request_in_flight = false
		if ok:
			_sync_retry_delay = SYNC_RETRY_START_SECONDS
			if _sync_timer != null:
				_sync_timer.stop()
			_set_cloud_status("Cloud backup synced.")
			var new_revision := maxi(0, int(body.get("revision", SaveManager.data.get("cloud_save_revision", 0))))
			if new_revision != int(SaveManager.data.get("cloud_save_revision", 0)):
				_suppress_save_event = true
				SaveManager.data.cloud_save_revision = new_revision
				SaveManager.save()
				_suppress_save_event = false
		elif status == 409:
			_set_cloud_status("Cloud changed on another device. Reconciling saved levels...")
			var remote_value: Variant = body.get("save", {})
			var remote_revision := maxi(0, int(body.get("revision", 0)))
			if remote_value is Dictionary and remote_revision > int(SaveManager.data.get("cloud_save_revision", 0)):
				var combined := _merge_progress_on_conflict(remote_value)
				_apply_remote(combined, remote_revision)
				if combined != remote_value:
					_pending_push = true
				else:
					# A newer remote already contains all local progression.
					# A resolved 409 must not leave the Backup screen reporting
					# "Reconciling..." forever when no upload is required.
					_sync_retry_delay = SYNC_RETRY_START_SECONDS
					if _sync_timer != null:
						_sync_timer.stop()
					_set_cloud_status("Cloud backup synced.")
			else:
				_pending_push = true
				_set_cloud_status("Cloud conflict could not be resolved; sync will retry.")
		else:
			_pending_push = true
			_set_cloud_status("Cloud is offline. Progress is saved locally; sync will retry.")
		if _pending_push:
			_pending_push = false
			_schedule_failed_cloud_retry()
	)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if _initial_reconciled and not _request_in_flight:
			_push_now()

func _request_json(payload: Dictionary, callback: Callable) -> void:
	var endpoint := _function_endpoint()
	var headers := _request_headers()
	if endpoint.is_empty() or headers.is_empty():
		if callback.is_valid():
			callback.call(false, 0, {})
		return
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.max_redirects = 0
	add_child(request)
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		var parsed := _decode_response_json(body)
		var success := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
		if callback.is_valid():
			callback.call(success, response_code, parsed)
		request.queue_free()
	)
	var error := request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		if callback.is_valid():
			callback.call(false, 0, {})

func _decode_response_json(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}
	var text := body.get_string_from_utf8().strip_edges()
	if text.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var decoded: Variant = parser.data
	return decoded if decoded is Dictionary else {}


func _function_endpoint() -> String:
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	if not base.begins_with("https://"):
		return ""
	return "%s/functions/v1/%s" % [base, FUNCTION_NAME]

func _request_headers() -> PackedStringArray:
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if key.is_empty():
		return PackedStringArray()
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: %s" % key,
	])
