extends Control

const ACCENTS := {
	"rescue_rush": Color("2dd4b6"),
	"water_sort": Color("5da9ff"),
	"block_puzzle": Color("8b7cf6")
}
const TAGS := {
	"rescue_rush": "FEATURED",
	"water_sort": "TRENDING",
	"block_puzzle": "CLASSIC"
}
const DESCRIPTIONS := {
	"rescue_rush": "Clear the lane, trigger chain reactions and rescue the trapped character.",
	"water_sort": "Sort every colour into clean tubes with the fewest possible pours.",
	"block_puzzle": "Place pieces, preserve space and clear satisfying lines."
}

var built := false
var last_theme := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _process(_delta: float) -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	visible = surface == "live"
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	if not visible:
		return
	var mode := _theme_mode()
	if not built or mode != last_theme:
		_build()

func _theme_mode() -> String:
	var shell := get_parent().get_node_or_null("UXShell")
	if shell != null and shell.get("theme_mode") != null:
		return String(shell.get("theme_mode"))
	return "dark"

func _dark() -> bool:
	return _theme_mode() == "dark"

func _ink() -> Color:
	return PremiumDesignSystem.ink(_dark())

func _muted() -> Color:
	return PremiumDesignSystem.muted(_dark())

func _surface() -> Color:
	return PremiumDesignSystem.canvas(_dark())

func _card() -> Color:
	return PremiumDesignSystem.surface(_dark())

func _border() -> Color:
	return PremiumDesignSystem.border(_dark())

func _button(text_value: String, minimum: Vector2, accent: Color, strong := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 21)
	PremiumDesignSystem.apply_button(button, _dark(), accent, "primary" if strong else "secondary", 24)
	return button

func _build() -> void:
	for child in get_children():
		child.queue_free()
	built = true
	last_theme = _theme_mode()

	var bg := PremiumBackdrop.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.configure(PremiumDesignSystem.game_canvas("water_sort", _dark()), Color("5da9ff"), 1)
	add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 40)
	outer.add_theme_constant_override("margin_right", 40)
	outer.add_theme_constant_override("margin_top", 30)
	outer.add_theme_constant_override("margin_bottom", 120)
	add_child(outer)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 15)
	outer.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	var back := _button("‹", Vector2(78, 72), Color("5da9ff"))
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(_go_home)
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title := Label.new()
	title.text = "LIVE"
	title.add_theme_font_size_override("font_size", 42)
	PremiumDesignSystem.apply_label(title, _dark(), "title", Color("5da9ff"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Choose a game and jump straight back in"
	subtitle.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_label(subtitle, _dark(), "muted", Color("5da9ff"))
	titles.add_child(subtitle)
	var wallet_panel := PanelContainer.new()
	wallet_panel.custom_minimum_size = Vector2(290, 72)
	wallet_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(PremiumDesignSystem.GOLD, _dark()))
	header.add_child(wallet_panel)
	var wallet := Label.new()
	wallet.text = "%d COINS   •   %d ★" % [int(SaveManager.data.get("coins", 0)), _total_stars()]
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wallet.add_theme_font_size_override("font_size", 20)
	wallet.add_theme_color_override("font_color", PremiumDesignSystem.GOLD)
	wallet_panel.add_child(wallet)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)
	var live_tab := _button("●  LIVE GAMES", Vector2(0, 82), Color("5da9ff"), true)
	live_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(live_tab)
	var daily := _button("DAILY CHALLENGE", Vector2(0, 82), Color("2dd4b6"))
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily.pressed.connect(_daily_for_best_game)
	tabs.add_child(daily)
	var levels := _button("LEVELS", Vector2(0, 82), Color("8b7cf6"))
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels.pressed.connect(_levels_for_best_game)
	tabs.add_child(levels)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 16)
	scroll.add_child(stack)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		_add_game_card(stack, game_id)

	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 118)
	footer.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color(_card(), 0.95), 28, _border(), _dark(), 7))
	stack.add_child(footer)
	var footer_text := Label.new()
	footer_text.text = "⚡  PLAY MORE. MASTER MORE.\nEvery game keeps its own progress, stars and 10,000-level journey."
	footer_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_text.add_theme_font_size_override("font_size", 19)
	PremiumDesignSystem.apply_label(footer_text, _dark(), "muted", Color("5da9ff"))
	footer.add_child(footer_text)

	_add_bottom_nav()
	if not MotionSystem.reduced():
		PremiumVisuals.entrance(root, 0.018)

