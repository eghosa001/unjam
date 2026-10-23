extends RefCounted
## UNJAM V3 -- static, game-safe visual materials for secondary screens.
## No input, navigation, economy, preference or ranking state is changed.
const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const NAV_HOME = preload("res://assets/art/brand/ui_home.svg")
const NAV_GAMES = preload("res://assets/art/brand/ui_games.svg")
const NAV_DAILY = preload("res://assets/art/brand/ui_daily.svg")
const NAV_COLLECTION = preload("res://assets/art/brand/ui_collection.svg")
const NAV_SETTINGS = preload("res://assets/art/brand/ui_settings.svg")
const NAV_PROFILE = preload("res://assets/art/brand/ui_profile.svg")

static func _nav_texture(key: String) -> Texture2D:
	match key:
		"HOME": return NAV_HOME
		"GAMES": return NAV_GAMES
		"DAILY": return NAV_DAILY
		"COLLECT": return NAV_COLLECTION
		"SETTINGS": return NAV_SETTINGS
		_: return null

# One vector/navigation system across every UI surface. Icons are purely
# decorative and mouse-ignore; all original focusable buttons own navigation.
static func _nav_icons(canvas: Control, prefix: String, active: String, dark: bool) -> void:
	var keys := ["HOME","GAMES","DAILY","COLLECT","SETTINGS"]
	for i in range(keys.size()):
		var key := String(keys[i])
		var glyph := canvas.find_child("%s_%s" % [prefix,key],true,false) as Label
		if glyph == null:
			continue
		glyph.visible = false # legacy label retained for navigation contracts
		var icon := TextureRect.new()
		icon.name = "V3NavIcon_%s" % key
		icon.texture = _nav_texture(key)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var selected := active == key
		icon.modulate = (Color("#89F1D4") if dark else Color("#16786F")) if selected \
			else (Color("#B8D0DC") if dark else Color("#607E8B"))
		RefCanvas.set_rect(icon, 38.0 + float(i)*72.0, 770, 21, 21)
		canvas.add_child(icon)


static func _accent(surface: String) -> Color:
	match surface:
		"settings": return Color("#63DCC4")
		"daily": return Color("#66D5B3")
		"compete": return Color("#C5A2FF")
		"selector": return Color("#6DDCCB")
		"goals": return Color("#F1C37D")
		"profile": return Color("#70D0EE")
		"friends": return Color("#B69BF6")
		"collection": return Color("#6DDEAC")
		"levels": return Color("#72C7EC")
		_: return Color("#67CAE9")

static func _material(fill: Color, edge: Color, radius: int = 18, depth: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.01, 0.05, 0.12, 0.15)
	s.shadow_size = depth
	s.shadow_offset = Vector2(0, float(depth))
	s.anti_aliasing = true
	return s

static func _button(button: Button, fill: Color, dark: bool, radius: int = 14) -> void:
	var edge := fill.lightened(0.23) if dark else fill.darkened(0.15)
	var ink := RefCanvas.accessible_text_color(
		Color("#F6FFFF") if dark else Color("#123B4A"), fill, 4.5)
	button.flat = false
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.add_theme_stylebox_override("normal", _material(fill, edge, radius, 3))
	button.add_theme_stylebox_override("hover", _material(fill.lightened(0.08), edge, radius, 3))
	button.add_theme_stylebox_override("pressed", _material(fill.darkened(0.13), edge, radius, 1))
	button.add_theme_stylebox_override("focus", _material(fill, Color("#FFF2B2"), radius, 3))
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	if button.disabled:
		var disabled_fill := Color("#244E43") if dark else Color("#D9ECE4")
		var disabled_ink := Color("#E5FFF2") if dark else Color("#1A5441")
		button.add_theme_stylebox_override("disabled", _material(disabled_fill,
			Color("#6AA18C") if dark else Color("#A5CDB9"), radius, 1))
		button.add_theme_color_override("font_disabled_color", disabled_ink)
	# Keep authored accessibility and control geometry. Do not resize buttons.
	button.set_meta("unjam_preserve_surface_style", true)
	button.set_meta("unjam_preserve_control_geometry", true)

