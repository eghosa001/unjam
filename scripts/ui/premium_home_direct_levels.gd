extends "res://scripts/ui/premium_home_casual.gd"

const FLAT_GAME_LOGO_SCRIPT = preload("res://scripts/ui/unjam_flat_game_logo.gd")

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color("#eef2f5")
const BG_MID := Color("#e7ebef")
const BG_BOTTOM := Color("#d8dee5")
const NAVY := Color("#1f2933")
const INK := Color("#26323d")
const MUTED := Color("#52606d")
const BLUE := Color(0.03, 0.43, 0.78)
const CYAN := Color(0.14, 0.68, 1.0)
const ORANGE := Color(1.0, 0.55, 0.12)
const GOLD := Color(1.0, 0.84, 0.24)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const DARK_TOP := Color("#12171d")
const DARK_MID := Color("#171e26")
const DARK_BOTTOM := Color("#0e1318")
const DARK_CARD := Color("#1a2129")
const DARK_INK := Color("#f5f7fa")
const DARK_MUTED := Color("#a7b1bc")
const SCENE_TOP := Color("#eef2f5")
const SCENE_MID := Color("#e6eaee")
const SCENE_BOTTOM := Color("#d6dce2")
const DARK_SCENE_TOP := Color("#171c22")
const DARK_SCENE_MID := Color("#12171d")
const DARK_SCENE_BOTTOM := Color("#0b0f13")

var figma_canvas: FigmaReferenceCanvas

func _home_dark() -> bool:
	return _theme_mode() == "dark"

func _home_text_color(color: Color) -> Color:
	if not _home_dark():
		return color
	if color.is_equal_approx(NAVY) or color.is_equal_approx(INK):
		return DARK_INK
	if color.is_equal_approx(MUTED):
		return DARK_MUTED
	if color.get_luminance() < 0.34:
		return color.lightened(0.48)
	return color.lightened(0.06)

func build_home_launcher() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	last_theme = _theme_mode()
	built = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	if not EconomyManager.balance_changed.is_connected(_on_economy_balance_changed):
		EconomyManager.balance_changed.connect(_on_economy_balance_changed)

	var viewport_bg := ColorRect.new()
	viewport_bg.name = "FigmaHomeViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The viewport fallback stays neutral for letterboxing; the visible 390x844 scene itself is the rich royal-blue 3D world.
	viewport_bg.color = DARK_BOTTOM if _home_dark() else BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaHome390x844"
	add_child(figma_canvas)
	_build_reference_home(figma_canvas)

func _build_reference_home(canvas: Control) -> void:
	_add_frame_background(canvas)
	var brand_title := _add_text(canvas, "UNJAM", Rect2(21, 23, 101, 34), 27, OFF_WHITE, true)
	brand_title.name = "HomeBrandTitle3D"
	RefCanvas.style_display_title(brand_title, Color("#ffb92f"), Color("#071d55"), 2)

	var selected_level := _home_current_level(selected_game)
	_add_pill(canvas, Rect2(21, 64, 78, 40), Color(0.03, 0.43, 0.78), "LV %d" % selected_level, 13, OFF_WHITE, "HomeSelectedGameLevel")
	home_coin_button = _add_action(canvas, Rect2(107, 62, 112, 44), Color(1.0, 0.55, 0.12), "   %s +" % _compact_number(EconomyManager.balance()), 12, OFF_WHITE, Callable(self, "_open_shop"), 20)
	home_coin_button.name = "HomeCoinShopButton"
	RefCanvas.add_collectible_gem(canvas, Vector2(122, 84), 8.0, "HomeCurrencyGem3D")
	_add_pill(canvas, Rect2(227, 64, 92, 40), GOLD, "   %s" % _compact_number(MultiGameManager.total_stars(selected_game)), 12, NAVY, "HomeSelectedGameStars")
	RefCanvas.add_collectible_star(canvas, Vector2(242, 84), 8.0, true, "HomeCurrencyStar3D")

	_add_hero(canvas)
	_add_quick_actions(canvas)
	_add_quick_switch(canvas)
	_add_world_progress(canvas)
	_add_bottom_nav_reference(canvas)

