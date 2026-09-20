extends "res://scripts/ui/ux_shell_premium.gd"

var _tutorial_canvas: FigmaReferenceCanvas
var _tutorial_demo_root: Control

func _main() -> Node:
	var parent := get_parent()
	if parent != null:
		return parent
	return super._main()

func _build_shell() -> void:
	if tutorial_layer != null:
		return
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.layer = 900
	add_child(tutorial_layer)

	# These compatibility controls remain available to the inherited shell state,
	# but Figma owns visible Help/Theme entry points.
	help_button = Button.new()
	help_button.name = "HiddenGameplayHelpCompatibility"
	help_button.visible = false
	help_button.pressed.connect(func(): show_tutorial(_current_game()))
	tutorial_layer.add_child(help_button)
	theme_button = Button.new()
	theme_button.name = "HiddenThemeCompatibility"
	theme_button.visible = false
	theme_button.pressed.connect(_toggle_theme)
	tutorial_layer.add_child(theme_button)

	var dim := ColorRect.new()
	dim.name = "TutorialDim"
	dim.color = Color(Color("#0a4f94"), 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_layer.add_child(dim)

	_tutorial_canvas = FigmaReferenceCanvas.new()
	_tutorial_canvas.name = "FigmaTutorial390x844"
	_tutorial_canvas.visible = false
	tutorial_layer.add_child(_tutorial_canvas)

	var backdrop := PanelContainer.new()
	backdrop.name = "TutorialBackdrop"
	backdrop.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		Color("#f0fcff"), Color("#fafcff"), Color("#e4f8ec"), 34, Color("#b8d1e0"), 1, 0.48
	))
	FigmaReferenceCanvas.set_rect(backdrop, 0, 0, 390, 844)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(backdrop)

	var halo := PanelContainer.new()
	halo.name = "TutorialHalo"
	halo.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(0.13,0.78,0.39,0.10), 55))
	FigmaReferenceCanvas.set_rect(halo, 109, 159, 170, 110)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(halo)

	var canvas_dim := ColorRect.new()
	canvas_dim.name = "TutorialCanvasDim"
	canvas_dim.color = Color(Color("#0a4f94"), 0.55)
	canvas_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FigmaReferenceCanvas.set_rect(canvas_dim, -1, -1, 390, 844)
	_tutorial_canvas.add_child(canvas_dim)

	var rail := ColorRect.new()
	rail.name = "TutorialAccentRail"
	rail.color = Color(Color("#21c763"), 0.88)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FigmaReferenceCanvas.set_rect(rail, -1, 11, 5, 820)
	_tutorial_canvas.add_child(rail)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(17,45,354,682), 24, Color(0.03,0.11,0.20,0.16), 5, Vector2(0,5))
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(
		Color("#fffef8"),Color("#fbfaf4"),Color("#f6f5ef"),24,Color(0.13,0.78,0.39,0.32),1.2,0.50
	))
	FigmaReferenceCanvas.set_rect(tutorial_panel,17,45,354,682)
	tutorial_panel.visible = true
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_canvas.add_child(tutorial_panel)

	var eyebrow := FigmaReferenceCanvas.label("QUICK PLAY GUIDE",12,Color("#21c763"),true)
	eyebrow.name = "TutorialEyebrow"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(eyebrow,117,68,154,15)
	_tutorial_canvas.add_child(eyebrow)

	tutorial_title = FigmaReferenceCanvas.label("",28,Color(0.03,0.23,0.47),true)
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(tutorial_title,69,94,250,38)
	_tutorial_canvas.add_child(tutorial_title)

	tutorial_body = FigmaReferenceCanvas.label("",14,Color(0.31,0.42,0.52),false)
	tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(tutorial_body,43,138,302,54)
	_tutorial_canvas.add_child(tutorial_body)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(43,207,302,184), 20, Color(0.03,0.11,0.20,0.16), 5, Vector2(0,5))
	var demo_panel := PanelContainer.new()
	demo_panel.name = "TutorialDemoPanel"
	demo_panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(
		Color("#e9fdef"),Color("#e3f8e9"),Color("#ddf4e5"),20,Color(0.13,0.78,0.39,0.32),1.2,0.50
	))
	FigmaReferenceCanvas.set_rect(demo_panel,43,207,302,184)
	demo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(demo_panel)
	_tutorial_demo_root = Control.new()
	_tutorial_demo_root.name = "TutorialDemoArt"
	FigmaReferenceCanvas.set_rect(_tutorial_demo_root,43,207,302,184)
	_tutorial_demo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(_tutorial_demo_root)

	tutorial_demo = Label.new()
	tutorial_demo.visible = false
	_tutorial_canvas.add_child(tutorial_demo)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(43,409,302,76), 17, Color(0.03,0.10,0.20,0.16), 3, Vector2(0,3))
	var step_card := PanelContainer.new()
	step_card.name = "TutorialStepCard"
	step_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(Color("#f7fbff"), Color("#eef6fb"), Color("#e5eff5"), 16, Color(0.35,0.58,0.72,0.30), 1.0, 0.42))
	FigmaReferenceCanvas.set_rect(step_card,43,409,302,76)
	step_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(step_card)

	tutorial_step_label = FigmaReferenceCanvas.label("",14,Color(0.07,0.20,0.35),false)
	tutorial_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(tutorial_step_label,57,417,274,58)
	_tutorial_canvas.add_child(tutorial_step_label)

	tutorial_progress_label = FigmaReferenceCanvas.label("STEP 1 OF 3",12,Color(0.31,0.42,0.52),true)
	tutorial_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(tutorial_progress_label,147,495,94,16)
	_tutorial_canvas.add_child(tutorial_progress_label)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(43,526,142,48), 16, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	tutorial_prev_button = FigmaReferenceCanvas.premium_button("‹ BACK",12,Color.WHITE,Color("#c7d6e3"),16,Color("#d0dde7"),1.2)
	tutorial_prev_button.name = "TutorialPrevious"
	FigmaReferenceCanvas.set_rect(tutorial_prev_button,43,526,142,48)
	tutorial_prev_button.pressed.connect(_tutorial_previous)
	_tutorial_canvas.add_child(tutorial_prev_button)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(203,526,142,48), 16, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	tutorial_next_button = FigmaReferenceCanvas.premium_button("NEXT ›",12,Color.WHITE,Color("#21c763"),16,Color("#74d999"),1.2)
	tutorial_next_button.name = "TutorialNext"
	FigmaReferenceCanvas.set_rect(tutorial_next_button,203,526,142,48)
	tutorial_next_button.pressed.connect(_tutorial_next)
	_tutorial_canvas.add_child(tutorial_next_button)

	FigmaReferenceCanvas.add_shadow(_tutorial_canvas, Rect2(43,598,302,58), 17, Color(0.03,0.10,0.20,0.22), 4, Vector2(0,4))
	var close := FigmaReferenceCanvas.premium_button("PLAY NOW",14,Color.WHITE,Color("#21c763"),17,Color("#74d999"),1.2)
	close.name = "TutorialClose"
	FigmaReferenceCanvas.set_rect(close,43,598,302,58)
	close.pressed.connect(hide_tutorial)
	_tutorial_canvas.add_child(close)

	_sync_shell(_current_surface())

