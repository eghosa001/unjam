extends Node

var last_signature := ""
var first_sync := true
var timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_sync")

func _process(delta: float) -> void:
	timer += delta
	# Check often enough that a newly-built surface is animated on the next
	# visible frame rather than up to 120 ms later.
	if timer < 0.025:
		return
	timer = 0.0
	_sync()

func _sync() -> void:
	var main := get_parent()
	if main == null:
		return
	var surface := String(main.get("current_surface")) if main.get("current_surface") != null else "home"
	var shell := main.get_node_or_null("UXShell")
	var theme := String(shell.get("theme_mode")) if shell != null and shell.get("theme_mode") != null else "dark"
	var content: Control = main.get("content") as Control
	var content_id := content.get_instance_id() if content != null and is_instance_valid(content) else 0
	var active: Control = main.get("active_game") as Control
	var active_id := active.get_instance_id() if active != null and is_instance_valid(active) else 0
	var signature := "%s|%s|%d|%d" % [surface, theme, content_id, active_id]
	if signature == last_signature:
		return
	last_signature = signature
	if theme == "light" and surface != "game":
		call_deferred("_soften_light_surface")
	if first_sync:
		first_sync = false
		return
	_play_transition(theme)

func _soften_light_surface() -> void:
	var main := get_parent()
	if main == null:
		return
	var targets: Array[Node] = []
	var premium_home := main.get_node_or_null("PremiumHome")
	var premium_live := main.get_node_or_null("PremiumLive")
	if premium_home != null and premium_home.visible:
		targets.append(premium_home)
	if premium_live != null and premium_live.visible:
		targets.append(premium_live)
	var content: Control = main.get("content") as Control
	if content != null and is_instance_valid(content) and content.visible:
		targets.append(content)
	for target in targets:
		_soften_tree(target)

func _soften_tree(node: Node) -> void:
	if node is PanelContainer:
		_soften_style(node as PanelContainer, "panel")
	elif node is Button:
		var button := node as Button
		for state in ["normal", "hover", "pressed"]:
			_soften_style(button, state)
	elif node is ColorRect:
		var rect := node as ColorRect
		if rect.color.a > 0.70 and rect.color.get_luminance() > 0.80:
			rect.color = rect.color.lerp(Color("dce8eb"), 0.20)
	for child in node.get_children():
		_soften_tree(child)

func _soften_style(control: Control, style_name: String) -> void:
	if not control.has_theme_stylebox_override(style_name):
		return
	var source := control.get_theme_stylebox(style_name)
	if not source is StyleBoxFlat:
		return
	var style := (source as StyleBoxFlat).duplicate() as StyleBoxFlat
	if style.bg_color.a > 0.72 and style.bg_color.get_luminance() > 0.80:
		style.bg_color = style.bg_color.lerp(Color("dfe9ec"), 0.24)
		control.add_theme_stylebox_override(style_name, style)

func _play_transition(theme: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 850
	layer.name = "PremiumTransition"
	add_child(layer)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color("07101d") if theme == "dark" else Color("dbe6e9")
	veil.modulate.a = 0.09
	layer.add_child(veil)
	var tween := veil.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(veil, "modulate:a", 0.0, 0.15)
	tween.finished.connect(layer.queue_free)
