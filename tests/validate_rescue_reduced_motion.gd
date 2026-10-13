extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var motion := root.get_node("MotionSystem")
	var old_flag: Variant = save.data.get("reduce_motion", false)
	save.data["reduce_motion"] = true
	motion.call("refresh_preferences")
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	game.level_number = 5
	root.add_child(game)
	for _i in range(6): await process_frame
	var grid: GridContainer = game.get("board_grid")
	if not _check(grid != null and grid.get_child_count() > 0, "Rescue must render puzzle grid"):return
	for tile in grid.get_children():
		var control := tile as Control
		if not _check(control != null and control.scale.is_equal_approx(Vector2.ONE), "Reduce Motion Rescue still zooms board tiles"):return
		if not _check(is_equal_approx(control.modulate.a,1.0), "Reduce Motion Rescue tile should appear immediately"):return
	var raw := FileAccess.get_file_as_string("res://scripts/game/rescue_rush_premium.gd")
	if not _check(raw.contains("if not MotionSystem.reduced():"), "Reduced Motion pulse guard is missing"):return
	game.queue_free()
	await process_frame
	save.data["reduce_motion"] = old_flag
	motion.call("refresh_preferences")
	print("RESCUE_REDUCED_MOTION_OK: static entry, no pulsing goal, immediate puzzle focus")
	quit(0)

func _check(ok: bool, why: String) -> bool:
	if ok:return true
	push_error(why)
	quit(1)
	return false
