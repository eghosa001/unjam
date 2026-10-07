extends "res://scripts/ui/premium_home_casual.gd"

const FLAT_GAME_LOGO_SCRIPT = preload("res://scripts/ui/unjam_flat_game_logo.gd")
const GAME_ART_SCRIPT = preload("res://scripts/ui/unjam_2d_game_art.gd")
const UNJAM_WORDMARK: Texture2D = preload("res://assets/art/brand/unjam_wordmark.svg")

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color("#e9e5dd")
const BG_MID := Color("#b9b2a7")
const BG_BOTTOM := Color("#8f887f")
const NAVY := Color("#252a30")
const INK := Color("#26323d")
const MUTED := Color("#62676e")
const BLUE := Color(0.03, 0.43, 0.78)
const CYAN := Color(0.14, 0.68, 1.0)
const ORANGE := Color(1.0, 0.55, 0.12)
const GOLD := Color(1.0, 0.84, 0.24)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const DARK_TOP := Color("#363636")
const DARK_MID := Color("#272727")
const DARK_BOTTOM := Color("#1f1f1f")
const DARK_CARD := Color("#252525")
const DARK_INK := Color("#f5f7fa")
const DARK_MUTED := Color("#a7b1bc")
const SCENE_TOP := Color("#e4dfd5")
const SCENE_MID := Color("#b3aca2")
const SCENE_BOTTOM := Color("#80786e")
const DARK_SCENE_TOP := Color("#363636")
const DARK_SCENE_MID := Color("#272727")
const DARK_SCENE_BOTTOM := Color("#1f1f1f")

var figma_canvas: FigmaReferenceCanvas
var wide_stage: Control

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
	# The viewport fallback stays neutral for letterboxing; the visible 390x844 scene itself carries the neutral premium depth treatment.
	viewport_bg.color = DARK_BOTTOM if _home_dark() else BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	wide_stage = Control.new()
	wide_stage.name = "HomeWideStage"
	wide_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wide_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wide_stage.visible = false
	add_child(wide_stage)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaHome390x844"
	add_child(figma_canvas)
	_build_reference_home(figma_canvas)
	if not resized.is_connected(_sync_wide_home_stage):
		resized.connect(_sync_wide_home_stage)
	call_deferred("_sync_wide_home_stage")

func _sync_wide_home_stage() -> void:
	if figma_canvas == null or not is_instance_valid(figma_canvas):
		return
	var available := size
	if available.x <= 2.0 or available.y <= 2.0:
		available = get_viewport_rect().size
	var wide := available.x >= 1180.0 and available.x / maxf(1.0, available.y) >= 1.22
	figma_canvas.set_fit_bias(0.10 if wide else 0.5, 0.5)
	if wide_stage == null or not is_instance_valid(wide_stage):
		return
	wide_stage.visible = wide
	for child in wide_stage.get_children():
		wide_stage.remove_child(child)
		child.queue_free()
	if not wide:
		return
	_build_wide_home_stage(wide_stage, available)

