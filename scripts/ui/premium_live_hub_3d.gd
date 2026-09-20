extends "res://scripts/ui/premium_live_hub.gd"

const RefCanvas = preload("res://scripts/ui/figma_reference_canvas.gd")

const BG_TOP := Color("#dcebe8")
const BG_MID := Color("#d4e3e8")
const BG_BOTTOM := Color("#c3d2df")
const NAVY := Color(0.03, 0.23, 0.47)
const INK := Color(0.07, 0.20, 0.35)
const MUTED := Color(0.31, 0.42, 0.52)
const OFF_WHITE := Color(1.0, 0.995, 0.97)
const CYAN := Color(0.14, 0.68, 1.0)
const DARK_TOP := Color("#182a3b")
const DARK_MID := Color("#20384b")
const DARK_BOTTOM := Color("#29465b")
const DARK_INK := Color("#eef7ff")
const DARK_MUTED := Color("#b6c7d6")

var figma_canvas: FigmaReferenceCanvas

func _selector_dark() -> bool:
	return _theme_mode() == "dark"

func _selector_text_color(color: Color) -> Color:
	if not _selector_dark():
		return color
	if color.is_equal_approx(NAVY) or color.is_equal_approx(INK):
		return DARK_INK
	if color.is_equal_approx(MUTED):
		return DARK_MUTED
	if color.get_luminance() < 0.34:
		return color.lightened(0.48)
	return color.lightened(0.06)

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
	viewport_bg.color = DARK_BOTTOM if _selector_dark() else BG_BOTTOM
	viewport_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_bg)

	figma_canvas = RefCanvas.new()
	figma_canvas.name = "FigmaSelector390x844"
	add_child(figma_canvas)
	_build_reference_selector(figma_canvas)

func _build_reference_selector(canvas: Control) -> void:
	var background := PanelContainer.new()
	var bg_top := DARK_TOP if _selector_dark() else BG_TOP
	var bg_mid := DARK_MID if _selector_dark() else BG_MID
	var bg_bottom := DARK_BOTTOM if _selector_dark() else BG_BOTTOM
	var bg_border := Color(0.22,0.36,0.48,0.82) if _selector_dark() else Color("#bad1e3")
	background.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(bg_top, bg_mid, bg_bottom, 34, bg_border, 1, 0.48))
	RefCanvas.set_rect(background, 0, 0, 390, 844)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)

	RefCanvas.add_shadow(canvas, Rect2(17, 19, 52, 52), 18, Color(0.02,0.15,0.30,0.16), 4, Vector2(0,3))
	var back := RefCanvas.premium_button("‹", 27, DARK_MUTED if _selector_dark() else NAVY, Color("#152337") if _selector_dark() else OFF_WHITE, 18)
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
	var pill_mid := Color(0.04, 0.30, 0.55)
	level_pill.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(pill_mid.lightened(0.20), pill_mid, pill_mid.darkened(0.16), 13, pill_mid.lightened(0.28), 1, 0.40))
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
	var stage_mid := Color(0.92, 1.0, 0.86, 0.50) if game_id == "rescue_rush" else (Color(0.91, 0.99, 1.0, 0.54) if game_id == "water_sort" else Color(0.94, 0.91, 1.0, 0.46))
	stage.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(stage_mid.lightened(0.12), stage_mid, stage_mid.darkened(0.10), 16, Color(1,1,1,0.24), 1, 0.40))
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
		[255.0,12.56,84.0,Color("#ff7ebd"),Color("#d64089"),41.57,48.72,38.88,19.75,68.0,10.76,85.37],
		[284.0,16.15,79.0,Color("#5ac1ff"),Color("#158dd6"),33.34,56.88,30.64,23.34,63.0,14.35,84.47],
		[313.0,12.56,84.0,Color("#5fd78f"),Color("#1ca754"),52.14,36.96,49.45,19.75,68.0,10.76,85.37],
	]
	for spec in specs:
		var x := float(spec[0])
		var top := y + float(spec[1])
		var h := float(spec[2])
		var left: Color = spec[3] as Color
		var right: Color = spec[4] as Color
		var shadow := PanelContainer.new()
		shadow.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(0.02,0.15,0.26,0.16),4))
		RefCanvas.set_rect(shadow,x,y+float(spec[11]),22,7)
		canvas.add_child(shadow)
		var bottle := PanelContainer.new()
		bottle.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(0.90,0.99,1.0,0.10),9,Color(0.82,0.98,1.0,0.90),1.3))
		RefCanvas.set_rect(bottle,x,top,22,h)
		canvas.add_child(bottle)
		var liquid := PanelContainer.new()
		liquid.add_theme_stylebox_override("panel",RefCanvas.horizontal_gradient(left,right,2))
		RefCanvas.set_rect(liquid,x+3,y+float(spec[5]),16,float(spec[6]))
		canvas.add_child(liquid)
		var meniscus := PanelContainer.new()
		meniscus.add_theme_stylebox_override("panel",RefCanvas.horizontal_gradient(left.lightened(0.08),right.lightened(0.04),3))
		RefCanvas.set_rect(meniscus,x+3,y+float(spec[7]),16,6)
		canvas.add_child(meniscus)
		var hi := ColorRect.new()
		hi.color = Color(1,1,1,0.48)
		RefCanvas.set_rect(hi,x+5,y+float(spec[8]),2,float(spec[9]))
		canvas.add_child(hi)
		var rim := PanelContainer.new()
		rim.add_theme_stylebox_override("panel",RefCanvas.horizontal_gradient(Color("#f4fdff"),Color("#cfeffc"),3,Color(0.82,0.98,1.0,0.90),0.8))
		RefCanvas.set_rect(rim,x+1,y+float(spec[10]),20,6)
		canvas.add_child(rim)

