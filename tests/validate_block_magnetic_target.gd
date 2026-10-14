extends SceneTree

const Magnetic = preload("res://scripts/ui/block_magnetic_target.gd")
const Piece = preload("res://scripts/ui/smooth_block_piece_button.gd")
const Preview = preload("res://scripts/ui/smooth_block_drag_preview.gd")

class Board:
	extends Control
	var cell_buttons: Array = []
	var blocked := Vector2i(-1,-1)
	var placed := Vector2i(-1,-1)
	func can_place(shape: Array, origin: Vector2i) -> bool:
		if origin == blocked: return false
		for raw in shape:
			var cell: Vector2i = origin + (raw as Vector2i)
			if cell.x < 0 or cell.y < 0 or cell.x >= 8 or cell.y >= 8:
				return false
		return true
	func place_piece_from_drag(_index: int, origin: Vector2i) -> void:
		placed = origin
	func clear_touch_drag(_button: Button) -> void:
		pass

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
	var got: Vector2i = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(2,3),"Centered magnetic placement picked wrong origin"):return
	got = Magnetic.choose(board,shape,finger+Vector2(16.5,0),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(2,3),"Near-midline touch jitter jumped to next cell"):return
	got = Magnetic.choose(board,shape,finger+Vector2(30,0),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(3,3),"Magnet does not move to clearly closer requested column"):return
	board.blocked = Vector2i(2,3)
	got = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(-1,-1),"Blocked target redirected to adjacent unintended placement"):return
	got = Magnetic.choose(board,shape,Vector2(-800,700),Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(-1,-1),"Off-board release magnetized to distant legal cells"):return
	board.blocked = Vector2i(-1,-1)
	piece.set("_drag_distance",0.0)
	piece.call("_finish_touch_drag",finger)
	if not _check(board.placed == Vector2i(-1,-1),"Static tray tap triggered unintended placement"):return
	piece.set("_drag_distance",42.0)
	piece.call("_finish_touch_drag",finger)
	if not _check(board.placed == Vector2i(2,3),"Committed placement differs from magnetic target"):return
	var ghost := Preview.new()
	root.add_child(ghost)
	ghost.configure(shape,Color("#5396fa"),34.0)
	ghost.set_drag_target(Vector2(10,10),true)
	ghost.set_drag_target(Vector2(100,100),true)
	ghost.call("_process",1.0/60.0)
	if not _check(ghost.position.distance_to(Vector2(100,100)) < 0.1,"Valid ghost lags behind snapped target"):return
	ghost.queue_free()
	board.queue_free()
	await process_frame
	print("BLOCK_MAGNETIC_TARGET_OK: precise nearest snap, hysteresis, blocked/offboard safety, tap protection, instant ghost")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
