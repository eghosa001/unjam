extends "res://scripts/ui/robust_main.gd"

func _dark() -> bool:
	var shell := get_node_or_null("UXShell")
	return shell == null or String(shell.get("theme_mode")) != "light"

func _accent(game_id: String = "") -> Color:
	var id := selected_game_id if game_id.is_empty() else game_id
	return PremiumDesignSystem.accent_for_game(id)

func _label(text_value: String, font_size: int, kind: String = "body", tint: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	PremiumDesignSystem.apply_label(label, _dark(), kind, tint)
	return label

func _button(text_value: String, minimum: Vector2, role: String = "secondary", game_id: String = "") -> Button:
	var button := make_button(text_value, minimum, role == "primary")
	button.clip_text = true
	var font_size := 24 if get_viewport_rect().size.x >= 700.0 else 18
	PremiumDesignSystem.apply_button(button, _dark(), _accent(game_id), role, font_size)
	return button

func _card(parent: Node, minimum: Vector2, emphasis: bool = false, game_id: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	PremiumDesignSystem.apply_panel(panel, _dark(), _accent(game_id), emphasis, 30)
	parent.add_child(panel)
	return panel

func _pad(panel: PanelContainer, amount: int = 24) -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, amount)
	panel.add_child(margin)
	return margin

func _page_root() -> VBoxContainer:
	clear_content()
	add_background()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var compact := get_viewport_rect().size.x < 700.0
	var side_margin := 20 if compact else 46
	var vertical_margin := 24 if compact else 42
	outer.add_theme_constant_override("margin_left", side_margin)
	outer.add_theme_constant_override("margin_right", side_margin)
	outer.add_theme_constant_override("margin_top", vertical_margin)
	outer.add_theme_constant_override("margin_bottom", vertical_margin)
	content.add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)
	return root

