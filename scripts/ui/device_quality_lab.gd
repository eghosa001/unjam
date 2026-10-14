extends CanvasLayer

# Read-only, player-triggered diagnostics. All metrics stay on the phone;
# COPY REPORT is the only export path. It is deliberately separate from the
# optional production analytics/advertising consent systems.
const UI = preload("res://scripts/ui/figma_reference_canvas.gd")
const INK := Color("#eff7ff")
const MUTED := Color("#c8d6e9")
const MINT := Color("#6ce8be")
var _summary: Label
var _state: Label
var _note: Label
var _finish_button: Button
var _copy_button: Button
var _refresh_timer: Timer

func _ready() -> void:
	layer = 160
	var shade := ColorRect.new()
	shade.name = "QualityLabShade"
	shade.color = Color(0.012,0.025,0.055,0.95)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var frame := Control.new()
	frame.name = "QualityLabFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var view := get_viewport().get_visible_rect().size
	var scale_factor := minf(view.x / 390.0, view.y / 844.0)
	var scroll := ScrollContainer.new()
	scroll.name = "QualityLabScroll"
	scroll.custom_minimum_size = Vector2(356,734)
	scroll.size = Vector2(356,734)
	scroll.scale = Vector2.ONE * scale_factor
	scroll.position = (view - scroll.size * scale_factor) * 0.5
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.add_child(scroll)

	var panel := PanelContainer.new()
	panel.name = "QualityLabCard"
	panel.custom_minimum_size.x = 356
	panel.add_theme_stylebox_override("panel", UI.solid_box(Color("#1c293c"),19,Color("#5a84aa"),2))
	scroll.add_child(panel)
	var pad := MarginContainer.new()
	for edge in ["left","right","top","bottom"]:
		pad.add_theme_constant_override("margin_%s" % edge,17)
	panel.add_child(pad)
	var stack := VBoxContainer.new()
	stack.name = "QualityLabStack"
	stack.add_theme_constant_override("separation",9)
	pad.add_child(stack)

	_label(stack,"DEVICE QUALITY LAB",23,INK,false)
	_label(stack,"REAL GAMEPLAY • 90-SECOND TEST",14,MINT,false)
	var description := _label(stack,
		"Start the test, then play all three games. The app measures main-loop frame pacing while you play. Return to Settings → QUALITY to see your report.",
		14,MUTED,true)
	description.custom_minimum_size.y = 82

	_state = _label(stack,"",16,MINT,true)
	_state.name = "QualityLabState"
	_summary = _label(stack,"",14,INK,true)
	_summary.name = "QualityLabReadout"
	_summary.custom_minimum_size.y = 220
	var explanation := _label(stack,
		"Measured locally; no automatic upload. p95 is the 95th-percentile frame interval, not GPU rendering time. For actual smoothness, test on your phone during active play.",
		12,MUTED,true)
	explanation.custom_minimum_size.y = 75
	_button(stack,"START 90S + CHOOSE GAME",Color("#227457"),_start_capture)
	_finish_button = _button(stack,"STOP & FREEZE REPORT",Color("#405c83"),_finish_capture)
	_copy_button = _button(stack,"COPY QUALITY REPORT",Color("#36567b"),_copy_report)
	_button(stack,"CLOSE",Color("#384355"),queue_free)
	_note = _label(stack,"No report leaves your device unless you choose Copy.",12,MUTED,true)
	_note.name = "QualityLabNote"
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 0.8
	_refresh_timer.timeout.connect(_refresh)
	add_child(_refresh_timer)
	_refresh_timer.start()
	_refresh()

func _label(parent: Node, value: String, font_size: int, color: Color, wrap: bool) -> Label:
	var label := UI.label(value,font_size,color,font_size >= 16)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.accessibility_name = value
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, color: Color, callback: Callable) -> Button:
	var action := UI.premium_button(title,15,Color.WHITE,color,13)
	action.custom_minimum_size = Vector2(318,47)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	action.focus_mode = Control.FOCUS_ALL
	action.accessibility_name = title
	action.pressed.connect(callback)
	parent.add_child(action)
	action.set_deferred("focus_mode",Control.FOCUS_ALL)
	return action

func _refresh() -> void:
	if not is_inside_tree():
		return
	var report: Dictionary = AnalyticsManager.local_quality_capture_report()
	var state := String(report.get("state","not_started"))
	var seconds := float(report.get("duration_seconds",0.0))
	var total := int(report.get("sampled_frames",0))
	if state == "capturing":
		_state.text = "CAPTURING • %.0f / 90 SECONDS" % seconds
	elif state == "ready":
		_state.text = "REPORT READY • %.1f SECONDS" % seconds
	else:
		_state.text = "NOT STARTED • PLAY TO MEASURE"
	_state.accessibility_name = _state.text
	_finish_button.disabled = state != "capturing"
	_copy_button.disabled = total <= 0
	_summary.text = "\n".join(PackedStringArray([
		"FRAMES SAMPLED  %d" % total,
		"p50 INTERVAL      %.2f ms" % float(report.get("p50_frame_ms",0.0)),
		"p95 INTERVAL      %.2f ms" % float(report.get("p95_frame_ms",0.0)),
		"p99 INTERVAL      %.2f ms" % float(report.get("p99_frame_ms",0.0)),
		"OVER 16.7 ms      %.1f%%" % float(report.get("over_16_7_percent",0.0)),
		"OVER 33.3 ms      %.1f%%" % float(report.get("over_33_3_percent",0.0)),
		"PEAK STATIC RAM   %.1f MiB" % float(report.get("peak_static_memory_mib",0.0)),
		"PEAK SCENE NODES  %d" % int(report.get("peak_scene_nodes",0))
	]))
	_summary.accessibility_name = _summary.text

func _start_capture() -> void:
	AnalyticsManager.start_local_quality_capture()
	var parent := get_parent()
	queue_free()
	if parent != null and parent.has_method("_open_games_surface"):
		parent.call_deferred("_open_games_surface")

func _finish_capture() -> void:
	AnalyticsManager.finish_local_quality_capture()
	_refresh()

func _copy_report() -> void:
	var report := AnalyticsManager.local_quality_capture_report()
	if int(report.get("sampled_frames",0)) <= 0:
		return
	DisplayServer.clipboard_set(AnalyticsManager.local_quality_report_text())
	_note.text = "Copied. Paste the report in ChatGPT to review Android performance."

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