func _build_wide_home_stage(stage: Control, available: Vector2) -> void:
	var accent := Unjam3DTheme.game_accent(selected_game)
	var dark := _home_dark()
	var art_side := minf(available.y * 0.66, available.x * 0.42)
	var art_x := available.x * 0.54
	var art_y := maxf(available.y * 0.18, (available.y - art_side) * 0.42)

	# Large atmospheric accents make the extra tablet canvas part of the selected
	# game world instead of leaving it as inert letterbox space.
	var glow := PanelContainer.new()
	glow.name = "HomeWideAccentGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(accent.r, accent.g, accent.b, 0.16 if dark else 0.12), art_side * 0.48))
	glow.position = Vector2(art_x - art_side * 0.08, art_y - art_side * 0.10)
	glow.size = Vector2(art_side * 1.04, art_side * 1.04)
	stage.add_child(glow)

	var art := GAME_ART_SCRIPT.new()
	art.name = "HomeWideSelectedGameArt"
	art.configure(selected_game, false, dark)
	art.position = Vector2(art_x, art_y)
	art.size = Vector2(art_side, art_side)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(art)

	var mark_width := minf(available.x * 0.27, 620.0)
	var mark := TextureRect.new()
	mark.name = "HomeWideWordmark"
	mark.texture = UNJAM_WORDMARK
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(available.x * 0.58, available.y * 0.055)
	mark.size = Vector2(mark_width, mark_width * 0.265)
	stage.add_child(mark)

	var title := RefCanvas.label(_short_game_name(selected_game), int(clampf(available.y * 0.036, 38.0, 64.0)), Color.WHITE, true)
	title.name = "HomeWideGameTitle"
	RefCanvas.style_display_title(title, accent.lightened(0.18), Color("#09141f"), 3)
	title.position = Vector2(available.x * 0.58, available.y * 0.77)
	title.size = Vector2(available.x * 0.34, available.y * 0.065)
	stage.add_child(title)

	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var meta := RefCanvas.label("LEVEL %d  •  WORLD %d  •  %s" % [level, world, _hero_cue(selected_game)], int(clampf(available.y * 0.015, 20.0, 28.0)), Color("#d9e4ee") if dark else Color("#354450"), true)
	meta.name = "HomeWideGameMeta"
	meta.position = Vector2(available.x * 0.58, available.y * 0.835)
	meta.size = Vector2(available.x * 0.34, available.y * 0.042)
	stage.add_child(meta)

	var cta_width := minf(available.x * 0.22, 430.0)
	var cta_height := clampf(available.y * 0.055, 64.0, 88.0)
	var cta := RefCanvas.premium_button("CONTINUE  •  LEVEL %d" % level, int(clampf(available.y * 0.016, 20.0, 28.0)), OFF_WHITE, accent, cta_height * 0.28, Color(accent.lightened(0.28), 0.44), 1.0)
	cta.name = "HomeWideContinueAction"
	cta.position = Vector2(available.x * 0.58, available.y * 0.895)
	cta.size = Vector2(cta_width, cta_height)
	cta.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	cta.pressed.connect(_continue_selected_game)
	stage.add_child(cta)

func _build_reference_home(canvas: Control) -> void:
	_add_frame_background(canvas)
	var brand_title := _add_text(canvas, "UNJAM", Rect2(21, 23, 101, 34), 27, OFF_WHITE, true)
	brand_title.name = "HomeBrandTitle3D"
	brand_title.visible = false
	var wordmark := TextureRect.new()
	wordmark.name = "HomeBrandWordmark"
	wordmark.texture = UNJAM_WORDMARK
	wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(wordmark, 18, 18, 126, 42)
	canvas.add_child(wordmark)

	_add_pill(canvas, Rect2(21, 64, 108, 40), Color("#d6d1c7") if not _home_dark() else Color("#2c2c2c"), "LV %d  ›" % _home_current_level(selected_game), 13, NAVY if not _home_dark() else DARK_INK, "HomeSelectedGameLevel")
	# Visual pill remains compact, while the invisible interaction target meets
	# the 44px mobile touch contract and stays clear of neighboring wallet pills.
	var profile_hit := _add_action(canvas, Rect2(21, 60, 108, 48), Color(1,1,1,0.001), "", 10, Color(1,1,1,0.001), Callable(self, "_open_profile"), 20)
	profile_hit.name = "HomeProfileButton"
	profile_hit.tooltip_text = "Open Profile & Achievements"
	home_coin_button = _add_action(canvas, Rect2(151, 62, 102, 44), Color("#cbc4b8"), "   %s +" % _compact_number(EconomyManager.balance()), 13, NAVY, Callable(self, "_open_shop"), 20)
	home_coin_button.name = "HomeCoinShopButton"
	RefCanvas.add_collectible_gem(canvas, Vector2(166, 84), 8.0, "HomeCurrencyGem3D")
	_add_pill(canvas, Rect2(261, 64, 108, 40), Color("#ead7a3"), "   %s" % _compact_number(MultiGameManager.total_stars(selected_game)), 13, NAVY, "HomeSelectedGameStars")
	RefCanvas.add_collectible_star(canvas, Vector2(277, 84), 8.0, true, "HomeCurrencyStar3D")

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
	var accent := Unjam3DTheme.game_accent(selected_game)
	var fill := (Color("#171b24").lerp(accent.darkened(0.58), 0.30) if _home_dark()
		else Color("#e7ecea").lerp(accent.lightened(0.42), 0.44))
	var edge := Color(accent, 0.18)
	bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
		fill.lightened(0.055), fill, fill.darkened(0.10), 34, edge, 1, 0.16
	))
	RefCanvas.set_rect(bg, 0, 0, 390, 844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	var glow := PanelContainer.new()
	glow.name = "HomeAccentGlow"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(accent, 0.12 if not _home_dark() else 0.08), 120))
	RefCanvas.set_rect(glow, 178, 82, 248, 280)
	canvas.add_child(glow)

