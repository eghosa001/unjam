extends Node

const FramePacingProbe = preload("res://scripts/systems/frame_pacing_probe.gd")

# Privacy-first in-process QA counters. This is deliberately NOT a production
# analytics backend: it sends no network requests, saves no identifiers and is
# bounded to one play session.
signal event_recorded(event_name: String, safe_properties: Dictionary)

const MAX_EVENT_KINDS := 96
const MAX_RECENT_EVENTS := 24
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

func _process(delta: float) -> void:
	# One constant-time ring write per frame. No disk/network calls, sorting,
	# allocation-heavy payloads or performance metrics in gameplay callbacks.
	_frame_probe.record_frame(delta)

func quality_snapshot() -> Dictionary:
	return _frame_probe.snapshot()

func track(event_name: String, properties: Dictionary = {}) -> void:
	if not enabled or not _safe_name(event_name) or (not _session_counts.has(event_name) and _session_counts.size() >= MAX_EVENT_KINDS):
		return
	var filtered := _safe_properties(properties)
	_session_counts[event_name] = int(_session_counts.get(event_name, 0)) + 1
	_session_recent.append({"event": event_name, "properties": filtered})
	if _session_recent.size() > MAX_RECENT_EVENTS:
		_session_recent.pop_front()
	event_recorded.emit(event_name, filtered)
	# A release does not emit debug data or forward events externally without
	# a separately reviewed, permissioned production analytics integration.
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
