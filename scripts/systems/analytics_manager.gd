extends Node

const FramePacingProbe = preload("res://scripts/systems/frame_pacing_probe.gd")

# In-process QA counters always remain device-local. Production telemetry is
# OPTIONAL, OFF by default, and sends only eight whitelisted event types in
# anonymous aggregate form. No save identity, device ID or raw event properties.
signal event_recorded(event_name: String, safe_properties: Dictionary)

const MAX_EVENT_KINDS := 96
const MAX_RECENT_EVENTS := 24
const MAX_TELEMETRY_BATCH := 24
const TELEMETRY_FOREGROUND_KEY := "telemetry_foreground_active"
const TELEMETRY_RETRY_START_MS := 25000
const TELEMETRY_RETRY_MAX_MS := 300000
const TELEMETRY_EVENTS := ["session_start", "session_interrupted", "level_start", "level_complete", "level_restart", "hint_used", "undo_used", "level_fail"]
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

# Voluntary, completely DEVICE-LOCAL 90s quality capture. This is not
# opt-in telemetry, never touches the server, and measures while a player
# navigates and plays. It does NOT claim GPU time or touch-to-photon latency.
const QA_CAPTURE_SECONDS := 90.0
var _qa_capture_probe := FramePacingProbe.new(7200, 2.0)
var _qa_capture_paused := false
var _qa_capture_uncertain_intervals := 0
var _qa_capture_pause_count := 0
var _qa_capture_active := false
var _qa_capture_done := false
var _qa_capture_seconds := 0.0
var _qa_capture_sample_after := 0.0
var _qa_capture_peak_static_mib := 0.0
var _qa_capture_peak_nodes := 0
var _qa_capture_start_utc := ""
var _telemetry_events: Array = []
var _telemetry_timer: Timer
var _telemetry_in_flight := false
# A retry preserves both the original anonymous batch and its one-use random
# receipt ID, preventing duplicate daily counts after an ambiguous HTTP timeout.
var _telemetry_retry_batch: Array = []
var _telemetry_retry_id := ""
var _telemetry_request: HTTPRequest
var _telemetry_consent_epoch := 0
var _telemetry_retry_after_ms := 0
var _telemetry_retry_delay_ms := TELEMETRY_RETRY_START_MS

func _ready() -> void:
	_telemetry_timer = Timer.new()
	_telemetry_timer.wait_time = 25.0
	_telemetry_timer.autostart = true
	_telemetry_timer.timeout.connect(_flush_opt_in_telemetry)
	add_child(_telemetry_timer)
	if analytics_opted_in():
		_begin_foreground_telemetry_session()
		_queue_telemetry("session_start", {})

func analytics_opted_in() -> bool:
	return bool(SaveManager.data.get("analytics_opt_in", false))

func set_analytics_opt_in(allowed: bool) -> void:
	if analytics_opted_in() == allowed:
		return
	# Cancel pending work when consent is revoked; in-flight HTTP already
	# accepted by the service cannot be retroactively removed from aggregates.
	_telemetry_consent_epoch += 1
	SaveManager.data["analytics_opt_in"] = allowed
	if allowed:
		# Never classify enabling analytics as a prior interruption.
		SaveManager.data[TELEMETRY_FOREGROUND_KEY] = true
	else:
		SaveManager.data.erase(TELEMETRY_FOREGROUND_KEY)
	SaveManager.save()
	if allowed:
		_queue_telemetry("session_start", {})
	else:
		_telemetry_events.clear()
		_telemetry_retry_batch.clear()
		_telemetry_retry_id = ""
		_telemetry_retry_after_ms = 0
		_telemetry_retry_delay_ms = TELEMETRY_RETRY_START_MS
		_telemetry_in_flight = false
		if _telemetry_request != null and is_instance_valid(_telemetry_request):
			_telemetry_request.cancel_request()
			_telemetry_request.queue_free()
			_telemetry_request = null

