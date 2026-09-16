extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/game/rescue_rush_motion_final.gd", FileAccess.READ)
	if file == null:
		push_error("Rescue Rush final motion source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	for needle in ["_board_has_rendered", "func _animate_cell", "if _board_has_rendered", "super._animate_cell"]:
		if not source.contains(needle):
			push_error("Rescue board still replays its full entrance on every update: " + needle)
			quit(1)
			return
	print("Rescue board entrance is first-render only.")
	quit(0)
