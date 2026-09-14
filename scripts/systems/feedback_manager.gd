extends Node

var player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_stream: AudioStreamWAV
var last_music_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	# Headless validation has no audio device and can retain a generated WAV
	# playback until engine teardown. Skip audio objects there; device builds keep
	# the exact same sound/music behaviour.
	if DisplayServer.get_name() == "headless":
		return
	player = AudioStreamPlayer.new()
	add_child(player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -11.0
	add_child(music_player)
	music_stream = _build_ambient_loop()
	music_player.stream = music_stream
	_sync_music()

func _exit_tree() -> void:
	# Release generated WAV/playback references explicitly. Headless test runs exit
	# immediately after interactions, so relying on shutdown order can leave the
	# current AudioStreamPlaybackWAV referenced by the player at ObjectDB cleanup.
	if player != null:
		player.stop()
		player.stream = null
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	music_stream = null

func _process(_delta: float) -> void:
	var enabled := bool(SaveManager.data.get("music", true))
	if enabled != last_music_enabled:
		_sync_music()

func _sync_music() -> void:
	last_music_enabled = bool(SaveManager.data.get("music", true))
	if music_player == null:
		return
	if last_music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()

func tap() -> void:
	_play_tone(540.0, 0.045, 0.16)
	_vibrate(12)

func blocked() -> void:
	_play_tone(180.0, 0.08, 0.20)
	_vibrate(28)

func escape(chain: int = 1) -> void:
	_play_tone(620.0 + float(min(chain, 8)) * 70.0, 0.07, 0.22)
	_vibrate(18)

func effect() -> void:
	_play_tone(880.0, 0.09, 0.24)
	_vibrate(32)

func rescue() -> void:
	_play_tone(1040.0, 0.18, 0.28)
	_vibrate(55)

func _vibrate(ms: int) -> void:
	if bool(SaveManager.data.get("vibration", true)):
		Input.vibrate_handheld(ms)

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	if player == null or not bool(SaveManager.data.get("sound", true)):
		return
	var rate := 22050
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var fade := 1.0 - float(i) / float(max(frames, 1))
		var sample := sin(TAU * frequency * float(i) / float(rate)) * volume * fade
		_write_sample(bytes, i, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	player.stream = stream
	player.play()

func _build_ambient_loop() -> AudioStreamWAV:
	var rate := 11025
	var duration := 6.0
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var notes := [130.81, 164.81, 196.00, 261.63]
	for i in range(frames):
		var t := float(i) / float(rate)
		var envelope := 0.6 + 0.4 * sin(TAU * t / duration)
		var sample := 0.0
		for f in notes:
			sample += sin(TAU * float(f) * t)
		var pulse := 0.72 + 0.28 * sin(TAU * t * 0.5)
		sample = sample / float(notes.size()) * 0.16 * envelope * pulse
		_write_sample(bytes, i, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func _write_sample(bytes: PackedByteArray, frame: int, sample: float) -> void:
	var value := int(clamp(sample, -1.0, 1.0) * 32767.0)
	bytes[frame * 2] = value & 0xff
	bytes[frame * 2 + 1] = (value >> 8) & 0xff
