extends Node

var layer: CanvasLayer
var launcher: Button
var hub_open: bool = false

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	launcher = Button.new()
	launcher.text = "LIVE\nEVENTS"
	launcher.position = Vector2(850, 1500)
	launcher.size = Vector2(180, 110)
	launcher.add_theme_font_size_override("font_size", 22)
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color("182f52")
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color("2dd4b6")
	launcher.add_theme_stylebox_override("normal", normal)
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("10243f")
	launcher.add_theme_stylebox_override("pressed", pressed)
	launcher.add_theme_color_override("font_color", Color.WHITE)
	launcher.pressed.connect(open_hub)
	layer.add_child(launcher)
	PremiumVisuals.premium_button(launcher)
	# Premium navigation owns Live access. Keep the retired floating launcher
	# available for compatibility, but do not burn a frame callback just to hide it.
	launcher.visible = false
	set_process(false)

func open_hub() -> void:
	if hub_open:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	hub_open = true
	launcher.visible = false
	var packed: PackedScene = load("res://scenes/RetentionHub.tscn") as PackedScene
	var hub: Control = packed.instantiate() as Control
	hub.z_index = 120
	hub.mouse_filter = Control.MOUSE_FILTER_STOP
	scene.add_child(hub)
	hub.closed.connect(func():
		hub_open = false
	)
	PremiumVisuals.screen_flash(Color("2dd4b6"), 0.12)