func _after_shell_sync() -> void:
	if help_button != null:
		help_button.visible = false
	if theme_button != null:
		theme_button.visible = false

func _apply_theme() -> void:
	if help_button != null:
		help_button.visible = false
	if theme_button != null:
		theme_button.visible = false
	apply_theme_mode(theme_mode == "dark")
	if _tutorial_canvas != null and is_instance_valid(_tutorial_canvas):
		_apply_figma_tutorial_theme(tutorial_game)

func apply_theme_mode(dark: bool) -> void:
	var main := _main()
	if main == null:
		return
	var game: Node = main.get("active_game") as Node
	if game == null or not is_instance_valid(game):
		game = main.get_node_or_null("ActiveGame")
	if game != null and game.has_method("apply_theme_mode"):
		game.call("apply_theme_mode",dark)

func _layout_tutorial_panel() -> void:
	# Reference canvas owns all geometry and viewport scaling.
	pass

func _layout_help_button() -> void:
	if help_button != null:
		help_button.visible = false

func _restyle_3d_shell() -> void:
	pass

func show_tutorial(game_id: String = "rescue_rush") -> void:
	if tutorial_panel == null or _tutorial_canvas == null:
		return
	tutorial_game = game_id
	tutorial_step_index = 0
	_apply_figma_tutorial_theme(game_id)
	tutorial_title.text = _game_name(game_id)
	match game_id:
		"water_sort":
			tutorial_body.text = "Sort every colour into its own tube. You only need three ideas."
			tutorial_steps = [
				"Tap a tube with liquid, then tap the tube you want to pour into.",
				"Pour only into an empty tube or onto the same colour. Each tube holds four layers.",
				"Use empty tubes as breathing room. UNDO repairs a mistake; HINT reveals a safe move."
			]
		"block_puzzle":
			tutorial_body.text = "Place all three shapes, clear lines and protect your future space."
			tutorial_steps = [
				"Touch and hold a piece. It lifts so the board stays visible.",
				"Drag to a valid position and release. Complete rows or columns disappear immediately.",
				"Look at all three pieces before committing. Keep the centre and long lanes flexible."
			]
		_:
			tutorial_body.text = "Free the trapped character by opening a clear route to the edge."
			tutorial_steps = [
				"Read the arrow. A piece can leave only in the direction it points.",
				"Tap it only when every square from the piece to the edge is clear.",
				"Special pieces can open gates or trigger chains. Clear the rescue lane to finish."
			]
	_render_tutorial_step()
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = true
	_tutorial_canvas.visible = true
	tutorial_panel.visible = true
	help_button.visible = false
	theme_button.visible = false

