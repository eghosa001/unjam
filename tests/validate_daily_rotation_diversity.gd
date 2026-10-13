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

	rng.seed = 20261013
	var old_level := int(daily.call("_daily_source_level", "2026-10-13", rng))
	if not _check(old_level >= 51 and old_level <= 60, "Mid-day upgrades change the previous Daily puzzle"):return
	print("DAILY_ROTATION_DIVERSITY_OK: 432 unique boss-free calendar days and sampled solver-proven boards")
	quit(0)

func _check(ok: bool, detail: String) -> bool:
	if ok:return true
	push_error(detail)
	quit(1)
	return false
