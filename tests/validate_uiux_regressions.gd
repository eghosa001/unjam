extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rescue := FileAccess.open("res://scripts/game/rescue_rush_premium.gd", FileAccess.READ).get_as_text()
	if not rescue.contains("viewport_height"):
		push_error("Rescue board sizing must use viewport height")
		quit(1)
		return
	print("UI/UX regression checks passed")
	quit(0)
