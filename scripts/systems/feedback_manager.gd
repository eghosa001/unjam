extends Node

# UNJAM calm-audio palette
# ------------------------
# The original feedback layer used isolated sine beeps. This revision keeps the
# zero-asset/instant-load architecture, but synthesizes warm mallet/chime voices
# with soft attacks, short harmonic tails and a spacious F-major ambient bed.
# It is intentionally restrained: frequent puzzle actions are quieter than
# rewards, error sounds avoid abrasive buzzes, and rapid taps can overlap
# naturally through a small player pool.

const SAMPLE_RATE := 22050
const MUSIC_RATE := 16000
const SFX_POOL_SIZE := 5
const MUSIC_DURATION := 32.0

var player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_stream: AudioStreamWAV
var last_music_enabled := false
var _sfx_cursor := 0
var _stream_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if DisplayServer.get_name() == "headless":
		return

	for i in range(SFX_POOL_SIZE):
		var sfx := AudioStreamPlayer.new()
		sfx.name = "CalmSfx%02d" % (i + 1)
		sfx.volume_db = -5.5
		add_child(sfx)
		sfx_players.append(sfx)
	player = sfx_players[0]

	music_player = AudioStreamPlayer.new()
	music_player.name = "CalmAmbientMusic"
	music_player.volume_db = -24.5
	add_child(music_player)
	music_stream = _build_calm_ambient_loop()
	music_player.stream = music_stream
	_sync_music()

func _exit_tree() -> void:
	shutdown_audio()

func shutdown_audio() -> void:
	set_process(false)
	for sfx in sfx_players:
		if sfx != null and is_instance_valid(sfx):
			sfx.stop()
			sfx.stream = null
			sfx.free()
	sfx_players.clear()
	player = null

	if music_player != null and is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
		music_player.free()
	music_player = null
	music_stream = null
	_stream_cache.clear()

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

# ---------------------------------------------------------------------------
# Semantic feedback API
# ---------------------------------------------------------------------------

func nav() -> void:
	_play_chime([392.0, 523.25], 0.105, 0.075, 0.42)

func lift() -> void:
	_play_chime([440.0, 659.25], 0.130, 0.085, 0.52)

func drop() -> void:
	_play_chime([329.63, 261.63], 0.145, 0.095, 0.34)

func snap() -> void:
	# Magnetic placement confirmation: lighter than a drop/clear, but tactile
	# enough that players feel the valid cell lock without looking away.
	_play_chime([493.88, 659.25], 0.090, 0.036, 0.28)
	_vibrate(8)

func pour_start() -> void:
	_play_chime([349.23, 440.0], 0.135, 0.058, 0.26)

func pour_land() -> void:
	_play_chime([440.0, 523.25, 659.25], 0.180, 0.070, 0.40)
	_vibrate(7)

func invalid() -> void:
	blocked()

func line_clear(lines: int = 1) -> void:
	var tier := clampi(lines, 1, 4)
	var roots := [523.25, 587.33, 659.25, 698.46]
	var root := float(roots[tier - 1])
	_play_chime([root, root * 1.25, root * 1.5], 0.22 + float(tier) * 0.035, 0.085 + float(tier) * 0.008, 0.56)
	if tier >= 2:
		_vibrate(12 + tier * 3)

