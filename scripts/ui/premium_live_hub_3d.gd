extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color(0.94, 0.99, 1.0)
const BG_BOTTOM := Color(0.892, 0.9496, 0.988)
const NAVY := Color(0.03, 0.23, 0.47)
const INK := Color(0.07, 0.20, 0.35)
const MUTED := Color(0.31, 0.42, 0.52)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const CYAN := Color(0.14, 0.68, 1.0)

var figma_canvas: FigmaReferenceCanvas

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	built = true
	last_theme = _theme_mode()
	clip_contents = true

	var viewport_bg := ColorRect.new()
	viewport_bg.name = "FigmaSelectorViewportBackground"
	viewport_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_bg.color = BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaSelector390x844"
	add_child(figma_canvas)
	_build_reference_selector(figma_canvas)

func _build_reference_selector(canvas: Control) -> void:
	var background := PanelContainer.new()
	background.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(BG_TOP, BG_BOTTOM, 0))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)

	var back := RefCanvas.button("‹", 27, NAVY, OFF_WHITE, 18)
	back.name = "SelectorBackButton"
	RefCanvas.set_rect(back, 18, 20, 52, 52)
	back.pressed.connect(_go_home)
	canvas.add_child(back)

	_add_text(canvas, "CHOOSE A GAME", Rect2(84, 22, 205, 28), 23, INK, true)
	_add_text(canvas, "THREE PUZZLES • ONE JOURNEY", Rect2(84, 52, 210, 15), 12, MUTED, false)

	var settings := RefCanvas.button("⚙", 18, OFF_WHITE, Color(0.03, 0.43, 0.78), 23)
	settings.name = "SelectorSettingsButton"
	RefCanvas.set_rect(settings, 286, 22, 84, 46)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	canvas.add_child(settings)

	_add_game_card(canvas, "rescue_rush", Rect2(18, 112, 354, 160), Color(0.13, 0.78, 0.39), Color(0.2866, 0.8196, 0.4998), "RESCUE RUSH", "Tap arrows. Clear the lane.", 76)
	_add_game_card(canvas, "water_sort", Rect2(18, 286, 354, 160), Color(0.10, 0.66, 1.0), Color(0.262, 0.7212, 1.0), "WATER SORT", "Pour colours into matching tubes.", 128)
	_add_game_card(canvas, "block_puzzle", Rect2(18, 460, 354, 160), Color(0.78, 0.24, 1.0), Color(0.8196, 0.3768, 1.0), "BLOCK PUZZLE", "Drag pieces. Clear lines.", 92)
	_add_bottom_nav(canvas)

func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String, figma_fallback_level: int) -> void:
	var card := PanelContainer.new()
	card.name = "GameCard3D_%s" % game_id
	card.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient(highlight, accent.darkened(0.18), 20, highlight.lightened(0.35), 1))
	RefCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)

	_add_text(canvas, title, Rect2(34, rect.position.y + 12.6, 170, 23), 19, OFF_WHITE, true)
	_add_text(canvas, subtitle, Rect2(34, rect.position.y + 39.6, 184, 18), 13, OFF_WHITE, false)
	var level := maxi(1, MultiGameManager.highest_level(game_id))
	if level <= 1:
		level = figma_fallback_level
	var level_pill := PanelContainer.new()
	level_pill.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.04, 0.30, 0.55), 13))
	RefCanvas.set_rect(level_pill, 34, rect.position.y + 100.7, 112, 36)
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(level_pill)
	_add_text(canvas, "LEVEL %d" % level, Rect2(46, rect.position.y + 111, 88, 16), 13, OFF_WHITE, true)
	_add_card_preview(canvas, game_id, rect.position.y)

	var tap := Button.new()
	tap.name = "SelectorCardHit_%s" % game_id
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.modulate.a = 0.001
	RefCanvas.set_rect(tap, rect.position.x - 2, rect.position.y - 5, rect.size.x + 4, rect.size.y + 10)
	tap.pressed.connect(_play.bind(game_id))
	canvas.add_child(tap)

func _add_card_preview(canvas: Control, game_id: String, card_y: float) -> void:
	var origin_y := card_y + 22.5
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", RefCanvas.solid_box(
		Color(0.92, 1.0, 0.86, 0.38) if game_id == "rescue_rush" else (Color(0.91, 0.99, 1.0, 0.42) if game_id == "water_sort" else Color(0.94, 0.91, 1.0, 0.34)),
		16
	))
	RefCanvas.set_rect(stage, 244, origin_y, 104, 112)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stage)
	match game_id:
		"rescue_rush": _preview_rescue(canvas, origin_y)
		"water_sort": _preview_water(canvas, origin_y)
		_: _preview_block(canvas, origin_y)

