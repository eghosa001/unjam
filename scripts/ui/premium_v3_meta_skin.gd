extends RefCounted
## UNJAM V3 -- static, game-safe visual materials for secondary screens.
## No input, navigation, economy, preference or ranking state is changed.
const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

static func _accent(surface: String) -> Color:
	match surface:
		"settings": return Color("#63DCC4")
		"daily": return Color("#66D5B3")
		"compete": return Color("#C5A2FF")
		"selector": return Color("#6DDCCB")
		_: return Color("#67CAE9")

static func _material(fill: Color, edge: Color, radius: int = 18, depth: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.01, 0.05, 0.12, 0.22)
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
	return ink

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
	for node in canvas.find_children("*", "PanelContainer", true, false):
		var panel := node as PanelContainer
		if panel == null or panel == bg:
			continue
		var name_value := String(panel.name)
		var is_card := name_value.begins_with("SettingsCard/") or name_value in [
			"HelpPrivacy", "DailyProgress", "DailyCheckIn", "CompetitionPlayerProgress",
			"CompetitionPrizeTimingCard"] or name_value.begins_with("DailyCard/") \
			or name_value.begins_with("Leaderboard/")
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
		var fill := Color("#27485A") if dark else Color("#E5F0EF")
		if id.begins_with("SettingToggle/"):
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
	# Preserve all existing labels, localized text, real counters, save values,
	# enabled/disabled states, callback connections, and nav geometry.


# Approved UNJAM V3 Home uses horizontal game-world panels and two peer
# Rankings/Daily actions. This method deliberately preserves every existing
# named Button, callback, saved progress and accessible label.
static func _home_rect(canvas: Control, node_name: String, area: Rect2) -> Control:
	var node := canvas.find_child(node_name, true, false) as Control
	if node != null:
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
		Rect2(34,140,203,57),22,fg)
	_home_text(canvas,"HomeWelcomeSubtitle","Make every move count.",
		Rect2(35,195,194,22),13,muted)
	var profile := _home_rect(canvas,"HomeProfileButton",Rect2(197,22,46,44)) as Button
	if profile != null:
		profile.text = "♙"
		_button(profile, Color("#214054") if dark else Color("#F8FEFC"), dark, 14)
	var profile_pill := canvas.find_child("HomeProfilePill",true,false) as CanvasItem
	if profile_pill != null: profile_pill.visible = false
	var coins := _home_rect(canvas,"HomeCoinShopButton",Rect2(252,22,118,44)) as Button
	if coins != null:
		_button(coins, Color("#274655") if dark else Color("#FCFFFE"), dark, 14)
	for gem_name in ["HomeCurrencyGem3D","HomeCurrencyGem3DSide","HomeCurrencyGem3DHighlight"]:
		var gem := canvas.find_child(gem_name,true,false) as Node2D
		if gem != null: gem.position += Vector2(8.0,-42.0)
	var choose := _home_rect(canvas,"HomePrimaryAction",Rect2(32,218,198,44)) as Button
	if choose != null:
		_button(choose,accent,dark,14)
		choose.add_theme_font_size_override("font_size",15)
	var resume := _home_rect(canvas,"HomeResumeAction",Rect2(238,218,118,44)) as Button
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
