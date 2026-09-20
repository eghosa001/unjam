extends "res://scripts/ui/premium_home_casual.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color(0.94, 0.99, 1.0)
const BG_MID := Color(0.98, 0.99, 1.0)
const BG_BOTTOM := Color(0.892, 0.9496, 0.988)
const NAVY := Color(0.03, 0.23, 0.47)
const INK := Color(0.07, 0.20, 0.35)
const MUTED := Color(0.31, 0.42, 0.52)
const BLUE := Color(0.03, 0.43, 0.78)
const CYAN := Color(0.14, 0.68, 1.0)
const ORANGE := Color(1.0, 0.55, 0.12)
const GOLD := Color(1.0, 0.84, 0.24)
const OFF_WHITE := Color(1.0, 0.995, 0.97)

var figma_canvas: FigmaReferenceCanvas

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
	viewport_bg.color = BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaHome390x844"
	add_child(figma_canvas)
	_build_reference_home(figma_canvas)

func _build_reference_home(canvas: Control) -> void:
	_add_frame_background(canvas)
	_add_text(canvas, "UNJAM", Rect2(21, 23, 101, 34), 27, NAVY, true)

	var cleared := 0
	for game_id in MultiGameManager.GAME_IDS:
		cleared += int(MultiGameManager.progress_for(game_id).get("levels_completed", 0))
	var player_level := maxi(1, 1 + int(cleared / 10))
	_add_pill(canvas, Rect2(21, 64, 78, 40), Color(0.03, 0.43, 0.78), "LV %d" % player_level, 13, OFF_WHITE)
	home_coin_button = _add_action(canvas, Rect2(107, 64, 112, 40), Color(1.0, 0.55, 0.12), "◈ %s +" % _compact_number(EconomyManager.balance()), 12, OFF_WHITE, Callable(self, "_open_shop"), 20)
	home_coin_button.name = "HomeCoinShopButton"
	_add_pill(canvas, Rect2(227, 64, 92, 40), GOLD, "★ %s" % _compact_number(_total_stars()), 12, NAVY)

	_add_hero(canvas)
	_add_quick_actions(canvas)
	_add_quick_switch(canvas)
	_add_bottom_nav_reference(canvas)

func _add_frame_background(canvas: Control) -> void:
	var bg := PanelContainer.new()
	bg.name = "FigmaHomeBackground"
	bg.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(BG_TOP, BG_MID, BG_BOTTOM, 34, Color("#bad1e3"), 1, 0.48))
	RefCanvas.set_rect(bg, 0, 0, 390, 844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

func _add_hero(canvas: Control) -> void:
	RefCanvas.add_shadow(canvas, Rect2(21, 121, 346, 224), 20, Color(0.03, 0.12, 0.22, 0.16), 5, Vector2(0, 4))
	var hero := PanelContainer.new()
	hero.name = "FigmaHomeHero"
	hero.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#d7f4ff"), Color("#d1eef9"), Color("#caeaf6"), 20, Color(0.505, 0.769, 0.945, 0.32), 1.2))
	RefCanvas.set_rect(hero, 21, 121, 346, 224)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hero)

	_add_text(canvas, "CURRENT JOURNEY", Rect2(41, 142, 150, 15), 12, ORANGE, true)
	var level := _home_current_level(selected_game)
	var world := MultiGameManager.world_for_game_level(selected_game, level)
	_add_text(canvas, _short_game_name(selected_game), Rect2(41, 167, 186, 34), 28, NAVY, true)
	_add_text(canvas, "LEVEL %d • WORLD %d" % [level, world], Rect2(41, 204, 170, 17), 14, BLUE, true)

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
	var stage := PanelContainer.new()
	stage.name = "FigmaHomeHeroPreview"
	stage.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.91, 0.99, 1.0, 0.34), 16))
	RefCanvas.set_rect(stage, 219, 144, 125, 136)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stage)
	match game_id:
		"water_sort":
			_add_mini_bottle(canvas, Vector2(231, 158), 22, 108, Color("#ff7ebd"), Color("#d64089"), 62.64)
			_add_mini_bottle(canvas, Vector2(270.5, 162), 22, 103, Color("#5ac1ff"), Color("#158dd6"), 74.16)
			_add_mini_bottle(canvas, Vector2(310, 158), 22, 108, Color("#5fd78f"), Color("#1ca754"), 47.52)
		"block_puzzle":
			_add_mini_block_preview(canvas, Vector2(230, 154))
		_:
			_add_mini_rescue_preview(canvas, Vector2(230, 154))