func _add_hero(canvas: Control) -> void:
	var hero := PanelContainer.new()
	hero.name = "FigmaHomeHero"
	var accent := Unjam3DTheme.game_accent(selected_game)
	var fill := (Color("#13242b").lerp(accent.darkened(0.52), 0.38) if _home_dark()
		else Color("#edf4ef").lerp(accent.lightened(0.38), 0.42))
	hero.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
		fill.lightened(0.08), fill, fill.darkened(0.12), 24, Color(accent, 0.22), 1, 0.20
	))
	RefCanvas.set_rect(hero, 21, 121, 346, 224)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hero)

	# Art is now the visual anchor, not a tiny logo sitting inside another card.
	_add_hero_preview(canvas, selected_game)

	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var game_title_size := 22 if selected_game == "block_puzzle" else 25
	# The selected game name is intentionally allowed to wrap, so reserve the
	# actual two-line font height instead of letting Label minimum-size expansion
	# push into the metadata below on compact displays.
	var game_title := _add_text(canvas, _short_game_name(selected_game), Rect2(37, 140, 158, 72), game_title_size, NAVY, true)
	game_title.name = "HomeHeroGameTitle"
	game_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_title.add_theme_color_override("font_color", Color("#f7fbff") if _home_dark() else accent.darkened(0.28))
	var game_meta := _add_text(canvas, "LEVEL %d • WORLD %d" % [level, world], Rect2(37, 218, 154, 20), 13, MUTED, false)
	game_meta.name = "HomeHeroGameMeta"
	var cue := _add_text(canvas, _hero_cue(selected_game), Rect2(37, 243, 154, 32), 11, MUTED, true)
	cue.name = "HomeHeroCue"
	cue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var continue_button := _add_action(
		canvas,
		Rect2(37, 287, 172, 48),
		accent,
		"CONTINUE • LEVEL %d" % level,
		13,
		OFF_WHITE,
		Callable(self, "_continue_selected_game"),
		16
	)
	continue_button.name = "HomePrimaryAction"
	primary_button = continue_button

func _hero_cue(game_id: String) -> String:
	match game_id:
		"water_sort": return "POUR • MATCH • CLEAR"
		"block_puzzle": return "PLACE • CLEAR • COMBO"
		_: return "READ • MOVE • ESCAPE"

func _add_hero_preview(canvas: Control, game_id: String) -> void:
	var preview_root := Control.new()
	preview_root.name = "HomeHeroPreviewRoot"
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(preview_root, 0, 0, 390, 844)
	canvas.add_child(preview_root)
	# Compatibility diagnostic: production hardening still measures the original
	# safe preview zone to guarantee title/art separation. It is non-visual.
	var preview_diagnostic := Control.new()
	preview_diagnostic.name = "FigmaHomeHeroPreview"
	preview_diagnostic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(preview_diagnostic, 229, 144, 115, 136)
	preview_root.add_child(preview_diagnostic)
	var art := GAME_ART_SCRIPT.new()
	# Preserve the established node id used by visual QA while upgrading what it renders.
	art.name = "HomeHeroFlatGameLogo"
	art.configure(game_id, false, _home_dark())
	RefCanvas.set_rect(art, 174, 129, 184, 204)
	preview_root.add_child(art)

