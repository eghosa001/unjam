extends SceneTree

const MUSIC_PATH := "res://assets/audio/unjam_puzzle_theme.ogg"
const LICENSE_PATH := "res://assets/audio/UNJAM_PUZZLE_THEME_LICENSE.txt"
const FEEDBACK_PATH := "res://scripts/systems/feedback_manager.gd"

func _initialize() -> void:
	var failures: Array[String] = []
	var source := _read(FEEDBACK_PATH)
	for token in [
		'const HUMAN_MUSIC := preload("res://assets/audio/unjam_puzzle_theme.ogg")',
		"const SFX_POOL_SIZE := 8",
		"const SFX_VOLUME_DB := 1.0",
		"const SFX_GAIN_MULTIPLIER := 1.18",
		"const MUSIC_VOLUME_DB := -7.0",
		"const MUSIC_FADE_IN_SECONDS := 0.90",
		"const MUSIC_PITCH_SCALE := 0.995",
		"music_stream = HUMAN_MUSIC.duplicate()",
		"var ogg := music_stream as AudioStreamOggVorbis",
		"ogg.loop = true",
		"music_player.pitch_scale = MUSIC_PITCH_SCALE",
		'fade.tween_property(music_player, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE_IN_SECONDS)',
		"func _play_chime",
		"func _next_available_sfx_player",
		"not candidate.playing",
		"func _chime_stream",
		"volume * SFX_GAIN_MULTIPLIER",
	]:
		if not source.contains(token):
			failures.append("Missing human-audio contract token: %s" % token)

	if source.contains('call_deferred("_ensure_music_stream")'):
		failures.append("Background music must not wait for synthesized music generation")
	if source.contains('music_intro_player = AudioStreamPlayer.new()'):
		failures.append("Generated startup primer must not compete with the human track")

	var license := _read(LICENSE_PATH)
	for token in ["Cozy Puzzle In-Game 2", "MintoDog", "CC0", "opengameart.org/content/cozy-puzzle-in-game-2"]:
		if not license.contains(token):
			failures.append("Music provenance missing: %s" % token)

	var music = load(MUSIC_PATH)
	if music == null:
		failures.append("Human puzzle music failed to load")
	elif not (music is AudioStreamOggVorbis):
		failures.append("Human puzzle music must import as AudioStreamOggVorbis")
	else:
		var ogg := music as AudioStreamOggVorbis
		if ogg.get_length() < 100.0:
			failures.append("Human puzzle music is unexpectedly short")
		var looped := ogg.duplicate() as AudioStreamOggVorbis
		looped.loop = true
		if not looped.loop:
			failures.append("Human puzzle music must support continuous looping")

	var script = load(FEEDBACK_PATH)
	if script == null:
		failures.append("Feedback manager script failed to load")
	else:
		var feedback = script.new()
		var chime = feedback.call("_chime_stream", [392.0, 523.25], 0.12, 0.085, 0.4)
		if chime == null or not chime.stereo or int(chime.mix_rate) != 32000:
			failures.append("Interaction chime must remain stereo at 32000 Hz")
		elif chime.data.size() <= 0:
			failures.append("Interaction chime generated no samples")
		else:
			var first := _pcm16(chime.data, 0)
			var last := _pcm16(chime.data, chime.data.size() - 4)
			if absi(first) > 96 or absi(last) > 96:
				failures.append("Interaction chime must enter and leave near zero")
		feedback.free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("HUMAN_PUZZLE_AUDIO_OK")
	quit(0)

func _pcm16(bytes: PackedByteArray, offset: int) -> int:
	var value := int(bytes[offset]) | (int(bytes[offset + 1]) << 8)
	return value - 65536 if value >= 32768 else value

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()
