extends SceneTree

const FEEDBACK_PATH := "res://scripts/systems/feedback_manager.gd"
const MUSIC_PATH := "res://assets/audio/unjam_happy_lullaby.ogg"
const LICENSE_PATH := "res://assets/audio/UNJAM_HAPPY_LULLABY_LICENSE.txt"

func _initialize() -> void:
	var failures: Array[String] = []
	var source := _read(FEEDBACK_PATH)
	for token in [
		'const HAPPY_LULLABY_PATH := "res://assets/audio/unjam_happy_lullaby.ogg"',
		"const SFX_POOL_SIZE := 8",
		"const SFX_VOLUME_DB := 1.0",
		"const SFX_GAIN_MULTIPLIER := 1.18",
		"const MUSIC_VOLUME_DB := -7.0",
		"const MUSIC_START_DB := -48.0",
		"const MUSIC_FADE_IN_SECONDS := 0.90",
		'music_player.name = "HappyLullabyMusic"',
		"music_stream = load(HAPPY_LULLABY_PATH) as AudioStream",
		"var selected_track := music_stream as AudioStreamOggVorbis",
		"selected_track.loop = true",
		'fade.tween_property(music_player, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE_IN_SECONDS)',
		"func _play_chime",
		"func _next_available_sfx_player",
		"not candidate.playing",
		"Never replace a waveform mid-play",
		"func _chime_stream",
		"sfx.volume_db = SFX_VOLUME_DB",
		"volume * SFX_GAIN_MULTIPLIER",
	]:
		if not source.contains(token):
			failures.append("Missing selected-audio contract token: %s" % token)

	for forbidden in [
		'call_deferred("_ensure_music_stream")',
		"func _build_calm_ambient_loop",
		"func _build_startup_ambient",
		"CalmAmbientIntro",
	]:
		if source.contains(forbidden):
			failures.append("Rejected synthesized background-music path still active: %s" % forbidden)

	var license := _read(LICENSE_PATH)
	for token in [
		"Happy Lullaby (song17)",
		"cynicmusic",
		"The Cynic Project",
		"CC0",
		"opengameart.org/content/happy-lullaby-song17",
	]:
		if not license.contains(token):
			failures.append("Happy Lullaby provenance missing: %s" % token)

	var music = load(MUSIC_PATH)
	if music == null:
		failures.append("Happy Lullaby failed to import")
	elif not (music is AudioStreamOggVorbis):
		failures.append("Happy Lullaby must import as AudioStreamOggVorbis")
	else:
		var ogg := music as AudioStreamOggVorbis
		if ogg.get_length() < 20.0:
			failures.append("Happy Lullaby audio is unexpectedly short")
		var loop_copy := ogg.duplicate() as AudioStreamOggVorbis
		loop_copy.loop = true
		if not loop_copy.loop:
			failures.append("Happy Lullaby must support continuous looping")

	var script = load(FEEDBACK_PATH)
	if script == null:
		failures.append("Feedback manager script failed to load")
	else:
		var feedback = script.new()
		var chime = feedback.call("_chime_stream", [392.0, 523.25], 0.12, 0.085, 0.4)
		if chime == null or not chime.stereo or int(chime.mix_rate) != 32000:
			failures.append("Gameplay chime must remain stereo at 32000 Hz")
		elif chime.data.size() <= 0:
			failures.append("Gameplay chime generated no samples")
		else:
			var first := _pcm16(chime.data, 0)
			var last := _pcm16(chime.data, chime.data.size() - 4)
			if absi(first) > 96 or absi(last) > 96:
				failures.append("Gameplay chime must start/end close to zero")
		feedback.free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("HAPPY_LULLABY_AUDIO_OK")
	quit(0)

func _pcm16(bytes: PackedByteArray, offset: int) -> int:
	var value := int(bytes[offset]) | (int(bytes[offset + 1]) << 8)
	return value - 65536 if value >= 32768 else value

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
