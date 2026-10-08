extends RefCounted

# A bounded, in-memory main-loop frame-interval sample for real-device QA.
# Does not collect device identifiers, IP addresses, accounts or gameplay text.
# It is NOT GPU timing, production crash reporting, or a telemetry backend.
const WINDOW_FRAMES := 600
const SLOW_FRAME_MS := 16.7
const VERY_SLOW_FRAME_MS := 33.3
const MAX_TRACKED_INTERVAL_SECONDS := 0.25

var _samples := PackedFloat32Array()
var _write_index := 0
var _total_sampled := 0

func record_frame(delta_seconds: float) -> void:
	# Backgrounding and editor focus changes can produce huge deltas; do not
	# misclassify them as in-game jank. Reject invalid measurements explicitly.
	if not is_finite(delta_seconds) or delta_seconds <= 0.0 or delta_seconds > MAX_TRACKED_INTERVAL_SECONDS:
		return
	var milliseconds := delta_seconds * 1000.0
	if _samples.size() < WINDOW_FRAMES:
		_samples.append(milliseconds)
	else:
		_samples[_write_index] = milliseconds
	_write_index = (_write_index + 1) % WINDOW_FRAMES
	_total_sampled += 1

func snapshot() -> Dictionary:
	var count := _samples.size()
	if count <= 0:
		return {
			"sampled_frames": 0,
			"p50_frame_ms": 0.0,
			"p95_frame_ms": 0.0,
			"p99_frame_ms": 0.0,
			"over_16_7_percent": 0.0,
			"over_33_3_percent": 0.0
		}
	var ordered: Array[float] = []
	var slow_count := 0
	var very_slow_count := 0
	for sample in _samples:
		ordered.append(sample)
		if sample > SLOW_FRAME_MS:
			slow_count += 1
		if sample > VERY_SLOW_FRAME_MS:
			very_slow_count += 1
	ordered.sort()
	return {
		"sampled_frames": count,
		"frames_since_launch": _total_sampled,
		"p50_frame_ms": snappedf(ordered[_percentile_index(count, 0.50)], 0.01),
		"p95_frame_ms": snappedf(ordered[_percentile_index(count, 0.95)], 0.01),
		"p99_frame_ms": snappedf(ordered[_percentile_index(count, 0.99)], 0.01),
		"over_16_7_percent": snappedf(100.0 * float(slow_count) / float(count), 0.01),
		"over_33_3_percent": snappedf(100.0 * float(very_slow_count) / float(count), 0.01)
	}

func reset() -> void:
	_samples.clear()
	_write_index = 0
	_total_sampled = 0

func _percentile_index(size: int, percentile: float) -> int:
	return clampi(ceili(float(size) * percentile) - 1, 0, maxi(0, size - 1))
