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
	# Home is an app-wide launcher, NOT a selected game's level screen.
	# Wide screens use the UNJAM identity rather than prominently featuring a
	# specific puzzle or adding another Continue action.
	var dark := _home_dark()
	var art_side := minf(available.y*0.58,available.x*0.38)
	var mark := TextureRect.new()
	mark.name = "HomeWideBrandMark"
	mark.texture = preload("res://assets/icon_user_adaptive_432.png")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(available.x*0.58,available.y*0.13)
	mark.size = Vector2(art_side,art_side)
	stage.add_child(mark)
	var title := RefCanvas.label("ONE HOME. ALL YOUR PUZZLES.",int(clampf(available.y*0.028,32.0,54.0)),DARK_INK if dark else NAVY,true)
	title.name = "HomeWideBrandTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.position = Vector2(available.x*0.51,available.y*0.74)
	title.size = Vector2(available.x*0.46,available.y*0.11)
	stage.add_child(title)
	var hint := RefCanvas.label("Choose Game  •  Daily Challenge  •  Your Rankings",int(clampf(available.y*0.017,19.0,27.0)),DARK_MUTED if dark else MUTED,false)
	hint.name = "HomeWideBrandSubtitle"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(available.x*0.52,available.y*0.87)
	hint.size = Vector2(available.x*0.44,available.y*0.055)
	stage.add_child(hint)

func _build_reference_home(canvas: Control) -> void:
	_add_frame_background(canvas)
	var wordmark := TextureRect.new()
	wordmark.name = "HomeBrandWordmark"
	wordmark.texture = UNJAM_WORDMARK
	wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(wordmark,20,19,150,44)
	canvas.add_child(wordmark)

	_add_pill(canvas,Rect2(21,66,113,40),Color("#323741") if _home_dark() else Color("#d9d7d1"),"PROFILE  ›",13,DARK_INK if _home_dark() else NAVY,"HomeProfilePill")
	var profile_hit := _add_action(canvas,Rect2(21,64,113,44),Color(1,1,1,0.001),"",10,Color(1,1,1,0.001),Callable(self,"_open_profile"),16)
	profile_hit.name = "HomeProfileButton"
	profile_hit.accessibility_name = "Open player profile"
	home_coin_button = _add_action(canvas,Rect2(238,64,129,44),Color("#d9cfaf"),"  %s  +" % _compact_number(EconomyManager.balance()),13,NAVY,Callable(self,"_open_shop"),16)
	home_coin_button.name = "HomeCoinShopButton"
	home_coin_button.accessibility_name = "View coins and open shop"
	RefCanvas.add_collectible_gem(canvas,Vector2(256,86),8.0,"HomeCurrencyGem3D")

	_add_hero(canvas)
	_add_game_showcase(canvas)
	_add_rank_summary(canvas)
	_add_daily_feature(canvas)
	_add_bottom_nav_reference(canvas)
	if not CompetitionManager.snapshot_updated.is_connected(_on_home_ranking_updated):
		CompetitionManager.snapshot_updated.connect(_on_home_ranking_updated)
	if not CompetitionManager.daily_snapshot_updated.is_connected(_on_home_ranking_updated):
		CompetitionManager.daily_snapshot_updated.connect(_on_home_ranking_updated)
	_on_home_ranking_updated({})
	# A return to Home should not issue duplicate requests if the shared manager
	# already fetched rankings. Daily data has its own independent snapshot.
	if CompetitionManager.daily_snapshot.is_empty() and OS.get_environment("UNJAM_FAST_VISUAL_AUDIT") != "1":
		CompetitionManager.refresh_daily_snapshot()

func _on_economy_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	if home_coin_button != null and is_instance_valid(home_coin_button):
		home_coin_button.text = "  %s  +" % _compact_number(new_balance)