func _add_game_card(parent: VBoxContainer, game_id: String) -> void:
	var accent: Color = ACCENTS[game_id]
	var progress := MultiGameManager.progress_for(game_id)
	var highest := clampi(int(progress.get("highest_level", 1)), 1, MultiGameManager.CAMPAIGN_LEVELS)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 390)
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color(_card(), 0.985), 34, Color(accent, 0.64), _dark(), 11))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	margin.add_child(row)

	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(326, 340)
	art_frame.add_theme_stylebox_override("panel", PremiumDesignSystem.recessed_box(PremiumDesignSystem.game_canvas(game_id, _dark()), 28, Color(accent, 0.42), _dark()))
	row.add_child(art_frame)
	var art := GameShowcaseArt.new()
	art.custom_minimum_size = Vector2(310, 330)
	art.configure(game_id, accent, _dark())
	art_frame.add_child(art)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	row.add_child(info)
	var top := HBoxContainer.new()
	info.add_child(top)
	var name := Label.new()
	name.text = MultiGameManager.display_name(game_id).to_upper()
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 36)
	PremiumDesignSystem.apply_label(name, _dark(), "title", accent)
	top.add_child(name)
	var tag_panel := PanelContainer.new()
	tag_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(accent, _dark()))
	top.add_child(tag_panel)
	var tag := Label.new()
	tag.text = TAGS[game_id]
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", accent)
	tag_panel.add_child(tag)
	var desc := Label.new()
	desc.text = DESCRIPTIONS[game_id]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_label(desc, _dark(), "muted", accent)
	info.add_child(desc)
	var stats := Label.new()
	stats.text = "LEVEL %d / 10,000   •   %d ★\nWORLD %d / 100   •   %d PERFECT" % [highest, MultiGameManager.total_stars(game_id), MultiGameManager.highest_unlocked_world(game_id), int(progress.get("perfect_clears", 0))]
	stats.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_label(stats, _dark(), "body", accent)
	info.add_child(stats)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	info.add_child(actions)
	var play := _button("PLAY  ›", Vector2(250, 88), accent, true)
	play.pressed.connect(_play.bind(game_id))
	actions.add_child(play)
	var daily := _button("DAILY", Vector2(180, 88), accent)
	daily.pressed.connect(_daily.bind(game_id))
	actions.add_child(daily)

func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_left = 40
	nav.offset_right = -40
	nav.offset_bottom = -20
	nav.offset_top = -112
	nav.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color(_card(), 0.985), 30, _border(), _dark(), 9))
	add_child(nav)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	nav.add_child(row)
	var home := _button("⌂  HOME", Vector2(0, 82), Color("5da9ff"))
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(_go_home)
	row.add_child(home)
	var live := _button("●  LIVE", Vector2(0, 82), Color("5da9ff"), true)
	live.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(live)
	var collection := _button("★  COLLECTION", Vector2(0, 82), Color("8b7cf6"))
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.pressed.connect(func(): get_parent().call("build_collection"))
	row.add_child(collection)
	var settings := _button("⚙  SETTINGS", Vector2(0, 82), Color("2dd4b6"))
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	row.add_child(settings)

func _best_game() -> String:
	var winner := "rescue_rush"
	var best := -1
	for game_id in MultiGameManager.GAME_IDS:
		var value := MultiGameManager.highest_level(game_id)
		if value > best:
			best = value
			winner = game_id
	return winner

func _total_stars() -> int:
	var total := 0
	for game_id in MultiGameManager.GAME_IDS:
		total += MultiGameManager.total_stars(game_id)
	return total

func _go_home() -> void:
	get_parent().call("build_home")

func _play(game_id: String) -> void:
	var main := get_parent()
	var checkpoint = main.call("_checkpoint_for", game_id) if main.has_method("_checkpoint_for") else {}
	if checkpoint is Dictionary and not checkpoint.is_empty():
		main.call("resume_game", game_id)
	else:
		main.call("open_game_campaign", game_id)

func _daily(game_id: String) -> void:
	get_parent().call("start_game_daily", game_id)

func _daily_for_best_game() -> void:
	_daily(_best_game())

func _levels_for_best_game() -> void:
	get_parent().call("open_game_campaign", _best_game())