func _on_economy_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	if home_coin_button != null and is_instance_valid(home_coin_button):
		home_coin_button.text = "   %s +" % _compact_number(new_balance)

func _add_frame_background(canvas: Control) -> void:
	var bg := PanelContainer.new()
	bg.name = "FigmaHomeBackground"
	var top := DARK_SCENE_TOP if _home_dark() else SCENE_TOP
	var middle := DARK_SCENE_MID if _home_dark() else SCENE_MID
	var bottom := DARK_SCENE_BOTTOM if _home_dark() else SCENE_BOTTOM
	var border := Color("#334c78") if _home_dark() else Color("#5ba6e8")
	bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(top, middle, bottom, 34, border, 1, 0.48))
	RefCanvas.set_rect(bg, 0, 0, 390, 844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)
	RefCanvas.add_world_depth(canvas, Color("#59636f") if _home_dark() else Color("#9aa4ae"), _home_dark(), 0.12 if _home_dark() else 0.08, "HomeWorldDepth")
	RefCanvas.add_scene_backdrop_layers(canvas, Color("#68737f") if _home_dark() else Color("#a9b1ba"), _home_dark(), "Home")
	var home_key_light := canvas.get_node_or_null("HomeKeyLight")
	var home_accent_glow := canvas.get_node_or_null("HomeAccentGlow")
	if home_key_light != null:
		home_key_light.set_meta("unjam_figma_scene_light", true)
	if home_accent_glow != null:
		home_accent_glow.set_meta("unjam_figma_scene_light", true)

	# Low-saturation sea-glass/slate depth layers add composition without borrowing
	# any gameplay accent. They are static, cheap, and stay behind all controls.
	var halo_a := PanelContainer.new()
	halo_a.name = "HomeBackdropHaloTop"
	halo_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_a.modulate.a = 0.22 if not _home_dark() else 0.18
	halo_a.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color("#8fb9bd") if not _home_dark() else Color("#52758a"), 110))
	RefCanvas.set_rect(halo_a, 252, -72, 208, 208)
	canvas.add_child(halo_a)
	canvas.move_child(halo_a, 1)

	var halo_b := PanelContainer.new()
	halo_b.name = "HomeBackdropHaloBottom"
	halo_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo_b.modulate.a = 0.18 if not _home_dark() else 0.15
	halo_b.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color("#9fb2c7") if not _home_dark() else Color("#476579"), 105))
	RefCanvas.set_rect(halo_b, -72, 610, 194, 194)
	canvas.add_child(halo_b)
	canvas.move_child(halo_b, 1)

	var ribbon := Polygon2D.new()
	ribbon.name = "HomeBackdropRibbon"
	ribbon.polygon = PackedVector2Array([Vector2(-30,310),Vector2(420,210),Vector2(420,280),Vector2(-30,380)])
	ribbon.color = Color("#6f98a3", 0.075 if not _home_dark() else 0.10)
	canvas.add_child(ribbon)
	canvas.move_child(ribbon, 1)

