extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save = root.get_node("SaveManager")
	var feedback = root.get_node("FeedbackManager")
	var original := bool(save.data.get("music", true))
	save.data["music"] = true
	feedback.last_music_enabled = false
	feedback.tap()
	var failures: Array[String] = []
	if feedback.last_music_enabled != true:
		failures.append("A settings tap must synchronize the music preference immediately")
	if feedback.is_processing():
		failures.append("FeedbackManager must not poll settings every frame")
	save.data["music"] = original
	if feedback.has_method("apply_settings"):
		feedback.apply_settings()
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("FeedbackManager music sync is event-driven through user feedback events.")
	quit(0)