func _apply_figma_tutorial_theme(game_id: String) -> void:
	var dark := theme_mode == "dark"
	var accent := Color("#21c763")
	var bottom := Color("#e4f8ec")
	var demo_top := Color("#e9fdef")
	var demo_bottom := Color("#ddf4e5")
	match game_id:
		"water_sort":
			accent = Color("#1aa8ff")
			bottom = Color("#e3f5ff")
			demo_top = Color("#e9f8ff")
			demo_bottom = Color("#ddeff6")
		"block_puzzle":
			accent = Color("#c73dff")
			bottom = Color("#f5eafd")
			demo_top = Color("#fbefff")
			demo_bottom = Color("#f1e5f6")
	var backdrop := _tutorial_canvas.get_node_or_null("TutorialBackdrop") as PanelContainer
	if backdrop != null:
		var backdrop_top := Color("#182a3b") if dark else Color("#dcebe8")
		var backdrop_mid := Color("#20384b") if dark else Color("#d4e3e8")
		var backdrop_bottom := Color("#29465b").lerp(accent.darkened(0.58),0.08) if dark else Color("#c3d2df").lerp(bottom,0.16)
		var backdrop_border := Color(0.22,0.36,0.48,0.82) if dark else Color("#b8d1e0")
		backdrop.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
			backdrop_top, backdrop_mid, backdrop_bottom, 34, backdrop_border, 1, 0.48
		))
	var halo := _tutorial_canvas.get_node_or_null("TutorialHalo") as PanelContainer
	if halo != null:
		halo.add_theme_stylebox_override("panel", FigmaReferenceCanvas.solid_box(Color(accent,0.10),55))
	var rail := _tutorial_canvas.get_node_or_null("TutorialAccentRail") as ColorRect
	if rail != null:
		rail.color = Color(accent,0.88)
	tutorial_panel.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
		Color("#172238") if dark else Color("#fffef8"),
		Color("#131e31") if dark else Color("#fbfaf4"),
		Color("#0f1828") if dark else Color("#f6f5ef"),
		24, Color(accent,0.62 if dark else 0.32), 1.2, 0.50
	))
	var step_card := _tutorial_canvas.get_node_or_null("TutorialStepCard") as PanelContainer
	if step_card != null:
		var step_mid := Color("#1a3042") if dark else Color("#eef6fb")
		step_card.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
			step_mid.lightened(0.12), step_mid, step_mid.darkened(0.10), 16, Color(accent,0.42 if dark else 0.28), 1.0, 0.40
		))
	var demo_panel := _tutorial_canvas.get_node_or_null("TutorialDemoPanel") as PanelContainer
	if demo_panel != null:
		var resolved_demo_top := Color("#122b2a").lerp(accent.darkened(0.58),0.16) if dark else demo_top
		var resolved_demo_bottom := Color("#0c1e22").lerp(accent.darkened(0.68),0.12) if dark else demo_bottom
		demo_panel.add_theme_stylebox_override("panel", FigmaReferenceCanvas.rounded_gradient3(
			resolved_demo_top, resolved_demo_top.lerp(resolved_demo_bottom,0.48), resolved_demo_bottom, 20, Color(accent,0.62 if dark else 0.32), 1.2, 0.50
		))
	var eyebrow := _tutorial_canvas.get_node_or_null("TutorialEyebrow") as Label
	if eyebrow != null:
		eyebrow.add_theme_color_override("font_color",accent)
	if tutorial_title != null:
		tutorial_title.add_theme_color_override("font_color", Color("#eef7ff") if dark else Color(0.03,0.23,0.47))
	if tutorial_body != null:
		tutorial_body.add_theme_color_override("font_color", Color("#b6c7d6") if dark else Color(0.31,0.42,0.52))
	if tutorial_step_label != null:
		tutorial_step_label.add_theme_color_override("font_color", Color("#dceaf5") if dark else Color(0.07,0.20,0.35))
	if tutorial_progress_label != null:
		tutorial_progress_label.add_theme_color_override("font_color",accent)
	_style_figma_tutorial_button(tutorial_prev_button, Color("#24364a") if dark else Color("#c7d6e3"))
	_style_figma_tutorial_button(tutorial_next_button,accent)
	var close := _tutorial_canvas.get_node_or_null("TutorialClose") as Button
	if close != null:
		_style_figma_tutorial_button(close,accent)

