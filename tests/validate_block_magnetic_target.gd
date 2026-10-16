extends SceneTree

const Magnetic = preload("res://scripts/ui/block_magnetic_target.gd")
const Piece = preload("res://scripts/ui/smooth_block_piece_button.gd")
const Preview = preload("res://scripts/ui/smooth_block_drag_preview.gd")

class Board:
	extends Control
	var cell_buttons: Array = []
	var blocked := Vector2i(-1,-1)
	var placed := Vector2i(-1,-1)
	var active_touch_piece: Button
	var selected_index := -1
	func can_place(shape: Array, origin: Vector2i) -> bool:
		if origin == blocked: return false
		for raw in shape:
			var cell: Vector2i = origin + (raw as Vector2i)
			if cell.x < 0 or cell.y < 0 or cell.x >= 8 or cell.y >= 8:
				return false
		return true
	func place_piece_from_drag(_index: int, origin: Vector2i) -> void:
		placed = origin
	func register_touch_drag(button: Button) -> void:
		active_touch_piece = button
	func clear_touch_drag(button: Button) -> void:
		if active_touch_piece == button:
			active_touch_piece = null
	func select_piece(index: int) -> void:
		selected_index = index

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var board := Board.new()
	root.add_child(board)
	for y in range(8):
		for x in range(8):
			var cell := Control.new()
			cell.position = Vector2(40+x*36,40+y*36)
			cell.size = Vector2(34,34)
			board.add_child(cell)
			board.cell_buttons.append(cell)
	var piece := Piece.new()
	board.add_child(piece)
	piece.configure([Vector2i(0,0),Vector2i(1,0)],false,Color("#5396fa"),0)
	await process_frame
	var target := Vector2(57+36.0*2.5,57+36.0*3.0)
	var finger := target+Vector2(0,132)
	var shape: Array = piece.shape
	var scaled_lift := Magnetic.lift_distance(board)
	if not _check(absf(scaled_lift - 84.6) < 0.1,"Finger lift is no longer a compact, board-relative distance"):return
	var got: Vector2i = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(2,3),"Centered magnetic placement picked wrong origin"):return
	got = Magnetic.choose(board,shape,finger+Vector2(16.5,0),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(2,3),"Near-midline touch jitter jumped to next cell"):return
	got = Magnetic.choose(board,shape,finger+Vector2(30,0),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(3,3),"Magnet does not move to clearly closer requested column"):return
	board.blocked = Vector2i(2,3)
	if not _check(Magnetic.preview_origin(board, shape, finger, 132.0) == Vector2i(2,3),"Blocked aim must remain visible for invalid red-cell feedback"):return
	got = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(-1,-1),"Blocked target redirected to adjacent unintended placement"):return
	got = Magnetic.choose(board,shape,finger+Vector2(20.0,0.0),Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(3,3),"Magnetic assist cannot help a deliberately shifted aim find its nearby legal column"):return
	got = Magnetic.choose(board,shape,Vector2(-800,700),Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(-1,-1),"Off-board release magnetized to distant legal cells"):return
	board.blocked = Vector2i(-1,-1)
	board.scale = Vector2(1.5,1.5)
	var scaled_geo := Magnetic.geometry(board)
	var scaled_first: Vector2 = scaled_geo["first"]
	var scaled_step: Vector2 = scaled_geo["step"]
	if not _check(absf(scaled_step.x - 54.0) < 0.1,"Board canvas scale was omitted from magnetic geometry"):return
	var scaled_center := scaled_first + scaled_step * Vector2(2.5,3.0)
	got = Magnetic.choose(board,shape,scaled_center+Vector2(0,Magnetic.lift_distance(board)),Vector2i(-1,-1),Magnetic.lift_distance(board))
	if not _check(got == Vector2i(2,3),"Magnet lost alignment when the canvas was scaled"):return
	board.scale = Vector2.ONE
	got = Magnetic.choose(board,shape,Vector2(57+36.0*7.5,57+36.0*3.0)+Vector2(0,132),Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(-1,-1),"Magnet committed a two-column block beyond the eighth board column"):return
	got = Magnetic.choose(board,shape,Vector2(-800,700),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(-1,-1),"Held magnet persisted after the finger left the board"):return
	piece.set("_drag_distance",0.0)
	piece.call("_finish_touch_drag",finger)
	if not _check(board.placed == Vector2i(-1,-1),"Static tray tap triggered unintended placement"):return
	piece.set("_drag_distance",42.0)
	piece.call("_finish_touch_drag",finger)
	if not _check(board.placed == Vector2i(2,3),"Committed placement differs from magnetic target"):return
	# Real touch lifecycle: start inside the tray, follow the same finger
	# across the entire board, ignore a second touch, and commit on release.
	board.placed = Vector2i(-1, -1)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(6.0, 8.0)
	piece._gui_input(press)
	if not _check(piece.touch_drag_started and piece.is_processing_input(), "Tray press did not capture a global touch pointer"):return
	if not _check(piece.touch_preview == null and not piece.dragging, "Simple touch unexpectedly lifted/enlarged a tray brick"):return
	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 1
	second_touch.pressed = false
	second_touch.position = target + Vector2(0.0, scaled_lift)
	piece._input(second_touch)
	if not _check(piece.touch_drag_started and board.placed.x < 0, "Another finger interrupted the active drag"):return
	var move := InputEventScreenDrag.new()
	move.index = 0
	move.position = target + Vector2(0.0, scaled_lift)
	piece._input(move)
	if not _check(piece.touch_preview != null and piece._last_magnet == Vector2i(2,3), "Viewport-wide drag failed to acquire a centered board target"):return
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = move.position
	piece._input(release)
	if not _check(board.placed == Vector2i(2,3), "Global release did not commit the highlighted magnetic target"):return
	if not _check(not piece.touch_drag_started and not piece.is_processing_input(), "Released touch kept the global handler alive"):return
	if not _check(piece.touch_preview == null and board.active_touch_piece == null, "Ghost or pointer owner survived release"):return
	board.placed = Vector2i(-1, -1)
	piece._gui_input(press)
	var tap_release := InputEventScreenTouch.new()
	tap_release.index = 0
	tap_release.pressed = false
	tap_release.position = press.position
	piece._input(tap_release)
	if not _check(board.selected_index == 0 and board.placed.x < 0, "Tray tap did not select without accidental placement"):return
	# Magnetic pull should ease a one-cell move, then settle in a few frames.
	var ghost := Preview.new()
	root.add_child(ghost)
	ghost.configure(shape,Color("#5396fa"),34.0)
	ghost.set_drag_target(Vector2(10,10),true)
	ghost.set_drag_target(Vector2(100,100),true)
	ghost.call("_process",1.0/60.0)
	if not _check(ghost.position.distance_to(Vector2(100,100)) < 0.1,"Valid ghost lags behind snapped target"):return
	ghost.set_drag_target(Vector2(136,100),true)
	ghost.call("_process",1.0/60.0)
	if not _check(ghost.position.x > 115.0 and ghost.position.x <= 136.0, "One-cell magnet ghost failed to track promptly"):return
	ghost.call("_process",1.0/60.0)
	ghost.call("_process",1.0/60.0)
	if not _check(ghost.position.distance_to(Vector2(136,100)) < 2.0, "Magnetic pull still visibly lags after three frames"):return
	ghost.queue_free()
	board.queue_free()
	await process_frame
	print("BLOCK_MAGNETIC_TARGET_OK: responsive lift, legal magnetic assist, occupied/edge safety, tap protection, instant ghost")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
