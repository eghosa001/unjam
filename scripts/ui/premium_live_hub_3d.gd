extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color(0.94, 0.99, 1.0)
const BG_MID := Color(0.98, 0.99, 1.0)
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
	background.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(BG_TOP, BG_MID, BG_BOTTOM, 34, Color("#bad1e3"), 1, 0.48))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)

	RefCanvas.add_shadow(canvas, Rect2(17, 19, 52, 52), 18, Color(0.02,0.15,0.30,0.16), 4, Vector2(0,3))
	var back := RefCanvas.premium_button("‹", 27, NAVY, OFF_WHITE, 18)
	back.name = "SelectorBackButton"
	RefCanvas.set_rect(back, 17, 19, 52, 52)
	back.pressed.connect(_go_home)
	canvas.add_child(back)

	_add_text(canvas, "CHOOSE A GAME", Rect2(83, 21, 205, 28), 23, INK, true)
	_add_text(canvas, "THREE PUZZLES • ONE JOURNEY", Rect2(83, 51, 210, 15), 12, MUTED, false)

	RefCanvas.add_shadow(canvas, Rect2(285, 21, 84, 46), 23, Color(0.02,0.15,0.30,0.16), 3, Vector2(0,2))
	var settings := RefCanvas.premium_button("⚙", 18, OFF_WHITE, Color(0.03, 0.43, 0.78), 23)
	settings.name = "SelectorSettingsButton"
	RefCanvas.set_rect(settings, 285, 21, 84, 46)
	settings.pressed.connect(func(): get_parent().call("build_settings"))
	canvas.add_child(settings)

	_add_game_card(canvas, "rescue_rush", Rect2(17, 111, 354, 160), Color("#21c763"), Color("#49d17f"), "RESCUE RUSH", "Tap arrows. Clear the lane.", 76)
	_add_game_card(canvas, "water_sort", Rect2(17, 285, 354, 160), Color("#1aa8ff"), Color("#43b8ff"), "WATER SORT", "Pour colours into matching tubes.", 128)
	_add_game_card(canvas, "block_puzzle", Rect2(17, 459, 354, 160), Color("#c73dff"), Color("#d160ff"), "BLOCK PUZZLE", "Drag pieces. Clear lines.", 92)
	_add_bottom_nav(canvas)

func _add_game_card(canvas: Control, game_id: String, rect: Rect2, accent: Color, highlight: Color, title: String, subtitle: String, figma_fallback_level: int) -> void:
	RefCanvas.add_shadow(canvas, rect, 20, Color(0.03,0.10,0.20,0.22), 8, Vector2(0,6))
	var card := PanelContainer.new()
	card.name = "GameCard3D_%s" % game_id
	card.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(highlight, accent, accent.darkened(0.18), 20, highlight.lightened(0.35), 1.6, 0.55))
	RefCanvas.set_rect(card, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card)

	_add_text(canvas, title, Rect2(34, rect.position.y + 12.6, 170, 23), 19, OFF_WHITE, true)
	_add_text(canvas, subtitle, Rect2(34, rect.position.y + 39.6, 184, 18), 13, OFF_WHITE, false)
	var level := maxi(1, MultiGameManager.highest_level(game_id))
	if level <= 1:
		level = figma_fallback_level
	RefCanvas.add_shadow(canvas, Rect2(33, rect.position.y + 100.7, 112, 36), 13, Color(0.02,0.10,0.20,0.16), 3, Vector2(0,2))
	var level_pill := PanelContainer.new()
	level_pill.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.04, 0.30, 0.55), 13))
	RefCanvas.set_rect(level_pill, 33, rect.position.y + 100.7, 112, 36)
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(level_pill)
	_add_text(canvas, "LEVEL %d" % level, Rect2(45, rect.position.y + 111, 88, 16), 13, OFF_WHITE, true)
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
	RefCanvas.set_rect(stage, 243, origin_y, 104, 112)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stage)
	match game_id:
		"rescue_rush": _preview_rescue(canvas, origin_y)
		"water_sort": _preview_water(canvas, origin_y)
		_: _preview_block(canvas, origin_y)

