extends SceneTree

func _initialize() -> void:
	var touch_file := FileAccess.open("res://scripts/ui/ui_touch_enhancer_casual.gd", FileAccess.READ)
	var base_touch_file := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ)
	var piece_file := FileAccess.open("res://scripts/ui/rescue_piece_3d_button.gd", FileAccess.READ)
	if touch_file == null or base_touch_file == null or piece_file == null:
		push_error("Rescue touch/performance source is missing")
		quit(1)
		return
	var touch_source := touch_file.get_as_text()
	var base_touch_source := base_touch_file.get_as_text()
	var piece_source := piece_file.get_as_text()
	if not touch_source.contains("_is_rescue_piece_button(button)"):
		push_error("Casual touch enhancer can still resize Rescue Rush board pieces")
		quit(1)
		return
	if not base_touch_source.contains("func _is_rescue_piece_button") or not base_touch_source.contains("rescue_piece_3d_button.gd"):
		push_error("Rescue Rush board pieces are not classified as gameplay geometry")
		quit(1)
		return
	if not piece_source.contains("set_process(false)"):
		push_error("3D Rescue Rush pieces still process every frame while idle")
		quit(1)
		return
	if not piece_source.contains("SubViewport.UPDATE_ONCE"):
		push_error("3D Rescue Rush pieces lost one-shot viewport rendering")
		quit(1)
		return
	print("Rescue Rush 3D pieces keep gameplay sizing and sleep while idle.")
	quit(0)
