extends SceneTree

func _initialize() -> void:
	var touch_file := FileAccess.open("res://scripts/ui/ui_touch_enhancer_casual.gd", FileAccess.READ)
	var base_touch_file := FileAccess.open("res://scripts/ui/ui_touch_enhancer.gd", FileAccess.READ)
	var piece_file := FileAccess.open("res://scripts/ui/rescue_piece_3d_button.gd", FileAccess.READ)
	var rescue_file := FileAccess.open("res://scripts/game/rescue_rush_premium.gd", FileAccess.READ)
	if touch_file == null or base_touch_file == null or piece_file == null or rescue_file == null:
		push_error("Rescue touch/performance source is missing")
		quit(1)
		return
	var touch_source := touch_file.get_as_text()
	var base_touch_source := base_touch_file.get_as_text()
	var piece_source := piece_file.get_as_text()
	var rescue_source := rescue_file.get_as_text()
	if not touch_source.contains("_is_rescue_piece_button(button)"):
		push_error("Casual touch enhancer can still resize Rescue Rush board pieces")
		quit(1)
		return
	if not base_touch_source.contains("func _is_rescue_piece_button") or not base_touch_source.contains("rescue_piece_3d_button.gd"):
		push_error("Rescue Rush board pieces are not classified as gameplay geometry")
		quit(1)
		return
	if not rescue_source.contains("RescuePiece3D.new()"):
		push_error("Rescue Rush no longer routes active pieces through the protected board-piece renderer")
		quit(1)
		return
	if not piece_source.contains("premium_piece_button.gd"):
		push_error("Rescue Rush pieces lost the lightweight Canvas renderer")
		quit(1)
		return
	for required in ["2.5D CanvasItem geometry", "func _draw_shell", "var depth :=", "func _draw_arrow", "raised inlay"]:
		if not piece_source.contains(required):
			push_error("Rescue Rush tile depth contract is missing: " + required)
			quit(1)
			return
	if not piece_source.contains("set_process(false)"):
		push_error("Rescue Rush 2.5D pieces still redraw continuously while idle")
		quit(1)
		return
	for forbidden in ["SubViewport", "Camera3D", "Node3D", "BoxMesh", "TorusMesh"]:
		if piece_source.contains(forbidden):
			push_error("Rescue Rush 2.5D piece still allocates perspective 3D resource: " + forbidden)
			quit(1)
			return
	print("Rescue Rush 2.5D pieces keep sculpted depth, gameplay sizing and idle sleep without per-tile perspective rendering.")
	quit(0)