func _add_frame_background(canvas: Control) -> void:
	var dark := _home_dark()
	var bg := PanelContainer.new()
	bg.name = "FigmaHomeBackground"
	var fill := Color("#1d2330") if dark else Color("#eaeaf0")
	bg.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
		fill.lightened(0.065),fill,fill.darkened(0.075),32,Color("#71768a",0.11),1,0.08))
	RefCanvas.set_rect(bg,0,0,390,844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

func _add_hero(canvas: Control) -> void:
	var dark := _home_dark()
	var hero := PanelContainer.new()
	hero.name = "FigmaHomeHero"
	var fill := Color("#2c3242") if dark else Color("#faf8f2")
	hero.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
		fill.lightened(0.07),fill,fill.darkened(0.08),24,
		Color("#789dff",0.45) if dark else Color("#a7a5bd",0.44),1,0.17))
	RefCanvas.set_rect(hero,21,126,346,168)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hero)
	var title := _add_text(canvas,"PLAY YOUR WAY.",Rect2(40,145,221,38),25,DARK_INK if dark else NAVY,true)
	title.name = "HomeWelcomeTitle"
	RefCanvas.fit_single_line_text(title,219.0,25,21)
	var subtitle := _add_text(canvas,"Puzzle. Compete. Repeat.",Rect2(40,190,226,24),14,DARK_MUTED if dark else MUTED,false)
	subtitle.name = "HomeWelcomeSubtitle"
	# Compact neutral brand mark: Home is NOT a selected game's landing page.
	var mark := TextureRect.new()
	mark.name = "HomeBrandEmblem"
	mark.texture = preload("res://assets/icon_user_adaptive_432.png")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RefCanvas.set_rect(mark,266,137,80,75)
	canvas.add_child(mark)
	var choose := _add_action(canvas,Rect2(39,227,312,54),
		Color("#4775e7") if dark else Color("#286ac0"),
		"▦  CHOOSE GAME",17,OFF_WHITE,Callable(self,"_open_game_selector"),17)
	choose.name = "HomePrimaryAction"
	choose.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	choose.accessibility_name = "Choose Game. Open the games screen to pick your puzzle."
	choose.tooltip_text = "Browse and choose Rescue Rush, Water Sort or Block Puzzle"
	primary_button = choose

