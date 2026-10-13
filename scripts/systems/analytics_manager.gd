extends Node

const FramePacingProbe = preload("res://scripts/systems/frame_pacing_probe.gd")

# In-process QA counters always remain device-local. Production telemetry is
# OPTIONAL, OFF by default, and sends only seven whitelisted event types in
# anonymous aggregate form. No save identity, device ID or raw event properties.
signal event_recorded(event_name: String, safe_properties: Dictionary)

const MAX_EVENT_KINDS := 96
const MAX_RECENT_EVENTS := 24
const MAX_TELEMETRY_BATCH := 24
const TELEMETRY_EVENTS := ["session_start", "level_start", "level_complete", "level_restart", "hint_used", "undo_used", "level_fail"]
const TELEMETRY_GAMES := ["rescue_rush", "water_sort", "block_puzzle"]
const TELEMETRY_LEVEL_BANDS := [1, 10, 50, 100, 500, 1000, 5000, 10000]
const SAFE_NUMBER_FIELDS := [
	"level", "moves", "stars", "score", "lines", "attempt",
	"hint_uses", "undo_uses", "session_count", "difficulty_score"
]
const SAFE_BOOLEAN_FIELDS := ["daily", "first_attempt_success", "provider", "success"]
const SAFE_ENUM_FIELDS := ["game", "game_id", "outcome", "mode", "placement"]

var enabled := true
var _session_counts: Dictionary = {}
var _session_recent: Array[Dictionary] = []
var _frame_probe := FramePacingProbe.new()
var _telemetry_events: Array = []
var _telemetry_timer: Timer
var _telemetry_in_flight := false

func _ready() -> void:
	_telemetry_timer = Timer.new()
	_telemetry_timer.wait_time = 25.0
	_telemetry_timer.autostart = true
	_telemetry_timer.timeout.connect(_flush_opt_in_telemetry)
	add_child(_telemetry_timer)

func analytics_opted_in() -> bool:
	return bool(SaveManager.data.get("analytics_opt_in", false))

func set_analytics_opt_in(allowed: bool) -> void:
	SaveManager.data["analytics_opt_in"] = allowed
	SaveManager.save()
	if allowed:
		_queue_telemetry("session_start", {})
	else:
		_telemetry_events.clear()

func pending_telemetry_for_test() -> Array:
	return _telemetry_events.duplicate(true)

func _queue_telemetry(event_name: String, props: Dictionary) -> void:
	if not analytics_opted_in() or event_name not in TELEMETRY_EVENTS:
		return
	var game := String(props.get("game_id", props.get("game", "all")))
	if game not in TELEMETRY_GAMES:
		game = "all"
	var level := clampi(int(props.get("level", 0)), 0, 10000)
	var band := 0
	if level > 0:
		for candidate in TELEMETRY_LEVEL_BANDS:
			if level >= candidate:
				band = candidate
	var event := {"name": event_name, "game": game, "level_band": band}
	_telemetry_events.append(event)
	while _telemetry_events.size() > MAX_TELEMETRY_BATCH:
		_telemetry_events.pop_front()
	if _telemetry_events.size() >= MAX_TELEMETRY_BATCH:
		_flush_opt_in_telemetry()

func _flush_opt_in_telemetry() -> void:
	if not analytics_opted_in() or _telemetry_in_flight or _telemetry_events.is_empty():
		return
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1":
		return
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if not base.begins_with("https://") or key.is_empty():
		return
	var request := HTTPRequest.new()
	request.timeout = 8.0
	request.max_redirects = 0
	add_child(request)
	_telemetry_in_flight = true
	var batch := _telemetry_events.duplicate(true)
	_telemetry_events.clear()
	request.request_completed.connect(func(result: int, status: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		_telemetry_in_flight = false
		if analytics_opted_in() and (result != HTTPRequest.RESULT_SUCCESS or status < 200 or status >= 300):
			_telemetry_events = batch + _telemetry_events
			if _telemetry_events.size() > MAX_TELEMETRY_BATCH:
				_telemetry_events = _telemetry_events.slice(0, MAX_TELEMETRY_BATCH)
		request.queue_free()
	)
	var headers := PackedStringArray(["Content-Type: application/json", "apikey: %s" % key])
	var error := request.request("%s/functions/v1/unjam-telemetry" % base, headers, HTTPClient.METHOD_POST, JSON.stringify({"consent": true, "events": batch}))
	if error != OK:
		_telemetry_in_flight = false
		if analytics_opted_in():
			_telemetry_events = batch + _telemetry_events
		request.queue_free()

func _process(delta: float) -> void:
	# One constant-time ring write per frame. No disk/network calls, sorting,
	# allocation-heavy payloads or performance metrics in gameplay callbacks.
	_frame_probe.record_frame(delta)

func quality_snapshot() -> Dictionary:
	return _frame_probe.snapshot()

func _notification(what: int) -> void:
	# Android QA builds can capture this numeric-only summary with adb logcat on
	# pause/close. No production telemetry, account data or disk retention.
	if OS.is_debug_build() and what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		print("[unjam-frame-quality] %s" % JSON.stringify(quality_snapshot()))

func track(event_name: String, properties: Dictionary = {}) -> void:
	if not enabled or not _safe_name(event_name) or (not _session_counts.has(event_name) and _session_counts.size() >= MAX_EVENT_KINDS):
		return
	var filtered := _safe_properties(properties)
	_session_counts[event_name] = int(_session_counts.get(event_name, 0)) + 1
	_session_recent.append({"event": event_name, "properties": filtered})
	if _session_recent.size() > MAX_RECENT_EVENTS:
		_session_recent.pop_front()
	event_recorded.emit(event_name, filtered)
	_queue_telemetry(event_name, filtered)
	# Local QA counters are never sent. Only whitelisted aggregate events
	# from explicitly opted-in users may reach the separate telemetry endpoint.
	if OS.is_debug_build():
		print("[analytics] %s %s" % [event_name, JSON.stringify(filtered)])

func session_snapshot() -> Dictionary:
	return {"counts": _session_counts.duplicate(), "recent": _session_recent.duplicate(true), "quality": quality_snapshot()}

func _safe_properties(properties: Dictionary) -> Dictionary:
	var output := {}
	for key in SAFE_NUMBER_FIELDS:
		var raw: Variant = properties.get(key)
		if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
			output[key] = clampi(int(raw), 0, 100000000)
	for key in SAFE_BOOLEAN_FIELDS:
		if typeof(properties.get(key)) == TYPE_BOOL:
			output[key] = bool(properties[key])
	for key in SAFE_ENUM_FIELDS:
		var raw: Variant = properties.get(key)
		if raw is String and (raw as String).length() <= 32 and _safe_name(String(raw)):
			output[key] = raw
	return output

func _safe_name(value: String) -> bool:
	if value.is_empty() or value.length() > 56:
		return false
	for index in range(value.length()):
		var scalar := value.unicode_at(index)
		if not ((scalar >= 97 and scalar <= 122) or (scalar >= 48 and scalar <= 57) or scalar == 95):
			return false
	return true

func level_started(level_number: int) -> void:
	track("level_start", {"level": level_number})

func level_completed(level_number: int, moves: int, stars: int) -> void:
	track("level_complete", {"level": level_number, "moves": moves, "stars": stars})

func level_restarted(level_number: int) -> void:
	track("level_restart", {"level": level_number})

func hint_used(level_number: int) -> void:
	track("hint_used", {"level": level_number})

func undo_used(level_number: int) -> void:
	track("undo_used", {"level": level_number})