func _page_header(root: VBoxContainer, title_text: String, subtitle_text: String, right_text: String = "", right_tint: Color = Color.WHITE) -> void:
	var accent := _accent()
	var compact := get_viewport_rect().size.x < 700.0
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10 if compact else 16)
	root.add_child(header)
	var back := _button("‹", Vector2(68, 68) if compact else Vector2(92, 82), "utility")
	back.add_theme_font_size_override("font_size", 32 if compact else 38)
	back.pressed.connect(build_home)
	header.add_child(back)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var title := _label(title_text, 31 if compact else 40, "title", accent)
	title.clip_text = true
	heading.add_child(title)
	var subtitle := _label(subtitle_text, 15 if compact else 19, "muted", accent)
	subtitle.clip_text = true
	heading.add_child(subtitle)
	if not right_text.is_empty():
		var right := _label(right_text, 14 if compact else 18, "accent", right_tint)
		right.custom_minimum_size = Vector2(112 if compact else 190, 58 if compact else 70)
		right.clip_text = true
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(right)

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	var root := _page_root()
	var accent := _accent()
	_page_header(root, "SETTINGS", "Make UNJAM feel exactly right", "●  AUTO-SAVE ON", PremiumDesignSystem.SUCCESS)

	var hero := _card(root, Vector2(0, 150), true)
	var hero_margin := _pad(hero, 26)
	var hero_box := VBoxContainer.new()
	hero_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_box.add_theme_constant_override("separation", 8)
	hero_margin.add_child(hero_box)
	var hero_title := _label("YOUR PLAY SPACE", 28, "accent", accent)
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_box.add_child(hero_title)
	var hero_copy := _label("Tune sound, music, touch feedback and appearance across all three games.", 19, "muted", accent)
	hero_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(hero_copy)

	var controls := GridContainer.new()
	controls.columns = 2
	controls.add_theme_constant_override("h_separation", 18)
	controls.add_theme_constant_override("v_separation", 18)
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(controls)
	var setting_rows: Array = [["sound", "SOUND", "GAME EFFECTS"], ["music", "MUSIC", "AMBIENT LOOP"], ["vibration", "HAPTICS", "TOUCH FEEDBACK"], ["reduce_motion", "REDUCE MOTION", "LESS MOVEMENT"], ["fast_animation", "FAST ANIMATION", "QUICKER GAMEPLAY"]]
	for setting in setting_rows:
		var key := String(setting[0])
		var enabled: bool = bool(SaveManager.data.get(key, true))
		var role := "success" if enabled else "toggle_off"
		var button := _button("%s\n%s  •  %s" % [String(setting[1]), String(setting[2]), "ON" if enabled else "OFF"], Vector2(475, 132), role)
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(_toggle_setting.bind(key))
		controls.add_child(button)

	var shell := get_node_or_null("UXShell")
	var theme_name := "DARK"
	if shell != null and shell.get("theme_mode") != null:
		theme_name = String(shell.get("theme_mode")).to_upper()
	var appearance := _button("APPEARANCE\n%s MODE  •  TAP TO SWITCH" % theme_name, Vector2(475, 132), "secondary")
	appearance.add_theme_font_size_override("font_size", 23)
	appearance.pressed.connect(func() -> void:
		if shell != null and shell.has_method("_toggle_theme"):
			shell.call("_toggle_theme")
		call_deferred("build_settings")
	)
	controls.add_child(appearance)

	var history := _card(root, Vector2(0, 190), false)
	var history_margin := _pad(history, 22)
	var history_box := VBoxContainer.new()
	history_box.add_theme_constant_override("separation", 14)
	history_margin.add_child(history_box)
	history_box.add_child(_label("PLAY HISTORY", 22, "accent", accent))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	history_box.add_child(stats)
	var values: Array = [["HINTS", int(SaveManager.data.hints_used)], ["UNDOS", int(SaveManager.data.undos_used)], ["PERFECT", int(SaveManager.data.perfect_clears)], ["PRESTIGE", int(SaveManager.data.prestige_points)], ["ACHIEVEMENT", int(SaveManager.data.achievement_points)]]
	for stat in values:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(174, 96)
		chip.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(_dark()), 20, Color(accent, 0.28), 1, 2, _dark()))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		chip.add_child(box)
		var value := _label(str(int(stat[1])), 28, "title", accent)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(value)
		var name := _label(String(stat[0]), 13, "muted", accent)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name)
		stats.add_child(chip)
	PremiumVisuals.entrance(root, 0.025)