func _add_hero(canvas: Control) -> void:
	RefCanvas.add_shadow(canvas, Rect2(21, 121, 346, 224), 20, Color(0.03, 0.12, 0.22, 0.25 if not _home_dark() else 0.16), 8 if not _home_dark() else 5, Vector2(0, 6 if not _home_dark() else 4))
	var hero := PanelContainer.new()
	hero.name = "FigmaHomeHero"
	if _home_dark():
		hero.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#162a40"), Color("#12243a"), Color("#0f1d30"), 20, Color(0.24,0.62,0.88,0.62), 1.2))
	else:
		hero.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#f8feff"), Color("#d7ebf0"), Color("#a9c8d2"), 20, Color("#4fa1bd"), 1.7, 0.40))
	RefCanvas.set_rect(hero, 21, 121, 346, 224)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hero)

	_add_text(canvas, "CURRENT JOURNEY", Rect2(41, 142, 150, 15), 12, ORANGE, true)
	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var game_title_size := 23 if selected_game == "block_puzzle" else 27
	var game_title := _add_text(canvas, _short_game_name(selected_game), Rect2(41, 167, 180, 34), game_title_size, NAVY, true)
	game_title.name = "HomeHeroGameTitle"
	RefCanvas.style_display_title(game_title, Unjam3DTheme.game_accent(selected_game).lightened(0.18), Color("#071d55"), 2)
	var game_meta := _add_text(canvas, "LEVEL %d • WORLD %d" % [level, world], Rect2(41, 204, 170, 17), 14, BLUE, true)
	game_meta.name = "HomeHeroGameMeta"

	var continue_button := _add_action(
		canvas,
		Rect2(41, 285, 178, 48),
		BLUE,
		"CONTINUE • LEVEL %d" % level,
		13,
		OFF_WHITE,
		Callable(self, "_continue_selected_game"),
		16
	)
	continue_button.name = "HomePrimaryAction"
	primary_button = continue_button
	_add_hero_preview(canvas, selected_game)

func _add_hero_preview(canvas: Control, game_id: String) -> void:
	var preview_root := Control.new()
	preview_root.name = "HomeHeroPreviewRoot"
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(preview_root, 0, 0, 390, 844)
	canvas.add_child(preview_root)
	var stage := PanelContainer.new()
	stage.name = "FigmaHomeHeroPreview"
	var stage_mid := Color(0.12,0.24,0.34,0.78) if _home_dark() else Color("#c7e1e9")
	stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(stage_mid.lightened(0.15), stage_mid, stage_mid.darkened(0.12), 16, Color(1,1,1,0.20), 1, 0.40))
	RefCanvas.set_rect(stage, 229, 144, 115, 136)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.add_child(stage)
	var mark := FLAT_GAME_LOGO_SCRIPT.new()
	mark.name = "HomeHeroFlatGameLogo"
	mark.configure(game_id)
	RefCanvas.set_rect(mark, 239, 154, 95, 116)
	preview_root.add_child(mark)

func _add_quick_actions(canvas: Control) -> void:
	var choose := _add_action(canvas, Rect2(21, 365, 166, 52), BLUE, "◈ CHOOSE GAME", 12, OFF_WHITE, Callable(self, "_open_game_selector"), 16)
	choose.name = "HomeChooseGameButton"
	var main := get_parent()
	var daily_done_count := 0
	if main != null and main.has_method("_daily_done"):
		for game_id in MultiGameManager.GAME_IDS:
			if bool(main.call("_daily_done", game_id)):
				daily_done_count += 1
	var daily_label := "☀ DAILY • DONE" if daily_done_count >= MultiGameManager.GAME_IDS.size() else "☀ DAILY • %d/3" % daily_done_count
	var daily := _add_action(canvas, Rect2(197, 365, 170, 52), GOLD, daily_label, 11, NAVY, Callable(self, "_open_daily_games"), 16)
	daily.name = "HomeDailyGamesButton"

