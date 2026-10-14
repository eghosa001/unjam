extends SceneTree

const Probe = preload("res://scripts/systems/frame_pacing_probe.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var probe := Probe.new()
	var empty := probe.snapshot()
	if not _check(int(empty.get("sampled_frames",-1)) == 0, "Empty probe must have zero samples"):return
	for _i in range(570):
		probe.record_frame(1.0 / 60.0)
	for _i in range(30):
		probe.record_frame(0.050)
	var data := probe.snapshot()
	if not _check(data.sampled_frames == 600 and data.frames_since_launch == 600, "Frame ring did not retain bounded count"):return
	if not _check(float(data.p50_frame_ms) < 17.0 and float(data.p95_frame_ms) < 18.0 and float(data.p99_frame_ms) >= 49.0, "Percentile calculations are inaccurate"):return
	if not _check(float(data.over_33_3_percent) == 5.0, "Jank percentage should be 30 of 600 frames"):return
	# Keep measuring without growing the array; no expensive shifting each frame.
	for _i in range(1200):
		probe.record_frame(0.010)
	data = probe.snapshot()
	if not _check(data.sampled_frames == 600 and data.frames_since_launch == 1800 and float(data.over_33_3_percent) == 0.0, "Old slow frames were not evicted from the ring"):return
	for invalid in [-1.0,0.0,0.6,INF,NAN]:
		probe.record_frame(invalid)
	if not _check(probe.snapshot().frames_since_launch == 1800, "Invalid/pause intervals polluted the sample"):return
	probe.reset()
	if not _check(probe.snapshot().sampled_frames == 0, "Reset failed to clear sample"):return
	# Prove the custom 90-second ring does not overwrite only the first
	# 600 entries. The old modulo-WINDOW_FRAMES bug hid slow frames after 600.
	var extended := Probe.new(1200,2.0)
	for _i in range(1200):
		extended.record_frame(1.0/60.0)
	for _i in range(600):
		extended.record_frame(0.080)
	var extended_stats := extended.snapshot()
	if not _check(int(extended_stats.sampled_frames) == 1200 and int(extended_stats.frames_since_launch) == 1800, "Extended QA probe discarded legitimate gameplay"):return
	if not _check(is_equal_approx(float(extended_stats.over_33_3_percent),50.0), "Extended QA ring overwrote wrong sample indices"):return
	extended.record_frame(0.650)
	if not _check(int(extended.snapshot().frames_since_launch) == 1801, "650ms foreground freeze was hidden from QA"):return
	if not _check(float(extended.snapshot().p99_frame_ms) >= 79.0, "Foreground jank was lost from QA percentiles"):return
	var analytics := root.get_node_or_null("AnalyticsManager")
	if not _check(analytics != null and analytics.has_method("quality_snapshot"), "QA metrics unavailable from running app"):return
	# SceneTree unit harness does not consistently tick autoload _process; feed
	# its real integration method once to establish the reporting contract.
	analytics.call("_process",1.0 / 60.0)
	var aggregate: Dictionary = analytics.session_snapshot()
	if not _check(aggregate.has("quality") and aggregate["quality"] is Dictionary and int((aggregate["quality"] as Dictionary).get("sampled_frames",0)) > 0, "App session snapshot lacks real frame sample"):return
	# A report contains only bounded numeric samples, never device IDs or secrets.
	for key in (aggregate["quality"] as Dictionary).keys():
		if not _check((aggregate["quality"] as Dictionary)[key] is int or (aggregate["quality"] as Dictionary)[key] is float, "Quality report contains non-numeric personal data"):return
	print("FRAME_PACING_PROBE_OK: bounded ring, correct p95/p99, jank rate and in-app sample integration")
	quit(0)

func _check(value: bool, error: String) -> bool:
	if value:return true
	push_error(error)
	quit(1)
	return false
