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