static func _card_surface(name_value: String, surface: String, dark: bool) -> Color:
	var ink := Color("#172B40") if dark else Color("#FFFFFF")
	match surface:
		"settings":
			if name_value.contains("Sound"): return Color("#16394A") if dark else Color("#F0F9F8")
			if name_value.contains("Comfort"): return Color("#25314A") if dark else Color("#F1F4FB")
			if name_value.contains("Appearance"): return Color("#1D3B3C") if dark else Color("#E9F7EF")
			return Color("#1A3043") if dark else Color("#F8FBFC")
		"daily":
			if name_value.contains("rescue_rush"): return Color("#103A38") if dark else Color("#E5F7EF")
			if name_value.contains("water_sort"): return Color("#133B52") if dark else Color("#E5F5FC")
			if name_value.contains("block_puzzle"): return Color("#312A4B") if dark else Color("#F1EAFE")
			if name_value.contains("CheckIn"): return Color("#2C3548") if dark else Color("#FFF4DF")
			return Color("#173B3F") if dark else Color("#F7FCF9")
		"compete":
			if name_value.contains("Leaderboard"): return Color("#252C46") if dark else Color("#F5F0FD")
			return Color("#1C3445") if dark else Color("#F8F7FD")
		"goals":
			if name_value.begins_with("Goal_") or name_value.begins_with("Goal/"):
				return Color("#203447") if dark else Color("#F3F8F7")
			if name_value.contains("Login"): return Color("#3B3641") if dark else Color("#FFF3E1")
			if name_value.contains("Season"): return Color("#302B4B") if dark else Color("#F3EEFD")
			return Color("#243748") if dark else Color("#FAFCF9")
		"profile":
			if name_value.contains("Identity"): return Color("#143D4A") if dark else Color("#EDF9FC")
			if name_value.contains("Stats"): return Color("#1D3348") if dark else Color("#F3F7FC")
			return Color("#24364D") if dark else Color("#F5F8FD")
		"friends":
			if name_value.contains("Code"): return Color("#1C3A4F") if dark else Color("#EEF8FC")
			if name_value.contains("Add"): return Color("#2A304D") if dark else Color("#F4F0FD")
			return Color("#252C49") if dark else Color("#F4F2FA")
		"collection":
			if name_value.begins_with("ProgressCard"):
				if name_value.contains("water_sort"): return Color("#193D54") if dark else Color("#E8F5FD")
				if name_value.contains("block_puzzle"): return Color("#312944") if dark else Color("#F1EBFB")
				return Color("#183C37") if dark else Color("#E7F8ED")
			if name_value.contains("Journey"): return Color("#173F39") if dark else Color("#E7F8EF")
			if name_value.contains("Garden"): return Color("#163B37") if dark else Color("#EAF7EF")
			if name_value.contains("Upgrade"): return Color("#242F46") if dark else Color("#F0F6F5")
			return Color("#1F3843") if dark else Color("#F4FBF7")
		"levels":
			if name_value.contains("Journey"): return Color("#1C3B4C") if dark else Color("#F1F9FC")
			return Color("#223346") if dark else Color("#FAFBFD")
	return ink

# Shared by native builders and the final V3 styling pass. Skip expensive
# temporary lacquer textures for cards whose style is overwritten this frame.
static func owns_card(name_value: String) -> bool:
	return name_value.begins_with("SettingsCard") or name_value in [
		"HelpPrivacy", "DailyProgress", "DailyCheckIn", "CompetitionPlayerProgress",
		"CompetitionPrizeTimingCard"] or name_value.begins_with("DailyCard") \
		or name_value.begins_with("Leaderboard") \
		or name_value.begins_with("Goal") or name_value.begins_with("Profile") \
		or name_value.begins_with("Friends") or name_value in [
			"Journey", "Achievements", "Garden", "CollectionTip", "JourneyHero"] \
		or name_value.begins_with("ProgressCard") \
		or name_value.begins_with("CollectionScroll")

