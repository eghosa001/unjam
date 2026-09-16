extends "res://scripts/ui/premium_surface_manager.gd"

func _animate_surface(content: Control) -> void:
	if bool(SaveManager.data.get("reduced_motion", false)):
		content.modulate.a = 1.0
		return
	var final_alpha := content.modulate.a
	content.modulate.a = minf(final_alpha, 0.82)
	var tween := content.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", final_alpha, 0.20)