# This is NOT a native crash reporter. It counts foreground sessions that
# remained marked active across a subsequent cold start. OS force-stop,
# process termination and some ungraceful shutdowns are indistinguishable.
# It is optional, anonymous, and stores one Boolean in the local save only.
func _begin_foreground_telemetry_session() -> void:
	if not analytics_opted_in():
		return
	if bool(SaveManager.data.get(TELEMETRY_FOREGROUND_KEY, false)):
		_queue_telemetry("session_interrupted", {})
	SaveManager.data[TELEMETRY_FOREGROUND_KEY] = true
	SaveManager.save()

func _close_foreground_telemetry_session() -> void:
	if not analytics_opted_in():
		return
	if bool(SaveManager.data.get(TELEMETRY_FOREGROUND_KEY, false)):
		SaveManager.data[TELEMETRY_FOREGROUND_KEY] = false
		SaveManager.save()

func _resume_foreground_telemetry_session() -> void:
	if not analytics_opted_in():
		return
	if not bool(SaveManager.data.get(TELEMETRY_FOREGROUND_KEY, false)):
		SaveManager.data[TELEMETRY_FOREGROUND_KEY] = true
		SaveManager.save()

func pending_telemetry_for_test() -> Array:
	return _telemetry_events.duplicate(true)

func _queue_telemetry(event_name: String, props: Dictionary) -> void:
	if not analytics_opted_in():
		return
	# The three games use distinct local QA names. Normalize only the
	# whitelisted gameplay milestones, never upload arbitrary QA properties.
	var canonical := event_name
	var game := String(props.get("game_id", props.get("game", "all")))
	match event_name:
		"water_sort_attempt_started":
			canonical = "level_start"
			game = "water_sort"
		"water_sort_completed":
			canonical = "level_complete"
			game = "water_sort"
		"water_sort_attempt_stuck":
			canonical = "level_fail"
			game = "water_sort"
		"water_sort_attempt_finished":
			if String(props.get("outcome", "")) != "restart":
				return
			canonical = "level_restart"
			game = "water_sort"
		"block_puzzle_level_started":
			canonical = "level_start"
			game = "block_puzzle"
		"block_puzzle_completed":
			canonical = "level_complete"
			game = "block_puzzle"
		"block_puzzle_level_restarted":
			canonical = "level_restart"
			game = "block_puzzle"
		"rescue_attempt_failed":
			canonical = "level_fail"
			game = "rescue_rush"
	if canonical not in TELEMETRY_EVENTS:
		return
	if game not in TELEMETRY_GAMES:
		game = "all"
	var level := clampi(int(props.get("level", 0)), 0, 10000)
	var band := 0
	if level > 0:
		for candidate in TELEMETRY_LEVEL_BANDS:
			if level >= candidate:
				band = candidate
	var event := {"name": canonical, "game": game, "level_band": band}
	_telemetry_events.append(event)
	while _telemetry_events.size() > MAX_TELEMETRY_BATCH:
		_telemetry_events.pop_front()
	if _telemetry_events.size() >= MAX_TELEMETRY_BATCH:
		_flush_opt_in_telemetry()

func _new_telemetry_batch_id() -> String:
	# One random identifier PER batch, never per installation or player.
	# It is held in memory only and is never used to link gameplay sessions.
	return Crypto.new().generate_random_bytes(16).hex_encode()

func _schedule_telemetry_retry() -> void:
	_telemetry_retry_after_ms = Time.get_ticks_msec() + _telemetry_retry_delay_ms
	_telemetry_retry_delay_ms = mini(TELEMETRY_RETRY_MAX_MS, _telemetry_retry_delay_ms * 2)

