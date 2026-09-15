extends Control

var content: Control
var selected_world := 1

const WORLD_BASE := ["081426", "0b1830", "141533", "25142b", "0d241f", "1b1230"]
const WORLD_ACCENT := ["2dd4b6", "5da9ff", "8b7cf6", "ff6b7a", "55d68b", "c074ff"]

func _ready() -> void:
	selected_world = LevelManager.highest_unlocked_world()
	build_home()

func clear_content() -> void:
	if content and is_instance_valid(content):
		content.queue_free()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)

func style_box(color: Color, radius := 28, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if width > 0:
		s.border_width_left = width
		s.border_width_right = width
		s.border_width_top = width
		s.border_width_bottom = width
		s.border_color = border
	return s

func make_button(text_value: String, size := Vector2(420, 92), accent := false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 28)
	var color := Color("243b63") if not accent else Color("21c7a8")
	b.add_theme_stylebox_override("normal", style_box(Color(color, 0.92), 24, Color(1,1,1,0.08), 1))
	b.add_theme_stylebox_override("hover", style_box(color.lightened(0.08), 24, Color(1,1,1,0.18), 2))
	b.add_theme_stylebox_override("pressed", style_box(color.darkened(0.10), 24, Color.WHITE, 2))
	b.add_theme_stylebox_override("disabled", style_box(Color("252d3e"), 24))
	b.add_theme_color_override("font_disabled_color", Color("697387"))
	return b

func world_palette(world: int) -> Array[Color]:
	var idx := posmod(world - 1, WORLD_BASE.size())
	return [Color(WORLD_BASE[idx]), Color(WORLD_ACCENT[idx])]

func add_background() -> void:
	var palette := world_palette(max(1, selected_world))
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(palette[0], palette[1], selected_world - 1)
	content.add_child(backdrop)
	PremiumVisuals.set_accent(palette[1])
	PremiumVisuals.ambient_sparkles(12)

func add_glass_card(parent: Node, minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", style_box(Color(0.035,0.06,0.11,0.88), 30, Color(1,1,1,0.10), 2))
	parent.add_child(panel)
	return panel

func build_home() -> void:
	clear_content()
	add_background()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-330, -650)
	box.custom_minimum_size = Vector2(660, 1300)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	content.add_child(box)

	var badge := Label.new()
	badge.text = "CHAIN-REACTION RESCUE PUZZLES"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color("67e8cf"))
	box.add_child(badge)

	var title := Label.new()
	title.text = "UNJAM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", Color("f3fbff"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "RESCUE RUSH"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.modulate = Color("a8b8cf")
	box.add_child(subtitle)

	var stats_panel := add_glass_card(box, Vector2(620, 132))
	var stats := Label.new()
	stats.text = "%d / %d LEVELS\n%d â˜…   â€¢   %d COINS   â€¢   %d PRESTIGE" % [min(int(SaveManager.data.highest_level) - 1, LevelManager.get_level_count()), LevelManager.get_level_count(), SaveManager.total_stars(), int(SaveManager.data.coins), int(SaveManager.data.prestige_points)]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats_panel.add_child(stats)

	var progress_strip := HBoxContainer.new()
	progress_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_strip.add_theme_constant_override("separation", 12)
	box.add_child(progress_strip)
	for text_value in ["PERFECT %d" % int(SaveManager.data.perfect_clears), "STREAK %d" % int(SaveManager.data.perfect_streak), "ACH %d" % int(SaveManager.data.achievement_points)]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(190, 58)
		chip.add_theme_stylebox_override("panel", style_box(Color(0.08,0.13,0.22,0.86), 20, Color("2dd4b6"), 1))
		var chip_label := Label.new()
		chip_label.text = text_value
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_label.add_theme_font_size_override("font_size", 16)
		chip.add_child(chip_label)
		progress_strip.add_child(chip)

	var play := make_button("PLAY CAMPAIGN", Vector2(560, 100), true)
	play.pressed.connect(func(): selected_world = LevelManager.highest_unlocked_world(); build_level_select())
	box.add_child(play)

	var daily_text := "DAILY RESCUE  â€¢  " + DailyChallenge.reward_text()
	var daily := make_button(daily_text, Vector2(560, 88))
	daily.pressed.connect(start_daily)
	box.add_child(daily)

	var secondary := HBoxContainer.new()
	secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary.add_theme_constant_override("separation", 16)
	box.add_child(secondary)
	var collection := make_button("RESCUE GARDEN", Vector2(272, 82))
	collection.pressed.connect(build_collection)
	collection.add_theme_font_size_override("font_size", 21)
	secondary.add_child(collection)
	var settings := make_button("SETTINGS", Vector2(272, 82))
	settings.pressed.connect(build_settings)
	settings.add_theme_font_size_override("font_size", 21)
	secondary.add_child(settings)

	var streak := Label.new()
	streak.text = "Daily streak: %d   â€¢   Best: %d" % [int(SaveManager.data.daily_streak), int(SaveManager.data.daily_best_streak)]
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.add_theme_font_size_override("font_size", 19)
	streak.modulate = Color("95a4bb")
	box.add_child(streak)
	PremiumVisuals.entrance(box, 0.04)

func difficulty_short(label: String) -> String:
	match label:
		"easy": return "EASY"
		"medium": return "MED"
		"hard": return "HARD"
		"milestone": return "MILE"
		"boss": return "BOSS"
		_: return label.to_upper()

func difficulty_color(label: String) -> Color:
	match label:
		"easy": return Color("57d69a")
		"medium": return Color("66a8ff")
		"hard": return Color("ff9d57")
		"milestone": return Color("ffd166")
		"boss": return Color("ff5d7a")
		_: return Color("95a4bb")

func build_level_select() -> void:
	selected_world = clamp(selected_world, 1, LevelManager.WORLD_COUNT)
	clear_content()
	add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	content.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 15)
	margin.add_child(root)

	var²È="25­••±Í”½±½È ˆØäÜÌàÜˆ¤¤($%‰ÕÑÑ½¸¹ÁÉ•ÍÍ•¹½¹¹•Ð¡ÍÑ…ÉÑ}±•Ù•°¹‰¥¹¡±•Ù•±}¹Õµ‰•È¤¤($%É¥¹…‘‘}¡¥±¡‰ÕÑÑ½¸¤()™Õ¹Œ}¡…¹•}Ý½É±¡‘•±Ñ„è¥¹Ð¤€´øÙ½¥è(%Í•±•Ñ•‘}Ý½É±€ô±…µÀ¡Í•±•Ñ•‘}Ý½É±€¬‘•±Ñ„°€Ä°1•Ù•±5…¹…•È¹]=I1}=U9P¤(%‰Õ¥±‘}±•Ù•±}Í•±•Ð ¤()™Õ¹Œ}©ÕµÁ}Ñ½}ÕÉÉ•¹Ñ}Ý½É± ¤€´øÙ½¥è(%Í•±•Ñ•‘}Ý½É±€ô1•Ù•±5…¹…•È¹¡¥¡•ÍÑ}Õ¹±½­•‘}Ý½É± ¤(%‰Õ¥±‘}±•Ù•±}Í•±•Ð ¤()™Õ¹ŒÍÑ…ÉÑ}±•Ù•°¡±•Ù•±}¹Õµ‰•Èè¥¹Ð¤€´øÙ½¥è(%¥˜½¹Ñ•¹Ðè($%½¹Ñ•¹Ð¹Ù¥Í¥‰±”€ô™…±Í”(%Ù…È…µ•}Í•¹”€ô±½… ‰É•Ìè¼½Í•¹•Ì½…µ”¹ÑÍ¸ˆ¤¹¥¹ÍÑ…¹Ñ¥…Ñ” ¤(%…µ•}Í•¹”¹±•Ù•±}¹Õµ‰•È€ô±•Ù•±}¹Õµ‰•È(%…µ•}Í•¹”¹™¥¹¥Í¡•¹½¹¹•Ð¡}½¹}…µ•}™¥¹¥Í¡•¤(%…µ•}Í•¹”¹ÅÕ¥Ñ}É•ÅÕ•ÍÑ•¹½¹¹•Ð¡}½¹}…µ•}ÅÕ¥Ð¤(%…‘‘}¡¥±¡…µ•}Í•¹”¤()™Õ¹ŒÍÑ…ÉÑ}‘…¥±ä ¤€´øÙ½¥è(%¥˜…¥±å¡…±±•¹”¹¥Í}½µÁ±•Ñ•‘}Ñ½‘…ä ¤è($%‰Õ¥±‘}¡½µ” ¤($%É•ÑÕÉ¸(%¥˜½¹Ñ•¹Ðè($%½¹Ñ•¹Ð¹Ù¥Í¥‰±”€ô™…±Í”(%Ù…È…µ•}Í•¹”€ô±½… ‰É•Ìè¼½Í•¹•Ì½…µ”¹ÑÍ¸ˆ¤¹¥¹ÍÑ…¹Ñ¥…Ñ” ¤(%…µ•}Í•¹”¹±•Ù•±}¹Õµ‰•È€ô€Ä(%…µ•}Í•¹”¹‘…¥±å}µ½‘”€ôÑÉÕ”(%…µ•}Í•¹”¹ÕÍÑ½µ}±•Ù•±}‘…Ñ„€ô…¥±å¡…±±•¹”¹‰Õ¥±‘}Ñ½‘…ä ¤(%…µ•}Í•¹”¹™¥¹¥Í¡•¹½¹¹•Ð¡}½¹}…µ•}™¥¹¥Í¡•¤(%…µ•}Í•¹”¹ÅÕ¥Ñ}É•ÅÕ•ÍÑ•¹½¹¹•Ð¡}½¹}…µ•}ÅÕ¥Ð¤(%…‘‘}¡¥±¡…µ•}Í•¹”¤()™Õ¹Œ}½¹}…µ•}™¥¹¥Í¡•¡½µÁ±•Ñ•‘}±•Ù•°è¥¹Ð¤€´øÙ½¥è(%¥˜½µÁ±•Ñ•‘}±•Ù•°€ð€Àè($%‰Õ¥±‘}¡½µ” ¤($%½¹Ñ•¹Ð¹Ù¥Í¥‰±”€ôÑÉÕ”($%É•ÑÕÉ¸(%¥˜1•Ù•±5…¹…•È¹¡…Í}±•Ù•°¡½µÁ±•Ñ•‘}±•Ù•°€¬€Ä¤è($%ÍÑ…ÉÑ}±•Ù•°¡½µÁ±•Ñ•‘}±•Ù•°€¬€Ä¤(%•±Í”è($%‰Õ¥±‘}¡½µ” ¤($%½¹Ñ•¹Ð¹Ù¥Í¥‰±”€ôÑÉÕ”()™Õ¹Œ}½¹}…µ•}ÅÕ¥Ð ¤€´øÙ½¥è(%Í•±•Ñ•‘}Ý½É±€ô1•Ù•±5…¹…•È¹¡¥¡•ÍÑ}Õ¹±½­•‘}Ý½É± ¤(%‰Õ¥±‘}±•Ù•±}Í•±•Ð ¤(%½¹Ñ•¹Ð¹Ù¥Í¥‰±”€ôÑÉÕ”()™Õ¹Œ‰Õ¥±‘}½±±•Ñ¥½¸ ¤€´øÙ½¥è(%±•…É}½¹Ñ•¹Ð ¤(%…‘‘}‰…­É½Õ¹ ¤(%Ù…Èµ…É¥¸€èô5…É¥¹½¹Ñ…¥¹•È¹¹•Ü ¤(%µ…É¥¸¹Í•Ñ}…¹¡½ÉÍ}…¹‘}½™™Í•ÑÍ}ÁÉ•Í•Ð¡½¹ÑÉ½°¹AIMQ}U11}IP¤(%µ…É¥¸¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰µ…É¥¹}±•™Ðˆ°€ØÀ¤(%µ…É¥¸¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰µ…É¥¹}É¥¡Ðˆ°€ØÀ¤(%µ…É¥¸¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰µ…É¥¹}Ñ½Àˆ°€ØÔ¤(%µ…É¥¸¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰µ…É¥¹}‰½ÑÑ½´ˆ°€ØÔ¤(%½¹Ñ•¹Ð¹…‘‘}¡¥±¡µ…É¥¸¤(%Ù…ÈÉ½½Ð€èôY	½á½¹Ñ…¥¹•È¹¹•Ü ¤(%É½½Ð¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰Í•Á…É…Ñ¥½¸ˆ°€ÈÈ¤(%µ…É¥¸¹…‘‘}¡¥±¡É½½Ð¤(%Ù…È¡•…‘•È€èô!	½á½¹Ñ…¥¹•È¹¹•Ü ¤(%Ù…È‰…¬€èôµ…­•}‰ÕÑÑ½¸ ‹Š@ˆ°Y•Ñ½ÈÈ ÄÈØ°€àØ¤¤(%‰…¬¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÌÀ¤(%‰…¬¹ÁÉ•ÍÍ•¹½¹¹•Ð¡‰Õ¥±‘}¡½µ”¤(%¡•…‘•È¹…‘‘}¡¥±¡‰…¬¤(%Ù…ÈÑ¥Ñ±”€èô1…‰•°¹¹•Ü ¤(%Ñ¥Ñ±”¹Ñ•áÐ€ô€‰IMUI8ˆ(%Ñ¥Ñ±”¹Í¥é•}™±…Í}¡½É¥é½¹Ñ…°€ô½¹ÑÉ½°¹M%i}aA9}%10(%Ñ¥Ñ±”¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%Ñ¥Ñ±”¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÌØ¤(%¡•…‘•È¹…‘‘}¡¥±¡Ñ¥Ñ±”¤(%Ù…È½¥¹Ì€èô1…‰•°¹¹•Ü ¤(%½¥¹Ì¹Ñ•áÐ€ô€ˆ•ƒŠ^ ˆ€”¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹½¥¹Ì¤(%½¥¹Ì¹ÕÍÑ½µ}µ¥¹¥µÕµ}Í¥é”€ôY•Ñ½ÈÈ ÄÌÀ°€Øà¤(%½¥¹Ì¹Ù•ÉÑ¥…±}…±¥¹µ•¹Ð€ôYIQ%1}1%959Q}9QH(%¡•…‘•È¹…‘‘}¡¥±¡½¥¹Ì¤(%É½½Ð¹…‘‘}¡¥±¡¡•…‘•È¤((%Ù…È…É‘•¸€èô…‘‘}±…ÍÍ}…É¡É½½Ð°Y•Ñ½ÈÈ À°€ÔÈÀ¤¤(%Ù…È…É‘•¹}‰½à€èôY	½á½¹Ñ…¥¹•È¹¹•Ü ¤(%…É‘•¹}‰½à¹…±¥¹µ•¹Ð€ô	½á½¹Ñ…¥¹•È¹1%959Q}9QH(%…É‘•¸¹…‘‘}¡¥±¡…É‘•¹}‰½à¤(%Ù…È¥¹¡…‰¥Ñ…¹ÑÌ€èô1…‰•°¹¹•Ü ¤(%¥¹¡…‰¥Ñ…¹ÑÌ¹Ñ•áÐ€ôÉ•ÍÕ•}…É‘•¹}Ñ•áÐ ¤(%¥¹¡…‰¥Ñ…¹ÑÌ¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%¥¹¡…‰¥Ñ…¹ÑÌ¹…ÕÑ½ÝÉ…Á}µ½‘”€ôQ•áÑM•ÉÙ•È¹UQ=]IA}]=I}M5IP(%¥¹¡…‰¥Ñ…¹ÑÌ¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€Ðà¤(%…É‘•¹}‰½à¹…‘‘}¡¥±¡¥¹¡…‰¥Ñ…¹ÑÌ¤(%Ù…È‘•½È€èô1…‰•°¹¹•Ü ¤(%‘•½È¹Ñ•áÐ€ô‘•½É…Ñ¥½¹}Ñ•áÐ ¤(%‘•½È¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%‘•½È¹…ÕÑ½ÝÉ…Á}µ½‘”€ôQ•áÑM•ÉÙ•È¹UQ=]IA}]=I}M5IP(%‘•½È¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÌÐ¤(%…É‘•¹}‰½à¹…‘‘}¡¥±¡‘•½È¤((%Ù…ÈÁÉ•ÍÑ¥”€èô1…‰•°¹¹•Ü ¤(%ÁÉ•ÍÑ¥”¹Ñ•áÐ€ô€‰AIMQ%€•€€ƒŠˆ€€!%Y59PA=%9QL€•€€ƒŠˆ€€]=I1	L€•ˆ€”m¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹ÁÉ•ÍÑ¥•}Á½¥¹ÑÌ¤°¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹…¡¥•Ù•µ•¹Ñ}Á½¥¹ÑÌ¤°M…Ù•5…¹…•È¹‘…Ñ„¹Ý½É±‘}‰…‘•Ì¹Í¥é” ¥t(%ÁÉ•ÍÑ¥”¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%ÁÉ•ÍÑ¥”¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€Äà¤(%É½½Ð¹…‘‘}¡¥±¡ÁÉ•ÍÑ¥”¤((%Ù…ÈÍ¡½Á}Ñ¥Ñ±”€èô1…‰•°¹¹•Ü ¤(%Í¡½Á}Ñ¥Ñ±”¹Ñ•áÐ€ô€‰I8=IQ%=9Lˆ(%Í¡½Á}Ñ¥Ñ±”¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%Í¡½Á}Ñ¥Ñ±”¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÈÐ¤(%É½½Ð¹…‘‘}¡¥±¡Í¡½Á}Ñ¥Ñ±”¤(%Ù…ÈÍ¡½À€èô!	½á½¹Ñ…¥¹•È¹¹•Ü ¤(%Í¡½À¹…±¥¹µ•¹Ð€ô	½á½¹Ñ…¥¹•È¹1%959Q}9QH(%Í¡½À¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰Í•Á…É…Ñ¥½¸ˆ°€ÄÐ¤(%É½½Ð¹…‘‘}¡¥±¡Í¡½À¤(%™½È¥Ñ•´¥¸ml‰ÑÉ•”ˆ°€‰QIˆ°€ÄÀÁt°l‰‰•¹ ˆ°€‰	9 ˆ°€ÄÔÁt°l‰™½Õ¹Ñ…¥¸ˆ°€‰=U9Q%8ˆ°€ÈÔÁutè($%Ù…È¥€èôMÑÉ¥¹œ¡¥Ñ•µlÁt¤($%Ù…È½Ý¹•è‰½½°€ô¥¥¸M…Ù•5…¹…•È¹‘…Ñ„¹‘•½É…Ñ¥½¹Ì($%Ù…È‰ÕÑÑ½¸€èôµ…­•}‰ÕÑÑ½¸ ¡MÑÉ¥¹œ¡¥Ñ•µlÅt¤€¬€ ˆ€=]9ˆ¥˜½Ý¹••±Í”€‰q¸•=%9Lˆ€”¥¹Ð¡¥Ñ•µlÉt¤¤¤°Y•Ñ½ÈÈ ÈàÀ°€ÄÀÔ¤°½Ý¹•¤($%‰ÕÑÑ½¸¹‘¥Í…‰±•€ô½Ý¹•($%‰ÕÑÑ½¸¹ÁÉ•ÍÍ•¹½¹¹•Ð¡}‰Õå}‘•½É…Ñ¥½¸¹‰¥¹¡¥°¥¹Ð¡¥Ñ•µlÉt¤¤¤($%Í¡½À¹…‘‘}¡¥±¡‰ÕÑÑ½¸¤()™Õ¹ŒÉ•ÍÕ•}…É‘•¹}Ñ•áÐ ¤€´øMÑÉ¥¹œè(%¥˜M…Ù•5…¹…•È¹‘…Ñ„¹É•ÍÕ•¹¥Í}•µÁÑä ¤è($%É•ÑÕÉ¸€‰e½ÕÈ™¥ÉÍÐ™É¥•¹¥ÌÝ…¥Ñ¥¹œÑ¼‰”É•ÍÕ•¸ˆ(%Ù…È¹…µ•Ì€èômt(%™½È¥¥¸M…Ù•5…¹…•È¹‘…Ñ„¹É•ÍÕ•è($%¹…µ•Ì¹…ÁÁ•¹¡MÑÉ¥¹œ¡¥¤¹…Á¥Ñ…±¥é” ¤¤(%É•ÑÕÉ¸€‰IMUI%9Mq¸ˆ€¬€ˆ€ƒŠˆ€€ˆ¹©½¥¸¡¹…µ•Ì¤()™Õ¹Œ‘•½É…Ñ¥½¹}Ñ•áÐ ¤€´øMÑÉ¥¹œè(%¥˜M…Ù•5…¹…•È¹‘…Ñ„¹‘•½É…Ñ¥½¹Ì¹¥Í}•µÁÑä ¤è($%É•ÑÕÉ¸€‰	Õ¥±„¡½µ”Ý½ÉÑ¡ä½˜å½ÕÈÉ•ÍÕ•É•Ü¸ˆ(%Ù…È¹…µ•Ì€èômt(%™½È¥¥¸M…Ù•5…¹…•È¹‘…Ñ„¹‘•½É…Ñ¥½¹Ìè($%¹…µ•Ì¹…ÁÁ•¹¡MÑÉ¥¹œ¡¥¤¹…Á¥Ñ…±¥é” ¤¤(%É•ÑÕÉ¸€‰I8è€ˆ€¬€ˆ€ƒŠˆ€€ˆ¹©½¥¸¡¹…µ•Ì¤()™Õ¹Œ}‰Õå}‘•½É…Ñ¥½¸¡¥èMÑÉ¥¹œ°½ÍÐè¥¹Ð¤€´øÙ½¥è(%¥˜M…Ù•5…¹…•È¹Õ¹±½­}‘•½É…Ñ¥½¸¡¥°½ÍÐ¤è($%••‘‰…­5…¹…•È¹•™™•Ð ¤($%AÉ•µ¥ÕµY¥ÍÕ…±Ì¹‰ÕÉÍÐ¡Y•Ñ½ÈÈ ÔÐÀ°€ÄÄÀÀ¤°½±½È ˆÉ‘ÑˆØˆ¤°€ÈÀ¤($%‰Õ¥±‘}½±±•Ñ¥½¸ ¤()™Õ¹Œ‰Õ¥±‘}Í•ÑÑ¥¹Ì ¤€´øÙ½¥è(%±•…É}½¹Ñ•¹Ð ¤(%…‘‘}‰…­É½Õ¹ ¤(%Ù…È‰½à€èôY	½á½¹Ñ…¥¹•È¹¹•Ü ¤(%‰½à¹Í•Ñ}…¹¡½ÉÍ}ÁÉ•Í•Ð¡½¹ÑÉ½°¹AIMQ}9QH¤(%‰½à¹Á½Í¥Ñ¥½¸€ôY•Ñ½ÈÈ ´ÌÀÀ°€´ÔÀÀ¤(%‰½à¹ÕÍÑ½µ}µ¥¹¥µÕµ}Í¥é”€ôY•Ñ½ÈÈ ØÀÀ°€ÄÀÀÀ¤(%‰½à¹…±¥¹µ•¹Ð€ô	½á½¹Ñ…¥¹•È¹1%959Q}9QH(%‰½à¹…‘‘}Ñ¡•µ•}½¹ÍÑ…¹Ñ}½Ù•ÉÉ¥‘” ‰Í•Á…É…Ñ¥½¸ˆ°€Èà¤(%½¹Ñ•¹Ð¹…‘‘}¡¥±¡‰½à¤(%Ù…ÈÑ¥Ñ±”€èô1…‰•°¹¹•Ü ¤(%Ñ¥Ñ±”¹Ñ•áÐ€ô€‰MQQ%9Lˆ(%Ñ¥Ñ±”¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%Ñ¥Ñ±”¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÐÐ¤(%‰½à¹…‘‘}¡¥±¡Ñ¥Ñ±”¤(%™½ÈÍ•ÑÑ¥¹œ¥¸ml‰Í½Õ¹ˆ°€‰M=U9‰t°l‰Ù¥‰É…Ñ¥½¸ˆ°€‰!AQ%L‰t°l‰µÕÍ¥Œˆ°€‰5UM%‰utè($%Ù…È­•ä€èôMÑÉ¥¹œ¡Í•ÑÑ¥¹lÁt¤($%Ù…È‰ÕÑÑ½¸€èôµ…­•}‰ÕÑÑ½¸ ˆ•Ìè€•Ìˆ€”mMÑÉ¥¹œ¡Í•ÑÑ¥¹lÅt¤°€‰=8ˆ¥˜‰½½°¡M…Ù•5…¹…•È¹‘…Ñ„¹•Ð¡­•ä°ÑÉÕ”¤¤•±Í”€‰=‰t°Y•Ñ½ÈÈ ÔÀÀ°€àØ¤¤($%‰ÕÑÑ½¸¹ÁÉ•ÍÍ•¹½¹¹•Ð¡}Ñ½±•}Í•ÑÑ¥¹œ¹‰¥¹¡­•ä¤¤($%‰½à¹…‘‘}¡¥±¡‰ÕÑÑ½¸¤(%Ù…ÈÍ¡•±°€èô•Ñ}¹½‘•}½É}¹Õ±° ‰UaM¡•±°ˆ¤(%¥˜Í¡•±°€„ô¹Õ±°è($%Ù…ÈÕÉÉ•¹Ñ}Ñ¡•µ”€èôMÑÉ¥¹œ¡Í¡•±°¹•Ð ‰Ñ¡•µ•}µ½‘”ˆ¤¤¥˜Í¡•±°¹•Ð ‰Ñ¡•µ•}µ½‘”ˆ¤€„ô¹Õ±°•±Í”€‰‘…É¬ˆ($%Ù…È…ÁÁ•…É…¹”€èôµ…­•}‰ÕÑÑ½¸ ‰AAI9è€•Ìˆ€”ÕÉÉ•¹Ñ}Ñ¡•µ”¹Ñ½}ÕÁÁ•È ¤°Y•Ñ½ÈÈ ÔÀÀ°€àØ¤¤($%…ÁÁ•…É…¹”¹ÁÉ•ÍÍ•¹½¹¹•Ð¡™Õ¹Œ ¤€´øÙ½¥è($$%¥˜Í¡•±°¹¡…Í}µ•Ñ¡½ ‰}Ñ½±•}Ñ¡•µ”ˆ¤è($$$%Í¡•±°¹…±° ‰}Ñ½±•}Ñ¡•µ”ˆ¤($$%…±±}‘•™•ÉÉ• ‰‰Õ¥±‘}Í•ÑÑ¥¹Ìˆ¤($$¤($%‰½à¹…‘‘}¡¥±¡…ÁÁ•…É…¹”¤(%Ù…È¥¹™¼€èô1…‰•°¹¹•Ü ¤(%¥¹™¼¹Ñ•áÐ€ô€‰AÉ½É•ÍÌÍ…Ù•Ì…ÕÑ½µ…Ñ¥…±±ä¹q¹!¥¹ÑÌ€•€€ƒŠˆ€€U¹‘½Ì€•€€ƒŠˆ€€A•É™•Ð±•…ÉÌ€•‘q¹AÉ•ÍÑ¥”€•€€ƒŠˆ€€¡¥•Ù•µ•¹ÐÁ½¥¹ÑÌ€•ˆ€”m¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹¡¥¹ÑÍ}ÕÍ•¤°¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹Õ¹‘½Í}ÕÍ•¤°¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹Á•É™•Ñ}±•…ÉÌ¤°¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹ÁÉ•ÍÑ¥•}Á½¥¹ÑÌ¤°¥¹Ð¡M…Ù•5…¹…•È¹‘…Ñ„¹…¡¥•Ù•µ•¹Ñ}Á½¥¹ÑÌ¥t(%¥¹™¼¹¡½É¥é½¹Ñ…±}…±¥¹µ•¹Ð€ô!=I%i=9Q1}1%959Q}9QH(%¥¹™¼¹…ÕÑ½ÝÉ…Á}µ½‘”€ôQ•áÑM•ÉÙ•È¹UQ=]IA}]=I}M5IP(%¥¹™¼¹…‘‘}Ñ¡•µ•}™½¹Ñ}Í¥é•}½Ù•ÉÉ¥‘” ‰™½¹Ñ}Í¥é”ˆ°€ÈÀ¤(%‰½à¹…‘‘}¡¥±¡¥¹™¼¤(%Ù…È‰…¬€èôµ…­•}‰ÕÑÑ½¸ ‰	,ˆ°Y•Ñ½ÈÈ ÔÀÀ°€àÈ¤°ÑÉÕ”¤(%‰…¬¹ÁÉ•ÍÍ•¹½¹¹•Ð¡‰Õ¥±‘}¡½µ”¤(%‰½à¹…‘‘}¡¥±¡‰…¬¤()™Õ¹Œ}Ñ½±•}Í•ÑÑ¥¹œ¡­•äèMÑÉ¥¹œ¤€´øÙ½¥è(%M…Ù•5…¹…•È¹‘…Ñ…m­•åt€ô¹½Ð‰½½°¡M…Ù•5…¹…•È¹‘…Ñ„¹•Ð¡­•ä°ÑÉÕ”¤¤(%M…Ù•5…¹…•È¹Í…Ù” ¤(%••‘‰…­5…¹…•È¹Ñ…À ¤(%‰Õ¥±‘}Í•ÑÑ¥¹Ì ¤(