func _preview_block(canvas: Control, y: float) -> void:
	var depth := PanelContainer.new()
	depth.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color("#241447"),12))
	RefCanvas.set_rect(depth,253,y+15.25,84,90)
	canvas.add_child(depth)
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color("#4f307d"),12,Color(0.72,0.52,1.0,0.55),1))
	RefCanvas.set_rect(board,253,y+10.76,84,90)
	canvas.add_child(board)

	var cube_specs := {
		0:[Color("#b89af9"),Color("#764dce"),Color(0.263,0.173,0.463,0.40)],
		1:[Color("#71c9ff"),Color("#158dd6"),Color(0.047,0.318,0.478,0.40)],
		5:[Color("#71c9ff"),Color("#158dd6"),Color(0.047,0.318,0.478,0.40)],
		6:[Color("#75dc9f"),Color("#1ca754"),Color(0.063,0.373,0.188,0.40)],
		9:[Color("#71c9ff"),Color("#158dd6"),Color(0.047,0.318,0.478,0.40)],
		10:[Color("#75dc9f"),Color("#1ca754"),Color(0.063,0.373,0.188,0.40)],
		11:[Color("#ffb874"),Color("#d6761a"),Color(0.478,0.263,0.059,0.40)],
		14:[Color("#75dc9f"),Color("#1ca754"),Color(0.063,0.373,0.188,0.40)],
	}
	for row in range(4):
		for col in range(4):
			var index := row*4+col
			var wx := 257.0+float(col)*19.0
			var wy := y+12.56+float(row)*17.08
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color("#291a47"),3,Color(0.52,0.39,0.68,0.34),0.7))
			RefCanvas.set_rect(well,wx,wy,17,17)
			canvas.add_child(well)
			if cube_specs.has(index):
				var spec: Array = cube_specs[index]
				var top_color: Color = spec[0] as Color
				var bottom_color: Color = spec[1] as Color
				var shadow_color: Color = spec[2] as Color
				var cube_shadow := PanelContainer.new()
				cube_shadow.add_theme_stylebox_override("panel",RefCanvas.solid_box(shadow_color,3))
				RefCanvas.set_rect(cube_shadow,wx+1.5,wy+4.04,14,14)
				canvas.add_child(cube_shadow)
				var cube := PanelContainer.new()
				cube.add_theme_stylebox_override("panel",RefCanvas.rounded_gradient3(top_color,top_color.lerp(bottom_color,0.48),bottom_color,3))
				RefCanvas.set_rect(cube,wx+0.5,wy+2.24,14,14)
				canvas.add_child(cube)

	var tray := PanelContainer.new()
	tray.name = "SelectorBlockTray"
	tray.add_theme_stylebox_override("panel",RefCanvas.solid_box(Color(0.969,0.929,1.0,0.95),6,Color(0.72,0.55,0.94,0.48),0.8))
	RefCanvas.set_rect(tray,251,y+85.5,88,20)
	canvas.add_child(tray)
	_add_selector_tray_piece(canvas,[Vector2(257,y+94),Vector2(267,y+94),Vector2(277,y+94)],Color("#466df2"),Color("#749bff"))
	_add_selector_tray_piece(canvas,[Vector2(293,y+90),Vector2(293,y+100),Vector2(303,y+100)],Color("#38df63"),Color("#66ff91"))
	_add_selector_tray_piece(canvas,[Vector2(321,y+90),Vector2(331,y+90),Vector2(321,y+100),Vector2(331,y+100)],Color("#f4b83d"),Color("#ffe66b"))

	# The small silhouettes below the tray are part of the audited selector polish.
	for px in [251.0,257.0,263.0]:
		_add_selector_flat_bit(canvas,Vector2(px,y+117.5),Color("#4ad175"))
	for pos in [Vector2(281,y+114.5),Vector2(281,y+120.5),Vector2(287,y+120.5)]:
		_add_selector_flat_bit(canvas,pos,Color("#4a8cfa"))
	for pos in [Vector2(313,y+114.5),Vector2(319,y+114.5),Vector2(313,y+120.5),Vector2(319,y+120.5)]:
		_add_selector_flat_bit(canvas,pos,Color("#f57a3d"))

