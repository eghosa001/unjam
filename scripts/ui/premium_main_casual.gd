extends "res://scripts/ui/premium_main.gd"

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	var root := _page_root()
	var accent := _accent()
	_page_header(root, "SETTINGS", "Comfort, sound and accessibility", "AUTO-SAVE", PremiumDesignSystem.SUCCESS)

	var intro := _card(root, Vector2(0, 88), true)
	var intro_margin := _pad(intro, 18)
	var intro_label := _label("Tune sound, comfort and appearance across all three games.", 18, "muted", accent)
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_margin.add_child(intro_label)

	var controls := GridContainer.new()
	controls.name = "CompactSettingsGrid"
	controls.columns = 2
	controls.add_theme_constant_override("h_separation", 14)
	controls.add_theme_constant_override("v_separation", 14)
	root.add_child(controls)

	var setting_rows: Array = [
		["sound", "SOUND", "Effects", true],
		["music", "MUSIC", "Ambient audio", true],
		["vibration", "HAPTICS", "Touch feedback", true]
	]
	for setting in setting_rows:
		var key := String(setting[0])
		var enabled := bool(SaveManager.data.get(key, bool(setting[3])))
		var button := _setting_button(String(setting[1]), String(setting[2]), enabled, accent)
		button.pressed.connect(_toggle_setting.bind(key))
		controls.add_child(button)

	var reduced := bool(SaveManager.data.get("reduce_motion", false))
	var reduced_button := _setting_button("REDUCED MOTION", "Minimise non-essential animation", reduced, accent)
	reduced_button.pressed.connect(_toggle_reduced_motion)
	controls.add_child(reduced_button)

	var fast := bool(SaveManager.data.get("fast_animation", false))
	var fast_button := _setting_button("FAST ANIMATION", "Quicker gameplay motion", fast, accent)
	fast_button.pressed.connect(_toggle_setting.bind("fast_animation"))
	controls.add_child(fast_button)

	var shell := get_node_or_null("UXShell")
	var theme_name := "DARK"
	if shell != null and shell.get("theme_mode") != null:
		theme_name = String(shell.get("theme_mode")).to_upper()
	var appearance := _button("APPEARANCE   •   %s" % theme_name, Vector2(0, 84), "secondary")
	appearance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance.add_theme_font_size_override("font_size", 20)
	appearance.pressed.connect(func() -> void:
		if shell != null and shell.has_method("_toggle_theme"):
			shell.call("_toggle_theme")
		call_deferred("build_settings")
	)
	controls.add_child(appearance)

	var accessibility := _button("ACCESSIBILITY   •   LARGE TOUCH TARGETS", Vector2(0, 84), "secondary")
	accessibility.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accessibility.add_theme_font_size_override("font_size", 18)
	accessibility.disabled = true
	controls.add_child(accessibility)

	var help_card := _card(root, Vector2(0, 132), false)
	var help_margin := _pad(help_card, 18)
	var help_box := VBoxContainer.new()
	help_box.add_theme_constant_override("separation", 12)
	help_margin.add_child(help_box)
	var help_title := _label("HELP & PRIVACY", 20, "accent", accent)
	help_box.add_child(help_title)
	var utility := HBoxContainer.new()
	utility.add_theme_constant_override("separation", 12)
	help_box.add_child(utility)
	var how_to := _button("?  HOW TO PLAY", Vector2(0, 74), "utility")
	how_to.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_to.pressed.connect(_show_current_tutorial)
	utility.add_child(how_to)
	var privacy := _button("PRIVACY OPTIONS", Vector2(0, 74), "utility")
	privacy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	utility.add_child(privacy)

	var note := _label("Progress saves automatically. You can adjust sound, music, haptics, motion and appearance at any time.", 15, "muted", accent)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	PremiumVisuals.entrance(root, 0.018)

func _setting_button(title_text: String, detail_text: String, enabled: bool, accent: Color) -> Button:
	var state := "ON" if enabled else "OFF"
	var role := "success" if enabled else "toggle_off"
	var button := _button("%s   •   %s\n%s" % [title_text, state, detail_text], Vector2(0, 96), role)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	return button

func _toggle_reduced_motion() -> void:
	var enabled := not bool(SaveManager.data.get("reduce_motion", false))
	# `reduce_motion` is the canonical preference used by MotionSystem. Mirror the
	# legacy key during this release so existing decorative systems and old saves
	# cannot disagree while the migration is rolling forward.
	SaveManager.data["reduce_motion"] = enabled
	SaveManager.data["reduced_motion"] = enabled
	SaveManager.save()
	PremiumVisuals.apply_motion_preference()
	FeedbackManager.tap()
	build_settings()

func _show_current_tutorial() -> void:
	var shell := get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", selected_game_id)
