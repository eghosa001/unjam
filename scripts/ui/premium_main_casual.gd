extends "res://scripts/ui/premium_main.gd"

func _sync_persistent_surfaces_now(surface: String) -> void:
	var home := get_node_or_null("PremiumHome")
	if home != null and home.has_method("_on_surface_changed"):
		home.call("_on_surface_changed", surface)
	var live := get_node_or_null("PremiumLive")
	if live != null and live.has_method("_on_surface_changed"):
		live.call("_on_surface_changed", surface)

func build_home() -> void:
	# Base navigation replaces/removes the outgoing surface immediately. Bring the
	# persistent premium surfaces into their final visibility state before this
	# call returns so Settings/Collection/Game -> Home cannot expose a blank frame
	# while robust_main's surface_changed signal is waiting for its deferred emit.
	super.build_home()
	var live := get_node_or_null("PremiumLive")
	if live != null and live.has_method("_on_surface_changed"):
		live.call("_on_surface_changed", "home")
	var home := get_node_or_null("PremiumHome")
	if home != null and home.has_method("_on_surface_changed"):
		home.call("_on_surface_changed", "home")

func add_background() -> void:
	# Base level builders call add_background() directly. Override it so every
	# secondary surface uses the final bright backdrop without allocating the
	# retired PremiumBackdrop first.
	if content == null or not is_instance_valid(content):
		return
	content.clip_contents = true
	var existing := content.get_node_or_null("Unjam3DSurfaceBackdrop") as Unjam3DBackdrop
	if existing == null:
		existing = Unjam3DBackdrop.new()
		existing.name = "Unjam3DSurfaceBackdrop"
		existing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		existing.z_index = -100
		content.add_child(existing)
		content.move_child(existing, 0)
	existing.configure(_accent(), _dark())

func _page_root() -> VBoxContainer:
	clear_content()
	add_background()
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport_rect().size
	var side_margin := 46 if viewport_size.x >= 760.0 else 28
	outer.add_theme_constant_override("margin_left", side_margin)
	outer.add_theme_constant_override("margin_right", side_margin)
	outer.add_theme_constant_override("margin_top", 34 if viewport_size.y >= 1400.0 else 24)
	outer.add_theme_constant_override("margin_bottom", 34 if viewport_size.y >= 1400.0 else 24)
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
	controls.add_theme_constant_override("v_separation", 18)
	controls.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var appearance := _button("APPEARANCE   •   %s" % theme_name, Vector2(0, 112 if get_viewport_rect().size.y >= 1400.0 else 84), "secondary")
	appearance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance.add_theme_font_size_override("font_size", 20)
	appearance.pressed.connect(func() -> void:
		if shell != null and shell.has_method("_toggle_theme"):
			shell.call("_toggle_theme")
		call_deferred("build_settings")
	)
	controls.add_child(appearance)
	var accessibility_note := _label("ACCESSIBILITY  •  LARGE TOUCH TARGETS ARE ENABLED THROUGHOUT GAMEPLAY", 16, "muted", accent)
	accessibility_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accessibility_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(accessibility_note)
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
	var button_height := 104 if get_viewport_rect().size.y >= 1400.0 else 88
	var button := _button("%s   •   %s\n%s" % [title_text, state, detail_text], Vector2(0, button_height), role)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
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

func build_daily_games() -> void:
	current_surface = "daily"
	_remove_active_game()
	var root := _page_root()
	var bonus := EconomyManager.collection_daily_bonus()
	_page_header(
		root,
		"DAILY GAMES",
		"Three fresh challenges every day",
		"+%d COLLECTION BONUS" % bonus if bonus > 0 else "3 CHALLENGES",
		PremiumDesignSystem.GOLD
	)

	var intro := _card(root, Vector2(0, 118), true)
	var intro_margin := _pad(intro, 18)
	var intro_box := VBoxContainer.new()
	intro_box.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_box.add_theme_constant_override("separation", 5)
	intro_margin.add_child(intro_box)
	var intro_title := _label("TODAY  •  %s" % DailyChallenge.date_key(), 22, "title", _accent())
	intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_box.add_child(intro_title)
	var intro_copy := _label(
		"Complete each puzzle once today. Collection upgrades permanently increase every Daily Game reward.",
		16,
		"muted",
		_accent()
	)
	intro_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_box.add_child(intro_copy)

	var scroll := ScrollContainer.new()
	scroll.name = "DailyGamesScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 16)
	scroll.add_child(stack)

	var grid := GridContainer.new()
	grid.name = "DailyGamesGrid"
	grid.columns = 3 if get_viewport_rect().size.x >= 900.0 else 1
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	stack.add_child(grid)
	for game_id in MultiGameManager.GAME_IDS:
		grid.add_child(_daily_game_card(game_id, bonus))

	var collection_cta := _button(
		"COLLECTION PERKS  •  +%d PER DAILY GAME  •  GARDEN GIFT +%d" % [
			bonus,
			EconomyManager.garden_gift_amount()
		],
		Vector2(0, 82),
		"secondary",
		"rescue_rush"
	)
	collection_cta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_cta.pressed.connect(build_collection)
	stack.add_child(collection_cta)
	PremiumVisuals.entrance(stack, 0.018)
	_add_surface_diorama("rescue_rush", "DailyGames3DDiorama")