func combo(chain: int = 1) -> void:
	var tier := clampi(chain, 1, 8)
	var scale := [392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
	var root := float(scale[tier - 1])
	_play_chime([root, root * 1.5], 0.16 + minf(0.08, float(tier) * 0.01), 0.075, 0.52)
	if tier >= 6:
		_vibrate(14 + tier)

func complete(kind: String = "level") -> void:
	if kind == "rescue":
		# Warm F-major add6 shape: celebratory without the piercing "ding" of the
		# old 1120 Hz single-sine completion tone.
		_play_chime([349.23, 440.0, 523.25, 659.25], 0.62, 0.105, 0.62)
		_vibrate(28)
	else:
		_play_chime([392.0, 493.88, 587.33, 783.99], 0.56, 0.100, 0.60)
		_vibrate(25)

# Backward-compatible API used throughout the existing scenes.
func tap() -> void:
	apply_settings()
	# A tiny wooden tick: audible enough for confirmation, quiet enough for
	# repeated menu use.
	_play_chime([392.0], 0.080, 0.042, 0.20)

func blocked() -> void:
	# Low, rounded two-note fall. Avoid sub-200 Hz buzzy sine errors.
	_play_chime([293.66, 246.94], 0.190, 0.070, 0.18)
	_vibrate(20)

func escape(chain: int = 1) -> void:
	var tier := clampi(chain, 1, 8)
	var notes := [392.0, 440.0, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99]
	var root := float(notes[tier - 1])
	_play_chime([root, root * 1.5], 0.165, 0.075, 0.45)
	if tier >= 3:
		_vibrate(8 + mini(8, tier))

func effect() -> void:
	_play_chime([523.25, 659.25, 783.99], 0.260, 0.085, 0.58)
	_vibrate(14)

func rescue() -> void:
	complete("rescue")

func _vibrate(ms: int) -> void:
	if bool(SaveManager.data.get("vibration", true)):
		Input.vibrate_handheld(ms)

# ---------------------------------------------------------------------------
# Warm mallet/chime synthesis
# ---------------------------------------------------------------------------

func _play_chime(notes: Array, duration: float, volume: float, brightness: float) -> void:
	if sfx_players.is_empty() or not bool(SaveManager.data.get("sound", true)):
		return
	var stream := _chime_stream(notes, duration, volume, brightness)
	var target := sfx_players[_sfx_cursor % sfx_players.size()]
	_sfx_cursor = (_sfx_cursor + 1) % sfx_players.size()
	target.stream = stream
	target.play()

func _chime_stream(notes: Array, duration: float, volume: float, brightness: float) -> AudioStreamWAV:
	var key := "%s|%.3f|%.3f|%.3f" % [str(notes), duration, volume, brightness]
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStreamWAV

	var frames := maxi(1, int(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)

	for i in range(frames):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(maxi(1, frames - 1))
		# 6 ms soft attack removes clicks. The squared/exponential tail gives the
		# plucked wooden feel of kalimba/marimba instead of an electronic beep.
		var attack := minf(1.0, t / 0.006)
		var decay := exp(-progress * (4.8 + brightness * 2.4))
		var envelope := attack * decay
		var body := 0.0
		for note_value in notes:
			var f := float(note_value)
			body += sin(TAU * f * t) * 0.72
			body += sin(TAU * f * 2.0 * t + 0.24) * (0.16 * brightness)
			body += sin(TAU * f * 3.01 * t + 0.61) * (0.055 * brightness)
			# Slight detune provides an organic, rounded mallet shimmer.
			body += sin(TAU * f * 0.997 * t + 0.10) * 0.08
		body /= float(maxi(1, notes.size()))
		var sample := body * envelope * volume
		# Very small stereo offset keeps headphones spacious without making UI
		# feedback feel like it jumps around the screen.
		var side := sin(TAU * 0.7 * t) * sample * 0.045
		_write_stereo(bytes, i, sample - side, sample + side)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = bytes
	_stream_cache[key] = stream
	return stream

# ---------------------------------------------------------------------------
# Calm ambient music synthesis
# ---------------------------------------------------------------------------

func _build_calm_ambient_loop() -> AudioStreamWAV:
	# 32-second original ambient loop: slow F-major/D-minor-family pads, sparse
	# kalimba-like notes, no drums, no sharp lead, and deliberately longer phrase
	# spacing so a multi-level session does not expose an obvious short loop.
	var frames := int(MUSIC_RATE * MUSIC_DURATION)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)

	# Fmaj7 -> Dm7 -> Bbmaj7 -> Cadd9, each held for eight seconds.
	var chords := [
		[87.31, 110.00, 130.81, 164.81],
		[73.42, 87.31, 110.00, 130.81],
		[58.27, 73.42, 87.31, 110.00],
		[65.41, 98.00, 130.81, 146.83],
	]
	var melody := [349.23, 440.00, 523.25, 440.00, 293.66, 349.23, 440.00, 523.25, 349.23, 392.00, 523.25, 587.33, 440.00, 392.00, 349.23, 293.66]
	var section_length := MUSIC_DURATION / 4.0

	for i in range(frames):
		var t := float(i) / float(MUSIC_RATE)
		var section := mini(3, int(t / section_length))
		var local_t := fmod(t, section_length)
		var edge := _smooth_edge(local_t, section_length, 1.15)
		var chord: Array = chords[section]

		var pad := 0.0
		for voice in range(chord.size()):
			var base := float(chord[voice])
			var phase := float(voice) * 0.61
			pad += sin(TAU * base * t + phase) * 0.095
			pad += sin(TAU * base * 2.0 * t + phase + 0.3) * 0.022
			pad += sin(TAU * base * 0.501 * t + phase * 0.7) * 0.035
		pad *= edge

		# Slow "breathing" keeps the pad alive while staying below conscious
		# rhythmic attention.
		var breath := 0.86 + 0.14 * sin(TAU * t / 7.5 + 0.5)
		pad *= breath

		# Sparse mallet note every two seconds. It decays quickly and leaves
		# generous silence, avoiding the constant arpeggio of the previous loop.
		var pulse_index := int(t / 2.0) % melody.size()
		var pulse_phase := fmod(t, 2.0)
		var mallet_env := exp(-pulse_phase * 4.6)
		var mf := float(melody[pulse_index])
		var mallet := sin(TAU * mf * t) * 0.040
		mallet += sin(TAU * mf * 2.0 * t + 0.2) * 0.009
		mallet *= mallet_env

		# Nearly subliminal low fundamental glues the harmony without a beat.
		var low := sin(TAU * float(chord[0]) * 0.5 * t) * 0.028
		var air := sin(TAU * 0.083 * t + sin(t * 0.11)) * 0.004

		var base_sample := (pad + mallet + low + air) * 0.76
		var width_l := sin(TAU * float(chord[1]) * 1.003 * t + 0.3) * 0.006
		var width_r := sin(TAU * float(chord[2]) * 0.997 * t + 1.0) * 0.006
		_write_stereo(bytes, i, base_sample + width_l, base_sample + width_r)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_RATE
	stream.stereo = true
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func _smooth_edge(local_t: float, section_length: float, fade_time: float) -> float:
	var fade_in := clampf(local_t / fade_time, 0.0, 1.0)
	var fade_out := clampf((section_length - local_t) / fade_time, 0.0, 1.0)
	var edge := minf(fade_in, fade_out)
	return edge * edge * (3.0 - 2.0 * edge)

func _write_stereo(bytes: PackedByteArray, frame: int, left: float, right: float) -> void:
	var l := int(clamp(left, -1.0, 1.0) * 32767.0)
	var r := int(clamp(right, -1.0, 1.0) * 32767.0)
	var o := frame * 4
	bytes[o] = l & 0xff
	bytes[o + 1] = (l >> 8) & 0xff
	bytes[o + 2] = r & 0xff
	bytes[o + 3] = (r >> 8) & 0xff
