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
	var placement_checks := 0
	func can_place(shape: Array, origin: Vector2i) -> bool:
		placement_checks += 1
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
	# The tile touched in the tray is the anchor: the whole shape must
	# not unexpectedly recenter when grabbed from its first/last tile.
	piece.size = Vector2(160, 100)
	var tray_tile := float(piece.call("_tray_cell_size", 1, 0))
	var tray_first := (piece.size - Vector2(2.0, 1.0) * tray_tile) * 0.5 + Vector2.ONE * (tray_tile * 0.5)
	if not _check(piece.call("_grab_cell_from_local",tray_first) == Vector2.ZERO,"Picking up left brick did not preserve left grab anchor"):return
	if not _check(piece.call("_grab_cell_from_local",tray_first+Vector2(tray_tile,0.0)) == Vector2(1.0,0.0),"Picking up right brick did not preserve right grab anchor"):return
	# A fingertip on the edge or gap of the drawn bricks must keep the nearest
	# real tile as the anchor. Falling back to the piece centroid made mobile
	# placement drift sideways from the player's intended contact point.
	var near_left := tray_first + Vector2(0.0, tray_tile * 0.75)
	var near_right := tray_first + Vector2(tray_tile, tray_tile * 0.75)
	if not _check(piece.call("_grab_cell_from_local",near_left) == Vector2.ZERO,"Touch near the left brick fell back to the unpredictable centroid"):return
	if not _check(piece.call("_grab_cell_from_local",near_right) == Vector2(1.0,0.0),"Touch near the right brick did not grab the closest brick"):return
	var long_shape: Array = [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)]
	var left_grab := Vector2(57.0+36.0*2.0, 57.0+36.0*3.0)+Vector2(0,132.0)
	var right_grab := Vector2(57.0+36.0*4.0, 57.0+36.0*3.0)+Vector2(0,132.0)
	if not _check(Magnetic.choose(board,long_shape,left_grab,Vector2i(-1,-1),132.0,Vector2.ZERO) == Vector2i(2,3),"Grabbing left tile displaced the piece by its centroid"):return
	if not _check(Magnetic.choose(board,long_shape,right_grab,Vector2i(-1,-1),132.0,Vector2(2.0,0.0)) == Vector2i(2,3),"Grabbing right tile displaced the piece on snap"):return
	if not _check(Magnetic.preview_origin(board,long_shape,left_grab,132.0,Vector2.ZERO) == Vector2i(2,3),"Unsapped ghost does not match anchored placement"):return
	var scaled_lift := Magnetic.lift_distance(board)
	if not _check(absf(scaled_lift - 84.6) < 0.1,"Finger lift is no longer a compact, board-relative distance"):return
	var got: Vector2i = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0)
	if not _check(got == Vector2i(2,3),"Centered magnetic placement picked wrong origin"):return
	# Rapid drag updates used to collide-test all 25 nearby origins even
	# when the pointer sat exactly over a legal one. This must stay O(1) on
	# the usual clear-cell path to protect 60/90/120Hz Android touch response.
	board.placement_checks = 0
	var saved_geometry := Magnetic.geometry(board)
	for sample in range(40):
		got = Magnetic.choose(board,shape,finger,Vector2i(-1,-1),132.0,Magnetic.NO_GRAB_ANCHOR,saved_geometry)
		if not _check(got == Vector2i(2,3),"Cached board geometry changed the snapped result"):return
	if not _check(board.placement_checks <= 45,"Magnet performs excessive placement collision checks for a legal target"):return
	if not _check(absf(Magnetic.lift_distance(board, saved_geometry) - Magnetic.lift_distance(board)) < 0.01,"Reused board geometry changed adaptive finger lift"):return
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
	# A green snap must not fail just because a finger slides a fraction
	# of a cell towards the blocked neighbour during the release gesture.
	var locked := Vector2i(1,3)
	var edge_jitter := finger - Vector2(36.0 * 0.28,0.0)
	got = Magnetic.choose(board,shape,edge_jitter,locked,132.0)
	if not _check(got == locked,"Finger jitter beside an occupied neighbour lost its visibly locked legal target"):return
	got = Magnetic.choose_release(board,shape,edge_jitter,locked,132.0)
	if not _check(got == locked,"Release jitter rejected the green magnetic lock"):return
	got = Magnetic.choose_release(board,shape,finger,locked,132.0)
	if not _check(got == Vector2i(-1,-1),"Release snapped a full cell away to a different intended location"):return
	got = Magnetic.choose_release(board,shape,Vector2(-800,700),locked,132.0)
	if not _check(got == Vector2i(-1,-1),"Off-board release committed stale magnet lock"):return
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
	if not _check(got == Vector2i(6,3),"Overflowing edge aim should magnetize to the last legal two-column footprint"):return
	got = Magnetic.choose(board,shape,Vector2(-800,700),Vector2i(2,3),132.0)
	if not _check(got == Vector2i(-1,-1),"Held magnet persisted after the finger left the board"):return
	piece.set("_drag_distance",0.0)
	piece.call("_finish_touch_drag",target + Vector2(0.0, scaled_lift))
	if not _check(board.placed == Vector2i(-1,-1),"Static tray tap triggered unintended placement"):return
	piece.set("_drag_distance",42.0)
	piece.call("_finish_touch_drag",target + Vector2(0.0, scaled_lift))
	if not _check(board.placed == Vector2i(2,3),"Committed placement differs from magnetic target"):return
	# Test the actual piece release path, not only the isolated chooser.
	board.placed = Vector2i(-1,-1)
	board.blocked = Vector2i(2,3)
	piece.set("_last_magnet",locked)
	piece.set("_drag_distance",42.0)
	# Actual touch release calculates the responsive live lift (not the
	# deliberately fixed 132px lift used by the chooser unit fixtures).
	piece.call("_finish_touch_drag",target + Vector2(-36.0 * 0.28, scaled_lift))
	if not _check(board.placed == locked,"The real release discarded the previously highlighted magnetic placement"):return
	board.blocked = Vector2i(-1,-1)
	board.placed = Vector2i(-1,-1)
	piece.set("_last_magnet",Vector2i(-1,-1))
	# Real touch lifecycle: start inside the tray, follow the same finger
	# across the entire board, ignore a second touch, and commit on release.
	board.placed = Vector2i(-1, -1)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = tray_first  # Actually pick up the left painted tile.
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
	move.position = target + Vector2(-18.0, scaled_lift)  # Finger follows the left tile, not the shape centroid.
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
	# Reproduce the recorded real-phone regression: the blue two-block
	# preview turns green at (2,3), yet Android finger-up drifts ~0.8
	# cells to the right and the next slot steals or rejects the brick.
	# The release must place precisely where the player saw it highlighted.
	board.placed = Vector2i(-1, -1)
	piece._gui_input(press)
	piece._input(move)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(2,3), "Drag did not record the actual highlighted snap"):return
	var jitter_release := InputEventScreenTouch.new()
	jitter_release.index = 0
	jitter_release.pressed = false
	jitter_release.position = move.position + Vector2(30.0, 0.0)
	piece._input(jitter_release)
	if not _check(board.placed == Vector2i(2,3), "Finger-up drift relocated/rejected a visibly snapped brick"):return
	if not _check(not piece._preview_valid, "Committed piece retained stale preview latch"):return
	# The uploaded clip is specifically a vertical two-tile blue piece
	# hovering above a partly occupied bottom row.
	piece.configure([Vector2i(0,0), Vector2i(0,1)],false,Color("#5396fa"),0)
	board.blocked = Vector2i(3,6)
	board.placed = Vector2i(-1, -1)
	# The vertical tray piece has a different painted first-tile centre.
	# Reuse of a horizontal press at the *midpoint* now correctly grabs the
	# nearest tile, so the test needs a real top-brick finger contact.
	var vertical_first := (piece.size - Vector2(1.0, 2.0) * tray_tile) * 0.5 + Vector2.ONE * (tray_tile * 0.5)
	var vertical_press := InputEventScreenTouch.new()
	vertical_press.index = 0
	vertical_press.pressed = true
	vertical_press.position = vertical_first
	piece._gui_input(vertical_press)
	if not _check(piece._grab_cell == Vector2.ZERO, "Vertical press did not anchor to its touched top tile"):return
	var vertical_move := InputEventScreenDrag.new()
	vertical_move.index = 0
	vertical_move.position = Vector2(57.0 + 36.0 * 3.0, 57.0 + 36.0 * 5.0 + scaled_lift)  # Anchored at the top tile.
	piece._input(vertical_move)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(3,5), "Vertical two-brick ghost did not highlight the intended bottom-board position"):return
	var vertical_release := InputEventScreenTouch.new()
	vertical_release.index = 0
	vertical_release.pressed = false
	vertical_release.position = vertical_move.position + Vector2(0.0, 27.0)
	piece._input(vertical_release)
	if not _check(board.placed == Vector2i(3,5), "Vertical block from phone video bounced back instead of following green snap"):return
	board.blocked = Vector2i(-1,-1)
	piece.configure([Vector2i(0,0), Vector2i(1,0)],false,Color("#5396fa"),0)
	# A late finger-up sample should keep the last shown green target even
	# after a slightly larger-than-one-cell Android release jump.
	board.placed = Vector2i(-1, -1)
	piece._gui_input(press)
	piece._input(move)
	var coalesced_release := InputEventScreenTouch.new()
	coalesced_release.index = 0
	coalesced_release.pressed = false
	coalesced_release.position = move.position + Vector2(43.0, 0.0)
	piece._input(coalesced_release)
	if not _check(board.placed == Vector2i(2,3), "Release jitter bounced a visibly green two-tile brick back to tray"):return
	# The last highlighted column is authoritative even if Android coalesces
	# the final pointer-up by ~1.5 board cells. The old 1.28-cell check
	# rejected this as a failed drop despite showing a green footprint.
	board.placed = Vector2i(-1, -1)
	piece._gui_input(press)
	piece._input(move)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(2,3),
			"Coalesced drop fixture lost its green preview"):return
	var wide_up := InputEventScreenTouch.new()
	wide_up.index = 0
	wide_up.pressed = false
	wide_up.position = move.position + Vector2(55.0, 0.0)
	piece._input(wide_up)
	if not _check(board.placed == Vector2i(2,3),
			"Visible magnetic column was rejected on delayed finger-up"):return
	var geo_for_release := Magnetic.geometry(board)
	var live_lift := Magnetic.lift_distance(board, geo_for_release)
	if not _check(Magnetic.release_matches_visible_snap(board,shape,
			move.position + Vector2(55.0,0.0),move.position,Vector2i(2,3),
			live_lift,Vector2.ZERO,geo_for_release),
			"Release solver refused valid held green cell"):return
	if not _check(not Magnetic.release_matches_visible_snap(board,shape,
			move.position + Vector2(98.0,0.0),move.position,Vector2i(2,3),
			live_lift,Vector2.ZERO,geo_for_release),
			"Distant lift-up incorrectly teleported a snapped brick"):return
	if not _check(not Magnetic.release_matches_visible_snap(board,shape,
			Vector2(-800.0,-800.0),move.position,Vector2i(2,3),
			live_lift,Vector2.ZERO,geo_for_release),
			"Off-board lift-up accepted a stale green brick"):return
	board.blocked = Vector2i(2,3)
	if not _check(not Magnetic.release_matches_visible_snap(board,shape,
			move.position,move.position,Vector2i(2,3),
			live_lift,Vector2.ZERO,geo_for_release),
			"Occupied cell committed despite a green stale footprint"):return
	board.blocked = Vector2i(-1,-1)

	# Regression: every valid horizontal placement ON THE EIGHTH ROW must
	# survive a downward Android finger-up event. The previous edge cutoff
	# accepted middle rows but discarded green targets near the bottom edge.
	piece.configure([Vector2i(0,0), Vector2i(1,0)],false,Color("#5396fa"),0)
	board.blocked = Vector2i(-1,-1)
	for column in range(7):
		board.placed = Vector2i(-1,-1)
		piece._gui_input(press)
		var bottom_move := InputEventScreenDrag.new()
		bottom_move.index = 0
		bottom_move.position = Vector2(57.0 + 36.0 * float(column), 57.0 + 36.0 * 7.0 + scaled_lift)
		piece._input(bottom_move)
		if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(column,7),
				"Last-row green preview absent at column %d" % column):return
		var bottom_up := InputEventScreenTouch.new()
		bottom_up.index = 0
		bottom_up.pressed = false
		bottom_up.position = bottom_move.position + Vector2(0.0,55.0)
		piece._input(bottom_up)
		if not _check(board.placed == Vector2i(column,7),
				"Valid bottom-row drop rejected at column %d" % column):return
	# Real phone video: the first horizontal three-block briefly appeared on
	# the last row but returned to the tray after Android's native drag ended.
	# Its touchscreen ownership must survive the parallel mouse drag ending;
	# the same green target must be committed on the first finger-up.
	piece.configure([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)], false, Color("#f3a24e"), 0)
	board.placed = Vector2i(-1,-1)
	var triple_tile := float(piece.call("_tray_cell_size",2,0))
	var triple_press := InputEventScreenTouch.new()
	triple_press.index = 0
	triple_press.pressed = true
	triple_press.position = (piece.size - Vector2(3.0,1.0) * triple_tile) * 0.5 + Vector2.ONE * (triple_tile * 0.5)
	piece._gui_input(triple_press)
	var triple_move := InputEventScreenDrag.new()
	triple_move.index = 0
	triple_move.position = Vector2(57.0,57.0 + 36.0 * 7.0 + scaled_lift)
	piece._input(triple_move)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(0,7),
			"First three-block pickup never magnetized to the lowest row"):return
	piece.notification(Control.NOTIFICATION_DRAG_END)
	if not _check(piece.touch_drag_started and piece._preview_valid and piece.touch_preview != null,
			"An unrelated native mouse drag end erased the active Android finger's green snap"):return
	# One sub-cell jitter sample at the eighth-row edge cannot cause the
	# preview to flicker red and bounce the brick back into its original slot.
	var triple_jitter := InputEventScreenDrag.new()
	triple_jitter.index = 0
	triple_jitter.position = triple_move.position + Vector2(5.0,13.0)
	piece._input(triple_jitter)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(0,7),
			"Sub-cell phone movement broke an acquired first-drag magnetic lock"):return
	var triple_up := InputEventScreenTouch.new()
	triple_up.index = 0
	triple_up.pressed = false
	triple_up.position = triple_jitter.position + Vector2(1.0,38.0)
	piece._input(triple_up)
	if not _check(board.placed == Vector2i(0,7),
			"Recorded opening three-tile placement bounced back on finger-up"):return
	# A two-tile column grabbed by its LOWER tile should fill the eighth
	# row without sending its top tile outside the grid or missing finger-up.
	piece.configure([Vector2i(0,0), Vector2i(0,1)],false,Color("#5396fa"),0)
	var bottom_grab := InputEventScreenTouch.new()
	bottom_grab.index = 0
	bottom_grab.pressed = true
	bottom_grab.position = vertical_first + Vector2(0.0,tray_tile)
	piece._gui_input(bottom_grab)
	if not _check(piece._grab_cell == Vector2(0,1),"Bottom-tile grab anchor is incorrect"):return
	var bottom_vertical_move := InputEventScreenDrag.new()
	bottom_vertical_move.index = 0
	bottom_vertical_move.position = Vector2(57.0 + 36.0 * 4.0,57.0 + 36.0 * 7.0 + scaled_lift)
	piece._input(bottom_vertical_move)
	if not _check(piece._preview_valid and piece._preview_snap_origin == Vector2i(4,6),
			"Vertical piece would not snap its second tile to the last row"):return
	board.placed = Vector2i(-1,-1)
	var bottom_vertical_up := InputEventScreenTouch.new()
	bottom_vertical_up.index = 0
	bottom_vertical_up.pressed = false
	bottom_vertical_up.position = bottom_vertical_move.position + Vector2(0.0,55.0)
	piece._input(bottom_vertical_up)
	if not _check(board.placed == Vector2i(4,6),
			"Bottom-row vertical drop bounced back on finger-up"):return
	# Movement significantly beyond the last visible legal cell must still
	# fail; the new release tolerance must not place a distant stale ghost.
	board.placed = Vector2i(-1,-1)
	piece._gui_input(bottom_grab)
	piece._input(bottom_vertical_move)
	var far_bottom_up := InputEventScreenTouch.new()
	far_bottom_up.index = 0
	far_bottom_up.pressed = false
	far_bottom_up.position = bottom_vertical_move.position + Vector2(0.0,110.0)
	piece._input(far_bottom_up)
	if not _check(board.placed == Vector2i(-1,-1),
			"Distant downward drag incorrectly committed a stale eighth-row snap"):return
	piece.configure([Vector2i(0,0), Vector2i(1,0)],false,Color("#5396fa"),0)
	# When a shape extends beyond the right edge, magnetize to its nearest
	# legal origin instead of rejecting an almost-correct drop.
	var edge_finger := Vector2(57.0 + 36.0 * 7.0, 57.0 + 36.0 * 4.0 + 132.0)
	if not _check(Magnetic.choose(board, shape, edge_finger, Vector2i(-1,-1), 132.0, Vector2.ZERO) == Vector2i(6,4), "Right-edge placement did not pull towards the nearest legal fit"):return
	# The locked ghost must visually coincide with its footprint on this
	# input sample: a three-frame easing lag is not premium snapping.
	var snapped_ghost := Preview.new()
	root.add_child(snapped_ghost)
	snapped_ghost.configure(shape, Color("#5396fa"), 34.0)
	snapped_ghost.set_drag_target(Vector2(14.0, 20.0), true)
	snapped_ghost.set_drag_target(Vector2(144.0, 200.0), true)
	if not _check(snapped_ghost.position == Vector2(144.0, 200.0) and snapped_ghost.scale == Vector2.ONE, "Green ghost trails or scales away from the board target"):return
	snapped_ghost.queue_free()
	# Large changes or a visibly red/off-board preview must never place
	# the previous valid brick at its stale highlighted location.
	board.placed = Vector2i(-1, -1)
	piece._gui_input(press)
	piece._input(move)
	var moved_off_board := InputEventScreenDrag.new()
	moved_off_board.index = 0
	moved_off_board.position = Vector2(-800.0, 700.0)
	piece._input(moved_off_board)
	if not _check(not piece._preview_valid, "Off-board/red ghost kept a green snap latch"):return
	var off_board_release := InputEventScreenTouch.new()
	off_board_release.index = 0
	off_board_release.pressed = false
	off_board_release.position = moved_off_board.position
	piece._input(off_board_release)
	if not _check(board.placed == Vector2i(-1,-1), "Off-board release committed a stale snap"):return
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
	# A premium edge catch must include the legal first/last cell even
	# when a finger slightly beyond the board rounds TWO cells out of range.
	# This used to reject green-looking placements at outer columns/rows.
	var one_block: Array = [Vector2i(0,0)]
	var just_outside := Vector2(57.0 - 36.0 * 1.55,57.0 + 36.0 * 4.0 + 132.0)
	if not _check(Magnetic.choose(board,one_block,just_outside,Vector2i(-1,-1),132.0,Vector2.ZERO) == Vector2i(0,4),
			"Near-edge thumb drop could not magnetize to the first legal column"):return
	var far_outside := Vector2(57.0 - 36.0 * 2.6,57.0 + 36.0 * 4.0 + 132.0)
	if not _check(Magnetic.choose(board,one_block,far_outside,Vector2i(-1,-1),132.0,Vector2.ZERO) == Magnetic.NO_TARGET,
			"Far-off-board pointer was incorrectly accepted as a placement"):return
	var visible_finger := Vector2(57.0+36.0*3.0,57.0+36.0*4.0+132.0)
	if not _check(Magnetic.release_matches_visible_snap(board,one_block,
			visible_finger+Vector2(36.0*1.95,0.0),visible_finger,
			Vector2i(3,4),132.0,Vector2.ZERO),
			"Green footprint rejected modest Android finger-up jitter"):return
	if not _check(not Magnetic.release_matches_visible_snap(board,one_block,
			visible_finger+Vector2(36.0*2.55,0.0),visible_finger,
			Vector2i(3,4),132.0,Vector2.ZERO),
			"Distant finger-up committed a stale green board footprint"):return
	board.queue_free()
	await process_frame
	print("BLOCK_MAGNETIC_TARGET_OK: nearest touched tile, quick legal target, same-frame geometry, finger-up latch, red/offboard safety")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