func _daily_game_card(game_id: String, collection_bonus: int) -> PanelContainer:
	var accent := Unjam3DTheme.game_accent(game_id)
	var done := _daily_done(game_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 250)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PremiumDesignSystem.apply_panel(card, _dark(), accent, true, 28)
	var margin := _pad(card, 18)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := _label(MultiGameManager.display_name(game_id).to_upper(), 24, "title", accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var challenge_text := "Fresh generated rescue"
	if game_id != "rescue_rush":
		challenge_text = "Daily level %d" % MultiGameManager.daily_level(game_id)
	var challenge := _label(challenge_text, 16, "body", accent)
	challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(challenge)

	var reward_text := "+%d COINS" % (100 + collection_bonus)
	if game_id != "rescue_rush":
		reward_text = "+%d–%d COINS" % [125 + collection_bonus, 175 + collection_bonus]
	var reward := _label(reward_text, 18, "accent", PremiumDesignSystem.GOLD)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(reward)

	var perk := _label(
		"Includes +%d permanent Collection bonus" % collection_bonus if collection_bonus > 0 else "Collection upgrades can boost this reward",
		14,
		"muted",
		accent
	)
	perk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(perk)

	var play := _button("COMPLETED TODAY" if done else "PLAY DAILY", Vector2(0, 68), "success" if done else "primary", game_id)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.disabled = done
	if not done:
		play.pressed.connect(start_game_daily.bind(game_id))
	box.add_child(play)
	return card

func _claim_collection_gift() -> void:
	var amount := EconomyManager.claim_garden_gift()
	if amount <= 0:
		return
	FeedbackManager.effect()
	PremiumVisuals.burst(Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.45), PremiumDesignSystem.GOLD, 22)
	build_collection()

