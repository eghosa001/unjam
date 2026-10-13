extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var starter = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	starter.level_number = 2
	starter.play_mode = "campaign"
	root.add_child(starter)
	for _i in range(6): await process_frame
	if not _check(starter.booster_buttons.size() == 4, "All booster functions must remain available after onboarding"):return
	for key in ["hammer","shuffle","rotate"]:
		if not _check(not (starter.booster_buttons[key] as Button).visible, "Paid %s booster obstructs first-play board" % key):return
	var undo := starter.booster_buttons["undo"] as Button
	if not _check(undo.visible and undo.text.contains("FREE"), "Starter Undo does not disclose free first use"):return
	if not _check(int(starter.call("_booster_price","undo")) == 0, "First beginner Undo is unexpectedly paid"):return
	var coins_before: int = int(root.get_node("EconomyManager").call("balance"))
	if not _check(bool(starter.call("_spend_booster","undo")), "Free starter Undo was rejected"):return
	if not _check(coins_before == int(root.get_node("EconomyManager").call("balance")), "Starter Undo unexpectedly charged coins"):return
	starter.booster_uses["undo"] = 1
	starter.call("_refresh_booster_buttons")
	if not _check(int(starter.call("_booster_price","undo")) == 20 and undo.text.contains("20"), "Subsequent Undo cost is not disclosed"):return
	starter.queue_free()
	await process_frame

	var mature = (load("res://scenes/BlockPuzzle.tscn") as PackedScene).instantiate()
	mature.level_number = 5
	mature.play_mode = "campaign"
	root.add_child(mature)
	for _i in range(5): await process_frame
	for key in ["undo","hammer","shuffle","rotate"]:
		if not _check((mature.booster_buttons[key] as Button).visible, "Progression level 5 permanently hides %s booster" % key):return
	if not _check(int(mature.call("_booster_price","undo")) == 20, "Full game Undo price changed"):return
	mature.queue_free()
	await process_frame
	print("BLOCK_STARTER_FOCUS_OK: 3 beginner puzzles teach first, first Undo free, standard boosters return")
	quit(0)

func _check(ok: bool, why: String) -> bool:
	if ok: return true
	push_error(why)
	quit(1)
	return false