static func apply(canvas: Control, surface: String, dark: bool) -> void:
	if canvas == null or not is_instance_valid(canvas):
		return
	var accent := _accent(surface)
	var bg := canvas.get_node_or_null("FigmaSurfaceBackground") as PanelContainer
	if bg != null:
		bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#0E273B") if dark else Color("#F8FCF9"),
			Color("#0B1B2E") if dark else Color("#EBF5F3"),
			Color("#091522") if dark else Color("#E3EFEF"),
			28, Color(accent, 0.10), 1, 0.10))
	for node in canvas.find_children("*", "CanvasItem", true, false):
		if String(node.name).begins_with("MetaArt"):
			(node as CanvasItem).modulate.a = 0.36 if dark else 0.23
	for node in canvas.find_children("*", "PanelContainer", true, false):
		var panel := node as PanelContainer
		if panel == null or panel == bg:
			continue
		var name_value := String(panel.name)
		var is_card := owns_card(name_value)
		if not is_card:
			continue
		var fill := _card_surface(name_value, surface, dark)
		var edge := Color(accent.r, accent.g, accent.b, 0.32 if dark else 0.21)
		if name_value.contains("water_sort"): edge = Color("#64CFFA", 0.55)
		if name_value.contains("block_puzzle"): edge = Color("#C2A0F8", 0.55)
		if name_value.contains("rescue_rush"): edge = Color("#58D9A8", 0.55)
		panel.add_theme_stylebox_override("panel", _material(fill, edge, 19, 4))
	for node in canvas.find_children("*", "Button", true, false):
		var b := node as Button
		if b == null or b.flat and b.text.is_empty():
			continue
		var id := String(b.name)
		# Numbered level tiles have their own earned/locked/current semantics
		# and must not become identically colored generic buttons.
		if surface == "levels" and (id.begins_with("Level_") or id.begins_with("Level/")):
			continue
		var fill := Color("#27485A") if dark else Color("#E5F0EF")
		if id.begins_with("SettingToggle"):
			fill = Color("#35B58F") if b.text == "ON" else (Color("#34475A") if dark else Color("#D6E2E5"))
		elif id == "SettingsThemeToggle": fill = Color("#3BC3A9") if dark else Color("#168D80")
		elif id.begins_with("Settings"): fill = Color("#2B5262") if dark else Color("#DDECEB")
		elif id.begins_with("DailyPlay_"):
			if id.ends_with("rescue_rush"): fill = Color("#32BC8F") if dark else Color("#159B73")
			if id.ends_with("water_sort"): fill = Color("#2495C8") if dark else Color("#0E7EA7")
			if id.ends_with("block_puzzle"): fill = Color("#9970D3") if dark else Color("#7854B6")
		elif id == "DailyLeaderboardOpen": fill = Color("#7059B5")
		elif id == "DailyCheckInAction": fill = Color("#D99646") if dark else Color("#AD6E23")
		elif id.begins_with("RankingGame_"):
			fill = accent if b.mouse_filter == Control.MOUSE_FILTER_IGNORE else (Color("#354054") if dark else Color("#E6E0F0"))
		elif id.begins_with("Competition"):
			fill = Color("#755AAE") if dark else Color("#6F51A4")
		elif id.begins_with("Goals"):
			fill = Color("#A16F33") if dark else Color("#B47732")
			if id.contains("Season"): fill = Color("#795CC0") if dark else Color("#7152AC")
		elif id.begins_with("Profile"):
			fill = Color("#1A83A3") if dark else Color("#177A9E")
			if id.contains("Friends"): fill = Color("#7156AC")
		elif id.begins_with("Friends"):
			fill = Color("#7255B5") if dark else Color("#7754B8")
			if id.contains("Copy"): fill = Color("#1C89A7") if dark else Color("#127E9A")
		elif id.begins_with("Collection"):
			fill = Color("#278D70") if dark else Color("#15896E")
			if id.contains("Upgrade") or id.contains("Achievements"):
				fill = Color("#6F54AA") if dark else Color("#7153AD")
		elif id.begins_with("Level"):
			fill = Color("#2D5567") if dark else Color("#DCEEF0")
			if id in ["LevelPlayCurrent","LevelCurrent"]: fill = accent.darkened(0.18)
		elif id == "FigmaBack": fill = Color("#27485A") if dark else Color("#DCEAE8")
		elif id == "FigmaHeaderPill": fill = accent.darkened(0.40) if dark else accent.darkened(0.22)
		_button(b, fill, dark, 13)
	for node in canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null: continue
		var n := String(label.name)
		if n == "FigmaHeaderTitle":
			label.add_theme_color_override("font_color", Color("#F7FBFF") if dark else Color("#193849"))
		elif n == "FigmaHeaderSubtitle":
			label.add_theme_color_override("font_color", Color("#BFD6E0") if dark else Color("#476B77"))
		elif n.begins_with("DailyTitle_"):
			label.add_theme_color_override("font_color", Color("#F7FCFF") if dark else Color("#1C3B4C"))
		elif label.text in [
			"SOUND & FEEDBACK","PLAY COMFORT","APPEARANCE",
			"HELP & PRIVACY","ACCOUNT & PURCHASES",
			"DAILY CHECK-IN","WEEKLY PRIZES","THIS WEEK","ALL-TIME",
			"DAILY MISSIONS","WEEKLY MISSIONS","SEASON JOURNEY","ACHIEVEMENTS",
			"PROGRESS","GAMES","RESCUE GARDEN","GARDEN UPGRADES",
			"YOUR FRIEND CODE","ADD A FRIEND"]:
			label.add_theme_color_override("font_color",
				Color("#84E9D4") if dark and surface == "settings" else
				(Color("#D2B9FF") if dark and surface == "compete" else
				(Color("#87E6CC") if dark else Color("#1D736C"))))
	# Give editable player-name/friend-code fields the same tactile material
	# and focus semantics as the actions, without touching their text or state.
	for node in canvas.find_children("*", "LineEdit", true, false):
		var field := node as LineEdit
		var fill := Color("#1A354A") if dark else Color("#FFFFFF")
		field.add_theme_stylebox_override("normal", _material(fill,
			Color(accent.r,accent.g,accent.b,0.40),12,1))
		field.add_theme_stylebox_override("focus", _material(fill,
			Color("#F3D998") if dark else accent.darkened(0.12),12,1))
		field.add_theme_color_override("font_color",
			Color("#F4FBFF") if dark else Color("#1D4052"))
		field.add_theme_color_override("font_placeholder_color",
			Color("#AEC4D1") if dark else Color("#58727D"))
		field.add_theme_color_override("caret_color",accent)
	var nav_bar := canvas.find_child("StdNav_Bar",true,false) as PanelContainer
	if nav_bar != null:
		nav_bar.add_theme_stylebox_override("panel",_material(
			Color("#142D41") if dark else Color("#FFFFFF"),
			Color("#46687D") if dark else Color("#C9DED8"),18,2))
	for child in canvas.find_children("StdNavActivePlate*", "PanelContainer", true, false):
		var plate := child as PanelContainer
		if plate != null:
			plate.add_theme_stylebox_override("panel",_material(
				Color("#235B60") if dark else Color("#CEF0E5"),
				Color("#64D8B8") if dark else Color("#8BC9B8"),14,0))
	for child in canvas.find_children("StdNavActiveShine*", "PanelContainer", true, false):
		(child as PanelContainer).modulate.a = 0.24
	for child in canvas.find_children("StdNavGlyph*", "Label", true, false):
		var glyph := child as Label
		var selected := surface.to_upper() == String(glyph.name).replace("StdNavGlyph_","")
		glyph.add_theme_color_override("font_color",
			Color("#8EECD1") if dark and selected else (
				Color("#177F74") if selected else (
					Color("#ABC7D7") if dark else Color("#677F8D"))))
	if surface == "daily":
		apply_daily_v3(canvas,dark)
	_nav_icons(canvas,"StdNavGlyph",surface.to_upper(),dark)
	# Preserve all existing labels, localized text, real counters, save values,
	# enabled/disabled states, callback connections, and nav geometry.