func _add_quick_switch(canvas: Control) -> void:
	_add_text(canvas, "QUICK SWITCH", Rect2(21, 437, 160, 18), 14, INK, true)
	var games := [
		["rescue_rush", "RESCUE RUSH", Color(0.13, 0.78, 0.39), 21.0],
		["water_sort", "WATER SORT", Color(0.10, 0.66, 1.0), 137.0],
		["block_puzzle", "BLOCK PUZZLE", Color(0.78, 0.24, 1.0), 253.0],
	]
	for entry in games:
		var id := String(entry[0])
		var x := float(entry[3])
		var selected_card := id == selected_game
		# Only the selected game lifts strongly from the surface. Keeping inactive
		# cards quieter reduces Home density while preserving full names/progress.
		RefCanvas.add_shadow(canvas, Rect2(x, 465, 108, 94), 18, Color(0.02, 0.10, 0.18, 0.18 if selected_card else 0.09), 5 if selected_card else 2, Vector2(0, 4 if selected_card else 2))
		var card := PanelContainer.new()
		card.name = "HomeSwitchCard_%s" % id
		var accent: Color = entry[2] as Color
		card.add_theme_stylebox_override("panel", _switch_card_style(id, accent))
		RefCanvas.set_rect(card, x, 465, 108, 94)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(card)
		var mark := FLAT_GAME_LOGO_SCRIPT.new()
		mark.name = "HomeQuickSwitchFlatLogo_%s" % id
		mark.configure(id)
		RefCanvas.set_rect(mark, x + 38, 471, 32, 32)
		canvas.add_child(mark)
		var switch_name := _add_text(canvas, String(entry[1]), Rect2(x + 5, 505, 100, 17), 11, entry[2], true)
		switch_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		switch_name.clip_text = true
		var level := _home_current_level(id)
		var stars := MultiGameManager.total_stars(id)
		var switch_meta := _add_text(canvas, "L%d • ★%s" % [level, _compact_number(stars)], Rect2(x + 6, 530, 96, 16), 11, MUTED, false)
		switch_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var tap := Button.new()
		tap.name = "HomeDirect_%s" % id
		tap.set_meta("unjam_figma_exact_geometry", true)
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.modulate.a = 0.001
		RefCanvas.set_rect(tap, x - 4, 459, 116, 106)
		tap.pressed.connect(_select_home_game.bind(id))
		canvas.add_child(tap)

