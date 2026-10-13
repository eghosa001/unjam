extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var games := root.get_node("MultiGameManager")
	var start := int(Time.get_unix_time_from_datetime_string("2026-10-14T12:00:00"))
	var seen := {"water_sort": {}, "block_puzzle": {}}
	for offset in range(432):
		var date := Time.get_date_string_from_unix_time(start + offset * 86400)
		var water := int(games.call("_daily_level_for_date", "water_sort", date))
		var block := int(games.call("_daily_level_for_date", "block_puzzle", date))
		for id in ["water_sort", "block_puzzle"]:
			var level := water if id == "water_sort" else block
			if not _check(level >= 51 and level <= 500 and level % 25 != 0,
				"Daily selected advanced/boss puzzle for %s on %s" % [id,date]):return
			if not _check(not seen[id].has(level),
				"Daily repeats the same %s level in 432 days: %d" % [id,level]):return
			seen[id][level] = true
		if not _check(water != block,
			"Two different Daily games share a rotation slot on %s" % date):return
	for id in ["water_sort", "block_puzzle"]:
		if not _check(seen[id].size() == 432,
			"Expected 432 distinct days for %s" % id):return

	# An Android update on 13 Oct must not replace an ongoing saved Daily.
	for id in ["water_sort", "block_puzzle"]:
		var key := "2026-10-13"
		var game_index := ["rescue_rush", "water_sort", "block_puzzle"].find(id)
		var expected := posmod(2026 * 372 + 10 * 31 + 13 + game_index * 997, 10000) + 1
		if not _check(int(games.call("_daily_level_for_date",id,key)) == expected,
			"Upgrade changed an in-progress historical Daily for %s" % id):return
	print("WATER_BLOCK_DAILY_ROTATION_OK: 432 unique approachable days per game, no level overlaps")
	quit(0)

func _check(ok: bool, reason: String) -> bool:
	if ok:
		return true
	push_error(reason)
	quit(1)
	return false