# Approved UNJAM V3 Home uses horizontal game-world panels and two peer
# Rankings/Daily actions. This method deliberately preserves every existing
# named Button, callback, saved progress and accessible label.
static func _home_rect(canvas: Control, node_name: String, area: Rect2) -> Control:
	var node := canvas.find_child(node_name, true, false) as Control
	if node != null:
		# set_rect writes size before minimum; clear the old minimum first so
		# shrinking V2 panels actually takes effect (Godot clamps otherwise).
		node.custom_minimum_size = Vector2.ZERO
		RefCanvas.set_rect(node, area.position.x, area.position.y,
			area.size.x, area.size.y)
	return node

static func _home_text(canvas: Control, node_name: String, caption: String,
		area: Rect2, font_size: int, color: Color) -> void:
	var label := _home_rect(canvas, node_name, area) as Label
	if label == null:
		return
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2.ZERO
	label.size = area.size
	label.clip_text = true

static func apply_home_v3(canvas: Control, dark: bool) -> void:
	if canvas == null:
		return
	var fg := Color("#F5FAFF") if dark else Color("#19394A")
	var muted := Color("#BDD4DF") if dark else Color("#4E6F7D")
	var accent := Color("#58DEB5") if dark else Color("#20B7A1")
	var backdrop := canvas.find_child("HomeWorldAtmosphere", true, false) as CanvasItem
	if backdrop != null: backdrop.modulate.a = 0.32 if dark else 0.22
	var hero := _home_rect(canvas,"FigmaHomeHero",Rect2(17,95,356,172)) as PanelContainer
	if hero != null:
		hero.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#23536B") if dark else Color("#FEFEFC"),
			Color("#183C54") if dark else Color("#F0F9F6"),
			Color("#112940") if dark else Color("#DFEFEC"),
			24, Color(accent, 0.36), 1, 0.16))
	var sheen := _home_rect(canvas,"HomeHeroIllustratedGlow",Rect2(17,95,356,172)) as CanvasItem
	if sheen != null: sheen.modulate.a = 0.35
	_home_rect(canvas,"HomeBrandEmblem",Rect2(240,113,120,131))
	_home_text(canvas,"HomeWelcomeTitle","THREE GAMES.\nONE UNJAM.",
		Rect2(34,129,203,54),19,fg)
	_home_text(canvas,"HomeWelcomeSubtitle","Make every move count.",
		Rect2(35,191,194,20),13,muted)
	var profile := _home_rect(canvas,"HomeProfileButton",Rect2(197,22,46,44)) as Button
	if profile != null:
		profile.text = ""
		_button(profile, Color("#214054") if dark else Color("#F8FEFC"), dark, 14)
	var avatar := TextureRect.new()
	avatar.name = "HomeProfileVectorIcon"
	avatar.texture = NAV_PROFILE
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.modulate = Color("#9FEBD9") if dark else Color("#1C7279")
	RefCanvas.set_rect(avatar,210,32,21,21)
	canvas.add_child(avatar)
	var profile_pill := canvas.find_child("HomeProfilePill",true,false) as CanvasItem
	if profile_pill != null: profile_pill.visible = false
	var coins := _home_rect(canvas,"HomeCoinShopButton",Rect2(252,22,118,44)) as Button
	if coins != null:
		_button(coins, Color("#274655") if dark else Color("#FCFFFE"), dark, 14)
	for gem_name in ["HomeCurrencyGem3D","HomeCurrencyGem3DSide","HomeCurrencyGem3DHighlight"]:
		var gem := canvas.find_child(gem_name,true,false) as Node2D
		if gem != null: gem.position += Vector2(8.0,-42.0)
	var choose := _home_rect(canvas,"HomePrimaryAction",Rect2(32,218,198,48)) as Button
	if choose != null:
		_button(choose,accent,dark,14)
		choose.add_theme_font_size_override("font_size",15)
	var resume := _home_rect(canvas,"HomeResumeAction",Rect2(238,218,118,48)) as Button
	if resume != null:
		_button(resume,Color("#315D6D") if dark else Color("#D6EAE7"),dark,14)
	_home_text(canvas,"HomeShowcaseTitle","CHOOSE YOUR WORLD",
		Rect2(21,284,254,27),17,fg)
	_home_text(canvas,"HomeShowcaseEyebrow","ALL LEVELS  ›",
		Rect2(275,287,94,24),12,muted)
	_home_rect(canvas,"HomeShowcaseBrowseLevels",Rect2(267,278,103,44))
	var game_specs := [
		["rescue_rush",326.0,Color("#53DDA9"),"Free the pieces"],
		["water_sort",432.0,Color("#66C9F8"),"Sort the colours"],
		["block_puzzle",538.0,Color("#C39EF9"),"Clear the rows"]
	]
	for spec in game_specs:
		var id := String(spec[0])
		var y := float(spec[1])
		var col: Color = spec[2]
		var panel := _home_rect(canvas,"HomeShowcaseCard_%s" % id,
			Rect2(17,y,356,98)) as PanelContainer
		if panel != null:
			var card_fill := Color("#133A37") if dark else Color("#E2F4EC")
			if id == "water_sort": card_fill = Color("#173854") if dark else Color("#E2F2FD")
			if id == "block_puzzle": card_fill = Color("#302849") if dark else Color("#F0E9FD")
			panel.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(
				card_fill.lightened(0.08),card_fill,card_fill.darkened(0.06),
				19,Color(col,0.58),1,0.14))
		_home_rect(canvas,"HomeShowcaseArt_%s" % id,Rect2(28,y+10,81,78))
		_home_text(canvas,"HomeShowcaseName_%s" % id,
			"RESCUE RUSH" if id == "rescue_rush" else ("WATER SORT" if id == "water_sort" else "BLOCK PUZZLE"),
			Rect2(123,y+15,231,24),17,fg)
		_home_text(canvas,"HomeShowcaseTagline_%s" % id,String(spec[3]),
			Rect2(124,y+42,223,19),13,muted)
		var level := _home_rect(canvas,"HomeShowcaseLevel_%s" % id,
			Rect2(267,y+69,88,22)) as Label
		if level != null:
			level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			level.add_theme_font_size_override("font_size",12)
			level.add_theme_color_override("font_color",col if dark else col.darkened(0.43))
			level.custom_minimum_size = Vector2.ZERO
			level.size = Vector2(88,22)
		_home_rect(canvas,"HomeShowcaseOpenLevels_%s" % id,
			Rect2(17,y,356,98))
	# Rankings and Daily are separate large accessible actions alongside each
	# other; unlike a static screen picture, the values and buttons remain live.
	var rank := _home_rect(canvas,"HomeRankSummaryCard",Rect2(17,651,173,99)) as PanelContainer
	if rank != null:
		rank.add_theme_stylebox_override("panel",_material(
			Color("#202F49") if dark else Color("#F0ECF9"),
			Color("#6E6790") if dark else Color("#D5CBE8"),18,3))
	_home_text(canvas,"HomeRankTitle","RANKINGS",Rect2(31,662,128,23),14,fg)
	_home_text(canvas,"HomeRankDailyLabel","TODAY",Rect2(30,687,70,16),11,muted)
	_home_text(canvas,"HomeRankWeeklyLabel","WEEKLY",Rect2(102,687,70,16),11,muted)
	for key in ["HomeRankDailyValue","HomeRankValue"]:
		var value := _home_rect(canvas,key,
			Rect2(30 if key == "HomeRankDailyValue" else 102,708,65,24)) as Label
		if value != null:
			value.add_theme_font_size_override("font_size",17)
			value.add_theme_color_override("font_color",
				Color("#F5D69D") if dark else Color("#64528D"))
	for hint in ["HomeRankDailyHint","HomeRankWeeklyHint"]:
		var label := canvas.find_child(hint,true,false) as CanvasItem
		if label != null: label.visible = false
	var rank_button := _home_rect(canvas,"HomeDailyGamesButton",
		Rect2(17,651,173,99)) as Button
	if rank_button != null:
		rank_button.text = ""
		rank_button.flat = true
		rank_button.add_theme_color_override("font_color",Color.TRANSPARENT)
		rank_button.add_theme_color_override("font_hover_color",Color.TRANSPARENT)
		rank_button.add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
		rank_button.add_theme_stylebox_override("normal",RefCanvas.solid_box(Color.TRANSPARENT,18))
		rank_button.add_theme_stylebox_override("hover",RefCanvas.solid_box(Color("#C5A2FF",0.08),18))
		rank_button.add_theme_stylebox_override("pressed",RefCanvas.solid_box(Color("#C5A2FF",0.16),18))
		rank_button.add_theme_stylebox_override("focus",RefCanvas.solid_box(Color.TRANSPARENT,18,Color("#DBC9FF"),2))
		rank_button.set_meta("unjam_preserve_surface_style",true)
		rank_button.set_meta("unjam_preserve_control_geometry",true)
	var daily := _home_rect(canvas,"HomeDailyFeatureCard",Rect2(200,651,173,99)) as PanelContainer
	if daily != null:
		daily.add_theme_stylebox_override("panel",_material(
			Color("#163D35") if dark else Color("#E2F5EA"),
			Color("#5EA38C") if dark else Color("#B2DEC5"),18,3))
	_home_text(canvas,"HomeDailyFeatureTitle","DAILY PUZZLE",
		Rect2(214,662,149,24),14,fg)
	var daily_sub := canvas.find_child("HomeDailyFeatureSubtitle",true,false) as CanvasItem
	if daily_sub != null: daily_sub.visible = false
	var daily_button := _home_rect(canvas,"HomeDailyChallengeButton",
		Rect2(211,698,151,44)) as Button
	if daily_button != null:
		daily_button.text = "PLAY TODAY  ›"
		_button(daily_button,Color("#4BD1AA") if dark else Color("#218E70"),dark,13)
		daily_button.add_theme_font_size_override("font_size",12)
	# Existing five-tab bottom navigation remains intact, including Settings
	# and Collection; V3's four-tab visual concept must never remove a route.
	var nav := canvas.find_child("HomeBottomNav3D",true,false) as PanelContainer
	if nav != null:
		nav.add_theme_stylebox_override("panel",_material(
			Color("#142C40") if dark else Color("#FFFFFF"),
			Color("#496A7F") if dark else Color("#CCDCD9"),17,2))
	var nav_plate := canvas.find_child("HomeNavActivePlate",true,false) as PanelContainer
	if nav_plate != null:
		nav_plate.add_theme_stylebox_override("panel",_material(
			Color("#23565F") if dark else Color("#D4F0E7"),
			Color("#57C9AF") if dark else Color("#AEDACC"),13,0))
	_nav_icons(canvas,"HomeNavGlyph","HOME",dark)