func _add_game_showcase(canvas: Control) -> void:
	# Each compact game image is a one-tap shortcut to THAT game's LEVEL
	# SELECT screen, never straight to gameplay. Retain the large Choose Game
	# button as the primary launcher and the quiet low-cost illustrated strip.
	var dark := _home_dark()
	var header := _add_text(canvas,"THREE GAMES. ONE APP.",Rect2(22,310,236,24),
		16,DARK_INK if dark else NAVY,true)
	header.name = "HomeShowcaseTitle"
	var note := _add_text(canvas,"LEVELS ›",Rect2(281,314,85,20),
		11,DARK_MUTED if dark else MUTED,true)
	RefCanvas.fit_single_line_text(note,82.0,11,10)
	note.custom_minimum_size = Vector2.ZERO
	note.size = Vector2(85,20)
	note.clip_text = true
	note.name = "HomeShowcaseEyebrow"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var games := [
		{"id":"rescue_rush","name":"RESCUE RUSH","description":"Free the pieces","accent":Color("#43d7a0"),"x":21.0},
		{"id":"water_sort","name":"WATER SORT","description":"Sort the colors","accent":Color("#4cbefa"),"x":139.0},
		{"id":"block_puzzle","name":"BLOCK PUZZLE","description":"Clear the rows","accent":Color("#be88ff"),"x":257.0},
	]
	for game in games:
		var id := String(game["id"])
		var left := float(game["x"])
		var accent := game["accent"] as Color
		var panel := PanelContainer.new()
		panel.name = "HomeShowcaseCard_%s" % id
		var neutral := Color("#272d38") if dark else Color("#f8f7f4")
		var tint := neutral.lerp(accent.darkened(0.58) if dark else accent.lightened(0.65),0.29)
		panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
			tint.lightened(0.08),tint,tint.darkened(0.08),16,Color(accent,0.56),1,0.22))
		RefCanvas.set_rect(panel,left,344,110,112)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.accessibility_name = "%s: %s" % [String(game["name"]),String(game["description"])]
		canvas.add_child(panel)
		# Square original artwork retains its aspect ratio and uses the largest
		# practical area of each compact card. This fixes the previous 82x46
		# squashing that made all three game pictures look indistinct.
		var art := GAME_ART_SCRIPT.new()
		art.name = "HomeShowcaseArt_%s" % id
		art.configure(id,true,dark)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		RefCanvas.set_rect(art,left+12,346,86,70)
		canvas.add_child(art)
		var label := _add_text(canvas,String(game["name"]),Rect2(left+3,417,104,18),
			12,accent.lightened(0.16) if dark else accent.darkened(0.56),true)
		label.name = "HomeShowcaseName_%s" % id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		RefCanvas.fit_single_line_text(label,102.0,12,10)
		label.custom_minimum_size = Vector2.ZERO
		label.size = Vector2(104,18)
		var tagline := _add_text(canvas,String(game["description"]),Rect2(left+6,436,98,17),
			11,DARK_INK if dark else Color("#484c59"),false)
		tagline.name = "HomeShowcaseTagline_%s" % id
		tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tagline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
		RefCanvas.fit_single_line_text(tagline,97.0,11,9)
		tagline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tagline.custom_minimum_size = Vector2.ZERO
		tagline.size = Vector2(98,17)
		tagline.clip_text = true

		# Topmost transparent touch layer covers the entire image, name and
		# caption; touch RELEASE avoids opening gameplay via touch-through.
		var shortcut := Button.new()
		shortcut.name = "HomeShowcaseOpenLevels_%s" % id
		# Visually subtle hover/press feedback while keeping the original
		# illustration fully visible in the resting state.
		shortcut.flat = false
		shortcut.add_theme_stylebox_override("normal",RefCanvas.solid_box(Color.TRANSPARENT,16))
		shortcut.add_theme_stylebox_override("hover",RefCanvas.solid_box(Color(accent,0.10),16,Color(accent,0.44),1))
		shortcut.add_theme_stylebox_override("pressed",RefCanvas.solid_box(Color(accent,0.19),16,accent,2))
		shortcut.mouse_filter = Control.MOUSE_FILTER_STOP
		shortcut.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		shortcut.focus_mode = Control.FOCUS_ALL
		shortcut.set_meta("unjam_figma_exact_geometry",true)
		shortcut.set_meta("unjam_preserve_surface_style",true)
		shortcut.set_meta("unjam_preserve_control_geometry",true)
		shortcut.add_theme_stylebox_override("focus",RefCanvas.solid_box(Color.TRANSPARENT,16,accent,2))
		shortcut.accessibility_name = "Open %s level selection" % String(game["name"]).capitalize()
		shortcut.tooltip_text = "Choose a %s level" % String(game["name"]).capitalize()
		RefCanvas.set_rect(shortcut,left,344,110,112)
		shortcut.pressed.connect(_open_game_levels.bind(id))
		canvas.add_child(shortcut)
		# Some parent/surface setup steps reset Button focus when mounted.
		# Reassert actual keyboard/TalkBack focus after entering the tree.
		shortcut.focus_mode = Control.FOCUS_ALL
		shortcut.set_deferred("focus_mode",Control.FOCUS_ALL)
		shortcut.set_meta("unjam_authored_focus_mode",int(Control.FOCUS_ALL))

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

