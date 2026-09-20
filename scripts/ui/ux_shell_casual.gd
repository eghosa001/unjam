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
	dim.color = Color(0.015,0.025,0.045,0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_layer.add_child(dim)

	_tutorial_canvas = FigmaReferenceCanvas.new()
	_tutorial_canvas.name = "FigmaTutorial390x844"
	_tutorial_canvas.visible = false
	tutorial_layer.add_child(_tutorial_canvas)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(
		Color(0.995,0.998,1.0),Color(0.94,0.98,0.99),24,Color(0.70,0.86,0.95,0.65),1
	))
	FigmaReferenceCanvas.set_rect(tutorial_panel,18,54,354,650)
	tutorial_panel.visible = true
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_canvas.add_child(tutorial_panel)

	var eyebrow := FigmaReferenceCanvas.label("QUICK PLAY GUIDE",12,Color(0.31,0.42,0.52),true)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(eyebrow,118,76,154,15)
	_tutorial_canvas.add_child(eyebrow)

	tutorial_title = FigmaReferenceCanvas.label("",28,Color(0.03,0.23,0.47),true)
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(tutorial_title,70,104,250,34)
	_tutorial_canvas.add_child(tutorial_title)

	tutorial_body = FigmaReferenceCanvas.label("",14,Color(0.31,0.42,0.52),false)
	tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(tutorial_body,44,150,302,42)
	_tutorial_canvas.add_child(tutorial_body)

	var demo_panel := PanelContainer.new()
	demo_panel.name = "TutorialDemoPanel"
	demo_panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(
		Color(0.94,0.98,1.0),Color(0.88,0.95,0.98),20,Color(0.68,0.84,0.94,0.60),1
	))
	FigmaReferenceCanvas.set_rect(demo_panel,44,222,302,190)
	demo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(demo_panel)
	_tutorial_demo_root = Control.new()
	_tutorial_demo_root.name = "TutorialDemoArt"
	FigmaReferenceCanvas.set_rect(_tutorial_demo_root,44,222,302,190)
	_tutorial_demo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_canvas.add_child(_tutorial_demo_root)

	tutorial_demo = Label.new()
	tutorial_demo.visible = false
	_tutorial_canvas.add_child(tutorial_demo)

	tutorial_step_label = FigmaReferenceCanvas.label("",14,Color(0.07,0.20,0.35),false)
	tutorial_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(tutorial_step_label,65,320,260,46)
	_tutorial_canvas.add_child(tutorial_step_label)

	tutorial_progress_label = FigmaReferenceCanvas.label("STEP 1 OF 3",12,Color(0.31,0.42,0.52),true)
	tutorial_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(tutorial_progress_label,148,438,94,15)
	_tutorial_canvas.add_child(tutorial_progress_label)

	tutorial_prev_button = FigmaReferenceCanvas.button("‹ BACK",12,Color(0.03,0.23,0.47),Color(0.96,0.985,1.0),16,Color(0.64,0.80,0.92),1)
	tutorial_prev_button.name = "TutorialPrevious"
	FigmaReferenceCanvas.set_rect(tutorial_prev_button,44,472,142,48)
	tutorial_prev_button.pressed.connect(_tutorial_previous)
	_tutorial_canvas.add_child(tutorial_prev_button)

	tutorial_next_button = FigmaReferenceCanvas.button("NEXT ›",12,Color.WHITE,Color(0.03,0.43,0.78),16,Color(0.48,0.74,0.92),1)
	tutorial_next_button.name = "TutorialNext"
	FigmaReferenceCanvas.set_rect(tutorial_next_button,204,472,142,48)
	tutorial_next_button.pressed.connect(_tutorial_next)
	_tutorial_canvas.add_child(tutorial_next_button)

	var close := FigmaReferenceCanvas.button("PLAY NOW",14,Color.WHITE,Color(0.13,0.78,0.39),17,Color(0.51,0.90,0.64),1)
	close.name = "TutorialClose"
	FigmaReferenceCanvas.set_rect(close,44,548,302,58)
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
	var colors := [Color("ff4f9c"),Color("19a9e8"),Color("f4cf25")]
	for i in range(3):
		var x := 56.0 + float(i)*74.0
		var glass := PanelContainer.new()
		glass.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.92,0.99,1.0,0.20),18,Color("a6e7ff"),1))
		FigmaReferenceCanvas.set_rect(glass,x,20,44,126)
		_tutorial_demo_root.add_child(glass)
		var liquid_h: float = float([62.0,82.0,36.0][i])
		if step == 1 and i == 2:
			liquid_h = 62.0
		var liquid := ColorRect.new()
		liquid.color = colors[i]
		FigmaReferenceCanvas.set_rect(liquid,x+6,138-liquid_h,32,liquid_h)
		_tutorial_demo_root.add_child(liquid)
		var meniscus := PanelContainer.new()
		meniscus.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(colors[i].lightened(0.08),5))
		FigmaReferenceCanvas.set_rect(meniscus,x+6,133-liquid_h,32,10)
		_tutorial_demo_root.add_child(meniscus)
	if step == 0:
		var arc := Line2D.new()
		arc.width = 5
		arc.default_color = Color("19a9e8")
		arc.points = PackedVector2Array([Vector2(100,42),Vector2(124,16),Vector2(156,12),Vector2(181,35)])
		arc.antialiased = true
		_tutorial_demo_root.add_child(arc)