func build_collection() -> void:
	current_surface = "collection"
	_remove_active_game()
	var root := _page_root()
	var accent := _accent("rescue_rush")
	_page_header(root, "COLLECTION", "Your complete UNJAM journey", "◈  %d" % int(SaveManager.data.get("coins", 0)), PremiumDesignSystem.GOLD)
	var scroll := ScrollContainer.new()
	scroll.name = "CollectionScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 18)
	scroll.add_child(stack)
	var total_completed := 0
	var total_stars := 0
	var total_perfect := 0
	var total_badges := 0
	for game_id in MultiGameManager.GAME_IDS:
		var progress := MultiGameManager.progress_for(game_id)
		total_completed += int(progress.get("levels_completed", 0))
		total_stars += MultiGameManager.total_stars(game_id)
		total_perfect += int(progress.get("perfect_clears", 0))
		total_badges += (progress.get("world_badges", []) as Array).size()
	var overview := _card(stack, Vector2(0, 172), true)
	var overview_margin := _pad(overview, 20)
	var overview_box := VBoxContainer.new()
	overview_box.add_theme_constant_override("separation", 12)
	overview_margin.add_child(overview_box)
	var overview_title := _label("JOURNEY OVERVIEW", 27, "title", accent)
	overview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overview_box.add_child(overview_title)
	var metrics := GridContainer.new()
	metrics.columns = 4 if get_viewport_rect().size.x >= 760.0 else 2
	metrics.add_theme_constant_override("h_separation", 10)
	metrics.add_theme_constant_override("v_separation", 10)
	overview_box.add_child(metrics)
	for metric in [["LEVELS", total_completed], ["STARS", total_stars], ["PERFECT", total_perfect], ["BADGES", total_badges]]:
		var chip := _journey_metric(String(metric[0]), int(metric[1]), accent)
		metrics.add_child(chip)
	var games_title := _label("YOUR THREE GAMES", 24, "title", accent)
	stack.add_child(games_title)
	var game_grid := GridContainer.new()
	game_grid.columns = 2 if get_viewport_rect().size.x >= 720.0 else 1
	game_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_grid.add_theme_constant_override("h_separation", 14)
	game_grid.add_theme_constant_override("v_separation", 14)
	stack.add_child(game_grid)
	for game_id in MultiGameManager.GAME_IDS:
		game_grid.add_child(_collection_game_card(game_id))
	var achievement_card := _card(stack, Vector2(0, 150), false)
	var achievement_margin := _pad(achievement_card, 20)
	var achievement_box := VBoxContainer.new()
	achievement_box.add_theme_constant_override("separation", 8)
	achievement_margin.add_child(achievement_box)
	achievement_box.add_child(_label("ACHIEVEMENTS", 23, "title", Unjam3DTheme.GOLD))
	var achievement_lines: Array[String] = []
	for game_id in MultiGameManager.GAME_IDS:
		var unlocked := MultiGameManager.unlocked_achievements(game_id)
		achievement_lines.append("%s  •  %d / %d" % [MultiGameManager.display_name(game_id), unlocked.size(), MultiGameManager.achievement_definitions(game_id).size()])
	var achievements := _label("\n".join(achievement_lines), 18, "body", accent)
	achievements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	achievement_box.add_child(achievements)
	var garden := _card(stack, Vector2(0, 260), true, "rescue_rush")
	var garden_margin := _pad(garden, 22)
	var garden_box := VBoxContainer.new()
	garden_box.add_theme_constant_override("separation", 10)
	garden_margin.add_child(garden_box)
	garden_box.add_child(_label("RESCUE GARDEN", 25, "title", accent))
	var rescued: Array = SaveManager.data.get("rescued", [])
	var friends := _label(_friend_roster_text(rescued), 20, "body", accent)
	friends.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garden_box.add_child(friends)
	var garden_status := _label(_garden_status_text(), 18, "muted", accent)
	garden_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garden_box.add_child(garden_status)
	var progress := ProgressBar.new()
	progress.max_value = 6.0
	progress.value = float(SaveManager.data.get("decorations", []).size())
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 22)
	progress.add_theme_stylebox_override("background", PremiumDesignSystem.box(PremiumDesignSystem.surface_3(_dark()), 10, Color.TRANSPARENT, 0, 0, _dark()))
	progress.add_theme_stylebox_override("fill", PremiumDesignSystem.box(accent, 10, accent.lightened(0.12), 1, 0, _dark()))
	garden_box.add_child(progress)
	var value_card := _card(stack, Vector2(0, 210), true, "rescue_rush")
	var value_margin := _pad(value_card, 20)
	var value_box := VBoxContainer.new()
	value_box.add_theme_constant_override("separation", 8)
	value_margin.add_child(value_box)
	var owned_count := EconomyManager.collection_owned_count()
	value_box.add_child(_label("PERMANENT COLLECTION PERKS  •  %d / 6" % owned_count, 23, "title", PremiumDesignSystem.GOLD))
	var value_copy := _label(
		"Every owned upgrade adds +5 coins to EVERY Daily Game. Your garden also creates a once-per-day gift; a complete 6/6 garden adds an extra +20 gift bonus.",
		18,
		"body",
		accent
	)
	value_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_box.add_child(value_copy)
	var current_value := _label(
		"CURRENT VALUE  •  +%d EACH DAILY GAME  •  +%d DAILY GARDEN GIFT" % [
			EconomyManager.collection_daily_bonus(),
			EconomyManager.garden_gift_amount()
		],
		18,
		"accent",
		PremiumDesignSystem.GOLD
	)
	current_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_box.add_child(current_value)
	var gift := _button(
		"NO GIFT YET  •  BUY AN UPGRADE" if owned_count <= 0 else (
			"GARDEN GIFT CLAIMED TODAY" if EconomyManager.garden_gift_claimed_today()
			else "CLAIM DAILY GARDEN GIFT  •  +%d COINS" % EconomyManager.garden_gift_amount()
		),
		Vector2(0, 64),
		"success" if EconomyManager.can_claim_garden_gift() else "secondary",
		"rescue_rush"
	)
	gift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift.disabled = not EconomyManager.can_claim_garden_gift()
	gift.pressed.connect(_claim_collection_gift)
	value_box.add_child(gift)

	var shop_title := _label("GARDEN UPGRADES  •  PERMANENT", 23, "title", accent)
	stack.add_child(shop_title)
	var shop := GridContainer.new()
	shop.columns = 2 if get_viewport_rect().size.x >= 720.0 else 1
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.add_theme_constant_override("h_separation", 14)
	shop.add_theme_constant_override("v_separation", 14)
	stack.add_child(shop)
	var collection_items := [
		["tree", "CANOPY TREE", 100, "SHADE"],
		["bench", "GARDEN BENCH", 150, "REST"],
		["fountain", "CRYSTAL FOUNTAIN", 250, "SPARKLE"],
		["lanterns", "LANTERN PATH", 350, "GLOW"],
		["cottage", "RESCUE COTTAGE", 500, "HOME"],
		["rainbow_bridge", "RAINBOW BRIDGE", 750, "WONDER"]
	]
	for item in collection_items:
		var id := String(item[0])
		var owned: bool = id in SaveManager.data.get("decorations", [])
		var state_text := "OWNED" if owned else "%d COINS" % int(item[2])
		var button := _button(
			"%s\n%s  •  %s\nPERMANENT +5 DAILY  •  +10 GIFT" % [
				String(item[1]),
				String(item[3]),
				state_text
			],
			Vector2(0, 148),
			"success" if owned else "secondary",
			"rescue_rush"
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = owned
		button.pressed.connect(_buy_decoration.bind(id, int(item[2])))
		shop.add_child(button)
	PremiumVisuals.entrance(stack, 0.018)
	_add_surface_diorama("rescue_rush", "Collection3DDiorama")

func _journey_metric(title_text: String, value: int, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(0, 82)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", PremiumDesignSystem.box(PremiumDesignSystem.surface_2(_dark()), 20, Color(accent, 0.30), 1, 2, _dark()))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(box)
	var number := _label(str(value), 27, "title", accent)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number)
	var title := _label(title_text, 13, "muted", accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return chip

func _collection_game_card(game_id: String) -> PanelContainer:
	var accent := Unjam3DTheme.game_accent(game_id)
	var progress := MultiGameManager.progress_for(game_id)
	var highest := clampi(int(progress.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Unjam3DTheme.surface_fill(_dark(), false), 26, Color(accent, 0.75), 2, 8))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var title := _label(MultiGameManager.display_name(game_id), 23, "title", accent)
	box.add_child(title)
	box.add_child(_label("LEVEL %d  •  WORLD %d / %d" % [highest, MultiGameManager.world_for_game_level(game_id, highest), MultiGameManager.world_count_for(game_id)], 17, "body", accent))
	box.add_child(_label("★ %d   •   PERFECT %d" % [MultiGameManager.total_stars(game_id), int(progress.get("perfect_clears", 0))], 16, "muted", accent))
	box.add_child(_label("%d levels cleared  •  %d badges" % [int(progress.get("levels_completed", 0)), (progress.get("world_badges", []) as Array).size()], 15, "muted", accent))
	var open := _button("OPEN LEVELS", Vector2(0, 68), "primary", game_id)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.pressed.connect(open_game_campaign.bind(game_id))
	box.add_child(open)
	return card

func build_level_select() -> void:
	super.build_level_select()
	_inject_game_tabs("rescue_rush")
	_upgrade_level_browser("rescue_rush")
	_add_surface_diorama("rescue_rush", "Levels3DDiorama")

func build_multi_level_select() -> void:
	super.build_multi_level_select()
	_inject_game_tabs(selected_game_id)
	if selected_game_id == "block_puzzle":
		_inject_block_modes()
	_upgrade_level_browser(selected_game_id)
	_add_surface_diorama(selected_game_id, "Levels3DDiorama")

func _inject_game_tabs(active_game_id: String) -> void:
	var root := _find_page_root()
	if root == null:
		return
	var old := root.get_node_or_null("LevelGameTabs")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	var tabs := HBoxContainer.new()
	tabs.name = "LevelGameTabs"
	tabs.custom_minimum_size = Vector2(0, 92)
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)
	root.move_child(tabs, mini(1, root.get_child_count() - 1))
	for game_id in MultiGameManager.GAME_IDS:
		var current: bool = game_id == active_game_id
		var button := _button(MultiGameManager.display_name(game_id), Vector2(0, 84), "primary" if current else "secondary", game_id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18 if get_viewport_rect().size.x >= 700.0 else 15)
		button.disabled = current
		button.pressed.connect(open_game_campaign.bind(game_id))
		tabs.add_child(button)

func _inject_block_modes() -> void:
	var root := _find_page_root()
	if root == null:
		return
	var old := root.get_node_or_null("BlockPuzzleModes")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	var stats = SaveManager.data.get("block_mode_stats", {})
	if not stats is Dictionary:
		stats = {}
	var bar := HBoxContainer.new()
	bar.name = "BlockPuzzleModes"
	bar.custom_minimum_size = Vector2(0, 86)
	bar.add_theme_constant_override("separation", 10)
	var specs := [
		["endless", "ENDLESS", "SURVIVAL"],
		["zen", "ZEN", "NO GAME OVER"],
		["extreme", "EXTREME", "MASTER RULES"],
	]
	for spec in specs:
		var mode := String(spec[0])
		var mode_stats = (stats as Dictionary).get(mode, {})
		var best := int((mode_stats as Dictionary).get("best_score", 0)) if mode_stats is Dictionary else 0
		var subtitle := String(spec[2])
		if best > 0:
			subtitle += "  •  BEST %d" % best
		var button := _button("%s\n%s" % [String(spec[1]), subtitle], Vector2(0, 82), "secondary", "block_puzzle")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(start_block_mode.bind(mode))
		bar.add_child(button)
	root.add_child(bar)
	root.move_child(bar, mini(2, root.get_child_count() - 1))

func _find_page_root() -> VBoxContainer:
	if content == null:
		return null
	for child in content.get_children():
		if child is MarginContainer:
			for inner in child.get_children():
				if inner is VBoxContainer:
					return inner as VBoxContainer
	return null

func _level_column_count(usable_width: float) -> int:
	if usable_width >= 900.0:
		return 4
	if usable_width >= 610.0:
		return 3
	return 2

func _upgrade_level_browser(game_id: String) -> void:
	if content == null or not is_instance_valid(content):
		return
	var accent := Unjam3DTheme.game_accent(game_id)
	var dark_accent := Unjam3DTheme.game_dark(game_id)
	var current_level := _highest_level_for_game(game_id)
	var usable_width := maxf(320.0, get_viewport_rect().size.x - (92.0 if get_viewport_rect().size.x >= 760.0 else 56.0))
	var columns := _level_column_count(usable_width)
	var gap := 14.0
	var button_width := floorf((usable_width - gap * float(columns - 1)) / float(columns)) - 4.0
	for grid in _collect_grids(content):
		if grid.get_child_count() < 20:
			continue
		grid.columns = columns
		grid.add_theme_constant_override("h_separation", int(gap))
		grid.add_theme_constant_override("v_separation", 14)
		for child in grid.get_children():
			if not child is Button:
				continue
			var button := child as Button
			button.custom_minimum_size = Vector2(maxf(132.0, button_width), 126.0)
			button.add_theme_font_size_override("font_size", 21 if columns >= 3 else 19)
			var first_line := button.text.get_slice("\n", 0).strip_edges()
			var is_current := "CURRENT" in button.text.to_upper() or (first_line.is_valid_int() and int(first_line) == current_level and not button.disabled)
			if button.disabled:
				Unjam3DTheme.gloss_button(button, Color("75879b") if _dark() else Color("9db6c8"), false, 22, _dark())
				button.add_theme_color_override("font_color", Color("a8b5c6") if _dark() else Color("6d8597"))
			elif is_current:
				Unjam3DTheme.gloss_button(button, accent, true, 22, _dark())
			elif first_line.is_valid_int() and (int(first_line) % 10 == 0 or "BOSS" in button.text.to_upper() or "MILE" in button.text.to_upper()):
				Unjam3DTheme.gloss_button(button, Unjam3DTheme.GOLD, true, 22, _dark())
				button.add_theme_color_override("font_color", Unjam3DTheme.NAVY)
				button.add_theme_color_override("font_hover_color", Unjam3DTheme.NAVY)
				button.add_theme_color_override("font_pressed_color", Unjam3DTheme.NAVY)
			else:
				Unjam3DTheme.gloss_button(button, dark_accent, false, 22, _dark())

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
	var viewport_size := get_viewport_rect().size
	var art_width := minf(400.0, viewport_size.x * 0.42)
	var art_height := minf(300.0, viewport_size.y * 0.22)
	art.offset_left = -art_width - 24.0
	art.offset_top = -art_height - 24.0
	art.offset_right = -24.0
	art.offset_bottom = -24.0
	art.z_index = -20
	art.modulate = Color(1, 1, 1, 0.42 if _dark() else 0.58)
	art.configure(game_id)
	content.add_child(art)

func _highest_level_for_game(game_id: String) -> int:
	if game_id == "rescue_rush":
		return int(SaveManager.data.get("highest_level", 1))
	return MultiGameManager.highest_level(game_id)