func _preview_rescue(canvas: Control, y: float) -> void:
	var board_depth := PanelContainer.new()
	board_depth.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color("#173d33"), 12))
	RefCanvas.set_rect(board_depth, 253, y + 15.3, 84, 90)
	canvas.add_child(board_depth)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#a9d3ad"), Color("#8cb896"), Color("#759d80"), 12, Color(0.92, 1.0, 0.86, 0.62), 1))
	RefCanvas.set_rect(board, 253, y + 10.8, 84, 90)
	canvas.add_child(board)
	var specs := [
		[Vector2(258.0, y + 13.5), Color("#1c9c5a"), "→"],
		[Vector2(282.7, y + 13.5), Color("#8942c1"), "↓"],
		[Vector2(258.0, y + 35.7), Color("#158dd6"), "←"],
		[Vector2(307.3, y + 35.7), Color("#8942c1"), "↑"],
		[Vector2(258.0, y + 57.9), Color("#d6761a"), "→"],
		[Vector2(307.3, y + 57.9), Color("#1c9c5a"), "↓"],
	]
	for spec in specs:
		var pos: Vector2 = spec[0]
		var fill: Color = spec[1]
		var depth := PanelContainer.new()
		depth.add_theme_stylebox_override("panel", RefCanvas.solid_box(fill.darkened(0.34), 4))
		RefCanvas.set_rect(depth, pos.x + 1.5, pos.y + 3.1, 21.7, 21.7)
		canvas.add_child(depth)
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(fill.lightened(0.33), fill, fill.darkened(0.14), 4))
		RefCanvas.set_rect(tile, pos.x, pos.y, 21.7, 21.7)
		canvas.add_child(tile)
		var arrow := _make_label(String(spec[2]), 13, Color.WHITE, true)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		RefCanvas.set_rect(arrow, pos.x, pos.y, 21.7, 21.7)
		canvas.add_child(arrow)
	var chick := PanelContainer.new()
	chick.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color("#ffd63d"), 8, Color("#fff1a0"), 1))
	RefCanvas.set_rect(chick, 287.5, y + 39.0, 15, 15)
	canvas.add_child(chick)
	var eye := ColorRect.new()
	eye.color = Color("#183b42")
	RefCanvas.set_rect(eye, 296.0, y + 44.9, 2, 2.5)
	canvas.add_child(eye)
	var exit := PanelContainer.new()
	exit.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#80efb0"), Color("#35b96b"), Color("#148b4c"), 5))
	RefCanvas.set_rect(exit, 329, y + 21.6, 11, 30)
	canvas.add_child(exit)

func _preview_water(canvas: Control, y: float) -> void:
	var specs := [
		[255.0, 12.6, 84.0, Color("#ffd63d"), 48.7],
		[284.0, 16.2, 79.0, Color("#ff4da3"), 56.9],
		[313.0, 12.6, 84.0, Color("#1aa8ff"), 48.7],
	]
	for spec in specs:
		var x := float(spec[0])
		var top := y + float(spec[1])
		var h := float(spec[2])
		RefCanvas.add_shadow(canvas, Rect2(x, top, 22, h), 9, Color(0.02,0.15,0.26,0.18), 3, Vector2(0,3))
		var bottle := PanelContainer.new()
		bottle.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(0.96,1.0,1.0,0.18), Color(0.82,0.97,1.0,0.08), Color(0.66,0.90,1.0,0.12), 9, Color(0.82,0.98,1.0,0.90), 1))
		RefCanvas.set_rect(bottle, x, top, 22, h)
		canvas.add_child(bottle)
		var liquid_h := float(spec[4])
		var liquid := PanelContainer.new()
		liquid.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color(spec[3]).lightened(0.08), Color(spec[3]), Color(spec[3]).darkened(0.10), 6))
		RefCanvas.set_rect(liquid, x + 3, top + h - liquid_h - 5, 16, liquid_h)
		canvas.add_child(liquid)
		var meniscus := PanelContainer.new()
		meniscus.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(spec[3]).lightened(0.10), 5))
		RefCanvas.set_rect(meniscus, x + 3, top + h - liquid_h - 7, 16, 5)
		canvas.add_child(meniscus)
		var rim := ColorRect.new()
		rim.color = Color(0.93, 0.995, 1.0, 0.92)
		RefCanvas.set_rect(rim, x - 1, top + 1, 24, 2)
		canvas.add_child(rim)
		var hi := ColorRect.new()
		hi.color = Color(1,1,1,0.46)
		RefCanvas.set_rect(hi, x + 4, top + 8, 2, h - 18)
		canvas.add_child(hi)