func _add_selector_tray_piece(canvas: Control, cells: Array, fill: Color, edge: Color) -> void:
	for value in cells:
		var pos: Vector2 = value as Vector2
		var top := Polygon2D.new()
		top.polygon = PackedVector2Array([
			Vector2(pos.x,pos.y),
			Vector2(pos.x+2.5,pos.y-2.5),
			Vector2(pos.x+9.0,pos.y-2.5),
			Vector2(pos.x+6.5,pos.y),
		])
		top.color = fill.lightened(0.28)
		canvas.add_child(top)
		var front := PanelContainer.new()
		front.add_theme_stylebox_override("panel",RefCanvas.solid_box(fill,3,Color(edge,0.85),0.8))
		RefCanvas.set_rect(front,pos.x,pos.y,6.5,6.5)
		canvas.add_child(front)

func _add_selector_flat_bit(canvas: Control, pos: Vector2, fill: Color) -> void:
	var bit := PanelContainer.new()
	bit.add_theme_stylebox_override("panel",RefCanvas.solid_box(fill,1.2))
	RefCanvas.set_rect(bit,pos.x,pos.y,5,5)
	canvas.add_child(bit)

func _add_bottom_nav(canvas: Control) -> void:
	var shell := PanelContainer.new()
	shell.name = "SelectorBottomNav"
	RefCanvas.add_shadow(canvas, Rect2(13, 757, 362, 70), 18, Color(0.02,0.10,0.18,0.12), 5, Vector2(0,4))
	var nav_fill := Color(0.07,0.10,0.17,0.98) if _selector_dark() else Color(0.985, 0.995, 1.0, 0.97)
	var nav_border := Color(0.23,0.34,0.45,0.90) if _selector_dark() else Color(0.78,0.88,0.95,0.75)
	shell.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(nav_fill.lightened(0.12), nav_fill, nav_fill.darkened(0.10), 18, nav_border, 1, 0.40))
	RefCanvas.set_rect(shell, 13, 757, 362, 70)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shell)
	var active := PanelContainer.new()
	active.add_theme_stylebox_override("panel", RefCanvas.rounded_gradient3(CYAN.lightened(0.18), CYAN, CYAN.darkened(0.14), 16, CYAN.lightened(0.24), 1, 0.40))
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
		var nav_text := (Color(0.42,0.78,1.0) if item[3] else DARK_MUTED) if _selector_dark() else (Color(0.05, 0.49, 0.86) if item[3] else Color(0.31, 0.43, 0.54))
		_add_text(canvas, item[0], Rect2(item[1] - 1.0, 788, 62, 30), 12, nav_text, true)
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
	return RefCanvas.label(text_value, font_size, _selector_text_color(color), bold)
