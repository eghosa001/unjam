extends Node

var tutorial_layer: CanvasLayer
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_body: Label
var help_button: Button
var logo: TextureRect
var tutorial_game := "rescue_rush"
var seen_this_session := {}

const INK := Color("24324a")
const MUTED := Color("667085")
const SURFACE := Color("f6f4fb")
const SURFACE_2 := Color("eef5fb")
const BORDER := Color("cad4e3")
const ACCENT := Color("5c67d8")
const ACCENT_SOFT := Color("e5e7ff")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_build_shell")
	call_deferred("_restyle_tree")

func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_handle_back()
		get_viewport().set_input_as_handled()

func _build_shell() -> void:
	if tutorial_layer != null:
		return
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.layer = 900
	add_child(tutorial_layer)
	help_button = Button.new()
	help_button.text = "?  HOW TO PLAY"
	help_button.custom_minimum_size = Vector2(220, 64)
	help_button.position = Vector2(36, 1820)
	help_button.add_theme_font_size_override("font_size", 18)
	help_button.add_theme_stylebox_override("normal", _box(Color("ffffffdd"), 24, BORDER, 2))
	help_button.add_theme_stylebox_override("pressed", _box(ACCENT_SOFT, 24, ACCENT, 2))
	help_button.add_theme_color_override("font_color", INK)
	help_button.pressed.connect(func(): show_tutorial(_current_game()))
	tutorial_layer.add_child(help_button)
	logo = TextureRect.new()
	logo.texture = load("res://assets/icon.svg")
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(112, 112)
	logo.size = Vector2(112, 112)
	logo.position = Vector2(42, 34)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_layer.add_child(logo)
	var dim := ColorRect.new()
	dim.name = "TutorialDim"
	dim.color = Color(0.08, 0.10, 0.16, 0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_layer.add_child(dim)
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.position = Vector2(-430, -560)
	tutorial_panel.custom_minimum_size = Vector2(860, 1120)
	tutorial_panel.add_theme_stylebox_override("panel", _box(Color("fbfbff"), 34, Color("bbc5da"), 2))
	tutorial_panel.visible = false
	tutorial_layer.add_child(tutorial_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 34)
	tutorial_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)
	tutorial_title = Label.new()
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_title.add_theme_font_size_override("font_size", 36)
	tutorial_title.add_theme_color_override("font_color", INK)
	box.add_child(tutorial_title)
	tutorial_body = Label.new()
	tutorial_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.add_theme_font_size_override("font_size", 25)
	tutorial_body.add_theme_color_override("font_color", INK)
	box.add_child(tutorial_body)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var b := Button.new()
		b.text = _game_name(game_id)
		b.custom_minimum_size = Vector2(245, 66)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(show_tutorial.bind(game_id))
		tabs.add_child(b)
	var close := Button.new()
	close.text = "GOT IT — PLAY"
	close.custom_minimum_size = Vector2(0, 84)
	close.add_theme_font_size_override("font_size", 23)
	close.add_theme_stylebox_override("normal", _box(ACCENT, 24, ACCENT, 1))
	close.add_theme_color_override("font_color", Color.WHITE)
	close.pressed.connect(hide_tutorial)
	box.add_child(close)

func _process(_delta: float) -> void:
	var main := _main()
	if main == null or help_button == null:
		return
	var raw_surface = main.get("current_surface")
	var surface := String(raw_surface) if raw_surface != null else "home"
	help_button.visible = surface in ["home", "levels", "game"] and not tutorial_panel.visible
	logo.visible = surface == "home" and not tutorial_panel.visible
	if surface == "game":
		var game_id := _current_game()
		if not bool(seen_this_session.get(game_id, false)):
			seen_this_session[game_id] = true
			call_deferred("show_tutorial", game_id)

func _handle_back() -> void:
	if tutorial_panel != null and tutorial_panel.visible:
		hide_tutorial()
		return
	var main := _main()
	if main == null:
		return
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.get("overlay") != null:
		var overlay = hub.get("overlay")
		if is_instance_valid(overlay) and overlay.visible:
			hub.call("_close_shop")
			return
	var raw_surface = main.get("current_surface")
	var surface := String(raw_surface) if raw_surface != null else "home"
	if surface == "game":
		var active = main.get("active_game")
		if active != null and is_instance_valid(active):
			if active.has_signal("quit_requested"):
				active.emit_signal("quit_requested")
				return
			if active.has_method("_quit"):
				active.call("_quit")
				return
		main.call("build_home")
	elif surface != "home":
		main.call("build_home")
	else:
		get_tree().quit()