static func apply_selector_v3(canvas: Control, dark: bool) -> void:
	if canvas == null:
		return
	var bg := canvas.find_child("SelectorBackground",true,false) as PanelContainer
	if bg != null:
		bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
			Color("#12314A") if dark else Color("#F6FBF8"),
			Color("#0B2137") if dark else Color("#ECF7F4"),
			Color("#08172B") if dark else Color("#E4F1EF"),
			22,Color("#72DCC4",0.16),1,0.12))
	_nav_icons(canvas,"SelectorNavGlyph","GAMES",dark)
	var selector_nav := canvas.find_child("SelectorBottomNav",true,false) as PanelContainer
	if selector_nav != null:
		selector_nav.add_theme_stylebox_override("panel",_material(
			Color("#142C40") if dark else Color("#FFFFFF"),
			Color("#486D81") if dark else Color("#CBDDD9"),17,2))
	for child in canvas.find_children("SelectorNavActivePlate*", "PanelContainer", true, false):
		var plate := child as PanelContainer
		plate.add_theme_stylebox_override("panel",_material(
			Color("#235C61") if dark else Color("#D1F0E6"),
			Color("#5AD8B7") if dark else Color("#9ACFBF"),14,0))
	for name in ["SelectorBackButton","SelectorSettingsButton"]:
		var action := canvas.find_child(name,true,false) as Button
		if action != null:
			_button(action,Color("#24465A") if dark else Color("#E6F3EF"),dark,13)
	_home_text(canvas,"SelectorTitle3D","CHOOSE A WORLD",Rect2(78,26,220,35),
		22,Color("#F7FCFF") if dark else Color("#173C50"))
	_home_text(canvas,"SelectorActionGuide",
		"CARD: LEVELS  •  PLAY / RESUME: START",
		Rect2(26,95,339,24),13,Color("#B8D7DF") if dark else Color("#57737B"))
	var sections := [
		["rescue_rush",148.0,Color("#5CE0AF")],
		["water_sort",340.0,Color("#66CEEF")],
		["block_puzzle",532.0,Color("#C5A2F9")]
	]
	for spec in sections:
		var id := String(spec[0])
		var y := float(spec[1])
		var col: Color = spec[2]
		var shadow := _home_rect(canvas,"SelectorCardShadow_%s" % id,
			Rect2(19,y,352,176)) as PanelContainer
		if shadow != null:
			shadow.add_theme_stylebox_override("panel",
				_material(Color("#030F20",0.40),Color.TRANSPARENT,22,2))
		var card := _home_rect(canvas,"GameCard3D_%s" % id,
			Rect2(19,y,352,176)) as PanelContainer
		var fill := Color("#123C37") if dark else Color("#E5F6EF")
		if id == "water_sort": fill = Color("#163854") if dark else Color("#E5F4FD")
		if id == "block_puzzle": fill = Color("#302547") if dark else Color("#F1EAFD")
		if card != null:
			card.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(
				fill.lightened(0.07),fill,fill.darkened(0.05),22,
				Color(col,0.58),1,0.12))
		_home_rect(canvas,"SelectorAccentRail_%s" % id,Rect2(22,y+16,4,144))
		_home_rect(canvas,"SelectorGamePreviewFrame_%s" % id,
			Rect2(31,y+18,128,132))
		_home_rect(canvas,"SelectorAuthoredGameArt_%s" % id,
			Rect2(36,y+23,118,121))
		var title := canvas.find_child("SelectorGameTitle_%s" % id,true,false) as Label
		if title != null:
			_home_rect(canvas,title.name,Rect2(171,y+26,186,28))
			title.add_theme_color_override("font_color",Color("#F9FCFF") if dark else Color("#193C50"))
			title.add_theme_font_size_override("font_size",22)
		var clip := _home_rect(canvas,"SelectorGameSubtitleClip_%s" % id,
			Rect2(171,y+61,177,44))
		if clip != null:
			var sub := clip.get_node_or_null("SelectorGameSubtitle_%s" % id) as Label
			if sub != null:
				RefCanvas.set_rect(sub,0,0,174,43)
				sub.add_theme_color_override("font_color",
					Color("#CBDCE6") if dark else Color("#4D6978"))
		var level := _home_rect(canvas,"SelectorLevelLabel_%s" % id,
			Rect2(171,y+108,90,22)) as Label
		if level != null:
			level.add_theme_color_override("font_color",col if dark else col.darkened(0.46))
			level.add_theme_font_size_override("font_size",13)
		_home_rect(canvas,"SelectorBrowseCue_%s" % id,
			Rect2(171,y+139,87,19))
		_home_rect(canvas,"SelectorCardHit_%s" % id,Rect2(17,y-3,356,182))
		var play := _home_rect(canvas,"SelectorPlay_%s" % id,
			Rect2(264,y+112,91,46)) as Button
		if play != null:
			_button(play,col.darkened(0.20) if dark else col.darkened(0.16),dark,13)
			play.add_theme_font_size_override("font_size",14)


