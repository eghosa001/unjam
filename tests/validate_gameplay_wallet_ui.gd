extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	var save = root.get_node_or_null("SaveManager")
	var economy = root.get_node_or_null("EconomyManager")
	expect_true(save != null and economy != null, "Economy autoloads missing")
	if save == null or economy == null:
		_finish()
		return
	var original_coins := int(save.data.get("coins", 0))
	var original_runs: Dictionary = save.data.get("multi_active_runs", {}).duplicate(true)

	var cases: Array = [
		["rescue_rush", "res://scenes/Game.tscn"],
		["water_sort", "res://scenes/WaterSort.tscn"],
		["block_puzzle", "res://scenes/BlockPuzzle.tscn"]
	]
	for case_value in cases:
		var case: Array = case_value
		var game_id := String(case[0])
		var scene_path := String(case[1])
		var isolated_runs: Dictionary = save.data.get("multi_active_runs", {}).duplicate(true)
		isolated_runs.erase(game_id)
		save.data["multi_active_runs"] = isolated_runs
		save.data.coins = 160
		save.save()
		var packed := load(scene_path) as PackedScene
		var game = packed.instantiate()
		game.level_number = 1
		root.add_child(game)
		await _frames(6)

		var hint_names := {"rescue_rush":"RescueHintAction","water_sort":"WaterHintAction","block_puzzle":"HintAction"}
		var hint := game.find_child(String(hint_names[game_id]), true, false) as Button
		expect_true(hint != null, "%s Hint button missing" % game_id)
		if hint != null:
			expect_true("25" in hint.tooltip_text and "160" in hint.tooltip_text, "%s Hint tooltip does not disclose 25-coin cost and live 160 balance" % game_id)
			if game_id == "block_puzzle":
				expect_true(hint.text == "💡", "Block Figma hint control was expanded beyond its icon-only design")

		var tube := game.find_child("AddTubeAction", true, false) as Button
		if game_id == "water_sort":
			expect_true(tube != null, "Water Sort Extra Tube button missing")
			if tube != null:
				expect_true(tube.text == "＋  TUBE • 75◈", "Extra Tube text drifted from the compact Figma action")
				expect_true("75" in tube.tooltip_text and "160" in tube.tooltip_text, "Extra Tube tooltip does not disclose 75-coin cost and live balance")

		economy.grant(10, "qa_gameplay_wallet", {"game": game_id})
		await _frames(2)
		if hint != null:
			expect_true("170" in hint.tooltip_text, "%s Hint wallet tooltip did not update after shared coin grant" % game_id)
		if tube != null:
			expect_true("170" in tube.tooltip_text, "Extra Tube wallet tooltip did not update after shared coin grant")

		game.queue_free()
		await _frames(2)

	save.data.coins = original_coins
	save.data["multi_active_runs"] = original_runs
	save.save()
	_finish()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("GAMEPLAY_WALLET_UI_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