func _demo_block(step: int) -> void:
	for row in range(4):
		for col in range(4):
			var well := PanelContainer.new()
			well.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.18,0.10,0.33),6))
			FigmaReferenceCanvas.set_rect(well,56+col*39,16+row*39,36,36)
			_tutorial_demo_root.add_child(well)
	var occupied := [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(3,2),Vector2i(3,3)]
	for pos in occupied:
		var cell := PanelContainer.new()
		cell.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(Color("ff8bd0"),Color("d84cad"),5))
		FigmaReferenceCanvas.set_rect(cell,59+pos.x*39,21+pos.y*39,27,27)
		_tutorial_demo_root.add_child(cell)
	var target_row := 2 if step < 2 else 1
	for col in range(1,4):
		var footprint := PanelContainer.new()
		footprint.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.20,0.80,1.0,0.18),6,Color("52d8ff"),1))
		FigmaReferenceCanvas.set_rect(footprint,58+col*39,18+target_row*39,32,32)
		_tutorial_demo_root.add_child(footprint)

func _demo_rescue(step: int) -> void:
	var colors := [Color("2da5ff"),Color("8b6df0"),Color("3dcc78"),Color("ef5d68")]
	var positions := [Vector2(41,16),Vector2(100,16),Vector2(41,75),Vector2(159,75),Vector2(41,134),Vector2(100,134),Vector2(159,134)]
	for i in range(positions.size()):
		var tile := PanelContainer.new()
		var tint: Color = colors[i%colors.size()] as Color
		tile.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(tint.lightened(0.08),tint.darkened(0.08),10))
		FigmaReferenceCanvas.set_rect(tile,positions[i].x,positions[i].y,50,47)
		_tutorial_demo_root.add_child(tile)
		var arrow := FigmaReferenceCanvas.label("→" if i%2==0 else "↑",22,Color.WHITE,true)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FigmaReferenceCanvas.set_rect(arrow,positions[i].x,positions[i].y,50,47)
		_tutorial_demo_root.add_child(arrow)
	var chick := PanelContainer.new()
	chick.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("ffd34f"),14))
	FigmaReferenceCanvas.set_rect(chick,113,87,28,28)
	_tutorial_demo_root.add_child(chick)
	var exit := PanelContainer.new()
	exit.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color(0.13,0.78,0.39,0.20),12,Color("3dcc78"),2))
	FigmaReferenceCanvas.set_rect(exit,168,20,30,44)
	_tutorial_demo_root.add_child(exit)
	var exit_label := FigmaReferenceCanvas.label("EXIT",12,Color("208a4c"),true)
	FigmaReferenceCanvas.set_rect(exit_label,161,68,44,14)
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_demo_root.add_child(exit_label)
	if step == 1:
		var blocker := PanelContainer.new()
		blocker.add_theme_stylebox_override("panel",FigmaReferenceCanvas.solid_box(Color("4c5667"),10))
		FigmaReferenceCanvas.set_rect(blocker,159,75,50,47)
		_tutorial_demo_root.add_child(blocker)