func _flush_opt_in_telemetry() -> void:
	if not analytics_opted_in() or _telemetry_in_flight:
		return
	if Time.get_ticks_msec() < _telemetry_retry_after_ms:
		return
	if _telemetry_retry_batch.is_empty() and _telemetry_events.is_empty():
		return
	if OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") == "1":
		return
	var base := String(ProjectSettings.get_setting("monetization/supabase_url", "")).strip_edges().trim_suffix("/")
	var key := String(ProjectSettings.get_setting("monetization/supabase_publishable_key", "")).strip_edges()
	if not base.begins_with("https://") or key.is_empty():
		return
	if _telemetry_retry_batch.is_empty():
		_telemetry_retry_batch = _telemetry_events.duplicate(true)
		_telemetry_retry_id = _new_telemetry_batch_id()
		_telemetry_events.clear()
	var batch := _telemetry_retry_batch.duplicate(true)
	var batch_id := _telemetry_retry_id
	var consent_epoch := _telemetry_consent_epoch
	var request := HTTPRequest.new()
	request.timeout = 8.0
	request.max_redirects = 0
	add_child(request)
	_telemetry_request = request
	_telemetry_in_flight = true
	request.request_completed.connect(func(result: int, status: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		if consent_epoch != _telemetry_consent_epoch:
			request.queue_free()
			return
		_telemetry_in_flight = false
		_telemetry_request = null
		if result == HTTPRequest.RESULT_SUCCESS and status >= 200 and status < 300:
			_telemetry_retry_batch.clear()
			_telemetry_retry_id = ""
			_telemetry_retry_after_ms = 0
			_telemetry_retry_delay_ms = TELEMETRY_RETRY_START_MS
			if not _telemetry_events.is_empty():
				call_deferred("_flush_opt_in_telemetry")
		else:
			_schedule_telemetry_retry()
		# On failure retain the SAME random batch ID and data. An eventual
		# replay after a committed-but-timed-out response remains idempotent.
		request.queue_free()
	)
	var headers := PackedStringArray(["Content-Type: application/json", "apikey: %s" % key])
	var payload := JSON.stringify({"consent": true, "batch_id": batch_id, "events": batch})
	var error := request.request("%s/functions/v1/unjam-telemetry" % base, headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		_telemetry_in_flight = false
		_telemetry_request = null
		request.queue_free()
		_schedule_telemetry_retry()
		# The batch and receipt remain pending for the next timer attempt.

func _process(delta: float) -> void:
	# One constant-time ring write per frame. No disk/network calls, sorting,
	# allocation-heavy payloads or performance metrics in gameplay callbacks.
	_frame_probe.record_frame(delta)
	if not _qa_capture_active or _qa_capture_paused or not is_finite(delta) or delta <= 0.0:
		return
	# A 300-800 ms main-thread stall is precisely the jank this QA tool
	# is intended to reveal. The normal 600-frame rolling probe stays strict
	# for focus changes; manual foreground QA captures stalls up to 2s.
	if delta > 2.0:
		_qa_capture_uncertain_intervals += 1
		return
	_qa_capture_probe.record_frame(delta)
	_qa_capture_seconds += delta
	_qa_capture_sample_after -= delta
	if _qa_capture_sample_after <= 0.0:
		_qa_capture_sample_after = 1.0
		_qa_sample_static_monitors()
	if _qa_capture_seconds >= QA_CAPTURE_SECONDS:
		finish_local_quality_capture()

func _qa_sample_static_monitors() -> void:
	# Godot's static-memory monitor is NOT an Android RSS or heap-size trace.
	# Sampling once a second prevents extra work in interactive frames.
	_qa_capture_peak_static_mib = maxf(_qa_capture_peak_static_mib,
		float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0)
	_qa_capture_peak_nodes = maxi(_qa_capture_peak_nodes,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))

func start_local_quality_capture() -> void:
	_qa_capture_probe.reset()
	_qa_capture_paused = false
	_qa_capture_uncertain_intervals = 0
	_qa_capture_pause_count = 0
	_qa_capture_active = true
	_qa_capture_done = false
	_qa_capture_seconds = 0.0
	_qa_capture_sample_after = 0.0
	_qa_capture_peak_static_mib = 0.0
	_qa_capture_peak_nodes = 0
	_qa_capture_start_utc = Time.get_datetime_string_from_system(true,true)
	_qa_sample_static_monitors()

func finish_local_quality_capture() -> void:
	if _qa_capture_active:
		_qa_capture_active = false
		_qa_capture_done = true
		_qa_sample_static_monitors()

func local_quality_capture_report() -> Dictionary:
	var report := _qa_capture_probe.snapshot()
	report["state"] = "capturing" if _qa_capture_active else ("ready" if _qa_capture_done else "not_started")
	report["duration_seconds"] = snappedf(_qa_capture_seconds,0.1)
	report["target_seconds"] = QA_CAPTURE_SECONDS
	report["peak_static_memory_mib"] = snappedf(_qa_capture_peak_static_mib,0.1)
	report["peak_scene_nodes"] = _qa_capture_peak_nodes
	report["pause_count"] = _qa_capture_pause_count
	report["uncertain_intervals"] = _qa_capture_uncertain_intervals
	report["captured_utc"] = _qa_capture_start_utc
	return report

func local_quality_report_text() -> String:
	var report := local_quality_capture_report()
	var screen := DisplayServer.screen_get_size()
	return "\n".join(PackedStringArray([
		"UNJAM / DEVICE QUALITY REPORT / 1.0.11",
		"Date UTC: %s" % String(report["captured_utc"]),
		"Platform: %s / screen %dx%d" % [OS.get_name(),screen.x,screen.y],
		"State: %s / gameplay seconds: %.1f of 90" % [report["state"],float(report["duration_seconds"])],
		"Frame intervals sampled: %d" % int(report["sampled_frames"]),
		"p50 / p95 / p99 CPU main-loop interval: %.2f / %.2f / %.2f ms" % [
			float(report["p50_frame_ms"]),float(report["p95_frame_ms"]),float(report["p99_frame_ms"])
		],
		"Intervals >16.7ms / >33.3ms: %.2f%% / %.2f%%" % [
			float(report["over_16_7_percent"]),float(report["over_33_3_percent"])
		],
		"Peak Godot static-memory monitor: %.1f MiB" % float(report["peak_static_memory_mib"]),
		"Peak scene-node monitor: %d" % int(report["peak_scene_nodes"]),
		"Foreground interruptions / >2s uncertain intervals: %d / %d" % [
			int(report["pause_count"]), int(report["uncertain_intervals"])
		],
		"NOTE: Device-local QA capture only. Not GPU rendering time, Android RSS, touch latency, FPS certification, crash rate, or production analytics.",
		"NOTE: No player identifiers or gameplay history. Copied by the player; never uploaded automatically."
	]))

func quality_snapshot() -> Dictionary:
	return _frame_probe.snapshot()

func _notification(what: int) -> void:
	# Backgrounding is a normal Android action, never evidence of a crash.
	# Do not count hours spent with the app paused as foreground jank.
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		if _qa_capture_active and not _qa_capture_paused:
			_qa_capture_paused = true
			_qa_capture_pause_count += 1
		_close_foreground_telemetry_session()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_qa_capture_paused = false
		_resume_foreground_telemetry_session()
	# Device-local debug frame numbers are never sent to the backend.
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
	track("level_start", {"level": level_number, "game_id": "rescue_rush"})

func level_completed(level_number: int, moves: int, stars: int) -> void:
	track("level_complete", {"level": level_number, "moves": moves, "stars": stars, "game_id": "rescue_rush"})

func level_restarted(level_number: int) -> void:
	track("level_restart", {"level": level_number, "game_id": "rescue_rush"})

func hint_used(level_number: int) -> void:
	track("hint_used", {"level": level_number, "game_id": "rescue_rush"})

func undo_used(level_number: int) -> void:
	track("undo_used", {"level": level_number, "game_id": "rescue_rush"})
