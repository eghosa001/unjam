extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save = root.get_node("SaveManager")
	var feedback = root.get_node("FeedbackManager")
	var original := bool(save.data.get("music", true))
	var failures: Array[String] = []

	save.data["music"] = true
	feedback.last_music_enabled = false
	feedback.tap()
	if feedback.last_music_enabled != false:
		failures.append("Ordinary tap feedback must not synchronize or restart music")

	feedback.apply_settings()
	if feedback.last_music_enabled != true:
		failures.append("Explicit settings application must synchronize music immediately")
	if feedback.is_processing():
		failures.append("FeedbackManager must not poll settings every frame")

	save.data["music"] = original
	feedback.apply_settings()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("MUSIC_SETTINGS_SYNC_ONLY_ON_EXPLICIT_SETTINGS_CHANGE")
	quit(0)
