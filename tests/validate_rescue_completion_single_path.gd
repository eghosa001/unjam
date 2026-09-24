extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	var multi := root.get_node_or_null("MultiGameManager")
	if save == null or multi == null:
		return _fail("Required progression autoloads are missing")
	var original: Dictionary = save.data.duplicate(true)

	save.data["stars"] = {}
	save.data["highest_level"] = 1
	save.data["rescued"] = []
	save.data["total_rescues"] = 0
	save.data["daily_mission_progress"] = {}
	save.data["daily_unique_levels"] = []
	save.data["weekly_played_levels"] = []
	save.data["weekly_points"] = 0
	save.data["season_points"] = 0
	save.data["event_currency"] = 0
	save.data["event_daily_earned"] = 0
	save.data["win_streak"] = 0
	save.data["rescue_variants"] = []

	multi.call("complete_level", "rescue_rush", 25, 3, 0, {
		"moves": 6,
		"par_moves": 8,
		"chain_count": 2,
		"rescue_id": "qa_puppy",
		"hints_used": 0,
		"difficulty": "hard"
	})

	var errors: Array[String] = []
	if "qa_puppy" not in save.data.get("rescued", []):
		errors.append("Rescue completion did not persist the rescued character")
	if int(save.data.get("total_rescues", 0)) != 1:
		errors.append("Rescue completion did not increment total rescues exactly once")
	if int(save.data.get("win_streak", 0)) != 1:
		errors.append("Rescue completion did not update retention exactly once")
	if int(save.data.get("weekly_points", 0)) <= 0 or int(save.data.get("season_points", 0)) <= 0:
		errors.append("Rescue completion did not reach shared retention progression")

	save.data = original
	save.save()

	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	print("RESCUE_COMPLETION_SINGLE_PATH_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