func _preview_block(canvas: Control, y: float) -> void:
	var board_depth := PanelContainer.new()
	board_depth.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color("#241445"), 10))
	RefCanvas.set_rect(board_depth, 253.8, y + 10.5, 84, 74)
	canvas.add_child(board_depth)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(Color("#613894"), Color("#452670"), Color("#2e1a54"), 10, Color(0.72,0.52,1.0,0.60), 1))
	RefCanvas.set_rect(board, 253, y + 7, 84, 74)
	canvas.add_child(board)
	var palette := [Color("#ffd63d"), Color("#ff7acb"), Color("#50e889"), Color("#47c8ff")]
	var occupied := [1,5,8,9,14,18,23,24,31,35,36,42,47,49,54,61]
	var cell := 7.0
	var gap := 2.0
	for row in range(8):
		for col in range(8):
			var px := 258.0 + col * (cell + gap)
			var py := y + 11.0 + row * (cell + gap)
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.23,0.16,0.37,0.98), 2, Color(0.51,0.39,0.67,0.72), 1))
			RefCanvas.set_rect(well, px, py, cell, cell)
			canvas.add_child(well)
			var idx := row * 8 + col
			if idx in occupied:
				var fill := palette[(row + col) % palette.size()]
				var depth := ColorRect.new()
				depth.color = fill.darkened(0.34)
				RefCanvas.set_rect(depth, px + 1, py + 2, cell - 1, cell - 1)
				canvas.add_child(depth)
				var top := ColorRect.new()
				top.color = fill
				RefCanvas.set_rect(top, px, py, cell - 1, cell - 2)
				canvas.add_child(top)
	# Three genuine tray shapes rather than decorative bars.
	var tray_shapes := [
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	]
	var starts := [Vector2(258,y+88),Vector2(286,y+87),Vector2(313,y+87)]
	for i in range(3):
		for p in tray_shapes[i]:
			var bit := PanelContainer.new()
			bit.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(palette[i].lightened(0.30), palette[i], palette[i].darkened(0.18), 2))
			RefCanvas.set_rect(bit, starts[i].x + p.x * 6, starts[i].y + p.y * 6, 6, 6)
			canvas.add_child(bit)

func _add_bottom_nav(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "SelectorBottomNav"
	RefCanvas.add_shadow(canvas, Rect2(13, 757, 362, 70), 18, Color(0.02,0.10,0.18,0.12), 5, Vector2(0,4))
	shell.add_theme_stylebox_override("panel", RefCanvas.solid_box(Color(0.985, 0.995, 1.0, 0.97), 18, Color(0.78, 0.88, 0.95, 0.75), 1))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)
	var active := PanelContainer.new()
	active.add_theme_stylebox_override("panel", RefCanvas.solid_box(CYAN, 16))
	RefCanvas.set_rect(active, 84, 767, 62, 48)
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
		_add_text(canvas, item[0], Rect2(item[1] - 1.0, 788, 62, 30), 12, Color(0.05, 0.49, 0.86) if item[3] else Color(0.31, 0.43, 0.54), true)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.modulate.a = 0.001
		RefCanvas.set_rect(hit, item[1] - 9, 753, 74, 78)
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