func show_tutorial(game_id: String = "rescue_rush") -> void:
	if tutorial_panel == null:
		return
	tutorial_game = game_id
	tutorial_title.text = _game_name(game_id) + " — HOW TO PLAY"
	match game_id:
		"water_sort":
			tutorial_body.text = "GOAL\nPut each colour into its own tube.\n\nHOW\n1. Tap a tube that contains liquid.\n2. Tap another tube to pour into it.\n3. You can pour only into an empty tube or onto the same colour.\n4. A tube holds four layers.\n\nTIP\nUse empty tubes as temporary space. UNDO reverses your last pour and HINT suggests a legal move."
		"block_puzzle":
			tutorial_body.text = "GOAL\nPlace the available shapes and clear complete rows or columns.\n\nHOW\n1. Touch and hold a piece.\n2. Drag it onto the board — the piece follows your finger above the touch point so you can see the target.\n3. Release over a valid position to place it.\n4. Clear lines to keep space open and build combos.\n\nTIP\nPlan all three pieces before using the tight spaces."
		_:
			tutorial_body.text = "GOAL\nFree the trapped character by sending every arrow block out of the board.\n\nHOW\n1. Each arrow moves only in the direction it points.\n2. Tap an arrow only when its entire path to the edge is clear.\n3. Escaping arrows can trigger special pieces and chain reactions.\n4. Clear the path around the rescue character to complete the level.\n\nTIP\nLook from the outside edges inward. HINT highlights a useful move and UNDO reverses mistakes."
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = true
	tutorial_panel.visible = true
	help_button.visible = false
	logo.visible = false

func hide_tutorial() -> void:
	if tutorial_panel == null:
		return
	tutorial_panel.visible = false
	var dim := tutorial_layer.get_node("TutorialDim") as ColorRect
	dim.visible = false

func _current_game() -> String:
	var main := _main()
	if main != null:
		var game_value = main.get("selected_game_id")
		if game_value != null:
			return String(game_value)
	return "rescue_rush"

func _game_name(game_id: String) -> String:
	match game_id:
		"water_sort": return "WATER SORT"
		"block_puzzle": return "BLOCK PUZZLE"
		_: return "RESCUE RUSH"

func _main() -> Node:
	return get_tree().current_scene

func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_soften_control", node)

func _restyle_tree() -> void:
	var root := get_tree().current_scene
	if root != null:
		_soften_control(root)

func _soften_control(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Button and not node is WaterTubeButton and not node is BlockPieceButton and not node is PremiumPieceButton:
		var b := node as Button
		b.add_theme_stylebox_override("normal", _box(Color("f8f9fc"), 22, BORDER, 2))
		b.add_theme_stylebox_override("hover", _box(Color("eef1ff"), 22, ACCENT, 2))
		b.add_theme_stylebox_override("pressed", _box(ACCENT_SOFT, 22, ACCENT, 2))
		b.add_theme_stylebox_override("disabled", _box(Color("eceff4"), 22, Color("d8dee8"), 1))
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", INK)
		b.add_theme_color_override("font_pressed_color", INK)
		b.add_theme_color_override("font_disabled_color", Color("98a2b3"))
	elif node is PanelContainer:
		var p := node as PanelContainer
		if p.name != "TutorialPanel":
			p.add_theme_stylebox_override("panel", _box(Color("f7f8fccc"), 28, Color("d5dce8aa"), 1))
	elif node is Label:
		var l := node as Label
		if l.name != "TutorialTitle" and l.name != "TutorialBody":
			l.add_theme_color_override("font_color", INK)
	for child in node.get_children():
		_soften_control(child)

func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if width > 0:
		style.border_width_left = width
		style.border_width_right = width
		style.border_width_top = width
		style.border_width_bottom = width
		style.border_color = border
	style.shadow_color = Color(0.12, 0.16, 0.25, 0.10)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style
