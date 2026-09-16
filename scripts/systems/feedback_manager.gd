extends Node

var player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_stream: AudioStreamWAV
var last_music_enabled := false
var _tone_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if DisplayServer.get_name() == "headless":
		return
	player = AudioStreamPlayer.new()
	add_child(player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -19.0
	add_child(music_player)
	music_stream = _build_premium_loop()
	music_player.stream = music_stream
	_sync_music()

func _exit_tree() -> void:
	shutdown_audio()

func shutdown_audio() -> void:
	# Generated WAV streams keep an AudioStreamPlaybackWAV alive until the
	# player itself is released. Explicit teardown keeps visual/CI runs clean
	# and also avoids retaining audio resources during controlled shutdowns.
	set_process(false)
	if player != null and is_instance_valid(player):
		player.stop()
		player.stream = null
		player.free()
	player = null
	if music_player != null and is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
		music_player.free()
	music_player = null
	music_stream = null
	_tone_cache.clear()

func apply_settings() -> void:
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

# Semantic feedback API. Gameplay code should prefer these names so sound,
# haptics and animation beats stay synchronized across all three games.
func nav() -> void:
	_play_tone(510.0, 0.035, 0.12)

func lift() -> void:
	_play_tone(680.0, 0.040, 0.13)

func drop() -> void:
	_play_tone(430.0, 0.055, 0.16)

func pour_start() -> void:
	_play_tone(560.0, 0.055, 0.10)

func pour_land() -> void:
	_play_tone(720.0, 0.060, 0.13)

func invalid() -> void:
	blocked()

func line_clear(lines: int = 1) -> void:
	var tier := clampi(lines, 1, 4)
	_play_tone(760.0 + float(tier) * 90.0, 0.075 + float(tier) * 0.012, 0.18 + float(tier) * 0.015)
	if tier >= 2:
		_vibrate(14 + tier * 4)

func combo(chain: int = 1) -> void:
	var tier := clampi(chain, 1, 8)
	_play_tone(700.0 + float(tier) * 65.0, 0.065 + minf(0.035, float(tier) * 0.004), 0.17 + minf(0.08, float(tier) * 0.01))
	if tier >= 5:
		_vibrate(16 + tier * 2)

func complete(kind: String = "level") -> void:
	var frequency := 1120.0 if kind == "rescue" else 980.0
	_play_tone(frequency, 0.16, 0.26)
	_vibrate(32 if kind != "rescue" else 36)

# Backward-compatible API used by existing scenes while they migrate to the
# semantic methods above.
func tap() -> void:
	# Settings changes flow through this feedback event too, so synchronize the
	# ambient-music preference without keeping an always-on frame poll alive.
	apply_settings()
	# Routine taps stay silent in the haptic channel. Continuous vibration on
	# every button press made navigation and puzzle input feel harsh.
	_play_tone(540.0, 0.045, 0.16)

func blocked() -> void:
	_play_tone(180.0, 0.08, 0.20)
	_vibrate(28)

func escape(chain: int = 1) -> void:
	# Escaping a normal piece is a frequent gameplay action; reserve vibration
	# for blocked/error states and meaningful completion effects.
	_play_tone(620.0 + float(min(chain, 8)) * 70.0, 0.07, 0.22)

func effect() -> void:
	_play_tone(880.0, 0.09, 0.24)
	_vibrate(20)

func rescue() -> void:
	complete("rescue")

func _vibrate(ms: int) -> void:
	if bool(SaveManager.data.get("vibration", true)):
		Input.vibrate_handheld(ms)

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	if player == null or not bool(SaveManager.data.get("sound", true)):
		return
	player.stream = _tone_stream(frequency, duration, volume)
	player.play()

func _tone_stream(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	# Tone synthesis is deterministic. Cache each profile so repeated taps,
	# pours and clears do not allocate/fill a new byte buffer every time.
	var key := "%.2f|%.4f|%.4f" % [frequency, duration, volume]
	if _tone_cache.has(key):
		return _tone_cache[key] as AudioStreamWAV
	var rate := 22050
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var fade := 1.0 - float(i) / float(max(frames, 1))
		var sample := sin(TAU * frequency * float(i) / float(rate)) * volume * fade
		_write_mono(bytes, i, sample)
	var Stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	_tone_cache[key] = stream
	return stream

func _build_premium_loop() -> AudioStreamWAV:
	# 12-second original stereo puzzle ambience: warm pads, sub bass,
	# arpeggiated plucks and a restrained pulse with slightly different L/R delay.
	var rate := 16000
	var duration := 12.0
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	var roots := [73.42, 58.27, 65.41, 65.41]
	var thirds := [87.31, 73.42, 87.31, 82.41]
	var fifths := [110.0, 87.31, 98.0, 98.0]
	var arp := [293.66, 349.23, 440.0, 523.25, 233.08, 293.66, 349.23, 440.0, 261.63, 349.23, 440.0, 523.25, 261.63, 329.63, 392.0, 523.25]
	var segment := duration / 4.0
	for i in range(frames):
		var t := float(i) / float(rate)
		var section := mini(3, int(t / segment))
		var segment_time := fmod(t, segment)
		var edge := minf(1.0, minf(segment_time / 0.45, (segment - segment_time) / 0.45))
		var r := float(roots[section])
		var pad := sin(TAU * r * 2.0 * t) * 0.16 + sin(TAU * float(thirds[section]) * 2.0 * t + 0.5) * 0.13 + sin(TAU * float(fifths[section]) * 2.0 * t + 1.1) * 0.11
		pad += sin(TAU * r * t + 0.2) * 0.12
		var beat_phase := fmod(t * 1.5, 1.0)
		var bass_env := exp(-beat_phase * 4.4)
		var bass := sin(TAU * r * t) * bass_env * 0.16
		var step := int(t * 3.0) % arp.size()
		var pluck_phase := fmod(t * 3.0, 1.0)
		var pluck_env := exp(-pluck_phase * 7.5)
		var pluck := sin(TAU * float(arp[step]) * t) * pluck_env * 0.065
		var shimmer := sin(TAU * (float(arp[(step + 5) % arp.size()]) * 2.0) * t + sin(t * 0.7) * 0.8) * 0.018
		var pulse := 0.78 + 0.22 * sin(TAU * t / 4.0)
		var base := (pad * edge + bass + pluck + shimmer) * pulse
		var left := base + sin(TAU * 0.083 * t) * 0.012
		var r