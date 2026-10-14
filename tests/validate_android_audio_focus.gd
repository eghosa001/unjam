extends SceneTree

const Feedback = preload("res://scripts/systems/feedback_manager.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sound := Feedback.new()
	root.add_child(sound)
	await process_frame
	var fake_music := AudioStreamPlayer.new()
	sound.add_child(fake_music)
	sound.music_player = fake_music
	sound.music_stream = null

	sound.suspend_audio_for_background()
	if not _check(bool(sound.get("_audio_suspended")) and fake_music.stream_paused,
		"Pausing Android app must immediately suspend music"): return
	sound.suspend_audio_for_background()
	if not _check(fake_music.stream_paused,"Duplicate pause must preserve suspended state"): return
	sound.apply_settings()
	if not _check(fake_music.stream_paused,"Settings must not resume audio while backgrounded"): return
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
	sound.queue_free()
	await process_frame
	var text := FileAccess.get_file_as_string("res://scripts/systems/feedback_manager.gd")
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