func _add_world_progress(canvas: Control) -> void:
	var highest := MultiGameManager.highest_level(selected_game)
	var completed_level := clampi(highest - 1, 0, MultiGameManager.CAMPAIGN_LEVELS)
	var world_level := maxi(1, mini(highest, MultiGameManager.CAMPAIGN_LEVELS))
	var world := MultiGameManager.world_for_game_level(selected_game, world_level)
	var first := MultiGameManager.first_level_in_game_world(selected_game, world)
	var last := MultiGameManager.last_level_in_game_world(selected_game, world)
	var total := maxi(1, last - first + 1)
	var completed_in_world := clampi(completed_level - first + 1, 0, total)
	var accent := Unjam3DTheme.game_accent(selected_game)
	var level := _home_current_level(selected_game)
	var next_milestone := int(ceil(float(level) / 25.0)) * 25
	if next_milestone <= level:
		next_milestone += 25
	next_milestone = mini(next_milestone, MultiGameManager.CAMPAIGN_LEVELS)

	var root := Control.new()
	root.name = "HomeWorldProgressRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(root, 0, 0, 390, 844)
	canvas.add_child(root)

	var showcase_rect := Rect2(21, 582, 346, 150)
	RefCanvas.add_shadow(root, showcase_rect, 20, Color(0.01,0.06,0.12,0.25 if _home_dark() else 0.16), 6, Vector2(0,5))
	var panel := PanelContainer.new()
	panel.name = "HomeWorldProgress"
	var fill := Color("#20384b") if _home_dark() else Color("#d5e7ea")
	var edge := Color(accent,0.76 if _home_dark() else 0.66)
	panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(fill.lightened(0.18), fill, fill.darkened(0.15), 20, edge, 1.5, 0.46))
	RefCanvas.set_rect(panel, showcase_rect.position.x, showcase_rect.position.y, showcase_rect.size.x, showcase_rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	# A compact one-shot 3D diorama makes world progression feel like a physical
	# destination instead of a thin status strip. The renderer returns to one-shot
	# mode after its initial frames, so the Home screen keeps its idle budget.
	var art_stage := PanelContainer.new()
	art_stage.name = "HomeWorldShowcaseStage"
	var stage_fill := Color("#13263b") if _home_dark() else Color("#cfe5ea").lerp(accent.lightened(0.76), 0.30)
	art_stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(stage_fill.lightened(0.10), stage_fill, stage_fill.darkened(0.15), 16, Color(accent,0.42), 1.0, 0.42))
	RefCanvas.set_rect(art_stage, 31, 592, 150, 130)
	art_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art_stage)

	var mark := FLAT_GAME_LOGO_SCRIPT.new()
	mark.name = "HomeWorldFlatGameLogo"
	mark.configure(selected_game)
	RefCanvas.set_rect(mark, 47, 603, 118, 108)
	root.add_child(mark)

	var world_title := _add_text(root, "WORLD JOURNEY", Rect2(195, 596, 152, 17), 12, accent, true)
	world_title.name = "HomeWorldProgressTitle"
	_add_text(root, "WORLD %d" % world, Rect2(195, 615, 152, 26), 18, OFF_WHITE if _home_dark() else NAVY, true)
	var world_value := _add_text(root, "LEVEL %d • %d/%d" % [level, completed_in_world, total], Rect2(195, 644, 152, 18), 12, MUTED, true)
	world_value.name = "HomeWorldProgressValue"
	_add_text(root, "NEXT MILESTONE • L%d" % next_milestone, Rect2(195, 668, 152, 17), 11, ORANGE, true)

	var progress := ProgressBar.new()
	progress.name = "HomeWorldProgressBar"
	progress.show_percentage = false
	progress.min_value = 0
	progress.max_value = total
	progress.value = completed_in_world
	progress.add_theme_stylebox_override("background", RefCanvas.rounded_gradient3(Color("#132642"), Color("#091a34"), Color("#051126"), 6, Color(0.38,0.58,0.78,0.55), 1.0, 0.50))
	progress.add_theme_stylebox_override("fill", RefCanvas.rounded_gradient3(accent.lightened(0.48), accent.lightened(0.12), accent.darkened(0.18), 6, Color(accent.lightened(0.62),0.72), 1.0, 0.32))
	RefCanvas.set_rect(progress, 195, 694, 150, 10)
	root.add_child(progress)

	var progress_specular := ColorRect.new()
	progress_specular.name = "WorldProgressSpecular"
	progress_specular.color = Color(1,1,1,0.38)
	progress_specular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(progress_specular, 199, 695, 84, 2)
	root.add_child(progress_specular)

	var percent := int(round(float(completed_in_world) / float(total) * 100.0))
	var percent_label := _add_text(root, "%d%% COMPLETE" % percent, Rect2(195, 706, 150, 16), 11, accent, true)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _add_bottom_nav_reference(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "HomeBottomNav3D"
	RefCanvas.add_shadow(canvas, Rect2(13, 757, 362, 70), 18, Color(0.02, 0.10, 0.18, 0.16), 5, Vector2(0, 4))
	var nav_fill := Color("#1a2129") if _home_dark() else Color("#e3e8ed")
	var nav_border := Color("#34404c") if _home_dark() else Color("#c3cbd3")
	shell.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(nav_fill.lightened(0.12), nav_fill, nav_fill.darkened(0.10), 18, nav_border, 1, 0.40))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)

	var top_gloss := PanelContainer.new()
	top_gloss.name = "HomeNavTopGloss"
	top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_gloss.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.64,0.88,1.0,0.22 if _home_dark() else 0.34), 1))
	RefCanvas.set_rect(top_gloss, 28, 760, 332, 2)
	canvas.add_child(top_gloss)

	var items := [
		["HOME", "⌂", 22.0, Callable(), "HomeNavButton", true, Color("#33b9ff")],
		["GAMES", "▦", 91.0, Callable(self, "_open_game_selector"), "HomeGamesNavButton", false, Color("#7b6cff")],
		["DAILY", "✦", 150.0, Callable(self, "_open_daily_games"), "HomeDailyNavButton", false, GOLD],
		["COLLECT", "◆", 225.0, func(): get_parent().call("build_collection"), "HomeCollectionNavButton", false, Color("#24c96b")],
		["SETTINGS", "⚙", 310.0, func(): get_parent().call("build_settings"), "HomeSettingsNavButton", false, CYAN],
	]
	for item in items:
		var selected: bool = bool(item[5])
		var accent: Color = item[6]
		var nav_color := Color.WHITE if selected and _home_dark() else (DARK_MUTED if _home_dark() else (INK if selected else Color(0.31,0.43,0.54)))
		var icon_color := accent.lightened(0.18) if selected else (DARK_MUTED.lightened(0.08) if _home_dark() else Color(0.38,0.51,0.62))
		if selected:
			var plate_fill := accent.darkened(0.50) if _home_dark() else accent.lightened(0.34)
			var plate_border := accent.lightened(0.16) if _home_dark() else accent.darkened(0.08)
			RefCanvas.add_shadow(canvas, Rect2(float(item[2]) - 3.0, 762, 60, 57), 15, Color(0.01,0.04,0.08,0.24), 3, Vector2(0,3))
			var plate := PanelContainer.new()
			plate.name = "HomeNavActivePlate"
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(plate_fill.lightened(0.14), plate_fill, plate_fill.darkened(0.12), 15, plate_border, 1.2, 0.40))
			RefCanvas.set_rect(plate, float(item[2]) - 3.0, 762, 60, 57)
			canvas.add_child(plate)
			var shine := PanelContainer.new()
			shine.name = "HomeNavActiveShine"
			shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shine.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1,1,1,0.34 if _home_dark() else 0.55), 1))
			RefCanvas.set_rect(shine, float(item[2]) + 7.0, 765, 40, 2)
			canvas.add_child(shine)
		var glyph := _add_text(canvas, item[1], Rect2(float(item[2]) - 1.0, 764, 58, 23), 20, icon_color, true)
		glyph.name = "HomeNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := "COLLECTION" if String(item[0]) == "COLLECT" else String(item[0])
		var label_width := 82.0 if String(item[0]) == "COLLECT" else (66.0 if String(item[0]) == "SETTINGS" else 58.0)
		var label_x := float(item[2]) - 12.0 if String(item[0]) == "COLLECT" else (float(item[2]) - 5.0 if String(item[0]) == "SETTINGS" else float(item[2]) - 1.0)
		# Active destination carries weight; inactive labels stay regular so the
		# five-item bar reads as navigation, not five competing headlines.
		var label := _add_text(canvas, display_name, Rect2(label_x, 790, label_width, 22), 13, nav_color, selected)
		label.name = "HomeNavLabel_%s" % String(item[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.custom_minimum_size = Vector2.ZERO
		label.position = Vector2(label_x, 790)
		label.size = Vector2(label_width, 22)
		var hit := Button.new()
		hit.name = item[4]
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, item[2] - 9, 753, 74, 78)
		var cb: Callable = item[3]
		if cb.is_valid():
			hit.pressed.connect(cb)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)

