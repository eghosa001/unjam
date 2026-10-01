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
		"const SFX_POOL_SIZE := 8",
		"const MUSIC_DURATION := 24.0",
		"const STARTUP_MUSIC_DURATION := 3.6",
		"const MUSIC_SYNTH_CHUNK_FRAMES := 4096",
		"func _start_music_immediately",
		"func _build_startup_ambient",
		"func _play_chime",
		"func _next_available_sfx_player",
		"not candidate.playing",
		"Never replace a waveform mid-play",
		"func snap()",
		"func _chime_stream",
		"func _build_calm_ambient_loop",
		"Fmaj9 -> Dm9 -> Bbmaj9 -> C6/9",
		"const SFX_VOLUME_DB := 1.0",
		"const SFX_GAIN_MULTIPLIER := 1.18",
		"const MUSIC_VOLUME_DB := -8.0",
		"const MUSIC_HANDOFF_FADE_SECONDS := 0.75",
		"func _handoff_to_music_stream() -> void:",
		"var delay_l := PackedFloat32Array()",
		"var music_intro_player: AudioStreamPlayer",
		"CalmAmbientIntro",
		"crossfade.set_parallel(true)",
		"func _ambient_pad_sample(chord: Array, t: float) -> float:",
		"func _smoothstep01(value: float) -> float:",
		"var delay_r := PackedFloat32Array()",
		"sfx.volume_db = SFX_VOLUME_DB",
		"volume * SFX_GAIN_MULTIPLIER",
		"release_raw",
		"var loop_edge := _smooth_edge(t, MUSIC_DURATION, 0.16)",
		"var note_step := 0.75",
		"var note_edge := _smooth_edge(note_phase, note_step, 0.045)",
		"var phrases := [",
		"var arpeggio :=",
		"var arp_frequency :=",
		"var arp_step := int(floor(local_t / 1.5)) % chord.size()",
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
	if not source.contains("[130.81, 196.00, 261.63, 293.66]"):
		failures.append("Ambient voicings must retain the mobile-safe Cadd9 final chord")

	var script = load(path)
	if script == null:
		failures.append("Feedback manager script failed to load")
	else:
		var feedback = script.new()
		var chime = feedback.call("_chime_stream", [392.0, 523.25], 0.12, 0.085, 0.4)
		if chime == null or not chime.stereo or int(chime.mix_rate) != 32000:
			failures.append("Calm chime stream must be stereo at 32000 Hz")
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
		var startup = feedback.call("_build_startup_ambient")
		if startup == null or startup.data.size() < 8 or int(startup.mix_rate) != 24000:
			failures.append("Startup ambient primer must be immediately available at 24000 Hz")
		var music = feedback.call("_build_calm_ambient_loop")
		if music == null or music.data.size() < 8:
			failures.append("Ambient loop generated no samples")
		else:
			var first := _pcm16(music.data, 0)
			var last := _pcm16(music.data, music.data.size() - 4)
			if absi(first) > 96 or absi(last) > 96:
				failures.append("Ambient loop seam must taper close to zero")
			for boundary_seconds in [6, 12, 18]:
				var frame: int = int(boundary_seconds) * int(music.mix_rate)
				var before := _pcm16(music.data, (frame - 1) * 4)
				var after := _pcm16(music.data, frame * 4)
				if absi(after - before) > 1200:
					failures.append("Ambient chord boundary has an audible PCM jump at %ds" % boundary_seconds)
			for step_index in range(1, 32):
				var note_time := float(step_index) * 0.75
				if note_time >= 24.0:
					break
				var note_frame: int = int(note_time * float(music.mix_rate))
				var note_before := _pcm16(music.data, (note_frame - 1) * 4)
				var note_after := _pcm16(music.data, note_frame * 4)
				if absi(note_after - note_before) > 900:
					failures.append("Ambient melody step has an audible PCM jump near %.2fs" % note_time)
			var reference_power := _goertzel_power(music.data, int(music.mix_rate), 174.61, 2.0)
			var low_power := 0.0
			for hz in [40.0, 55.0, 70.0, 85.0, 100.0]:
				low_power = maxf(low_power, _goertzel_power(music.data, int(music.mix_rate), hz, 2.0))
			if reference_power <= 0.0 or low_power > reference_power * 0.10:
				failures.append("Ambient loop still carries excessive sub-bass energy (low/reference %.4f)" % (low_power / maxf(reference_power, 0.000001)))
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
