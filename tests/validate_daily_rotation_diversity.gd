extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var daily := root.get_node("DailyChallenge")
	var rng := RandomNumberGenerator.new()
	var start := Time.get_unix_time_from_datetime_string("2026-10-14T12:00:00")
	var sampled: Dictionary = {}
	var sources: Array[int] = []
	for day_index in range(432):
		var key := Time.get_datetime_string_from_unix_time(start + day_index * 86400).substr(0, 10)
		var level := int(daily.call("_daily_source_level", key, rng))
		if not _check(level >= 51 and level <= 500 and level % 25 != 0, "Daily content includes a boss/milestone at %s: %d" % [key,level]):return
		if not _check(not sampled.has(level), "Daily repeats a board within 432 days: %d" % level):return
		sampled[level] = true
		sources.append(level)
	if not _check(sampled.size() == 432, "Yearlong Daily cycle has repeated source levels"):return

	# Test a small, change-scoped solver sample rather than all 432 boards.
	# The actual candidate boards use the existing solver-confirmed generator.
	var board_signatures: Dictionary = {}
	for offset in [0, 70, 140, 210, 280, 350, 431]:
		var level := sources[offset]
		var board: Dictionary = CampaignGenerator.generate(level)
		if not _check(bool(board.get("solver_verified", false)), "Sampled Daily level has no solution: %d" % level):return
		var signature := String(board.get("structural_signature", ""))
		if not _check(not signature.is_empty() and not board_signatures.has(signature), "Daily sample has repeated board structure: %d" % level):return
		board_signatures[signature] = true

	# Exercise the LIVE autoload implementation (robust_daily_challenge.gd),
	# not only the base class that previously went unused in production.
	var save := root.get_node("SaveManager")
	var previous_level: Variant = save.data.get("highest_level", 1)
	for day in ["2026-10-14", "2026-12-01", "2027-10-13"]:
		var expected_level := int(daily.call("_daily_source_level", day, rng))
		var expected_signature := ""
		for account_level in [1, 9999]:
			save.data["highest_level"] = account_level
			var produced: Dictionary = daily.call("_build_for_key", day)
			if not _check(bool(produced.get("daily", false)) and String(produced.get("daily_key", "")) == day,
					"Live Daily generator lost date/mode metadata"):return
			if not _check(int(produced.get("daily_source_level", 0)) == expected_level,
					"High-progression players receive a different Daily challenge"):return
			var signature := String(produced.get("structural_signature", ""))
			if not _check(bool(produced.get("solver_verified", false)) and not signature.is_empty(),
					"Live Daily board was not solver-verified"):return
			if expected_signature.is_empty():
				expected_signature = signature
			if not _check(signature == expected_signature,
					"Daily level depends on player progression rather than calendar date"):return
	save.data["highest_level"] = previous_level

	rng.seed = 20261013
	var old_level := int(daily.call("_daily_source_level", "2026-10-13", rng))
	if not _check(old_level >= 51 and old_level <= 60, "Mid-day upgrades change the previous Daily puzzle"):return
	print("DAILY_ROTATION_DIVERSITY_OK: 432 days, solver-proven boards and equal Daily competition for every player")
	quit(0)

func _check(ok: bool, detail: String) -> bool:
	if ok:return true
	push_error(detail)
	quit(1)
	return false