func build_collection() -> void:
	current_surface = "collection"
	selected_game_id = "rescue_rush"
	_remove_active_game()
	var root := _page_root()
	var accent := _accent("rescue_rush")
	_page_header(root, "RESCUE GARDEN", "A living home for everyone you save", "◈  %d" % int(SaveManager.data.coins), PremiumDesignSystem.GOLD)

	var sanctuary := _card(root, Vector2(0, 500), true, "rescue_rush")
	var sanctuary_margin := _pad(sanctuary, 28)
	var sanctuary_box := VBoxContainer.new()
	sanctuary_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sanctuary_box.add_theme_constant_override("separation", 16)
	sanctuary_margin.add_child(sanctuary_box)
	var crest := _label("✦  SANCTUARY  ✦", 22, "accent", accent)
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(crest)
	var rescued: Array = SaveManager.data.rescued
	var hero_text := "YOUR FIRST FRIEND IS WAITING" if rescued.is_empty() else "%d FRIEND%s HOME" % [rescued.size(), "" if rescued.size() == 1 else "S"]
	var hero := _label(hero_text, 36, "title", accent)
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(hero)
	var friends := _label(_friend_roster_text(rescued), 24 if not rescued.is_empty() else 21, "body", accent)
	friends.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friends.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	friends.custom_minimum_size = Vector2(0, 110)
	sanctuary_box.add_child(friends)
	var garden_status := _label(_garden_status_text(), 19, "muted", accent)
	garden_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	garden_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sanctuary_box.add_child(garden_status)
	var progress := ProgressBar.new()
	progress.max_value = 3.0
	progress.value = float(SaveManager.data.decorations.size())
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(720, 20)
	progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(_dark()), 10, Color.TRANSPARENT, 0, 0, _dark()))
	progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 10, accent.lightened(0.12), 1, 0, _dark()))
	sanctuary_box.add_child(progress)
	var completion := _label("GARDEN UPGRADES  %d / 3" % SaveManager.data.decorations.size(), 15, "muted", accent)
	completion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(completion)

	var metrics := HBoxContainer.new()
	metrics.alignment = BoxContainer.ALIGNMENT_CENTER
	metrics.add_theme_constant_override("separation", 14)
	root.add_child(metrics)
	var metric_values: Array = [["PRESTIGE", int(SaveManager.data.prestige_points)], ["ACHIEVEMENT", int(SaveManager.data.achievement_points)], ["WORLD BADGES", SaveManager.data.world_badges.size()]]
	for metric in metric_values:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 100)
		card.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(_dark()), 22, Color(accent, 0.25), 1, 3, _dark()))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		var value := _label(str(int(metric[1])), 27, "title", accent)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(value)
		var name := _label(String(metric[0]), 14, "muted", accent)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name)
		metrics.add_child(card)

	var shop_header := HBoxContainer.new()
	root.add_child(shop_header)
	var shop_title := _label("GARDEN UPGRADES", 25, "title", accent)
	shop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_header.add_child(shop_title)
	shop_header.add_child(_label("Permanent sanctuary decorations", 16, "muted", accent))
	var shop := HBoxContainer.new()
	shop.alignment = BoxContainer.ALIGNMENT_CENTER
	shop.add_theme_constant_override("separation", 16)
	root.add_child(shop)
	var items: Array = [["tree", "CANOPY TREE", 100, "SHADE"], ["bench", "GARDEN BENCH", 150, "REST"], ["fountain", "CRYSTAL FOUNTAIN", 250, "SPARKLE"]]
	for item in items:
		var id := String(item[0])
		var owned: bool = id in SaveManager.data.decorations
		var state_text := "OWNED" if owned else "%d COINS" % int(item[2])
		var button := _button("%s\n%s  •  %s" % [String(item[1]), String(item[3]), state_text], Vector2(302, 124), "success" if owned else "secondary", "rescue_rush")
		button.add_theme_font_size_override("font_size", 20)
		button.disabled = owned
		button.pressed.connect(_buy_decoration.bind(id, int(item[2])))
		shop.add_child(button)
	PremiumVisuals.entrance(root, 0.025)

func _friend_roster_text(rescued: Array) -> String:
	if rescued.is_empty():
		return "Complete Rescue Rush levels to bring characters into your sanctuary."
	var names: Array[String] = []
	for id in rescued:
		names.append(String(id).capitalize())
	return "  •  ".join(names)

func _garden_status_text() -> String:
	if SaveManager.data.decorations.is_empty():
		return "The sanctuary is ready to grow. Add your first permanent decoration below."
	var names: Array[String] = []
	for id in SaveManager.data.decorations:
		names.append(String(id).capitalize())
	return "Installed: " + "  •  ".join(names)

func build_level_select() -> void:
	super.build_level_select()
	_upgrade_level_browser("rescue_rush")

func build_multi_level_select() -> void:
	super.build_multi_level_select()
	_upgrade_level_browser(selected_game_id)

func _upgrade_level_browser(game_id: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var accent := _accent(game_id)
	for grid in _collect_grids(content):
		if grid.columns != 5:
			continue
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		for child in grid.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 176.0), maxf(button.custom_minimum_size.y, 116.0))
				button.add_theme_font_size_override("font_size", maxi(19, button.get_theme_font_size("font_size")))
				PremiumDesignSystem.apply_button(button, _dark(), accent, "disabled" if button.disabled else ("primary" if "CURRENT" in button.text.to_upper() else "secondary"), 20)

func _collect_grids(node: Node) -> Array[GridContainer]:
	var result: Array[GridContainer] = []
	if node is GridContainer:
		result.append(node as GridContainer)
	for child in node.get_children():
		result.append_array(_collect_grids(child))
	return result
