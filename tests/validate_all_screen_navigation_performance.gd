extends SceneTree
# Measured synchronous construction and route-to-visible timing for the real
# production Main.tscn. Intended for selective CI and performance regressions,
# not as an Android-device latency claim.
const WARM_SCENES := {
	"rescue_rush": "res://scenes/Game.tscn",
	"water_sort": "res://scenes/WaterSort.tscn",
	"block_puzzle": "res://scenes/BlockPuzzle.tscn",
}
var samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT", "1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if not _check(packed != null,"Production Main scene could not load"): return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	var baseline_nodes := _count_nodes(main)
	# First visit and repeat navigation use identical real UI builders.
	for repeat in range(2):
		for spec in [
			["home","build_home","home"],
			["games","_open_games_surface","live"],
			["rescue_levels","open_game_campaign","levels","rescue_rush"],
			["water_levels","open_game_campaign","levels","water_sort"],
			["block_levels","open_game_campaign","levels","block_puzzle"],
			["daily","build_daily_games","daily"],
			["weekly_rankings","build_compete_leaderboard","compete",false],
			["settings","build_settings","settings"],
			["collection","build_collection","collection"],
			["collection_upgrades","build_collection_upgrades","collection"],
			["goals","build_goals","goals"],
			["profile","build_profile","profile"],
			["friends","build_friends","friends",false],
		]:
			var args: Array = spec.slice(3)
			var route_name := "%s_%s" % ["repeat" if repeat == 1 else "first",String(spec[0])]
			if not _measure_route(main,route_name,String(spec[1]),String(spec[2]),args): return
			await _frames(2)
	# The Shop is built as a persistent CanvasLayer; opening it cannot
	# reconstruct the purchase UI or synchronously wait for the network.
	var hub := main.get_node_or_null("MonetizationHub")
	if not _check(hub != null and hub.has_method("open_shop"),"Missing production Shop"): return
	for i in range(2):
		var start := Time.get_ticks_usec()
		hub.call("open_shop")
		var micros := Time.get_ticks_usec() - start
		samples.append({"route":"shop_%d" % i,"us":micros,"node_count":_count_nodes(main)})
		print("NAVIGATION_PROFILE route=shop_%d elapsed_us=%d node_count=%d" % [i,micros,_count_nodes(main)])
		if hub.has_method("_close_shop"): hub.call("_close_shop")
		await _frames(2)
	# Warm game entry benchmarks actual synchronous scene creation, not loading
	# indicators. No fragile global 100-ms pass/fail on shared CI runners.
	var resources: Dictionary = main.get("_ready_game_scenes")
	for game_id in WARM_SCENES.keys():
		var scene_path := String(WARM_SCENES[game_id])
		var scene := load(scene_path) as PackedScene
		if not _check(scene != null,"Unable to warm " + scene_path): return
		resources[scene_path] = scene
	main.set("_ready_game_scenes",resources)
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		for run in range(2):
			var start := Time.get_ticks_usec()
			if game_id == "rescue_rush":
				main.call("start_level",1)
			else:
				main.call("start_multi_level",game_id,1,false)
			var micros := Time.get_ticks_usec()-start
			if not _check(String(main.get("current_surface")) == "game","Cached %s did not open gameplay immediately" % game_id): return
			samples.append({"route":"warm_%s_%d" % [game_id,run],"us":micros,"node_count":_count_nodes(main)})
			print("NAVIGATION_PROFILE route=warm_%s_%d elapsed_us=%d node_count=%d" % [game_id,run,micros,_count_nodes(main)])
			main.call("force_back_from_game")
			await _frames(3)
	var max_us := 0
	var slowest := ""
	for sample in samples:
		if int(sample["us"]) > max_us:
			max_us = int(sample["us"])
			slowest = String(sample["route"])
	print("NAVIGATION_PROFILE_SUMMARY samples=%d slowest=%s slowest_us=%d baseline_nodes=%d" % [samples.size(),slowest,max_us,baseline_nodes])
	main.queue_free()
	await _frames(12)
	print("ALL_SCREEN_NAVIGATION_AUDIT_OK")
	quit(0)

func _measure_route(main: Control, name: String, method: String, expected: String, args: Array) -> bool:
	if not _check(main.has_method(method),"Missing navigation route: "+method): return false
	var start := Time.get_ticks_usec()
	main.callv(method,args)
	var elapsed := Time.get_ticks_usec()-start
	var actual := String(main.get("current_surface"))
	if not _check(actual == expected,"%s sent to %s, expected %s" % [name,actual,expected]): return false
	var nodes := _count_nodes(main)
	samples.append({"route":name,"us":elapsed,"node_count":nodes})
	print("NAVIGATION_PROFILE route=%s elapsed_us=%d node_count=%d" % [name,elapsed,nodes])
	if not _check(elapsed < 2000000,"%s synchronous callback blocked over two seconds" % name): return false
	return true

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total

func _frames(count: int) -> void:
	for i in range(count): await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
