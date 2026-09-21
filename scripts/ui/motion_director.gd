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
	# Navigation may fade, but the screen root itself must remain geometrically
	# fixed. Premium settling is applied only to a few large local cards.
	if MotionSystem.reduced():
		target.modulate = Color.WHITE
		return
	var final_modulate := target.modulate
	target.modulate = Color(final_modulate.r, final_modulate.g, final_modulate.b, final_modulate.a * 0.88)
	var tween := target.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", final_modulate, MotionSystem.duration(&"screen"))
	_animate_key_elements(target)

func _animate_key_elements(target: Control) -> void:
	var cards: Array[Control] = []
	for raw in target.find_children("*", "Control", true, false):
		var control := raw as Control
		if control == null or not control.visible or control == target:
			continue
		if control.size.x < 180.0 or control.size.y < 44.0 or control.size.y > 260.0:
			continue
		var name_value := String(control.name)
		if not _is_major_surface_element(name_value):
			continue
		cards.append(control)
	cards.sort_custom(func(a: Control, b: Control) -> bool:
		return a.global_position.y < b.global_position.y
	)
	if cards.size() > 6:
		cards.resize(6)
	for i in range(cards.size()):
		var control := cards[i]
		var final_position := control.position
		var final_modulate := control.modulate
		control.position = final_position + Vector2(0, 5)
		control.modulate = Color(final_modulate.r, final_modulate.g, final_modulate.b, final_modulate.a * 0.84)
		var delay := minf(0.060, float(i) * 0.012)
		var settle := control.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		settle.tween_interval(delay)
		settle.tween_property(control, "position", final_position, MotionSystem.duration(&"settle"))
		settle.parallel().tween_property(control, "modulate", final_modulate, MotionSystem.duration(&"screen"))

func _is_major_surface_element(name_value: String) -> bool:
	for token in ["Card", "Journey", "Perks", "HelpPrivacy", "WorldProgress", "DailyIntro", "ShopProduct", "ResultPanel"]:
		if name_value.contains(token):
			return true
	return false
