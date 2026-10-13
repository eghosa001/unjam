extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var motion := root.get_node("MotionSystem")
	var had_gentle := save.data.has("gentle_effects")
	var old_gentle: Variant = save.data.get("gentle_effects",true)
	var old_reduced: Variant = save.data.get("reduce_motion",false)
	var overlay := PremiumResultOverlay.new()
	root.add_child(overlay)
	save.data["reduce_motion"] = false
	motion.call("refresh_preferences")
	save.data["gentle_effects"] = true
	var gentle: Dictionary = overlay.call("_celebration_budget")
	if gentle.get("flash") != false or int(gentle.get("accent",0)) > 8 or int(gentle.get("gold",0)) > 4:
		return _fail("Gentle Effects must avoid flash and limit result particles")
	save.data["gentle_effects"] = false
	var vivid: Dictionary = overlay.call("_celebration_budget")
	if vivid.get("flash") != true or int(vivid.get("accent",0)) <= int(gentle.get("accent",0)):
		return _fail("Opt-in vivid results did not restore the stronger celebration")
	save.data["reduce_motion"] = true
	motion.call("refresh_preferences")
	var reduced: Dictionary = overlay.call("_celebration_budget")
	if reduced.get("flash") != false or int(reduced.get("accent",1)) != 0 or int(reduced.get("gold",1)) != 0:
		return _fail("Reduced Motion must suppress flashes and bursts even with vivid effects")
	overlay.queue_free()
	await process_frame
	save.data["reduce_motion"] = old_reduced
	if had_gentle:
		save.data["gentle_effects"] = old_gentle
	else:
		save.data.erase("gentle_effects")
	motion.call("refresh_preferences")
	print("RESULT_COMFORT_BUDGET_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
