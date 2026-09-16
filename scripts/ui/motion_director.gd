extends Node

var _last_signature := ""
var _first := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := get_parent()
	if main != null and main.has_signal("surface_changed"):
		main.surface_changed.connect(_on_surface_changed)
	call_deferred("_on_surface_changed", String(main.get("current_surface")) if main != null and main.get("current_surface") != null else "home")

func _on_surface_changed(surface: String) -> void:
	var main := get_parent()
	if main == null:
		return
	var content: Control = main.get("content") as Control
	var active: Control = main.get("active_game") as Control
	var target := _surface_target(main, surface, content, active)
	var target_id := target.get_instance_id() if target != null and is_instance_valid(target) else 0
	var signature := "%s|%d" % [surface, target_id]
	if signature == _last_signature:
		return
	_last_signature = signature
	if _first:
		_first = false
		return
	if target != null and is_instance_valid(target):
		_animate_surface_in(target)

func _surface_target(main: Node, surface: String, content: Control, active: Control) -> Control:
	if surface == "game" and active != null and is_instance_valid(active):
		return active
	if surface == "home":
		var home := main.get_node_or_null("PremiumHome") as Control
		if home != null and home.visible:
			return home
	if surface == "live":
		var live := main.get_node_or_null("PremiumLive") as Control
		if live != null and live.visible:
			return live
	if content != null and is_instance_valid(content) and content.visible:
		return content
	return null

func _animate_surface_in(target: Control) -> void:
	# Navigation may fade, but the screen itself must remain geometrically fixed.
	# Moving/scaling the root reads as a whole-screen vibration on phones.
	if MotionSystem.reduced():
		target.modulate = Color.WHITE
		return
	var final_modulate := target.modulate
	target.modulate = Color(final_modulate.r, final_modulate.g, final_modulate.b, final_modulate.a * 0.88)
	var tween := target.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", final_modulate, MotionSystem.duration(&"screen"))
