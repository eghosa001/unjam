extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func run() -> void:
	await process_frame
	var save_manager = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	var hints = root.get_node_or_null("HintManager")
	expect_true(save_manager != null and economy != null and hints != null, "Economy/Hint autoloads missing")
	if save_manager == null or economy == null or hints == null:
		_finish()
		return
	var original_coins := int(save_manager.data.get("coins", 0))
	var transactions: Array = []
	var callback := func(transaction: Dictionary) -> void:
		transactions.append(transaction.duplicate(true))
	economy.transaction_recorded.connect(callback)

	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		save_manager.data.coins = int(hints.HINT_COST)
		save_manager.save()
		var state := {"granted": 0}
		var accepted := bool(hints.request_hint(game_id, func() -> void: state.granted += 1))
		expect_true(accepted, "%s paid hint request was rejected" % game_id)
		expect_true(int(state.granted) == 1, "%s paid hint did not execute exactly once" % game_id)
		expect_true(int(save_manager.data.get("coins", -1)) == 0, "%s hint did not cost exactly 25 coins" % game_id)
		var last: Dictionary = transactions.back() if not transactions.is_empty() else {}
		expect_true(String(last.get("reason", "")) == "hint_%s" % game_id, "%s hint did not record semantic reason" % game_id)

	# No coins and no Main prompt host: request must not mutate wallet or execute.
	ProjectSettings.set_setting("monetization/test_mode", false)
	save_manager.data.coins = 0
	save_manager.save()
	var blocked := {"granted": false}
	var blocked_ok := bool(hints.request_hint("water_sort", func() -> void: blocked.granted = true))
	expect_true(not blocked_ok and not bool(blocked.granted), "Unaffordable hint executed without coins/ad recovery")
	expect_true(int(save_manager.data.get("coins", -1)) == 0, "Unaffordable hint changed wallet")

	# Water Sort Extra Tube is a paid one-use assist.
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	var game = packed.instantiate()
	game.level_number = 1
	root.add_child(game)
	await _frames(5)
	var starting_tubes := (game.get("tubes") as Array).size()
	save_manager.data.coins = 75
	save_manager.save()
	var first_ok = game.call("add_extra_tube")
	expect_true(first_ok == true, "Paid Extra Tube was not granted")
	expect_true(int(save_manager.data.get("coins", -1)) == 0, "Extra Tube did not cost exactly 75 coins")
	expect_true((game.get("tubes") as Array).size() == starting_tubes + 1, "Extra Tube did not append exactly one empty tube")
	var second_ok = game.call("add_extra_tube")
	expect_true(second_ok == false, "Second Extra Tube use should be rejected")
	expect_true(int(save_manager.data.get("coins", -1)) == 0, "Second Extra Tube tap charged again")
	game.queue_free()
	await _frames(2)

	if economy.transaction_recorded.is_connected(callback):
		economy.transaction_recorded.disconnect(callback)
	save_manager.data.coins = original_coins
	save_manager.save()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("ASSIST_ECONOMY_RUNTIME_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
