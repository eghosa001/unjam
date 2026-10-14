extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sound := root.get_node_or_null("FeedbackManager")
	if not _check(sound != null,"FeedbackManager autoload missing"): return
	await process_frame
	var fake_music := AudioStreamPlayer.new()
	fake_music.stream = AudioStreamGenerator.new()
	sound.add_child(fake_music)
	fake_music.play()
	sound.music_player = fake_music
	sound.music_stream = null

	sound.suspend_audio_for_background()
	if not _check(bool(sound.get("_audio_suspended")),
		"Pausing Android app must immediately enter audio suspension"): return
	if fake_music.playing and not _check(fake_music.stream_paused,
		"Active music stream was not paused"): return
	sound.suspend_audio_for_background()
	if not _check(bool(sound.get("_audio_suspended")),"Duplicate pause must preserve suspended state"): return
	sound.apply_settings()
	if not _check(bool(sound.get("_audio_suspended")),"Settings must not resume audio while backgrounded"): return
	sound.resume_audio_after_background()
	if not _check(not bool(sound.get("_audio_suspended")) and not fake_music.stream_paused,
		"Foreground recovery must restore only the audio player state"): return
	sound.resume_audio_after_background()
	if not _check(not bool(sound.get("_audio_suspended")),"Repeat foreground signal must be idempotent"): return
	var save := root.get_node_or_null("SaveManager")
	if not _check(save != null,"SaveManager required"): return
	var enabled_before := bool(save.data.get("music",true))
	sound.suspend_audio_for_background()
	if not _check(bool(save.data.get("music",true)) == enabled_before,
		"Backgrounding must never overwrite user's music preference"): return
	sound.resume_audio_after_background()
	sound.music_player = null
	fake_music.queue_free()
	await process_frame
	var text := FileAccess.get_file_as_string("res://scripts/systems/feedback_manager.gd")
	if not _check(text.contains("music_player.stream_paused = true") and text.contains("music_player.stream_paused = false"),
		"Background music must pause and resume without resetting its stream"): return
	if not _check(text.contains("NOTIFICATION_APPLICATION_PAUSED") and text.contains("NOTIFICATION_APPLICATION_RESUMED"),
		"Audio focus lifecycle must be wired to actual Android app notifications"): return
	if not _check(text.contains("if _audio_suspended or sfx_players.is_empty()"),
		"Suspended app must not generate chimes on callbacks"): return
	print("ANDROID_BACKGROUND_AUDIO_FOCUS_OK")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
