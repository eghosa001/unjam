extends Node

# One vocabulary for every transition/gameplay tween. Keep this deliberately
# small: consistency reads as quality more than having dozens of curves.
const DURATIONS := {
	# Premium puzzle controls should acknowledge input inside a single visual beat.
	# These values keep motion readable while removing the small "wait" between
	# touch, travel, settle and the next available decision.
	&"micro": 0.045,
	&"press": 0.065,
	&"travel": 0.16,
	&"settle": 0.10,
	&"celebrate": 0.27,
	&"screen": 0.085,
	&"pour": 0.21,
	&"reflow": 0.11,
}
const FAST_SCALE := 0.62
const REDUCED_SCALE := 0.28

var _cached_reduced := false
var _cached_fast := false
var _preferences_loaded := false

func _ready() -> void:
	refresh_preferences()

func refresh_preferences() -> void:
	_cached_reduced = _save_flag("reduce_motion", false)
	_cached_fast = _save_flag("fast_animation", false)
	_preferences_loaded = true

func reduced() -> bool:
	if not _preferences_loaded:
		refresh_preferences()
	return _cached_reduced

func fast() -> bool:
	if not _preferences_loaded:
		refresh_preferences()
	return _cached_fast

func duration(kind: StringName) -> float:
	return duration_for_flags(kind, reduced(), fast())

func duration_for_flags(kind: StringName, reduce_motion: bool, fast_animation: bool) -> float:
	var base := float(DURATIONS.get(kind, 0.16))
	if reduce_motion:
		return maxf(0.01, base * REDUCED_SCALE)
	if fast_animation:
		return maxf(0.01, base * FAST_SCALE)
	return base

func fade_in(target: CanvasItem):
	if target == null or not is_instance_valid(target):
		return null
	var final_modulate := target.modulate
	if reduced():
		target.modulate = final_modulate
		return null
	target.modulate = Color(final_modulate.r, final_modulate.g, final_modulate.b, final_modulate.a * 0.86)
	var tween := target.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", final_modulate, duration(&"screen"))
	return tween

func press(target: Control, strength: float = 1.0):
	if target == null or not is_instance_valid(target) or reduced():
		return null
	var original := target.scale
	var amount := clampf(0.025 * strength, 0.01, 0.055)
	var tween := target.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original * (1.0 - amount), duration(&"press") * 0.42)
	tween.tween_property(target, "scale", original, duration(&"press") * 0.58)
	return tween

func pop(target: Control, strength: float = 1.0):
	if target == null or not is_instance_valid(target) or reduced():
		return null
	var original := target.scale
	var amount := clampf(0.06 * strength, 0.025, 0.14)
	target.scale = original * (1.0 - amount * 0.35)
	var tween := target.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original * (1.0 + amount), duration(&"settle") * 0.58)
	tween.tween_property(target, "scale", original, duration(&"settle") * 0.42).set_trans(Tween.TRANS_CUBIC)
	return tween

func local_punch(target: Control, strength: float = 1.0):
	# Callers must pass a board/piece/local effect container, never a screen root.
	if target == null or not is_instance_valid(target) or reduced():
		return null
	var original := target.scale
	var amount := clampf(0.025 * strength, 0.012, 0.065)
	var tween := target.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original * (1.0 + amount), duration(&"micro"))
	tween.tween_property(target, "scale", original, duration(&"settle"))
	return tween

func _save_flag(key: String, fallback: bool) -> bool:
	var save := get_node_or_null("/root/SaveManager")
	if save == null:
		return fallback
	var raw = save.get("data")
	if raw is Dictionary:
		return bool(raw.get(key, fallback))
	return fallback
