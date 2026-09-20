extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var path := "res://scripts/systems/feedback_manager.gd"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Feedback manager source missing")
		quit(1)
		return
	var source := file.get_as_text()
	for token in [
		"const SFX_POOL_SIZE := 5",
		"const MUSIC_DURATION := 32.0",
		"func _play_chime",
		"func snap()",
		"func _chime_stream",
		"func _build_calm_ambient_loop",
		"Fmaj7 -> Dm7 -> Bbmaj7 -> Cadd9",
		"music_player.volume_db = -10.0",
		"sfx.volume_db = 0.0",
		"release_raw",
		"var loop_edge := _smooth_edge(t, MUSIC_DURATION, 0.38)",
		"* edge * loop_edge",
		"root * 1.5",
	]:
		if not source.contains(token):
			failures.append("Missing calm-audio contract token: %s" % token)
	if source.contains("func _play_tone"):
		failures.append("Legacy single-sine feedback path must not remain active")
	if source.contains("1120.0"):
		failures.append("Legacy piercing rescue tone must not remain")

	var script = load(path)
	if script == null:
		failures.append("Feedback manager script failed to load")
	else:
		var feedback = script.new()
		var chime = feedback.call("_chime_stream", [392.0, 523.25], 0.12, 0.07, 0.4)
		if chime == null or not chime.stereo or int(chime.mix_rate) != 22050:
			failures.append("Calm chime stream must be stereo at 22050 Hz")
		elif chime.data.size() <= 0:
			failures.append("Calm chime stream generated no samples")
		var music = feedback.call("_build_calm_ambient_loop")
		if music == null or music.data.size() < 8:
			failures.append("Ambient loop generated no samples")
		else:
			var first := _pcm16(music.data, 0)
			var last := _pcm16(music.data, music.data.size() - 4)
			if absi(first) > 96 or absi(last) > 96:
				failures.append("Ambient loop seam must taper close to zero")
		feedback.free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("SOOTHING_AUDIO_PALETTE_OK")
	quit(0)


func _pcm16(bytes: PackedByteArray, offset: int) -> int:
	var value := int(bytes[offset]) | (int(bytes[offset + 1]) << 8)
	return value - 65536 if value >= 32768 else value
