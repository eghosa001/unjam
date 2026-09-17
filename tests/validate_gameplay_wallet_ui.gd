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

	var cases: Array = [
		["rescue_rush", "res://scenes/Game.tscn"],
		["water_sort", "res://scenes/WaterSort.tscn"],
		["block_puzzle", "res://scenes/BlockPuzzle.tscn"]
	]
	for case_value in cases:
		var case: Array = case_value
		var game_id := String(case[0])
		var scene_path := String(case[1])
		save.data.coins = 160
		save.save()
		var packed := load(scene_path) as PackedScene
		var game = packed.instantiate()
		game.level_number = 1
		root.add_child(game)
		await _frames(6)

		var hint := _find_button_with_text(game, "HINT")
		expect_true(hint != null, "%s Hint button missing" % game_id)
		if hint != null:
			expect_true("25" in hint.text and "160" in hint.text, "%s Hint does not disclose 25-coin cost and live 160 balance" % game_id)

		var tube := game.find_child("AddTubeAction", true, false) as Button
		if game_id == "water_sort":
			expect_true(tube != null, "Water Sort Extra Tube button missing")
			if tube != null:
				expect_true("75" in tube.text and "160" in tube.text, "Extra Tube does not disclose 75-coin cost and live balance")

		economy.grant(10, "qa_gameplay_wallet", {"game": game_id})
		await _frames(2)
		if hint != null:
			expect_true("170" in hint.text, "%s Hint wallet did not update after shared coin grant" % game_id)
		if tube != null:
			expect_true("170" in tube.text, "Extra Tube wallet did not update after shared coin grant")

		game.queue_free()
		await _frames(2)

	save.data.coins = original_coins
	save.save()
	_finish()

func _find_button_with_text(node: Node, needle: String) -> Button:
	for child in node.get_children():
		if child is Button and needle in (child as Button).text.to_upper():
			return child as Button
		var nested := _find_button_with_text(child, needle)
		if nested != null:
			return nested
	return null

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
