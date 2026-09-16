extends "res://scripts/ui/premium_main.gd"

func add_background() -> void:
	# Base level builders call add_background() directly. Override it so every
	# secondary surface uses the final bright backdrop without allocating the
	# retired PremiumBackdrop first.
	if content == null or not is_instance_valid(content):
		return
	var existing := content.get_node_or_null("Unjam3DSurfaceBackdrop") as Unjam3DBackdrop
	if existing == null:
		existing = Unjam3DBackdrop.new()
		existing.name = "Unjam3DSurfaceBackdrop"
		existing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		existing.z_index = -100
		content.add_child(existing)
		content.move_child(existing, 0)
	existing.configure(_accent())

func _page_root() -> VBoxContainer:
	clear_content()
	add_background()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 46)
	outer.add_theme_constant_override("margin_right", 46)
	outer.add_theme_constant_override("margin_top", 42)
	outer.add_theme_constant_override("margin_bottom", 42)
	content.add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	return root

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
	var theme_name := "LIGHT"
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
	_add_surface_diorama(selected_game_id, "Settings3DDiorama")

func _setting_button(title_text: String, detail_text: String, enabled: bool, accent: Color) -> Button:
	var state := "ON" if enabled else "OFF"
	var role := "success" if enabled else "toggle_off"
	var button := _button("%s   •   %s\n%s" % [title_text, state, detail_text], Vector2(0, 96), role)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	return button

func _toggle_reduced_motion() -> void:
	var enabled := not bool(SaveManager.data.get("reduce_motion", false))
	SaveManager.data["reduce_motion"] = enabled
	SaveManager.save()
	PremiumVisuals.apply_motion_preference()
	FeedbackManager.tap()
	build_settings()

func _show_current_tutorial() -> void:
	var shell := get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial", selected_game_id)

func build_collection() -> void:
	super.build_collection()
	_add_surface_diorama("rescue_rush", "Collection3DDiorama")

func build_level_select() -> void:
	super.build_level_select()
	_add_surface_diorama("rescue_rush", "Levels3DDiorama")

func build_multi_level_select() -> void:
	super.build_multi_level_select()
	_add_surface_diorama(selected_game_id, "Levels3DDiorama")

func _add_surface_diorama(game_id: String, node_name: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var old := content.get_node_or_null(node_name)
	if old != null:
		content.remove_child(old)
		old.queue_free()
	var art := Unjam3DGameArt.new()
	art.name = node_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.anchor_left = 1.0
	art.anchor_top = 1.0
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.offset_left = -430.0
	art.offset_top = -330.0
	art.offset_right = -30.0
	art.offset_bottom = -30.0
	art.z_index = -20
	art.modulate = Color(1, 1, 1, 0.58)
	art.configure(game_id)
	content.add_child(art)

func _upgrade_level_browser(game_id: String) -> void:
	# The level screen is styled once when it is built. This replaces the old
	# always-running polling helper and keeps the 4-column chunky 3D layout.
	if content == null or not is_instance_valid(content):
		return
	var accent := Unjam3DTheme.game_accent(game_id)
	var dark_accent := Unjam3DTheme.game_dark(game_id)
	var current_level := _highest_level_for_game(game_id)
	for grid in _collect_grids(content):
		if grid.columns != 5:
			continue
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		for child in grid.get_children():
			if not child is Button:
				continue
			var button := child as Button
			button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 218.0), maxf(button.custom_minimum_size.y, 120.0))
			button.add_theme_font_size_override("font_size", maxi(20, button.get_theme_font_size("font_size")))
			var first_line := button.text.get_slice("\n", 0).strip_edges()
			var is_current := "CURRENT" in button.text.to_upper() or (first_line.is_valid_int() and int(first_line) == current_level and not button.disabled)
			if button.disabled:
				Unjam3DTheme.gloss_button(button, Color("9db6c8"), false, 22)
				button.add_theme_color_override("font_color", Color("6d8597"))
			elif is_current:
				Unjam3DTheme.gloss_button(button, accent, true, 22)
			else:
				Unjam3DTheme.gloss_button(button, dark_accent, false, 22)

func _highest_level_for_game(game_id: String) -> int:
	if game_id == "rescue_rush":
		return int(SaveManager.data.get("highest_level", 1))
	return MultiGameManager.highest_level(game_id)