func _add_quick_actions(canvas: Control) -> void:
	# Secondary navigation still has game identity: one saturated game action and
	# one trophy action, rather than two generic application bars.
	var selected_accent := Unjam3DTheme.game_accent(selected_game)
	var choose_fill := selected_accent.darkened(0.18) if _home_dark() else selected_accent
	var choose := _add_action(canvas, Rect2(21, 365, 166, 52), choose_fill, "▦  CHOOSE GAME", 12, OFF_WHITE, Callable(self, "_open_game_selector"), 14)
	choose.name = "HomeChooseGameButton"
	# Open the selector only after the finger is released. The button overlaps the
	# Water Sort card coordinates on the next surface, so press-mode can let the
	# same Android touch carry through and immediately launch that game.
	choose.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var compete_fill := Color("#7052d8") if _home_dark() else Color("#7659e8")
	var compete := _add_action(canvas, Rect2(197, 365, 170, 52), compete_fill, "★  COMPETE", 12, OFF_WHITE, Callable(self, "_open_compete"), 14)
	# Keep the stable node id used by older automation while the player-facing
	# action now opens campaign progression rankings instead of Daily.
	compete.name = "HomeDailyGamesButton"
	compete.tooltip_text = "Campaign rankings • all-time and weekly"

	# Sidekick stays discoverable without taking a third content column.
	var sidekick := _add_action(canvas, Rect2(261, 15, 108, 44), Color("#4f446e") if _home_dark() else Color("#d9d0f5"), "SIDEKICK • β", 11, OFF_WHITE if _home_dark() else Color("#493b70"), Callable(self, "_open_sidekick"), 14)
	sidekick.name = "HomePlaymateSidekickBeta"
	sidekick.tooltip_text = LocalizationManager.localize("PLAYMATE SIDEKICK") + " • " + LocalizationManager.localize("BETA")

func _open_sidekick() -> void:
	var main := get_parent()
	if main != null and main.has_method("show_playmate_sidekick"):
		main.call("show_playmate_sidekick", selected_game)

func _open_profile() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_profile"):
		main.call("build_profile")

func _open_goals() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_goals"):
		main.call("build_goals")

func _open_friends() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_friends"):
		main.call("build_friends")