func _add_pill(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color, label_name: String = "") -> PanelContainer:
	RefCanvas.add_shadow(canvas, rect, rect.size.y * 0.5, Color(0.02, 0.10, 0.18, 0.15), 3, Vector2(0, 2))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(fill.lightened(0.16), fill, fill.darkened(0.12), rect.size.y * 0.5, fill.lightened(0.20), 1, 0.40))
	RefCanvas.set_rect(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	var resolved_text := text_color if fill.get_luminance() > 0.58 else _home_text_color(text_color)
	var label := RefCanvas.label(text_value, font_size, resolved_text, true)
	if not label_name.is_empty():
		label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return panel

func _add_action(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color, callback: Callable, radius: float) -> Button:
	RefCanvas.add_shadow(canvas, rect, radius, Color(0.02, 0.10, 0.18, 0.20), 5, Vector2(0, 4))
	var resolved_text := text_color if fill.get_luminance() > 0.58 else _home_text_color(text_color)
	var button := RefCanvas.premium_button(text_value, font_size, resolved_text, fill, radius)
	RefCanvas.set_rect(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	if callback.is_valid():
		button.pressed.connect(callback)
	canvas.add_child(button)
	return button

func _add_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color, bold: bool) -> Label:
	var label := _make_label(text_value, font_size, color, bold)
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return label

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	var label := RefCanvas.label(text_value, font_size, _home_text_color(color), bold)
	return label

func _home_current_level(game_id: String) -> int:
	if game_id == "rescue_rush":
		return clampi(int(SaveManager.data.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	return clampi(MultiGameManager.highest_level(game_id), 1, MultiGameManager.CAMPAIGN_LEVELS)

func _short_game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _continue_selected_game() -> void:
	var main := get_parent()
	if main == null:
		return
	FeedbackManager.tap()
	var level := _home_current_level(selected_game)
	if selected_game == "rescue_rush":
		main.call("start_level", level)
	else:
		main.call("start_multi_level", selected_game, level, false)

func _open_daily_games() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_daily_games"):
		FeedbackManager.tap()
		main.call("build_daily_games")

func _switch_card_style(game_id: String, accent: Color) -> StyleBox:
	var selected := game_id == selected_game
	var card_fill := accent.darkened(0.64) if selected and _home_dark() else (DARK_CARD if _home_dark() else (accent.lightened(0.76) if selected else Color("#d9eaf0")))
	var border_width := 2.4 if selected else 1.25
	return RefCanvas.rounded_gradient3(
		card_fill.lightened(0.04),
		card_fill,
		card_fill.darkened(0.035),
		18,
		accent,
		border_width
	)

func _refresh_home_selection() -> void:
	if figma_canvas == null or not is_instance_valid(figma_canvas):
		build_home_launcher()
		return
	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var title := figma_canvas.get_node_or_null("HomeHeroGameTitle") as Label
	if title != null:
		title.text = _short_game_name(selected_game)
		title.add_theme_font_size_override("font_size", 23 if selected_game == "block_puzzle" else 27)
		RefCanvas.style_display_title(title, Unjam3DTheme.game_accent(selected_game).lightened(0.18), Color("#071d55"), 2)
	var meta := figma_canvas.get_node_or_null("HomeHeroGameMeta") as Label
	if meta != null:
		meta.text = "LEVEL %d • WORLD %d" % [level, world]
	var top_level := figma_canvas.get_node_or_null("HomeSelectedGameLevel") as Label
	if top_level != null:
		top_level.text = "LV %d" % level
	var top_stars := figma_canvas.get_node_or_null("HomeSelectedGameStars") as Label
	if top_stars != null:
		top_stars.text = "   %s" % _compact_number(MultiGameManager.total_stars(selected_game))
	if primary_button != null and is_instance_valid(primary_button):
		primary_button.text = "CONTINUE • LEVEL %d" % level
	var old_preview := figma_canvas.get_node_or_null("HomeHeroPreviewRoot")
	if old_preview != null:
		figma_canvas.remove_child(old_preview)
		old_preview.queue_free()
	_add_hero_preview(figma_canvas, selected_game)

	# Quick Switch rebuilds the complete world showcase so its one-shot 3D art,
	# world data, milestone and progress bar always match the selected game.
	var old_world_progress := figma_canvas.get_node_or_null("HomeWorldProgressRoot")
	if old_world_progress != null:
		figma_canvas.remove_child(old_world_progress)
		old_world_progress.queue_free()
	_add_world_progress(figma_canvas)
	var progress_accent := Unjam3DTheme.game_accent(selected_game)
	var home_accent_glow := figma_canvas.get_node_or_null("HomeAccentGlow") as PanelContainer
	if home_accent_glow != null:
		home_accent_glow.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(progress_accent.r, progress_accent.g, progress_accent.b, 0.12 if not _home_dark() else 0.08), 120))

	var accents := {
		"rescue_rush": Color(0.13, 0.78, 0.39),
		"water_sort": Color(0.10, 0.66, 1.0),
		"block_puzzle": Color(0.78, 0.24, 1.0),
	}
	for id in accents.keys():
		var card := figma_canvas.get_node_or_null("HomeSwitchCard_%s" % String(id)) as PanelContainer
		if card != null:
			card.add_theme_stylebox_override("panel", _switch_card_style(String(id), accents[id]))

func _select_home_game(game_id: String) -> void:
	if game_id == selected_game:
		return
	selected_game = game_id
	var main := get_parent()
	if main != null:
		main.set("selected_game_id", game_id)
	FeedbackManager.tap()
	_refresh_home_selection()