# Keep Home focused on three decisions: choose a game, see your ranking,
# or play the Daily challenge. Individual game cards and world progression
# are available on Games; only compact secondary destinations stay here.
func _add_rank_summary(canvas: Control) -> void:
	var dark := _home_dark()
	var panel := PanelContainer.new()
	panel.name = "HomeRankSummaryCard"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
		Color("#323447") if dark else Color("#f1edfa"),
		Color("#282d43") if dark else Color("#e7e2f4"),
		Color("#22273b") if dark else Color("#ddd9ed"),
		19,Color("#ad96ef",0.55),1,0.14))
	RefCanvas.set_rect(panel,21,472,346,164)
	canvas.add_child(panel)
	var heading := _add_text(canvas,"YOUR RANKINGS",Rect2(37,480,280,22),
		16,DARK_INK if dark else NAVY,true)
	heading.name = "HomeRankTitle"
	var daily_tag := _add_text(canvas,"TODAY",Rect2(38,505,140,21),
		12,DARK_MUTED if dark else Color("#424a59"),true)
	daily_tag.name = "HomeRankDailyLabel"
	var daily_rank := _add_text(canvas,"—",Rect2(38,532,135,34),
		27,GOLD if dark else Color("#714e12"),true)
	daily_rank.name = "HomeRankDailyValue"
	var daily_hint := _add_text(canvas,"PLAY TO JOIN",Rect2(38,568,140,18),
		11,DARK_MUTED if dark else Color("#424a59"),false)
	daily_hint.name = "HomeRankDailyHint"
	var weekly_tag := _add_text(canvas,"BEST WEEKLY",Rect2(200,505,145,21),
		12,DARK_MUTED if dark else Color("#424a59"),true)
	weekly_tag.name = "HomeRankWeeklyLabel"
	var weekly_rank := _add_text(canvas,"—",Rect2(200,532,135,34),
		27,GOLD if dark else Color("#714e12"),true)
	weekly_rank.name = "HomeRankValue"
	var weekly_hint := _add_text(canvas,"PLAY TO JOIN",Rect2(200,568,144,18),
		11,DARK_MUTED if dark else Color("#424a59"),false)
	weekly_hint.name = "HomeRankWeeklyHint"
	var open := _add_action(canvas,Rect2(38,590,314,44),Color("#7757cf"),
		"★  VIEW FULL LEADERBOARD",14,OFF_WHITE,Callable(self,"_open_compete"),14)
	open.name = "HomeDailyGamesButton"
	open.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	open.accessibility_name = "Open full-screen Today, Weekly and All-Time leaderboards"
	open.tooltip_text = "Open full-screen Today, Weekly and All-Time player rankings"

func _on_home_ranking_updated(_data: Dictionary) -> void:
	if figma_canvas == null or not is_instance_valid(figma_canvas):
		return
	var daily := figma_canvas.get_node_or_null("HomeRankDailyValue") as Label
	var weekly := figma_canvas.get_node_or_null("HomeRankValue") as Label
	if daily == null or weekly == null:
		return
	var today_rank := CompetitionManager.daily_rank()
	daily.text = "#%d" % today_rank if today_rank > 0 else "—"
	daily.accessibility_name = "Today's daily leaderboard rank: %d" % today_rank if today_rank > 0 else "No Daily rank yet"
	# The backend has independent rankings per game. Show the best weekly
	# placement across them; never suggest an invented overall leaderboard.
	var best := 0
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		var position := CompetitionManager.game_weekly_rank(game_id)
		if position > 0 and (best == 0 or position < best):
			best = position
	weekly.text = "#%d" % best if best > 0 else "—"
	weekly.accessibility_name = "Best weekly game leaderboard rank: %d" % best if best > 0 else "No weekly rank yet"
	var daily_hint := figma_canvas.get_node_or_null("HomeRankDailyHint") as Label
	if daily_hint != null:
		daily_hint.text = "ON THE BOARD" if today_rank > 0 else "PLAY TO JOIN"
	var weekly_hint := figma_canvas.get_node_or_null("HomeRankWeeklyHint") as Label
	if weekly_hint != null:
		weekly_hint.text = "ON THE BOARD" if best > 0 else "PLAY TO JOIN"

