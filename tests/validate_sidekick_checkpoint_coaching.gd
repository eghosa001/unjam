extends SceneTree

const Coach = preload("res://scripts/systems/sidekick_coach.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var standard := {"game":"water_sort","level":15,"daily":false,"moves":8,
		"tubes":[[1,2,1,2],[2,1,2,1],[]]}
	var original := standard.duplicate(true)
	var insight: Dictionary = Coach.checkpoint_guidance("water_sort",15,standard,0)
	if not _require(insight.active and insight.tip_index == 1 and String(insight.status).contains("1 EMPTY TUBES"),"Water strategy should reflect one open tube"):return
	if not _require(standard == original,"Coach mutated the saved game position"):return
	var stuck := {"game":"water_sort","level":15,"daily":false,"moves":13,
		"tubes":[[1,2,1,2],[2,1,2,1]]}
	insight = Coach.checkpoint_guidance("water_sort",15,stuck,0)
	if not _require(insight.active and String(insight.status).begins_with("NO LEGAL POUR"),"Stuck water board was not reported accurately"):return
	var spacious := {"game":"water_sort","level":15,"daily":false,"moves":1,
		"tubes":[[1,2,1,2],[2,1,2,1],[],[]]}
	insight = Coach.checkpoint_guidance("water_sort",15,spacious,2)
	if not _require(insight.active and insight.tip_index == 0,"Water guidance ignored safe working space"):return
	var empty_board := _block_board(0)
	insight = Coach.checkpoint_guidance("block_puzzle",11,{"game":"block_puzzle","level":11,"daily":false,"cells":empty_board,"placements":0},0)
	if not _require(insight.active and insight.tip_index == 2 and String(insight.status).contains("0/64 FILLED CELLS"),"Empty Block Puzzle strategy incorrect"):return
	var crowded := _block_board(52)
	insight = Coach.checkpoint_guidance("block_puzzle",11,{"game":"block_puzzle","level":11,"daily":false,"cells":crowded,"placements":9},2)
	if not _require(insight.active and insight.tip_index == 1 and String(insight.status).contains("52/64"),"Crowded Block board should prioritize clearing"):return
	var rescue := {"level":3,"daily":false,"pieces":[{"dir":"up"},{"dir":"down"}],"moves":6,"mistakes":2}
	insight = Coach.checkpoint_guidance("rescue_rush",3,rescue,0)
	if not _require(insight.active and insight.tip_index == 1 and String(insight.status).contains("2 BLOCKED TAPS"),"Rescue should respond to mistakes"):return
	for snapshot in [
		{}, {"game":"water_sort","level":14,"tubes":[[],[]]},
		{"game":"block_puzzle","level":15,"daily":true,"cells":crowded},
		{"game":"block_puzzle","level":15,"daily":false,"cells":[[]]},
		{"game":"water_sort","level":15,"daily":false,"tubes":[[1,2,3,4,5],[]]},
		{"game":"block_puzzle","level":15,"daily":false,"cells":[[1,2,3,4,5,6,7,8]]}
	]:
		var id := String(snapshot.get("game","water_sort"))
		insight = Coach.checkpoint_guidance(id,15,snapshot,2)
		if not _require(not bool(insight.get("active",false)) and insight.tip_index == 2,"Stale or malformed state must be ignored: %s" % str(snapshot)):return

	# Render the real secondary Sidekick screen with a saved Water puzzle, not just
	# a pure policy unit test. Navigation, tooltip and text-fitting remain covered
	# by the existing secondary UI viewport/overlap contract.
	root.size = Vector2i(432,936)
	var save := root.get_node_or_null("SaveManager")
	if not _require(save != null,"Save manager missing"):return
	var prior_runs = save.data.get("multi_active_runs",{}).duplicate(true)
	var prior_progress = save.data.get("game_progress",{}).duplicate(true)
	var progress: Dictionary = prior_progress.duplicate(true)
	var water: Dictionary = progress.get("water_sort",{}).duplicate(true)
	water["highest_level"] = 15
	progress["water_sort"] = water
	save.data["game_progress"] = progress
	save.data["multi_active_runs"] = {"water_sort":standard}
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _require(packed != null,"Main scene could not load"):return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(6): await process_frame
	main.call("show_playmate_sidekick","water_sort")
	for _i in range(3): await process_frame
	var status_label := main.find_child("SidekickTipStatus",true,false) as Label
	if not _require(status_label != null and status_label.text.contains("EMPTY TUBES"),"Sidekick did not render saved puzzle context"):return
	var next_tip := main.find_child("SidekickNextTip",true,false) as Button
	if not _require(next_tip != null and next_tip.size.x >= 150 and next_tip.size.y >= 48,"Sidekick actions are not usable"):return
	main.queue_free()
	await process_frame
	save.data["multi_active_runs"] = prior_runs
	save.data["game_progress"] = prior_progress
	save.save()
	print("SIDEKICK_CHECKPOINT_COACHING_OK: validated real checkpoint facts, safe fallback, and rendered coaching")
	quit(0)

func _block_board(filled: int) -> Array:
	var board := []
	for y in range(8):
		var row := []
		for x in range(8):
			row.append(y*8+x<filled)
		board.append(row)
	return board

func _require(value: bool, reason: String) -> bool:
	if value:return true
	push_error(reason)
	quit(1)
	return false
