extends SceneTree

# Change-scoped test: device-local frame capture, Settings entry, navigation,
# report honesty and no implicit consent/telemetry changes.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var Probe = load("res://scripts/systems/frame_pacing_probe.gd")
	var long_probe = Probe.new(1200)
	for _i in range(1000):
		long_probe.record_frame(0.016)
	if int(long_probe.snapshot().get("sampled_frames",0)) != 1000:
		return _fail("QA frame probe incorrectly capped to the 600-frame rolling HUD window")

	var analytics := root.get_node_or_null("AnalyticsManager")
	if analytics == null:
		return _fail("AnalyticsManager is unavailable")
	var prior_opt_in := bool(analytics.call("analytics_opted_in"))
	var packed := load("res://scenes/Main.tscn") as PackedScene
	var app := packed.instantiate() as Control
	root.add_child(app)
	await _frames(6)
	app.call("build_settings")
	await _frames(2)
	var quality := app.find_child("SettingsQualityLab",true,false) as Button
	if quality == null or quality.disabled or quality.size.x < 75.0:
		return _fail("Settings lacks an accessible QUALITY action")
	if not quality.accessibility_name.contains("measure"):
		return _fail("Device Quality Lab entry lacks a meaningful accessible name")
	quality.emit_signal("pressed")
	await _frames(2)
	var panel := app.get_node_or_null("DeviceQualityLab")
	if panel == null:
		return _fail("Quality Lab modal did not open")
	var scroll := panel.find_child("QualityLabScroll",true,false) as Control
	var report := panel.find_child("QualityLabReadout",true,false) as Label
	var start := _find_button(panel,"START 90S")
	if scroll == null or report == null or start == null:
		return _fail("Quality Lab modal is missing controls or report")
	var rect := scroll.get_global_rect()
	print("QUALITY_LAB_GEOMETRY: ",rect," root=",root.size," viewport=",app.get_viewport().get_visible_rect().size," scroll_scale=",scroll.scale)
	if rect.position.x < -1.0 or rect.position.y < -1.0 or rect.end.x > root.size.x + 1.0 or rect.end.y > root.size.y + 1.0:
		return _fail("Quality Lab content is clipped off compact-phone screen")
	start.emit_signal("pressed")
	await _frames(16)
	var captured: Dictionary = analytics.call("local_quality_capture_report")
	if String(captured.get("state","")) != "capturing" or int(captured.get("sampled_frames",0)) < 4:
		return _fail("Starting 90s QA capture did not measure main-loop frames")
	if String(app.get("current_surface")) != "games":
		return _fail("Quality Lab did not hand the player off to Choose Game")
	app.call("build_settings")
	await _frames(2)
	quality = app.find_child("SettingsQualityLab",true,false) as Button
	quality.emit_signal("pressed")
	await _frames(2)
	panel = app.get_node_or_null("DeviceQualityLab")
	var finish := _find_button(panel,"STOP & FREEZE")
	if finish == null or finish.disabled:
		return _fail("Cannot freeze a running QA capture")
	finish.emit_signal("pressed")
	await _frames(2)
	captured = analytics.call("local_quality_capture_report")
	if String(captured.get("state","")) != "ready" or int(captured.get("sampled_frames",0)) < 4:
		return _fail("Frozen QA capture lost its main-loop evidence")
	var report_text := String(analytics.call("local_quality_report_text"))
	for expected in ["p95", "p99", "No player identifiers", "Not GPU rendering time"]:
		if not report_text.contains(expected):
			return _fail("Quality report must contain measurement and honest limitations: " + expected)
	if bool(analytics.call("analytics_opted_in")) != prior_opt_in:
		return _fail("Running device QA unexpectedly changed production analytics consent")
	panel.queue_free()
	app.queue_free()
	await _frames(2)
	print("DEVICE_QUALITY_LAB_OK")
	quit(0)

func _find_button(root_node: Node, needle: String) -> Button:
	if root_node == null:
		return null
	if root_node is Button and needle in (root_node as Button).text:
		return root_node as Button
	for child in root_node.get_children():
		var hit := _find_button(child,needle)
		if hit != null:
			return hit
	return null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
