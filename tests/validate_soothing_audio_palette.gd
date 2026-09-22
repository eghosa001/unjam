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
		"func _next_available_sfx_player",
		"not candidate.playing",
		"Never replace a waveform mid-play",
		"func snap()",
		"func _chime_stream",
		"func _build_calm_ambient_loop",
		"Fmaj7 -> Dm7 -> Bbmaj7 -> Cadd9",
		"music_player.volume_db = -11.0",
		"var body_tone := sin(TAU * float(chord[0]) * t) * 0.008 * edge",
		"sfx.volume_db = -3.0",
		"release_raw",
		"var loop_edge := _smooth_edge(t, MUSIC_DURATION, 0.38)",
		"var pulse_edge := _smooth_edge(pulse_phase, 2.0, 0.035)",
		"* edge * loop_edge",
		"root * 1.5",
	]:
		if not source.contains(token):
			failures.append("Missing calm-audio contract token: %s" % token)
	if source.contains("var target := sfx_players[_sfx_cursor % sfx_players.size()]"):
		failures.append("SFX pool must not overwrite a possibly active channel")
	if source.contains("func _play_tone"):
		failures.append("Legacy single-sine feedback path must not remain active")
	if source.contains("1120.0"):
		failures.append("Legacy piercing rescue tone must not remain")
	if source.contains("float(chord[0]) * 0.5"):
		failures.append("Ambient loop must not reintroduce a half-frequency sub-bass oscillator")
	if source.contains("base * 0.501"):
		failures.append("Ambient pad must not reintroduce the near-half-frequency 58-87 Hz partial")
	if source.contains("TAU * 0.083 * t"):
		failures.append("Ambient loop must not mix sub-audible oscillator energy directly into PCM")
	if source.contains("[58.27, 73.42, 87.31, 110.00]"):
		failures.append("Ambient chord voicings must stay above phone-rumble bass territory")
	if source.contains("[196.00, 293.66, 392.00, 440.00]"):
		failures.append("Ambient loop must not reintroduce the former 196 Hz bass-root voicing")
	if not source.contains("[261.63, 329.63, 392.00, 493.88]"):
		failures.append("Ambient voicings must retain the raised mobile-safe final chord")

	var script = load(path)
	if script == null:
		failures.append("Feedback manager script failed to load")
	else:
		var feedback = script.new()
		var chime = feedback.call("_chime_stream", [392.0, 523.25], 0.12, 0.085, 0.4)
		if chime == null or not chime.stereo or int(chime.mix_rate) != 22050:
			failures.append("Calm chime stream must be stereo at 22050 Hz")
		elif chime.data.size() <= 0:
			failures.append("Calm chime stream generated no samples")
		else:
			var chime_first := _pcm16(chime.data, 0)
			var chime_last := _pcm16(chime.data, chime.data.size() - 4)
			if absi(chime_first) > 96 or absi(chime_last) > 96:
				failures.append("Calm chime must enter and leave near zero to avoid clicks")
			var chime_peak := _pcm_peak(chime.data)
			if chime_peak < 900:
				failures.append("Calm chime became too quiet to provide tactile confirmation")
			if chime_peak > 20000:
				failures.append("Calm chime lost safe PCM headroom")
		var music = feedback.call("_build_calm_ambient_loop")
		if music == null or music.data.size() < 8:
			failures.append("Ambient loop generated no samples")
		else:
			var first := _pcm16(music.data, 0)
			var last := _pcm16(music.data, music.data.size() - 4)
			if absi(first) > 96 or absi(last) > 96:
				failures.append("Ambient loop seam must taper close to zero")
			for boundary_seconds in [8, 16, 24]:
				var frame: int = int(boundary_seconds) * int(music.mix_rate)
				var before := _pcm16(music.data, (frame - 1) * 4)
				var after := _pcm16(music.data, frame * 4)
				if absi(after - before) > 1200:
					failures.append("Ambient chord boundary has an audible PCM jump at %ds" % boundary_seconds)
			for pulse_seconds in range(2, 32, 2):
				var pulse_frame: int = int(pulse_seconds) * int(music.mix_rate)
				var pulse_before := _pcm16(music.data, (pulse_frame - 1) * 4)
				var pulse_after := _pcm16(music.data, pulse_frame * 4)
				if absi(pulse_after - pulse_before) > 900:
					failures.append("Ambient mallet pulse has an audible PCM jump at %ds" % pulse_seconds)
			var reference_power := _goertzel_power(music.data, int(music.mix_rate), 261.63, 2.0)
			var low_power := 0.0
			for hz in [40.0, 60.0, 80.0, 100.0, 120.0, 150.0]:
				low_power = maxf(low_power, _goertzel_power(music.data, int(music.mix_rate), hz, 2.0))
			if reference_power <= 0.0 or low_power > reference_power * 0.12:
				failures.append("Ambient loop still carries excessive low-frequency energy (low/reference %.4f)" % (low_power / maxf(reference_power, 0.000001)))
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

func _pcm_peak(bytes: PackedByteArray) -> int:
	var peak := 0
	for offset in range(0, bytes.size() - 3, 4):
		peak = maxi(peak, absi(_pcm16(bytes, offset)))
		peak = maxi(peak, absi(_pcm16(bytes, offset + 2)))
	return peak

func _goertzel_power(bytes: PackedByteArray, sample_rate: int, frequency: float, seconds: float) -> float:
	var frame_count := mini(int(float(sample_rate) * seconds), int(bytes.size() / 4))
	if frame_count <= 0:
		return 0.0
	var omega := TAU * frequency / float(sample_rate)
	var coeff := 2.0 * cos(omega)
	var s1 := 0.0
	var s2 := 0.0
	for frame in range(frame_count):
		var sample := float(_pcm16(bytes, frame * 4)) / 32768.0
		var s0 := sample + coeff * s1 - s2
		s2 = s1
		s1 = s0
	return s1 * s1 + s2 * s2 - coeff * s1 * s2
