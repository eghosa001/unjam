extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var motion := root.get_node("MotionSystem")
	var original: Variant = save.data.get("reduce_motion", false)
	save.data["reduce_motion"] = true
	motion.call("refresh_preferences")

	var button := load("res://scripts/ui/water_tube_reference_button.gd").new() as Button
	root.add_child(button)
	button.call("configure", [0, 1, 1, 2], true, 0)
	await process_frame
	if not _check(not button.is_processing(), "Selected Water bottle must not animate at 30fps under Reduce Motion"):return
	button.call("_press")
	button.call("_release")
	if not _check(button.scale.is_equal_approx(Vector2.ONE), "Water bottle still scales during press under Reduce Motion"):return
	button.call("play_invalid")
	button.call("play_success")
	if not _check(float(button.get("invalid_flash")) == 0.0 and float(button.get("success_flash")) == 0.0, "Reduced Motion still flashes full-screen bottles"):return
	if not _check(not button.is_processing(), "Water bottle still keeps processing after reduced feedback"):return

	save.data["reduce_motion"] = false
	motion.call("refresh_preferences")
	button.call("configure", [0, 1], true, 0)
	await process_frame
	if not _check(button.is_processing(), "Standard selected-tube feedback lost its light animation"):return

	button.queue_free()
	await process_frame
	save.data["reduce_motion"] = original
	motion.call("refresh_preferences")
	print("WATER_REDUCED_MOTION_POWER_OK: static selected bottles, no tween/flash, normal feedback preserved")
	quit(0)

func _check(ok: bool, why: String) -> bool:
	if ok: return true
	push_error(why)
	quit(1)
	return false
