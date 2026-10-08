extends SceneTree

func _initialize() -> void:
	var script := load("res://scripts/systems/feedback_manager.gd")
	if script == null:
		_fail("FeedbackManager audio implementation missing")
		return
	var feedback: Node = script.new()
	var previous := -0.1
	for voices in range(0, 10):
		var attenuation := float(feedback.call("_voice_headroom_db", voices))
		if attenuation < previous or attenuation < 0.0 or attenuation > 9.01:
			feedback.free()
			_fail("Audio concurrency reduction is not monotonic or bounded")
			return
		previous = attenuation
	feedback.free()
	if previous < 8.0:
		_fail("Dense sound effects do not reserve sufficient mix headroom")
		return
	print("AUDIO_MIX_HEADROOM_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
