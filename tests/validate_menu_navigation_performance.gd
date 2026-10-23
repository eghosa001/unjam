extends SceneTree
# Targeted navigation performance benchmark. It never modifies a save,
# submits ranking results, claims rewards or starts a puzzle.
# Manual metric output is intended for before/after comparison, not a
# machine-independent latency promise.
const WARM_ROUNDS := 3
const SCREENS := ["settings","daily","goals","profile","collection","friends","compete","home"]
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		push_error("Navigation benchmark: Main.tscn missing")
		quit(1)
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(10)
	var results := {}
	for screen in SCREENS:
		var samples: Array[int] = []
		for pass_number in range(WARM_ROUNDS + 1):
			var before := Time.get_ticks_usec()
			match screen:
				"settings": main.call("build_settings")
				"daily": main.call("build_daily_games")
				"goals": main.call("build_goals")
				"profile": main.call("build_profile")
				"collection": main.call("build_collection")
				"friends": main.call("build_friends",false)
				"compete": main.call("build_compete_leaderboard",false)
				"home": main.call("build_home")
			var elapsed := Time.get_ticks_usec() - before
			samples.append(elapsed)
			await _frames(2)
		var warm := samples.slice(1)
		warm.sort()
		results[screen] = {"cold_us":samples[0],"warm_us":warm,"warm_med_us":warm[1]}
		print("NAV_LATENCY %s cold_us=%d warm_us=%s warm_median_us=%d" %
			[screen,samples[0],str(warm),warm[1]])
	# Warm scenes keep callback semantics and the complete surface visibly
	# available after one frame. This is the only hard benchmark assertion.
	main.call("build_settings")
	await _frames(1)
	if String(main.get("current_surface")) != "settings" or main.find_child("FigmaSurface390x844",true,false) == null:
		push_error("Menu navigation did not settle to Settings")
		quit(1)
		return
	main.queue_free()
	await _frames(2)
	print("NAV_LATENCY_BENCHMARK_OK")
	quit(0)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
