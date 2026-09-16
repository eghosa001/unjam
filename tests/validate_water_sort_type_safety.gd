extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/game/water_sort_ultra_motion.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	var text := "" if file == null else file.get_as_text()
	var required := "var max_width_from_screen: float = floorf("
	if not text.contains(required):
		push_error("Water Sort narrow-phone layout must use typed floorf() math so warnings-as-errors builds compile")
		quit(1)
		return
	print("Water Sort typed layout math validated.")
	quit(0)
