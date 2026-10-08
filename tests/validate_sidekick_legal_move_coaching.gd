extends SceneTree

const Coach = preload("res://scripts/systems/sidekick_coach.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var water := {"game":"water_sort","level":15,"daily":false,"moves":2,
		"tubes":[[1,2],[2,2],[]]}
	var original := water.duplicate(true)
	var tip: Dictionary = Coach.checkpoint_guidance("water_sort",15,water,1)
	var action: Dictionary = tip.get("action",{})
	if not _check(tip.active and action.get("kind","") == "water_pour" and int(action.get("source",0)) == 1 and int(action.get("target",0)) == 2, "Water Sidekick missed a legal same-colour merge"):return
	if not _check(water == original, "Water guidance must not mutate the real puzzle"):return
	water["daily"] = true
	if not _check((Coach.checkpoint_guidance("water_sort",15,water,1).get("action",{}) as Dictionary).is_empty(), "Daily ranked state must never yield an action"):return
	water["daily"] = false
	water["level"] = 14
	if not _check((Coach.checkpoint_guidance("water_sort",15,water,1).get("action",{}) as Dictionary).is_empty(), "Stale level must never yield an action"):return

	var block := {"game":"block_puzzle","level":11,"daily":false,
		"cells":_board(0),"pieces":[[Vector2i(0,0),Vector2i(1,0)]],"placements":1}
	tip = Coach.checkpoint_guidance("block_puzzle",11,block,2)
	action = tip.get("action",{})
	if not _check(action.get("kind","") == "block_place" and int(action.get("piece",0)) == 1 and int(action.get("row",0)) == 1, "Block Sidekick missed a legal placement"):return
	block["campaign_special_cells"] = {"0":{"kind":"preserve","layers":1}}
	tip = Coach.checkpoint_guidance("block_puzzle",11,block,2)
	action = tip.get("action",{})
	if not _check(int(action.get("col",0)) > 1 or int(action.get("row",0)) > 1, "Block suggestion ignored preserve-cell restriction"):return
	block["cells"] = _board(63)
	tip = Coach.checkpoint_guidance("block_puzzle",11,block,1)
	if not _check((tip.get("action",{}) as Dictionary).is_empty() and not String(tip.get("recovery_tip","")).is_empty(), "Stuck Block position must give recovery advice, not an illegal placement"):return

	var locale := root.get_node_or_null("LocalizationManager")
	if not _check(locale != null, "Localization manager missing"):return
	var original_language := String(locale.get("language_code"))
	for language in ["es","fr","pt","de","it","ha","yo","ig"]:
		locale.set_language(language,false)
		if not _check(locale.localize("LEGAL MOVE, NOT A SOLUTION") != "LEGAL MOVE, NOT A SOLUTION", "Legal move disclaimer missing in %s" % language):return
	locale.set_language("en",false)

	var save := root.get_node_or_null("SaveManager")
	if not _check(save != null,"Save manager missing"):return
	var old_data: Dictionary = save.data.duplicate(true)
	var progress: Dictionary = save.data.get("game_progress",{}).duplicate(true)
	var game_progress: Dictionary = progress.get("water_sort",{}).duplicate(true)
	game_progress["highest_level"] = 15
	progress["water_sort"] = game_progress
	save.data["game_progress"] = progress
	water["level"] = 15
	save.data["multi_active_runs"] = {"water_sort":water}
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Main scene missing"):return
	var main := packed.instantiate() as Control
	root.size = Vector2i(432,936)
	root.add_child(main)
	for _i in range(7): await process_frame
	main.call("show_playmate_sidekick","water_sort")
	for _i in range(3): await process_frame
	var view := main.find_child("SidekickTip",true,false) as Label
	if not _check(view != null and view.text.contains("TUBE") and view.text.contains("LEGAL MOVE"),"Sidekick UI did not show the validated Water action"):return
	main.queue_free()
	await process_frame
	save.data = old_data
	save.save()
	locale.set_language(original_language,false)
	print("SIDEKICK_LEGAL_MOVE_COACHING_OK: verified legal moves, preserve restrictions, fallback and translated disclaimers")
	quit(0)

func _board(filled: int) -> Array:
	var board: Array = []
	for row in range(8):
		var cells: Array = []
		for col in range(8):
			cells.append(row * 8 + col < filled)
		board.append(cells)
	return board

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
