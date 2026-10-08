extends SceneTree

const Coach = preload("res://scripts/systems/sidekick_coach.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cases := [
		["rescue_rush", 1, 0, 0, 1],
		["rescue_rush", 38, 2, 0, 1],
		["rescue_rush", 86, 3, 0, 2],
		["rescue_rush", 38, 3, 4, 0],
		["water_sort", 12, 0, 0, 1],
		["water_sort", 48, 1, 0, 1],
		["water_sort", 140, 3, 5, 2],
		["block_puzzle", 5, 0, 0, 2],
		["block_puzzle", 75, 2, 0, 1],
		["block_puzzle", 140, 3, 4, 0],
		["block_puzzle", 10001, 3, 4, 0]
	]
	for entry in cases:
		var index := Coach.recommended_tip_index(String(entry[0]), int(entry[1]), int(entry[2]), int(entry[3]))
		if index != int(entry[4]):
			push_error("Sidekick recommended incorrect strategy for %s: got %d instead of %d" % [str(entry), index, int(entry[4])])
			quit(1)
			return
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		for level in [1, 10, 75, 100, 10000, 10001]:
			for stars in [0, 1, 2, 3]:
				var index := Coach.recommended_tip_index(game_id, level, stars, 3)
				if index < 0 or index >= 3:
					push_error("Sidekick returned an out-of-bounds tip index")
					quit(1)
					return
	print("SIDEKICK_PROGRESS_COACHING_OK: performance-aware guidance stays within the three curated tips")
	quit(0)
