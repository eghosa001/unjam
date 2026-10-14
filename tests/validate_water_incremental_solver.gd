extends SceneTree

const WaterSolver = preload("res://scripts/core/water_sort_solver.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Incremental state machine must return the SAME first winning move
	# as the established synchronous solution search, not a random legal pour.
	var state := [[0,1,0,1],[1,0,1,0],[],[]]
	var reference: Vector2i = WaterSolver.best_move(state,4000)
	if reference == WaterSolver.NO_MOVE:
		return _fail("Known Water Sort fixture was unexpectedly unsolved")
	var job := WaterSolver.begin_search(state,4000)
	var report: Dictionary = {}
	for i in range(600):
		report = WaterSolver.advance_search(job,8)
		if bool(report.get("done",false)):
			break
	if not bool(report.get("done",false)) or report.get("move",WaterSolver.NO_MOVE) != reference:
		return _fail("Frame-sliced solver differs from established verified move")
	if int(job.get("expanded",0)) > 4000:
		return _fail("Solver frame budget exceeded cumulative state limit")

	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water Sort scene unavailable")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var save := root.get_node("SaveManager")
	var starting_coins := int(save.data.get("coins",0))
	var requested: bool = bool(game.call("request_verified_hint"))
	if not requested or not bool(game.get("_hint_preparing")):
		return _fail("Water Hint did not enter its nonblocking verification state")
	if int(save.data.get("coins",0)) != starting_coins:
		return _fail("Water Hint charged coins before verification completed")
	# A moved board invalidates the original proof; never auto-apply a
	# stale hint, silently charge or keep an unbounded pending worker.
	var modified: Array = (game.get("tubes") as Array).duplicate(true)
	modified.append([])
	game.set("tubes",modified)
	for _i in range(5):
		await process_frame
	if bool(game.get("_hint_preparing")):
		return _fail("Moving bottles did not cancel stale solver computation")
	if int(save.data.get("coins",0)) != starting_coins:
		return _fail("Cancelling an unverified Hint changed the wallet")
	game.queue_free()
	await process_frame
	print("WATER_HINT_FRAMES_OK: winning path parity, input remains responsive, no premature charge")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
