extends "res://scripts/ui/robust_main.gd"

func _surface_dark() -> bool:
	var shell := get_node_or_null("UXShell")
	return shell == null or String(shell.get("theme_mode")) != "light"

func _surface_accent() -> Color:
	return PremiumDesignSystem.accent_for_game(selected_game_id)

func _page_label(text_value: String, size: int, kind := "body", accent := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	PremiumDesignSystem.apply_label(label, _surface_dark(), kind, accent)
	return label

func _premium_button(text_value: String, minimum := Vector2(420, 94), role := "secondary") -> Button:
	var button := make_button(text_value, minimum, role == "primary")
	PremiumDesignSystem.apply_button(button, _surface_dark(), _surface_accent(), role, 24)
	return button

func _premium_card(parent: Node, minimum := Vector2.ZERO, emphasis := false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	PremiumDesignSystem.apply_panel(panel, _surface_dark(), _surface_accent(), emphasis, 30)
	parent.add_child(panel)
	return panel

func _card_margin(panel: PanelContainer, amount := 24) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_top", amount)
	margin.add_theme_constant_override("margin_bottom", amount)
	panel.add_child(margin)
	return margin

func build_settings() -> void:
	current_surface = "settings"
	_remove_active_game()
	clear_content()
	add_background()
	var dark := _surface_dark()
	var accent := _surface_accent()
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

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var back := _premium_button("‹", Vector2(92, 82), "utility")
	back.add_theme_font_size_override("font_size", 38)
	back.pressed.connect(build_home)
	header.add_child(back)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var title := _page_label("SETTINGS", 40, "title", accent)
	heading.add_child(title)
	var subtitle := _page_label("Make UNJAM feel exactly right", 19, "muted", accent)
	heading.add_child(subtitle)
	var save_chip := _page_label("●  AUTO-SAVE ON", 16, "accent", PremiumDesignSystem.SUCCESS)
	save_chip.custom_minimum_size = Vector2(190, 70)
	save_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(save_chip)

	var hero := _premium_card(root, Vector2(0, 146), true)
	var hero_margin := _card_margin(hero, 26)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 8)
	hero_margin.add_child(hero_box)
	var hero_title := _page_label("YOUR PLAY SPACE", 27, "accent", accent)
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_box.add_child(hero_title)
	var hero_copy := _page_label("Audio, feedback and appearance stay synced across all three games.", 19, "muted", accent)
	hero_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(hero_copy)

	var controls := GridContainer.new()
	controls.columns = 2
	controls.add_theme_constant_override("h_separation", 18)
	controls.add_theme_constant_override("v_separation", 18)
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(controls)
	for setting in [["sound", "SOUND", "GAME EFFECTS"], ["music", "MUSIC", "AMBIENT LOOP"], ["vibration", "HAPTICS", "TOUCH FEEDBACK"]]:
		var key := String(setting[0])
		var enabled := bool(SaveManager.data.get(key, true))
		var button := _premium_button("%s\n%s  •  %s" % [String(setting[1]), String(setting[2]), "ON" if enabled else "OFF"], Vector2(475, 126), "success" if enabled else "toggle_off")
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(_toggle_setting.bind(key))
		controls.add_child(button)
	var shell := get_node_or_null("UXShell")
	var current_theme := "dark"
	if shell != null and shell.get("theme_mode") != null:
		current_theme = String(shell.get("theme_mode"))
	var appearance := _premium_button("APPEARANCE\n%s MODE  •  TAP TO SWITCH" % current_theme.to_upper(), Vector2(475, 126), "secondary")
	appearance.add_theme_font_size_override("font_size", 23)
	appearance.pressed.connect(func() -> void:
		if shell != null and shell.has_method("_toggle_theme"):
			shell.call("_toggle_theme")
		call_deferred("build_settings")
	)
	controls.add_child(appearance)

	var stats_card := _premium_card(root, Vector2(0, 176), false)
	var stats_margin := _card_margin(stats_card, 22)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 14)
	stats_margin.add_child(stats_box)
	var stats_title := _page_label("PLAY HISTORY", 21, "accent", accent)
	stats_box.add_child(stats_title)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	stats_box.add_child(stats)
	for stat in [["HINTS", int(SaveManager.data.hints_used)], ["UNDOS", int(SaveManager.data.undos_used)], ["PERFECT", int(SaveManager.data.perfect_clears)], ["PRESTIGE", int(SaveManager.data.prestige_points)], ["ACHIEVEMENT", int(SaveManager.data.achievement_points)]]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(174, 92)
		chip.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(dark), 20, Color(accent, 0.28), 1, 2, dark))
		var chip_box := VBoxContainer.new()
		chip_box.alignment = BoxContainer.ALIGNMENT_CENTER
		chip.add_child(chip_box)
		var value := _page_label(str(int(stat[1])), 27, "title", accent)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_box.add_child(value)
		var name := _page_label(String(stat[0]), 13, "muted", accent)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_box.add_child(name)
		stats.add_child(chip)
	PremiumVisuals.entrance(root, 0.025)