func _style_figma_tutorial_button(button: Button, fill: Color) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal",FigmaReferenceCanvas.rounded_gradient3(fill.lightened(0.18),fill,fill.darkened(0.18),16,fill.lightened(0.30),1.2))
	button.add_theme_stylebox_override("hover",FigmaReferenceCanvas.rounded_gradient3(fill.lightened(0.24),fill.lightened(0.05),fill.darkened(0.13),16,fill.lightened(0.38),1.2))
	button.add_theme_stylebox_override("pressed",FigmaReferenceCanvas.rounded_gradient3(fill,fill.darkened(0.08),fill.darkened(0.25),16,fill.lightened(0.20),1.2))

func _render_tutorial_step() -> void:
	if tutorial_steps.is_empty() or tutorial_step_label == null:
		return
	tutorial_step_index = clampi(tutorial_step_index,0,tutorial_steps.size()-1)
	tutorial_step_label.text = tutorial_steps[tutorial_step_index]
	tutorial_progress_label.text = "STEP %d OF %d" % [tutorial_step_index+1,tutorial_steps.size()]
	tutorial_prev_button.disabled = tutorial_step_index <= 0
	tutorial_next_button.disabled = tutorial_step_index >= tutorial_steps.size()-1
	tutorial_next_button.text = "READY ✓" if tutorial_next_button.disabled else "NEXT ›"
	_render_figma_demo(tutorial_game,tutorial_step_index)