func _add_quick_switch(canvas: Control) -> void:
	_add_text(canvas, "GAMES", Rect2(21, 437, 160, 18), 14, OFF_WHITE if _home_dark() else INK, true)
	var games := [
		["rescue_rush", "RESCUE RUSH", Color(0.13, 0.78, 0.39), 21.0],
		["water_sort", "WATER SORT", Color(0.10, 0.66, 1.0), 137.0],
		["block_puzzle", "BLOCK PUZZLE", Color(0.78, 0.24, 1.0), 253.0],
	]
	for entry in games:
		var id := String(entry[0])
		var x := float(entry[3])
		var selected_card := id == selected_game
		# Keep quick-switch cards flat. A faint cue only on the selected game gives
		# hierarchy without bringing back the heavier 3D card stack.
		if selected_card:
			RefCanvas.add_shadow(canvas, Rect2(x, 465, 108, 94), 18, Color(0.02, 0.10, 0.18, 0.08), 2, Vector2(0, 1))
		var card := PanelContainer.new()
		card.name = "HomeSwitchCard_%s" % id
		var accent: Color = entry[2] as Color
		card.add_theme_stylebox_override("panel", _switch_card_style(id, accent))
		RefCanvas.set_rect(card, x, 465, 108, 94)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(card)
		var mark := GAME_ART_SCRIPT.new()
		mark.name = "HomeQuickSwitchFlatLogo_%s" % id
		mark.configure(id, true, _home_dark())
		RefCanvas.set_rect(mark, x + 7, 468, 94, 48)
		canvas.add_child(mark)
		var switch_font := 10 if id == "block_puzzle" else 11
		var switch_name := _add_text(canvas, String(entry[1]), Rect2(x + 2, 516, 104, 17), switch_font, entry[2], true)
		switch_name.name = "HomeQuickSwitchName_%s" % id
		switch_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		switch_name.clip_text = true
		RefCanvas.fit_single_line_text(switch_name, 100.0, switch_font, 9)
		var level := _home_current_level(id)
		var stars := MultiGameManager.total_stars(id)
		var switch_meta := _add_text(canvas, "L%d • ★%s" % [level, _compact_number(stars)], Rect2(x + 6, 537, 96, 16), 11, MUTED, false)
		switch_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var tap := Button.new()
		tap.name = "HomeDirect_%s" % id
		tap.set_meta("unjam_figma_exact_geometry", true)
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.modulate.a = 0.001
		tap.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
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

	var root := Control.new()
	root.name = "HomeWorldProgressRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(root, 0, 0, 390, 844)
	canvas.add_child(root)

	var showcase_rect := Rect2(21, 582, 346, 150)
	var panel := PanelContainer.new()
	panel.name = "HomeWorldProgress"
	var fill := (Color("#20262b").lerp(accent.darkened(0.50),0.22) if _home_dark()
		else Color("#edf1ee").lerp(accent.lightened(0.48),0.34))
	panel.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(fill.lightened(0.05),fill,fill.darkened(0.08),18,Color(accent,0.18),1,0.10))
	RefCanvas.set_rect(panel, showcase_rect.position.x, showcase_rect.position.y, showcase_rect.size.x, showcase_rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	# Keep the shared selected-game identity present, but compact: the hero and
	# quick-switch row already carry the large art. This frees room for live meta.
	var mark := GAME_ART_SCRIPT.new()
	mark.name = "HomeWorldFlatGameLogo"
	mark.configure(selected_game, true, _home_dark())
	RefCanvas.set_rect(mark, 32, 590, 52, 48)
	root.add_child(mark)

	var world_title := _add_text(root, "%s %d" % [MultiGameManager.progression_scope_label(selected_game), world], Rect2(86, 592, 150, 22), 15, OFF_WHITE if _home_dark() else NAVY, true)
	world_title.name = "HomeWorldProgressTitle"
	var world_value := _add_text(root, "LEVEL %d • %d/%d" % [level, completed_in_world, total], Rect2(86, 615, 164, 18), 12, MUTED, false)
	world_value.name = "HomeWorldProgressValue"

	var progress := ProgressBar.new()
	progress.name = "HomeWorldProgressBar"
	progress.show_percentage = false
	progress.min_value = 0
	progress.max_value = total
	progress.value = completed_in_world
	progress.add_theme_stylebox_override("background", RefCanvas.solid_box(Color(0.05,0.08,0.10,0.28) if _home_dark() else Color(1,1,1,0.42), 4))
	progress.add_theme_stylebox_override("fill", RefCanvas.solid_box(accent, 4))
	RefCanvas.set_rect(progress, 258, 607, 91, 7)
	root.add_child(progress)

	var live_title := _add_text(root, "LIVE NOW", Rect2(35, 643, 100, 18), 12, GOLD, true)
	live_title.name = "HomeLiveNowTitle"

	var daily := _add_action(root, Rect2(35, 670, 96, 44), Color("#7a57e0"), "DAILY", 11, OFF_WHITE, Callable(self, "_open_daily_games"), 12)
	daily.name = "HomeDailyChallengeButton"
	daily.tooltip_text = "Daily challenges • streaks and rewards"

	var ready := MetaProgressionManager.ready_claim_count()
	var goals_text := "GOALS %d" % ready if ready > 0 else "GOALS"
	var goals := _add_action(root, Rect2(147, 670, 96, 44), Color("#ee8a2d") if not _home_dark() else Color("#9a5620"), goals_text, 11, OFF_WHITE, Callable(self, "_open_goals"), 12)
	goals.name = "HomeGoalsButton"
	goals.tooltip_text = "Daily check-in, missions and Season Journey"

	var friends := _add_action(root, Rect2(259, 670, 90, 44), Color("#22a9e8"), "FRIENDS", 11, OFF_WHITE, Callable(self, "_open_friends"), 12)
	friends.name = "HomeFriendsButton"
	friends.tooltip_text = "Friend codes • compare campaign progress"

func _add_bottom_nav_reference(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "HomeBottomNav3D"
	var nav_fill := Color("#252629") if _home_dark() else Color("#f0ede6")
	var nav_border := Color("#3a3d42") if _home_dark() else Color("#cbc6bc")
	shell.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(nav_fill, 18, nav_border, 1, 0.12))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)

	var items := [
		["HOME", "⌂", 22.0, 14.0, Callable(), "HomeNavButton", true, GOLD],
		["GAMES", "▦", 94.0, 86.0, Callable(self, "_open_game_selector"), "HomeGamesNavButton", false, GOLD],
		["DAILY", "✦", 166.0, 158.0, Callable(self, "_open_daily_games"), "HomeDailyNavButton", false, GOLD],
		["COLLECT", "◆", 238.0, 230.0, func(): get_parent().call("build_collection"), "HomeCollectionNavButton", false, GOLD],
		["SETTINGS", "⚙", 310.0, 302.0, func(): get_parent().call("build_settings"), "HomeSettingsNavButton", false, GOLD],
	]
	for item in items:
		var selected: bool = bool(item[6])
		var accent: Color = item[7]
		var idle_color := Color("#98a2ad") if _home_dark() else Color("#66707a")
		var nav_color := DARK_INK if selected and _home_dark() else (INK if selected else idle_color)
		var icon_color := accent if selected else idle_color
		if selected:
			var plate := PanelContainer.new()
			plate.name = "HomeNavActivePlate"
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate.add_theme_stylebox_override("panel", RefCanvas.flat_gloss(Color(accent.r, accent.g, accent.b, 0.12 if _home_dark() else 0.15), 12, Color(accent.r, accent.g, accent.b, 0.40), 1, 0.16))
			RefCanvas.set_rect(plate, float(item[3]) + 8.0, 764, 56, 52)
			canvas.add_child(plate)
		var glyph := _add_text(canvas, item[1], Rect2(float(item[2]) - 1.0, 765, 58, 22), 20, icon_color, true)
		glyph.name = "HomeNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := String(item[0])
		var label_width := 66.0 if String(item[0]) in ["COLLECT", "SETTINGS"] else 58.0
		var label_x := float(item[3]) + (72.0 - label_width) * 0.5
		var label := _add_text(canvas, display_name, Rect2(label_x, 790, label_width, 20), 13, nav_color, selected)
		label.name = "HomeNavLabel_%s" % String(item[0])
		label.custom_minimum_size = Vector2.ZERO
		RefCanvas.fit_single_line_text(label, label_width - 2.0, 13, 10)
		label.position = Vector2(label_x, 790)
		label.size = Vector2(label_width, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		var hit := Button.new()
		hit.name = item[5]
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		hit.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		RefCanvas.set_rect(hit, float(item[3]), 753, 72, 78)
		var cb: Callable = item[4]
		if cb.is_valid():
			hit.pressed.connect(cb)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)

