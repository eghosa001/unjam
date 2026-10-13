extends CanvasLayer

# All telemetry choices are separate from advertising consent. The analytics
# toggle starts OFF, and advertising privacy still routes to Google UMP.
var _analytics_button: Button

func _ready() -> void:
	layer = 135
	var overlay := Control.new()
	overlay.name = "PrivacySettingsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.05, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var card := PanelContainer.new()
	card.name = "PrivacySettingsCard"
	card.anchor_left = 0.06
	card.anchor_right = 0.94
	card.anchor_top = 0.17
	card.anchor_bottom = 0.83
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#262d3b")
	style.border_color = Color("#789dff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", style)
	overlay.add_child(card)

	var padding := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_%s" % edge, 14)
	card.add_child(padding)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	padding.add_child(stack)

	_label(stack, "PRIVACY & DATA", 24, Color.WHITE, false)
	_label(stack, "OPTIONAL GAME ANALYTICS", 16, Color("#f0d580"), false)
	var description := _label(stack, "Help improve level fairness, responsiveness and tutorials. Sends only anonymous event totals and broad level ranges. No player ID, device ID or purchase data.", 14, Color("#f5f7fc"), true)
	description.custom_minimum_size.y = 90
	_analytics_button = _button(stack, "", _toggle_analytics)
	_refresh_analytics_label()
	_label(stack, "This choice is OFF unless you turn it on. Turning it off discards queued events. Advertising consent is separate.", 13, Color("#cbd3e2"), true)
	_button(stack, "AD PRIVACY OPTIONS", _open_ad_options)
	_button(stack, "VIEW PRIVACY POLICY", _open_policy)
	var close := _button(stack, "CLOSE", close_sheet)
	close.grab_focus.call_deferred()

func _label(parent: VBoxContainer, value: String, size: int, tint: Color, wrap: bool) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: VBoxContainer, label: String, cb: Callable) -> Button:
	var action := Button.new()
	action.text = label
	action.accessibility_name = label
	action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	action.focus_mode = Control.FOCUS_ALL
	action.custom_minimum_size.y = 48
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_font_size_override("font_size", 15)
	action.add_theme_color_override("font_color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#405a8c")
	box.set_corner_radius_all(12)
	box.set_content_margin_all(9)
	action.add_theme_stylebox_override("normal", box)
	action.pressed.connect(cb)
	parent.add_child(action)
	# The shared UI mount path can reset Button focus when the node enters the
	# tree. Reassert keyboard/Android accessibility focus on the live control.
	action.focus_mode = Control.FOCUS_ALL
	action.set_deferred("focus_mode", Control.FOCUS_ALL)
	return action

func _refresh_analytics_label() -> void:
	var state := "ON" if AnalyticsManager.analytics_opted_in() else "OFF"
	_analytics_button.text = "ANONYMOUS ANALYTICS: %s" % state
	_analytics_button.accessibility_name = "Optional anonymous game analytics, %s. Activate to change." % state.to_lower()
	_analytics_button.tooltip_text = "No analytics events are uploaded while OFF."

func _toggle_analytics() -> void:
	AnalyticsManager.set_analytics_opt_in(not AnalyticsManager.analytics_opted_in())
	_refresh_analytics_label()

func _open_ad_options() -> void:
	PrivacyManager.show_privacy_options()

func _open_policy() -> void:
	PrivacyManager.open_privacy_policy()

func close_sheet() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_sheet()