func _add_mini_bottle(canvas: Control, pos: Vector2, width: float, height: float, liquid_left: Color, liquid_right: Color, liquid_height: float) -> void:
	var shadow := PanelContainer.new()
	shadow.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.02, 0.15, 0.26, 0.16), 4))
	RefCanvas.set_rect(shadow, pos.x, pos.y + height - 3, width, 7)
	canvas.add_child(shadow)
	var bottle := PanelContainer.new()
	bottle.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.90, 0.99, 1.0, 0.10), 9, Color(0.82, 0.98, 1.0, 0.90), 1.3))
	RefCanvas.set_rect(bottle, pos.x, pos.y, width, height)
	bottle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bottle)
	var body_y := pos.y + height - liquid_height - 3.0
	var body := PanelContainer.new()
	body.add_theme_stylebox_override("panel", RefCanvas.horizontal_gradient(liquid_left, liquid_right, 1))
	RefCanvas.set_rect(body, pos.x + 3, body_y, width - 6, liquid_height)
	canvas.add_child(body)
	var meniscus := PanelContainer.new()
	meniscus.add_theme_stylebox_override("panel", RefCanvas.horizontal_gradient(liquid_left.lightened(0.08), liquid_right.lightened(0.04), 3))
	RefCanvas.set_rect(meniscus, pos.x + 3, body_y - 3.0, width - 6, 6)
	canvas.add_child(meniscus)
	var hi := ColorRect.new()
	hi.color = Color(1, 1, 1, 0.48)
	RefCanvas.set_rect(hi, pos.x + 5, pos.y + 8, 2, height - 16)
	canvas.add_child(hi)
	var rim := PanelContainer.new()
	rim.add_theme_stylebox_override("panel", RefCanvas.horizontal_gradient(Color("#f4fdff"), Color("#cfeffc"), 3, Color(0.82,0.98,1.0,0.90), 0.8))
	RefCanvas.set_rect(rim, pos.x + 1, pos.y - 2, width - 2, 6)
	canvas.add_child(rim)

func _add_mini_block_preview(canvas: Control, origin: Vector2) -> void:
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.23, 0.16, 0.37), 12, Color(0.72, 0.52, 1.0, 0.55), 1))
	RefCanvas.set_rect(board, origin.x, origin.y, 105, 105)
	canvas.add_child(board)
	var palette := [Color(1, 0.84, 0.24), Color(1, 0.48, 0.82), Color(0.31, 0.96, 0.57), Color(0.28, 0.84, 1)]
	for y in range(4):
		for x in range(4):
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.18, 0.10, 0.33), 4))
			RefCanvas.set_rect(well, origin.x + 8 + x * 23, origin.y + 8 + y * 23, 19, 19)
			canvas.add_child(well)
			if (x + y * 2) % 3 == 0:
				var fill := ColorRect.new()
				fill.color = palette[(x + y) % palette.size()]
				RefCanvas.set_rect(fill, origin.x + 10 + x * 23, origin.y + 10 + y * 23, 15, 15)
				canvas.add_child(fill)

func _add_mini_rescue_preview(canvas: Control, origin: Vector2) -> void:
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.55, 0.72, 0.59), 12, Color(0.92, 1.0, 0.86, 0.62), 1))
	RefCanvas.set_rect(board, origin.x, origin.y, 105, 105)
	canvas.add_child(board)
	var colors := [Color(0.20, 0.76, 0.44), Color(0.66, 0.40, 0.86), Color(0.18, 0.67, 1.0), Color(1, 0.57, 0.20)]
	for i in range(6):
		var x := i % 3
		var y := i / 3
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", RefCanvas.solid_box(colors[i % colors.size()], 4))
		RefCanvas.set_rect(tile, origin.x + 8 + x * 29, origin.y + 8 + y * 29, 22, 22)
		canvas.add_child(tile)
		var arrow := _make_label("→", 14, Color.WHITE, true)
		RefCanvas.set_rect(arrow, origin.x + 10 + x * 29, origin.y + 8 + y * 29, 18, 22)
		canvas.add_child(arrow)
	var chick := PanelContainer.new()
	chick.add_theme_stylebox_override("panel", RefCanvas.solid_box(GOLD, 9))
	RefCanvas.set_rect(chick, origin.x + 42, origin.y + 67, 18, 18)
	canvas.add_child(chick)

func _add_quick_actions(canvas: Control) -> void:
	var choose := _add_action(canvas, Rect2(21, 365, 166, 52), BLUE, "◈ CHOOSE GAME", 12, OFF_WHITE, Callable(self, "_open_game_selector"), 16)
	choose.name = "HomeChooseGameButton"
	var daily_done := 0
	for game_id in MultiGameManager.GAME_IDS:
		var main := get_parent()
		if main != null and main.has_method("_daily_done") and bool(main.call("_daily_done", game_id)):
			daily_done += 1
	var daily := _add_action(canvas, Rect2(197, 365, 170, 52), GOLD, "☀ DAILY • %d/3" % daily_done, 12, NAVY, Callable(self, "_open_daily_games"), 16)
	daily.name = "HomeDailyGamesButton"