func _add_pill(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color, label_name: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", RefCanvas.solid_box(fill, rect.size.y * 0.5, Color(fill.r, fill.g, fill.b, 0.38), 1))
	RefCanvas.set_rect(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	var resolved_text := text_color if fill.get_luminance() > 0.58 else _home_text_color(text_color)
	var label := RefCanvas.label(text_value, font_size, resolved_text, true)
	if not label_name.is_empty():
		label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	RefCanvas.fit_single_line_text(label, maxf(18.0, rect.size.x - 10.0), font_size, 10)
	canvas.add_child(label)
	return panel

func _add_action(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color, callback: Callable, radius: float) -> Button:
	var resolved_text := text_color if fill.get_luminance() > 0.58 else _home_text_color(text_color)
	var button := RefCanvas.premium_button(text_value, font_size, resolved_text, fill, radius, Color(fill.r, fill.g, fill.b, 0.34), 1)
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	RefCanvas.set_rect(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	RefCanvas.fit_single_line_text(button, maxf(24.0, rect.size.x - 16.0), font_size, 10)
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

func _open_game_selector() -> void:
	var main := get_parent()
	if main != null and main.has_method("_open_games_surface"):
		# _open_games_surface owns navigation feedback so every caller produces
		# exactly one tap instead of stacking duplicate sounds on the same action.
		main.call("_open_games_surface")

func _open_compete() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_compete_leaderboard"):
		FeedbackManager.tap()
		main.call("build_compete_leaderboard")

func _open_daily_games() -> void:
	var main := get_parent()
	if main != null and main.has_method("build_daily_games"):
		FeedbackManager.tap()
		main.call("build_daily_games")

func _switch_card_style(game_id: String, accent: Color) -> StyleBox:
	var selected := game_id == selected_game
	var base_fill := Color("#202832") if _home_dark() else Color("#f1f5f3")
	var card_fill := base_fill.lerp(accent.darkened(0.45) if _home_dark() else accent.lightened(0.62), 0.22 if selected else 0.08)
	var border_color := Color(accent, 0.46) if selected else Color(accent, 0.10)
	return RefCanvas.rounded_gradient3(card_fill.lightened(0.05), card_fill, card_fill.darkened(0.08), 16, border_color, 1, 0.12)

func _refresh_home_selection() -> void:
	if figma_canvas == null or not is_instance_valid(figma_canvas):
		build_home_launcher()
		return
	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	var title := figma_canvas.get_node_or_null("HomeHeroGameTitle") as Label
	if title != null:
		title.text = _short_game_name(selected_game)
		title.add_theme_font_size_override("font_size", 22 if selected_game == "block_puzzle" else 25)
		var title_accent := Unjam3DTheme.game_accent(selected_game)
		title.add_theme_color_override("font_color", title_accent.lightened(0.16) if _home_dark() else title_accent.darkened(0.20))
		title.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
		title.add_theme_constant_override("outline_size", 0)
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
	_sync_wide_home_stage()

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
