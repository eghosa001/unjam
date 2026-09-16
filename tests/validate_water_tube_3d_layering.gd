extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/ui/water_tube_3d_motion.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	var source := "" if file == null else file.get_as_text()
	if not source.contains("viewport_container.z_index = 0"):
		push_error("Water tube 3D viewport must render at the normal child layer so the translucent gameplay panel cannot wash it out")
		quit(1)
		return
	print("Water tube 3D layering validated: bottle viewport is not behind the gameplay panel.")
	quit(0)
