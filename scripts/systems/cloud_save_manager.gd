extends Node

const FUNCTION_NAME := "unjam-cloud-save"
const REQUEST_TIMEOUT_SECONDS := 15.0
const SYNC_DEBOUNCE_SECONDS := 2.5
const CLOUD_ID_BYTES := 32

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
	"decorations",
	"collection_levels",
	"crown_tokens",
	"competition_claimed_periods",
	"competition_display_name",
	"reward_double_claims",
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
	"privacy_consent_status",
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
	var cloud_id := String(SaveManager.data.get("cloud_save_id", ""))
	_request_json({
		"action": "pull",
		"cloud_save_id": cloud_id,
	}, func(ok: bool, status: int, body: Dictionary) -> void:
		var local_revision := maxi(0, int(SaveManager.data.get("cloud_save_revision", 0)))
		if ok and bool(body.get("exists", false)):
			var remote_revision := maxi(0, int(body.get("revision", 0)))
			var remote_value: Variant = body.get("save", {})
			if remote_value is Dictionary and remote_revision > local_revision:
				_apply_remote(remote_value, remote_revision)
			elif remote_value is Dictionary and remote_value != _snapshot():
				# Same/older server revision with different local data means this
				# install changed after its last successful upload.
				_initial_reconciled = true
				_schedule_push(0.4)
				return
		_initial_reconciled = true
		if ok and not bool(body.get("exists", false)):
			_schedule_push(0.2)
		elif not ok:
			# Never block gameplay on networking. A later local save will retry,
			# and server-side revision checks prevent stale overwrite.
			_pending_push = true
	)

func _apply_remote(remote: Dictionary, revision: int) -> void:
	_suppress_save_event = true
	for key in CLOUD_KEYS:
		if remote.has(key):
			var value: Variant = remote[key]
			SaveManager.data[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	SaveManager.data.cloud_save_revision = max(0, revision)
	if SaveManager.has_method("_sanitize"):
		SaveManager.call("_sanitize")
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
	var payload := {
		"action": "push",
		"cloud_save_id": String(SaveManager.data.get("cloud_save_id", "")),
		"base_revision": maxi(0, int(SaveManager.data.get("cloud_save_revision", 0))),
		"save": _snapshot(),
	}
	_request_json(payload, func(ok: bool, status: int, body: Dictionary) -> void:
		_request_in_flight = false
		if ok:
			var new_revision := maxi(0, int(body.get("revision", SaveManager.data.get("cloud_save_revision", 0))))
			if new_revision != int(SaveManager.data.get("cloud_save_revision", 0)):
				_suppress_save_event = true
				SaveManager.data.cloud_save_revision = new_revision
				SaveManager.save()
				_suppress_save_event = false
		elif status == 409:
			var remote_value: Variant = body.get("save", {})
			var remote_revision := maxi(0, int(body.get("revision", 0)))
			if remote_value is Dictionary and remote_revision > int(SaveManager.data.get("cloud_save_revision", 0)):
				_apply_remote(remote_value, remote_revision)
		else:
			_pending_push = true
		if _pending_push:
			_pending_push = false
			_schedule_push(5.0)
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