static func apply_daily_v3(canvas: Control, dark: bool) -> void:
	var specs := [
		["rescue_rush",115.0],
		["water_sort",239.0],
		["block_puzzle",363.0]
	]
	for spec in specs:
		var id := String(spec[0])
		var y := float(spec[1])
		_home_rect(canvas,"DailyGameArt_%s" % id,Rect2(31,y+12,75,76))
		var title := _home_rect(canvas,"DailyTitle_%s" % id,
			Rect2(120,y+13,174,27)) as Label
		if title != null:
			title.add_theme_font_size_override("font_size",17)
			title.add_theme_color_override("font_color",
				Color("#F6FBFF") if dark else Color("#1D3C50"))
		# Existing dynamic detail and collection reward labels have no stable
		# names. Locate only the exact legacy authored lanes for this one card.
		for child in canvas.get_children():
			if not child is Label: continue
			var label := child as Label
			if absf(label.position.x-33.0) > 1.5: continue
			if absf(label.position.y-(y+47.0)) < 1.5:
				label.custom_minimum_size = Vector2.ZERO
				RefCanvas.set_rect(label,120,y+43,130,20)
				label.add_theme_font_size_override("font_size",12)
				label.add_theme_color_override("font_color",
					Color("#BCD5E1") if dark else Color("#54707E"))
			elif absf(label.position.y-(y+70.0)) < 1.5:
				label.custom_minimum_size = Vector2.ZERO
				RefCanvas.set_rect(label,120,y+70,132,20)
				label.add_theme_font_size_override("font_size",13)
				label.add_theme_color_override("font_color",
					Color("#F5D48A") if dark else Color("#875E1B"))
		var action := _home_rect(canvas,"DailyPlay_%s" % id,
			Rect2(258,y+57,100,44)) as Button
		if action != null:
			action.add_theme_font_size_override("font_size",14)
			action.clip_text = true
	var progress := canvas.find_child("DailyProgressBar",true,false) as ProgressBar
	if progress != null:
		progress.add_theme_stylebox_override("background",
			RefCanvas.solid_box(Color("#2B5559") if dark else Color("#D2E4DB"),6))
		progress.add_theme_stylebox_override("fill",
			RefCanvas.solid_box(Color("#52D6B3") if dark else Color("#239F85"),6))