func _preview_rescue(canvas: Control, y: float) -> void:
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.55, 0.72, 0.59), 12, Color(0.92, 1, 0.86, 0.62), 1))
	RefCanvas.set_rect(board, 254, y + 10.8, 84, 90)
	canvas.add_child(board)
	var colors := [Color(0.11, 0.61, 0.35), Color(0.54, 0.26, 0.76), Color(0.084, 0.55, 0.84), Color(0.84, 0.46, 0.10)]
	var spots := [Vector2(259, y + 13.5), Vector2(283.7, y + 13.5), Vector2(259, y + 35.6), Vector2(308.3, y + 35.6), Vector2(259, y + 57.8), Vector2(308.3, y + 57.8)]
	for i in range(spots.size()):
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", RefCanvas.solid_box(colors[i % colors.size()].lightened(0.08), 4))
		RefCanvas.set_rect(tile, spots[i].x, spots[i].y, 21.7, 21.7)
		canvas.add_child(tile)
		var arrow := _make_label("→", 13, Color.WHITE, true)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		RefCanvas.set_rect(arrow, spots[i].x, spots[i].y, 21.7, 21.7)
		canvas.add_child(arrow)
	var chick := PanelContainer.new()
	chick.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(1, 0.80, 0.12), 8))
	RefCanvas.set_rect(chick, 288.5, y + 39, 15, 15)
	canvas.add_child(chick)

func _preview_water(canvas: Control, y: float) -> void:
	var specs := [
		[256.0, 12.6, 84.0, Color(1.0, 0.30, 0.64), 48.7],
		[285.0, 16.2, 79.0, Color(0.10, 0.66, 1.0), 56.9],
		[314.0, 12.6, 84.0, Color(1.0, 0.84, 0.24), 48.7],
	]
	for spec in specs:
		var x := float(spec[0])
		var top := y + float(spec[1])
		var h := float(spec[2])
		var bottle := PanelContainer.new()
		bottle.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.90, 0.99, 1.0, 0.10), 9, Color(0.82, 0.98, 1.0, 0.90), 1))
		RefCanvas.set_rect(bottle, x, top, 22, h)
		canvas.add_child(bottle)
		var liquid_h := float(spec[4])
		var liquid := ColorRect.new()
		liquid.color = spec[3]
		RefCanvas.set_rect(liquid, x + 3, top + h - liquid_h - 5, 16, liquid_h)
		canvas.add_child(liquid)
		var meniscus := ColorRect.new()
		meniscus.color = Color(spec[3]).lightened(0.07)
		RefCanvas.set_rect(meniscus, x + 3, top + h - liquid_h - 7, 16, 5)
		canvas.add_child(meniscus)

func _preview_block(canvas: Control, y: float) -> void:
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.23, 0.16, 0.37), 12, Color(0.72, 0.52, 1.0, 0.60), 1))
	RefCanvas.set_rect(board, 254, y + 8, 84, 78)
	canvas.add_child(board)
	var palette := [Color(1, 0.84, 0.24), Color(1, 0.48, 0.82), Color(0.31, 0.96, 0.57), Color(0.28, 0.84, 1)]
	for row in range(4):
		for col in range(4):
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.18, 0.10, 0.33), 3))
			RefCanvas.set_rect(well, 260 + col * 18, y + 14 + row * 16, 14, 13)
			canvas.add_child(well)
			if (row + col * 2) % 3 == 0:
				var cell := ColorRect.new()
				cell.color = palette[(row + col) % palette.size()]
				RefCanvas.set_rect(cell, 262 + col * 18, y + 16 + row * 16, 10, 9)
				canvas.add_child(cell)
	for i in range(3):
		var tray := ColorRect.new()
		tray.color = palette[(i + 1) % palette.size()]
		RefCanvas.set_rect(tray, 262 + i * 23, y + 93, 16, 6)
		canvas.add_child(tray)

func _add_bottom_nav(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "SelectorBottomNav"
	shell.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.985, 0.995, 1.0, 0.97), 18, Color(0.78, 0.88, 0.95, 0.75), 1))
	RefCanvas.set_rect(shell, 14, 758, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)
	var active := PanelContainer.new()
	active.add_theme_stylebox_override("panel", RefCanvas.solid_box(CYAN, 16))
	RefCanvas.set_rect(active, 85, 768, 62, 48)
	active.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(active)
	var items := [
		["HOME", 22.0, Callable(self, "_go_home"), false],
		["GAMES", 91.0, Callable(), true],
		["DAILY", 160.0, func(): get_parent().call("build_daily_games"), false],
		["COLLECT", 229.0, func(): get_parent().call("build_collection"), false],
		["SETTINGS", 298.0, func(): get_parent().call("build_settings"), false],
	]
	for item in items:
		_add_text(canvas, item[0], Rect2(item[1], 789, 62, 30), 12, Color(0.05, 0.49, 0.86) if item[3] else Color(0.31, 0.43, 0.54), true)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, item[1] - 8, 754, 74, 78)
		var callback: Callable = item[2]
		if callback.is_valid():
			hit.pressed.connect(callback)
		canvas.add_child(hit)

func _add_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color, bold: bool) -> Label:
	var label := _make_label(text_value, font_size, color, bold)
	RefCanvas.set_rect(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	canvas.add_child(label)
	return label

func _make_label(text_value: String, font_size: int, color: Color, bold: bool) -> Label:
	return RefCanvas.label(text_value, font_size, color, bold)