func hide_tutorial() -> void:
	if tutorial_panel == null or _tutorial_canvas == null:
		return
	tutorial_seen[tutorial_game] = true
	_save_config()
	_tutorial_canvas.visible = false
	tutorial_panel.visible = false
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = false
	_sync_shell(_current_surface())

func _render_figma_demo(game_id: String, step: int) -> void:
	for child in _tutorial_demo_root.get_children():
		child.queue_free()
	match game_id:
		"water_sort": _demo_water(step)
		"block_puzzle": _demo_block(step)
		_: _demo_rescue(step)

func _demo_water(step: int) -> void:
	var colors: Array[Color] = [Color("#ff4da3"),Color("#1fabff"),Color("#ff4da3")]
	for i in range(3):
		var x := 56.0 + float(i)*74.0
		var glass := PanelContainer.new()
		glass.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.92,0.99,1.0,0.12),18,Color(0.74,0.95,1.0,0.96),1.5))
		FigmaReferenceCanvas.set_rect(glass,x,24,44,126)
		_tutorial_demo_root.add_child(glass)
		var liquid_h: float = float([62.0,82.0,36.0][i])
		if step == 1 and i == 2:
			liquid_h = 62.0
		var liquid := ColorRect.new()
		liquid.color = colors[i]
		FigmaReferenceCanvas.set_rect(liquid,x+6,142-liquid_h,32,liquid_h)
		_tutorial_demo_root.add_child(liquid)
		var meniscus := PanelContainer.new()
		meniscus.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(colors[i].lightened(0.08),5))
		FigmaReferenceCanvas.set_rect(meniscus,x+6,137-liquid_h,32,10)
		_tutorial_demo_root.add_child(meniscus)
		var rim := PanelContainer.new()
		rim.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.90,0.99,1.0,0.92),5))
		FigmaReferenceCanvas.set_rect(rim,x+4,20,36,10)
		_tutorial_demo_root.add_child(rim)
		var highlight := ColorRect.new()
		highlight.color = Color(1,1,1,0.44)
		FigmaReferenceCanvas.set_rect(highlight,x+9,36,2.5,94)
		_tutorial_demo_root.add_child(highlight)
	if step == 0:
		var arc := Line2D.new()
		arc.width = 5
		arc.default_color = Color("#1fabff")
		arc.points = PackedVector2Array([Vector2(93,44),Vector2(117,18),Vector2(149,14),Vector2(174,37)])
		arc.antialiased = true
		_tutorial_demo_root.add_child(arc)

func _demo_block(step: int) -> void:
	for row in range(4):
		for col in range(4):
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("#3b295e"),6,Color(0.51,0.39,0.67,0.60),1))
			FigmaReferenceCanvas.set_rect(well,56+col*39,16+row*39,36,36)
			_tutorial_demo_root.add_child(well)
	var occupied := [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(3,2),Vector2i(3,3)]
	for pos in occupied:
		var fx: float = 59.0 + float(pos.x) * 39.0
		var fy: float = 21.0 + float(pos.y) * 39.0
		var shadow := ColorRect.new()
		shadow.color = Color(0.25,0.16,0.43,0.34)
		FigmaReferenceCanvas.set_rect(shadow,fx+3,fy+25,23,3)
		_tutorial_demo_root.add_child(shadow)
		var top := Polygon2D.new()
		top.polygon = PackedVector2Array([Vector2(fx,fy),Vector2(fx+3,fy-3),Vector2(fx+30,fy-3),Vector2(fx+27,fy)])
		top.color = Color("#b68aff")
		_tutorial_demo_root.add_child(top)
		var cell := PanelContainer.new()
		cell.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("#8c5cf5"),5,Color(0.73,0.54,1.0,0.90),1.2))
		FigmaReferenceCanvas.set_rect(cell,fx,fy,27,27)
		_tutorial_demo_root.add_child(cell)
	var target_row := 2 if step < 2 else 1
	for col in range(1,4):
		var footprint := PanelContainer.new()
		footprint.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.27,0.43,0.95,0.08),6,Color(0.58,0.72,1.0,0.96),2))
		FigmaReferenceCanvas.set_rect(footprint,58+col*39,18+target_row*39,32,32)
		_tutorial_demo_root.add_child(footprint)
	if step < 2:
		for col in range(1,4):
			var gx := 59.0 + col*39.0
			var gy := 52.0
			var ghost_shadow := ColorRect.new()
			ghost_shadow.color = Color(0.12,0.19,0.43,0.34)
			FigmaReferenceCanvas.set_rect(ghost_shadow,gx+3,gy+25,23,3)
			_tutorial_demo_root.add_child(ghost_shadow)
			var ghost_top := Polygon2D.new()
			ghost_top.polygon = PackedVector2Array([Vector2(gx,gy),Vector2(gx+3,gy-3),Vector2(gx+30,gy-3),Vector2(gx+27,gy)])
			ghost_top.color = Color("#739cff")
			_tutorial_demo_root.add_child(ghost_top)
			var ghost := PanelContainer.new()
			ghost.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("#456ef2"),5,Color(0.45,0.61,1.0,0.90),1.2))
			FigmaReferenceCanvas.set_rect(ghost,gx,gy,27,27)
			_tutorial_demo_root.add_child(ghost)

