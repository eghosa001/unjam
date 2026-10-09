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
	# First-time combo effects are generated from a finite, bounded WAV cache.
	# An indefinitely growing cache would accumulate PCM memory on long runs.
	var cache_limit := int(feedback.MAX_CACHED_CHIMES)
	var newest = null
	for n in range(cache_limit + 12):
		newest = feedback.call("_chime_stream",[330.0 + float(n)],0.048,0.065,0.33)
		if newest == null or newest.data.is_empty():
			return _fail("Audio waveform generation failed while warming unique tones")
	if (feedback.get("_stream_cache") as Dictionary).size() > cache_limit:
		return _fail("Audio waveform cache grew past its bounded capacity")
	var reused = feedback.call("_chime_stream",[330.0 + float(cache_limit + 11)],0.048,0.065,0.33)
	if not is_same(newest,reused):
		return _fail("Cached waveforms are regenerated during repeated sound effects")
	feedback.free()
	if previous < 8.0:
		_fail("Dense sound effects do not reserve sufficient mix headroom")
		return
	print("AUDIO_MIX_HEADROOM_OK")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
