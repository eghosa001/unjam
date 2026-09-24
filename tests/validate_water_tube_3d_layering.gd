extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/ui/water_tube_3d_motion.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	var source := "" if file == null else file.get_as_text()
	var motion_file := FileAccess.open("res://scripts/game/water_sort_reference_motion.gd", FileAccess.READ)
	var motion := "" if motion_file == null else motion_file.get_as_text()
	if not source.contains("viewport_container.z_index = 0"):
		push_error("Water tube 3D viewport must render at the normal child layer so the translucent gameplay panel cannot wash it out")
		quit(1)
		return
	var configure_start := source.find("func configure(values: Array, selected: bool, index: int) -> void:")
	var configure_end := source.find("\nfunc _ready()", configure_start)
	var configure_source := "" if configure_start < 0 or configure_end < 0 else source.substr(configure_start, configure_end - configure_start)
	if not configure_source.contains("_request_3d_frame()"):
		push_error("Every configured 3D bottle must request one fresh SubViewport frame after board relayout")
		quit(1)
		return
	if not motion.contains("button.modulate = Color(1, 1, 1, 0.0)"):
		push_error("Active pour originals must remain hidden so animated ghosts have single visual ownership")
		quit(1)
		return
	print("Water tube 3D visibility validated.")
	quit(0)