func _add_daily_feature(canvas: Control) -> void:
	var dark := _home_dark()
	var panel := PanelContainer.new()
	panel.name = "HomeDailyFeatureCard"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
		Color("#294536") if dark else Color("#e3f9e9"),
		Color("#263c30") if dark else Color("#d9f2e1"),
		Color("#22342a") if dark else Color("#cbead7"),
		18,Color("#6ab894",0.40),1,0.08))
	RefCanvas.set_rect(panel,21,652,346,84)
	canvas.add_child(panel)
	var title := _add_text(canvas,"DAILY CHALLENGE",Rect2(36,662,178,27),
		16,DARK_INK if dark else NAVY,true)
	title.name = "HomeDailyFeatureTitle"
	var subtitle := _add_text(canvas,"A new challenge daily",Rect2(36,699,171,24),
		12,DARK_MUTED if dark else Color("#3b624c"),false)
	subtitle.name = "HomeDailyFeatureSubtitle"
	var daily := _add_action(canvas,Rect2(225,668,126,52),Color("#257e55"),
		"PLAY DAILY",13,OFF_WHITE,Callable(self,"_open_daily_games"),14)
	daily.name = "HomeDailyChallengeButton"
	daily.accessibility_name = "Play today's Daily challenges"

func _add_secondary_links(canvas: Control) -> void:
	var dark := _home_dark()
	var link_fill := Color("#353945") if dark else Color("#e7e8e7")
	var link_text := OFF_WHITE if dark else NAVY
	var goals := _add_action(canvas,Rect2(21,682,168,49),link_fill,"✦  GOALS",12,link_text,Callable(self,"_open_goals"),14)
	goals.name = "HomeGoalsButton"
	goals.tooltip_text = "Missions and collection progress"
	var friends := _add_action(canvas,Rect2(199,682,168,49),link_fill,"♧  FRIENDS",12,link_text,Callable(self,"_open_friends"),14)
	friends.name = "HomeFriendsButton"
	friends.tooltip_text = "Friends and private rankings"

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
	var compete := _add_action(canvas, Rect2(197, 365, 170, 52), compete_fill, "★  RANKINGS", 12, OFF_WHITE, Callable(self, "_open_compete"), 14)
	# Keep the stable node id used by older automation while the player-facing
	# action now opens campaign progression rankings instead of Daily.
	compete.name = "HomeDailyGamesButton"
	compete.tooltip_text = "Open the full player leaderboard • today, weekly and all-time"

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
			RefCanvas.add_shadow(canvas, Rect2(x, 465, 108, 98), 18, Color(0.02, 0.10, 0.18, 0.08), 2, Vector2(0, 1))
		var card := PanelContainer.new()
		card.name = "HomeSwitchCard_%s" % id
		var accent: Color = entry[2] as Color
		card.add_theme_stylebox_override("panel", _switch_card_style(id, accent))
		RefCanvas.set_rect(card, x, 465, 108, 98)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(card)
		var mark := GAME_ART_SCRIPT.new()
		mark.name = "HomeQuickSwitchFlatLogo_%s" % id
		mark.configure(id, true, _home_dark())
		RefCanvas.set_rect(mark, x + 7, 468, 94, 48)
		canvas.add_child(mark)
		var switch_font := 10 if id == "block_puzzle" else 11
		var switch_name := _add_text(canvas, String(entry[1]), Rect2(x + 2, 516, 104, 22), switch_font, entry[2], true)
		switch_name.name = "HomeQuickSwitchName_%s" % id
		switch_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		switch_name.clip_text = true
		RefCanvas.fit_single_line_text(switch_name, 100.0, switch_font, 9)
		var level := _home_current_level(id)
		var stars := MultiGameManager.total_stars(id)
		var switch_meta := _add_text(canvas, "L%d • ★%s" % [level, _compact_number(stars)], Rect2(x + 6, 544, 96, 18), 11, MUTED, false)
		switch_meta.name = "HomeQuickSwitchMeta_%s" % id
		switch_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var tap := Button.new()
		tap.name = "HomeDirect_%s" % id
		tap.set_meta("unjam_figma_exact_geometry", true)
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.modulate.a = 0.001
		tap.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		RefCanvas.set_rect(tap, x - 4, 459, 116, 110)
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
			RefCanvas.set_rect(plate, float(item[3]) + 8.0, 761, 56, 58)
			canvas.add_child(plate)
		var glyph := _add_text(canvas, item[1], Rect2(float(item[2]) - 1.0, 761, 58, 24), 18, icon_color, true)
		glyph.name = "HomeNavGlyph_%s" % String(item[0])
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var display_name := String(item[0])
		var label_width := 66.0 if String(item[0]) in ["COLLECT", "SETTINGS"] else 58.0
		var label_x := float(item[3]) + (72.0 - label_width) * 0.5
		var label := _add_text(canvas, display_name, Rect2(label_x, 799, label_width, 18), 13, nav_color, selected)
		label.name = "HomeNavLabel_%s" % String(item[0])
		label.custom_minimum_size = Vector2.ZERO
		RefCanvas.fit_single_line_text(label, label_width - 2.0, 13, 10)
		label.position = Vector2(label_x, 799)
		label.size = Vector2(label_width, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		var hit := Button.new()
		hit.name = item[5]
		hit.flat = true
		hit.accessibility_name = String(item[0]).capitalize()
		hit.tooltip_text = "Open %s" % String(item[0]).capitalize()
		var cb: Callable = item[4]
		hit.focus_mode = Control.FOCUS_NONE if selected else Control.FOCUS_ALL
		hit.add_theme_stylebox_override("focus", RefCanvas.solid_box(Color.TRANSPARENT, 12, Color(GOLD, 0.94), 2))
		hit.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		RefCanvas.set_rect(hit, float(item[3]), 753, 72, 78)
		if cb.is_valid():
			hit.pressed.connect(cb)
		else:
			hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hit)
		# Apply focus after adding the hit target: theme/parent initialization may
		# otherwise leave an otherwise visible launcher action unfocusable.
		if not selected:
			hit.focus_mode = Control.FOCUS_ALL
			# The scene lifecycle can clear focus on freshly attached transparent
			# touch targets. Restore it after deferred layout and visibility setup.
			hit.set_deferred("focus_mode", Control.FOCUS_ALL)
		hit.set_meta("unjam_authored_focus_mode", int(hit.focus_mode))

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