func _demo_rescue(step: int) -> void:
	var colors: Array[Color] = [Color("#26c26b"),Color("#8f5ceb"),Color("#26c26b"),Color("#ff8f1f"),Color("#26c26b"),Color("#8f5ceb"),Color("#ff8f1f")]
	var positions := [Vector2(39,16),Vector2(98,16),Vector2(39,75),Vector2(157,75),Vector2(39,134),Vector2(98,134),Vector2(157,134)]
	for i in range(positions.size()):
		var tint: Color = colors[i]
		var depth := PanelContainer.new()
		depth.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(tint.darkened(0.38),10))
		FigmaReferenceCanvas.set_rect(depth,positions[i].x+2,positions[i].y+6,50,48)
		_tutorial_demo_root.add_child(depth)
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(tint.lightened(0.28),tint,tint.darkened(0.12),10,Color(1,1,1,0.42),1))
		FigmaReferenceCanvas.set_rect(tile,positions[i].x,positions[i].y,50,47)
		_tutorial_demo_root.add_child(tile)
		var arrow := FigmaReferenceCanvas.label("→" if i in [0,4,6] else "↑",22,Color.WHITE,true)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FigmaReferenceCanvas.set_rect(arrow,positions[i].x,positions[i].y,50,47)
		_tutorial_demo_root.add_child(arrow)
	var chick_shadow := PanelContainer.new()
	chick_shadow.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.04,0.18,0.12,0.20),8))
	FigmaReferenceCanvas.set_rect(chick_shadow,110,110,30,9)
	_tutorial_demo_root.add_child(chick_shadow)
	var chick := PanelContainer.new()
	chick.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("#ffd63d"),14,Color("#fff1a0"),1))
	FigmaReferenceCanvas.set_rect(chick,111,87,28,28)
	_tutorial_demo_root.add_child(chick)
	var exit := PanelContainer.new()
	exit.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(Color("#80efb0"),Color("#35b96b"),Color("#148b4c"),10))
	FigmaReferenceCanvas.set_rect(exit,168,21,30,44)
	_tutorial_demo_root.add_child(exit)
	var exit_label := FigmaReferenceCanvas.label("EXIT",12,Color("#1f8c52"),true)
	FigmaReferenceCanvas.set_rect(exit_label,161,69,44,14)
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_demo_root.add_child(exit_label)
	if step == 1:
		var blocker := PanelContainer.new()
		blocker.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("#4c5667"),10))
		FigmaReferenceCanvas.set_rect(blocker,157,75,50,47)
		_tutorial_demo_root.add_child(blocker)