func _add_quick_switch(canvas: Control) -> void:
	_add_text(canvas, "QUICK SWITCH", Rect2(21, 437, 160, 18), 14, INK, true)
	var games := [
		["rescue_rush", "↗ RESCUE", Color(0.13, 0.78, 0.39), 21.0],
		["water_sort", "◉ WATER", Color(0.10, 0.66, 1.0), 137.0],
		["block_puzzle", "◆ BLOCK", Color(0.78, 0.24, 1.0), 253.0],
	]
	for entry in games:
		var id := String(entry[0])
		var x := float(entry[3])
		RefCanvas.add_shadow(canvas, Rect2(x, 465, 108, 94), 18, Color(0.02, 0.10, 0.18, 0.13), 4, Vector2(0, 3))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", RefCanvas.solid_box(OFF_WHITE, 18, entry[2], 1.5))
		RefCanvas.set_rect(card, x, 465, 108, 94)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(card)
		_add_text(canvas, String(entry[1]), Rect2(x + 9, 479, 92, 15), 12, entry[2], true)
		var level := _home_current_level(id)
		var stars := MultiGameManager.total_stars(id)
		_add_text(canvas, "L%d • ★%s" % [level, _compact_number(stars)], Rect2(x + 9, 509, 92, 15), 12, MUTED, false)
		var tap := Button.new()
		tap.name = "HomeDirect_%s" % id
		tap.set_meta("unjam_figma_exact_geometry", true)
		tap.flat = true
		tap.focus_mode = Control.FOCUS_NONE
		tap.modulate.a = 0.001
		RefCanvas.set_rect(tap, x - 4, 459, 116, 106)
		tap.pressed.connect(_select_and_open_game.bind(id))
		canvas.add_child(tap)

func _add_bottom_nav_reference(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "HomeBottomNav3D"
	RefCanvas.add_shadow(canvas, Rect2(13, 757, 362, 70), 18, Color(0.02, 0.10, 0.18, 0.12), 5, Vector2(0, 4))
	shell.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.985, 0.995, 1.0, 0.97), 18, Color(0.78, 0.88, 0.95, 0.75), 1))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)
	var active := PanelContainer.new()
	active.add_theme_stylebox_override("panel", RefCanvas.solid_box(CYAN, 16))
	RefCanvas.set_rect(active, 15, 767, 62, 48)
	active.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(active)
	var items := [
		["HOME", 22.0, Callable(), "HomeNavButton", true],
		["GAMES", 91.0, Callable(self, "_open_game_selector"), "HomeLevelsNavButton", false],
		["DAILY", 160.0, Callable(self, "_open_daily_games"), "HomeDailyNavButton", false],
		["COLLECT", 229.0, func(): get_parent().call("build_collection"), "HomeCollectionNavButton", false],
		["SETTINGS", 298.0, func(): get_parent().call("build_settings"), "HomeSettingsNavButton", false],
	]
	for item in items:
		_add_text(canvas, item[0], Rect2(item[1] - 1.0, 788, 62, 30), 12, Color(0.05, 0.49, 0.86) if item[4] else Color(0.31, 0.43, 0.54), true)
		var hit := Button.new()
		hit.name = item[3]
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, item[1] - 9, 753, 74, 78)
		var cb: Callable = item[2]
		if cb.is_valid():
			hit.pressed.connect(cb)
		canvas.add_child(hit)

func _add_pill(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color) -> PanelContainer:
	RefCanvas.add_shadow(canvas, rect, rect.size.y * 0.5, Color(0.02, 0.10, 0.18, 0.15), 3, Vector2(0, 2))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", RefCanvas.solid_box(fill, rect.size.y * 0.5))
	RefCanvas.set_rect(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	var label := _make_label(text_value, font_size, text_color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return panel

func _add_action(canvas: Control, rect: Rect2, fill: Color, text_value: String, font_size: int, text_color: Color, callback: Callable, radius: float) -> Button:
	RefCanvas.add_shadow(canvas, rect, radius, Color(0.02, 0.10, 0.18, 0.20), 5, Vector2(0, 4))
	var button := RefCanvas.premium_button(text_value, font_size, text_color, fill, radius)
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
	var label := RefCanvas.label(text_value, font_size, color, bold)
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

func _select_and_open_game(game_id: String) -> void:
	selected_game = game_id
	var main := get_parent()
	if main == null or not main.has_method("open_game_campaign"):
		return
	main.set("selected_game_id", game_id)
	FeedbackManager.tap()
	main.call("open_game_campaign", game_id)

func _open_game_levels(game_id: String) -> void:
	_select_and_open_game(game_id)