func _open_game_levels(game_id: String) -> void:
	# Jump directly to the campaign level browser for the tapped puzzle.
	# open_game_campaign applies the correct Rescue/Water/Block routing,
	# restores Daily-suspended progress, and does not start a live game.
	if game_id not in ["rescue_rush","water_sort","block_puzzle"]:
		return
	var main := get_parent()
	if main != null and main.has_method("open_game_campaign"):
		FeedbackManager.tap()
		main.call("open_game_campaign",game_id)

func _open_game_selector() -> void:
	var main := get_parent()
	if main != null and main.has_method("_open_games_surface"):
		# _open_games_surface owns navigation feedback so every caller produces
		# exactly one tap instead of stacking duplicate sounds on the same action.
		main.call("_open_games_surface")

func _open_compete() -> void:
	var main := get_parent()
	if main == null:
		return
	FeedbackManager.tap()
	main.set("_ranking_game", selected_game)
	if main.has_method("show_leaderboard_popup"):
		main.call("show_leaderboard_popup", "week")
	elif main.has_method("build_compete_leaderboard"):
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
	# Rebuild the selected hero and weekly-rank preview together, preventing a
	# stale rank from a different game after a Games-screen selection.
	if built:
		build_home_launcher()

func _select_home_game(game_id: String) -> void:
	if game_id == selected_game:
		return
	selected_game = game_id
	var main := get_parent()
	if main != null:
		main.set("selected_game_id", game_id)
	FeedbackManager.tap()
	_refresh_home_selection()