func build_collection() -> void:
	current_surface = "collection"
	_remove_active_game()
	clear_content()
	add_background()
	var dark := _surface_dark()
	var accent := PremiumDesignSystem.accent_for_game("rescue_rush")
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 46)
	outer.add_theme_constant_override("margin_right", 46)
	outer.add_theme_constant_override("margin_top", 42)
	outer.add_theme_constant_override("margin_bottom", 42)
	content.add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 17)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var back := _premium_button("‹", Vector2(92, 82), "utility")
	back.add_theme_font_size_override("font_size", 38)
	back.pressed.connect(build_home)
	header.add_child(back)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var title := _page_label("RESCUE GARDEN", 40, "title", accent)
	heading.add_child(title)
	var subtitle := _page_label("A living home for everyone you save", 19, "muted", accent)
	heading.add_child(subtitle)
	var coins := _page_label("◈  %d" % int(SaveManager.data.coins), 24, "accent", PremiumDesignSystem.GOLD)
	coins.custom_minimum_size = Vector2(170, 72)
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(coins)

	var sanctuary := _premium_card(root, Vector2(0, 520), true)
	var sanctuary_margin := _card_margin(sanctuary, 28)
	var sanctuary_box := VBoxContainer.new()
	sanctuary_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sanctuary_box.add_theme_constant_override("separation", 16)
	sanctuary_margin.add_child(sanctuary_box)
	var crest := _page_label("✦  SANCTUARY  ✦", 22, "accent", accent)
	crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(crest)
	var rescued: Array = SaveManager.data.rescued
	var hero_text := "YOUR FIRST FRIEND IS WAITING" if rescued.is_empty() else "%d FRIEND%s HOME" % [rescued.size(), "" if rescued.size() == 1 else "S"]
	var hero := _page_label(hero_text, 34, "title", accent)
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(hero)
	var friends := _page_label(_friend_roster_text(rescued), 25 if not rescued.is_empty() else 21, "body", accent)
	friends.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friends.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	friends.custom_minimum_size = Vector2(0, 110)
	sanctuary_box.add_child(friends)
	var decor_line := _page_label(_garden_status_text(), 19, "muted", accent)
	decor_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decor_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sanctuary_box.add_child(decor_line)
	var progress := ProgressBar.new()
	progress.max_value = 3
	progress.value = SaveManager.data.decorations.size()
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(720, 18)
	progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(dark), 9, Color.TRANSPARENT, 0, 0, dark))
	progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 9, accent.lightened(0.12), 1, 0, dark))
	sanctuary_box.add_child(progress)
	var completion := _page_label("GARDEN UPGRADES  %d / 3" % SaveManager.data.decorations.size(), 15, "muted", accent)
	completion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sanctuary_box.add_child(completion)

	var metrics := HBoxContainer.new()
	metrics.alignment = BoxContainer.ALIGNMENT_CENTER
	metrics.add_theme_constant_override("separation", 14)
	root.add_child(metrics)
	for metric in [["PRESTIGE", int(SaveManager.data.prestige_points)], ["ACHIEVEMENT", int(SaveManager.data.achievement_points)], ["WORLD BADGES", SaveManager.data.world_badges.size()]]:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 94)
		card.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(dark), 22, Color(accent, 0.24), 1, 3, dark))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(box)
		var value := _page_label(str(int(metric[1])), 26, "title", accent)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(value)
		var name := _page_label(String(metric[0]), 14, "muted", accent)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name)
		metrics.add_child(card)

	var shop_head := HBoxContainer.new()
	root.add_child(shop_head)
	var shop_title := _page_label("GARDEN UPGRADES", 24, "title", accent)
	shop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_head.add_child(shop_title)
	var shop_hint := _page_label("Permanent sanctuary decorations", 16, "muted", accent)
	shop_head.add_child(shop_hint)
	var shop := HBoxContainer.new()
	shop.alignment = BoxContainer.ALIGNMENT_CENTER
	shop.add_theme_constant_override("separation", 16)
	root.add_child(shop)
	for item in [["tree", "CANOPY TREE", 100, "SHADE"], ["bench", "GARDEN BENCH", 150, "REST"], ["fountain", "CRYSTAL FOUNTAIN", 250, "SPARKLE"]]:
		var id := String(item[0])
		var owned := id in SaveManager.data.decorations
		var copy := "%s\n%s  •  %s" % [String(item[1]), String(item[3]), "OWNED" if owned else "%d COINS" % int(item[2])]
		var button := _premium_button(copy, Vector2(302, 120), "success" if owned else "secondary")
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
	var dark := _surface_dark()
	var accent := PremiumDesignSystem.accent_for_game(game_id)
	var grids := _collect_grids(content)
	for grid in grids:
		if grid.columns != 5:
			continue
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		for child in grid.get_children():
			if child is Button:
				var button := child as Button
				button.custom_minimum_size = Vector2(maxf(174, button.custom_minimum_size.x), maxf(116, button.custom_minimum_size.y))
				button.add_theme_font_size_override("font_size", maxi(18, button.get_theme_font_size("font_size")))
				var current := not button.disabled and ("CURRENT" in button.text or button.button_pressed)
				PremiumDesignSystem.apply_button(button, dark, accent, "primary" if current else ("disabled" if button.disabled else "secondary"), 20)
	var labels := _collect_labels(content)
	for label in labels:
		var fs := label.get_theme_font_size("font_size")
		if fs >= 26:
			label.add_theme_font_size_override("font_size", fs + 4)
			PremiumDesignSystem.apply_label(label, dark, "title", accent)
		elif fs > 0 and fs <= 18:
			label.add_theme_font_size_override("font_size", fs + 2)
	var scroll := _find_scroll(content)
	if scroll != null:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	PremiumVisuals.entrance(content, 0.015)

func _collect_grids(node: Node) -> Array[GridContainer]:
	var out: Array[GridContainer] = []
	if node is GridContainer:
		out.append(node)
	for child in node.get_children():
		out.append_array(_collect_grids(child))
	return out

func _collect_labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	if node is Label:
		out.append(node)
	for child in node.get_children():
		out.append_array(_collect_labels(child))
	return out

func _find_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
	for child in node.get_children():
		var found := _find_scroll(child)
		if found != null:
			return found
	return null
