extends Node

# UNJAM audio palette.
# Background music is a human-composed CC0 puzzle track. UNJAM keeps synthesized
# one-shot feedback for tactile interactions, but no longer synthesizes the
# background score during startup.

const HUMAN_MUSIC_PATH := "res://assets/audio/unjam_puzzle_theme.ogg"
const SAMPLE_RATE := 32000
const MUSIC_RATE := 24000
const STARTUP_MUSIC_RATE := 24000
const SFX_POOL_SIZE := 8
const MUSIC_DURATION := 24.0
const STARTUP_MUSIC_DURATION := 3.6
const SFX_VOLUME_DB := 1.0
const SFX_GAIN_MULTIPLIER := 1.18
const MUSIC_VOLUME_DB := -7.0
const MUSIC_HANDOFF_SILENCE_DB := -48.0
const MUSIC_HANDOFF_FADE_SECONDS := 0.75
const MUSIC_FADE_IN_SECONDS := 0.90
const MUSIC_PITCH_SCALE := 0.995
# Keep the expensive full-loop synthesis below the early-frame budget. A tiny
# primer plays immediately, so the full loop can be built without blocking UI.
const MUSIC_SYNTH_CHUNK_FRAMES := 4096

var player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_intro_player: AudioStreamPlayer
var music_stream: AudioStream
var _startup_music_stream: AudioStreamWAV
var last_music_enabled := false
var _sfx_cursor := 0
var _stream_cache: Dictionary = {}
var _music_building := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if DisplayServer.get_name() == "headless":
		return

	for i in range(SFX_POOL_SIZE):
		var sfx := AudioStreamPlayer.new()
		sfx.name = "CalmSfx%02d" % (i + 1)
		sfx.volume_db = SFX_VOLUME_DB
		add_child(sfx)
		sfx_players.append(sfx)
	player = sfx_players[0]

	music_player = AudioStreamPlayer.new()
	music_player.name = "HumanPuzzleMusic"
	music_player.volume_db = MUSIC_HANDOFF_SILENCE_DB
	music_player.pitch_scale = MUSIC_PITCH_SCALE
	add_child(music_player)

	music_stream = load(HUMAN_MUSIC_PATH) as AudioStream
	var ogg := music_stream as AudioStreamOggVorbis
	if ogg != null:
		ogg.loop = true
	music_player.stream = music_stream

	last_music_enabled = bool(SaveManager.data.get("music", true))
	if last_music_enabled:
		_start_music_immediately()

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
	_startup_music_stream = null
	_stream_cache.clear()

func apply_settings() -> void:
	last_music_enabled = bool(SaveManager.data.get("music", true))
	_sync_music()

func _start_music_immediately() -> void:
	if music_player == null or music_stream == null:
		return
	music_player.stream = music_stream
	music_player.pitch_scale = MUSIC_PITCH_SCALE
	if music_player.playing:
		music_player.volume_db = MUSIC_VOLUME_DB
		return
	music_player.volume_db = MUSIC_HANDOFF_SILENCE_DB
	music_player.play()
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)
	fade.tween_property(music_player, "volume_db", MUSIC_VOLUME_DB, MUSIC_FADE_IN_SECONDS)

func _sync_music() -> void:
	last_music_enabled = bool(SaveManager.data.get("music", true))
	if music_player == null:
		return
	if last_music_enabled:
		_start_music_immediately()
	else:
		music_player.stop()
		music_player.volume_db = MUSIC_HANDOFF_SILENCE_DB

# ---------------------------------------------------------------------------
# Semantic feedback API
# ---------------------------------------------------------------------------

func nav() -> void:
	_play_chime([392.0, 523.25], 0.105, 0.085, 0.42)

func lift() -> void:
	_play_chime([440.0, 659.25], 0.130, 0.095, 0.52)

func drop() -> void:
	_play_chime([392.0, 329.63], 0.145, 0.095, 0.30)

func snap() -> void:
	# Magnetic placement confirmation: lighter than a drop/clear, but tactile
	# enough that players feel the valid cell lock without looking away.
	_play_chime([493.88, 659.25], 0.090, 0.055, 0.28)
	# Placement audio is tactile enough on its own; avoid coupling routine taps
	# to phone vibration.

func pour_start() -> void:
	_play_chime([349.23, 440.0], 0.135, 0.080, 0.26)

func pour_land() -> void:
	_play_chime([440.0, 523.25, 659.25], 0.180, 0.092, 0.40)
	# Landing remains audio-only to prevent repeated pour actions from rumbling.

func invalid() -> void:
	blocked()

func line_clear(lines: int = 1) -> void:
	var tier := clampi(lines, 1, 4)
	var roots := [523.25, 587.33, 659.25, 698.46]
	var root := float(roots[tier - 1])
	_play_chime([root, root * 1.25, root * 1.5], 0.22 + float(tier) * 0.035, 0.085 + float(tier) * 0.008, 0.56)
	if tier >= 3:
		_vibrate(8)

func combo(chain: int = 1) -> void:
	var tier := clampi(chain, 1, 8)
	var scale := [392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
	var root := float(scale[tier - 1])
	_play_chime([root, root * 1.5], 0.16 + minf(0.08, float(tier) * 0.01), 0.075, 0.52)
	# Combo escalation stays musical; no repeated haptic stacking.

func complete(kind: String = "level") -> void:
	if kind == "rescue":
		# Warm F-major add6 shape: celebratory without the piercing "ding" of the
		# old 1120 Hz single-sine completion tone.
		_play_chime([349.23, 440.0, 523.25, 659.25], 0.62, 0.105, 0.62)
		_vibrate(16)
	else:
		_play_chime([392.0, 493.88, 587.33, 783.99], 0.56, 0.100, 0.60)
		_vibrate(14)

# Backward-compatible API used throughout the existing scenes.
func tap() -> void:
	apply_settings()
	# A tiny wooden tick: audible enough for confirmation, quiet enough for
	# repeated menu use.
	_play_chime([392.0], 0.080, 0.060, 0.20)

func blocked() -> void:
	# Low, rounded two-note fall. Avoid sub-200 Hz buzzy sine errors.
	_play_chime([392.0, 329.63], 0.180, 0.070, 0.16)
	_vibrate(8)

func escape(chain: int = 1) -> void:
	var tier := clampi(chain, 1, 8)
	var notes := [392.0, 440.0, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99]
	var root := float(notes[tier - 1])
	_play_chime([root, root * 1.5], 0.165, 0.075, 0.45)
	if tier >= 6:
		_vibrate(8)

func effect() -> void:
	_play_chime([523.25, 659.25, 783.99], 0.260, 0.085, 0.58)
	_vibrate(8)

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
	var target := _next_available_sfx_player()
	if target == null:
		# Never replace a waveform mid-play. A dropped micro-effect under extreme
		# overlap is far less noticeable than the click caused by truncating an
		# active channel at a non-zero sample.
		return
	# A modest global lift matches the clearer feedback-to-music balance common
	# in polished casual puzzle games while the per-sound envelopes retain headroom.
	var stream := _chime_stream(notes, duration, volume * SFX_GAIN_MULTIPLIER, brightness)
	target.stream = stream
	target.play()

func _next_available_sfx_player() -> AudioStreamPlayer:
	if sfx_players.is_empty():
		return null
	for offset in range(sfx_players.size()):
		var index := (_sfx_cursor + offset) % sfx_players.size()
		var candidate := sfx_players[index]
		if candidate != null and is_instance_valid(candidate) and not candidate.playing:
			_sfx_cursor = (index + 1) % sfx_players.size()
			return candidate
	return null

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
		# Soft felt-mallet attack with faster-decaying upper partials. The small
		# inharmonic component gives a glass/wood character instead of a plain
		# synthesizer beep, while every one-shot still returns to zero cleanly.
		var attack := minf(1.0, t / 0.008)
		var body_decay := exp(-progress * (4.0 + brightness * 1.8))
		var high_decay := exp(-progress * (8.0 + brightness * 3.0))
		var release_raw := clampf((duration - t) / 0.014, 0.0, 1.0)
		var release := release_raw * release_raw * (3.0 - 2.0 * release_raw)
		var body := 0.0
		for note_value in notes:
			var f := float(note_value)
			body += sin(TAU * f * t) * 0.62 * body_decay
			body += sin(TAU * f * 1.997 * t + 0.18) * (0.11 * brightness) * body_decay
			body += sin(TAU * f * 2.73 * t + 0.47) * (0.075 * brightness) * high_decay
			body += sin(TAU * f * 4.11 * t + 0.83) * (0.025 * brightness) * high_decay
			body += sin(TAU * f * 1.006 * t + 0.08) * 0.075 * body_decay
		body /= float(maxi(1, notes.size()))
		var envelope := attack * release
		var sample := body * envelope * volume
		var side := sin(TAU * 0.62 * t) * sample * 0.05
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

func _build_startup_ambient() -> AudioStreamWAV:
	# A sustained Fmaj9 pad shares the same tonal center as the main loop. There
	# is no separate "loading melody" to clash with the first bar, and the long
	# gentle attack masks device/audio-driver startup transients.
	var frames := maxi(1, int(STARTUP_MUSIC_RATE * STARTUP_MUSIC_DURATION))
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)
	var chord := [174.61, 220.00, 261.63, 329.63, 392.00]
	for i in range(frames):
		var t := float(i) / float(STARTUP_MUSIC_RATE)
		var attack := clampf(t / 0.72, 0.0, 1.0)
		attack = attack * attack * (3.0 - 2.0 * attack)
		var pad := 0.0
		for voice in range(chord.size()):
			var base := float(chord[voice])
			var phase := float(voice) * 0.43
			pad += sin(TAU * base * t + phase) * 0.018
			pad += sin(TAU * base * 2.0 * t + phase + 0.23) * 0.0035
		var breathe := 0.94 + 0.06 * sin(TAU * 0.16 * t)
		var air := sin(TAU * 784.0 * t + 0.2) * 0.0008
		var out := (pad * breathe + air) * attack
		_write_stereo(bytes, i, out * 0.985, out)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = STARTUP_MUSIC_RATE
	stream.stereo = true
	stream.data = bytes
	return stream

func _build_calm_ambient_loop() -> AudioStreamWAV:
	# Original 24-second casual-puzzle score at 80 BPM. The arrangement follows
	# the genre's strongest pattern: a warm non-rhythmic pad, sparse felt/glass
	# notes, generous rests, and restrained stereo ambience. It supports focus
	# rather than competing with the puzzle.
	var frames := int(MUSIC_RATE * MUSIC_DURATION)
	var bytes := PackedByteArray()
	bytes.resize(frames * 4)

	# Smooth diatonic voice-leading in F major:
	# Fmaj9 -> Dm9 -> Bbmaj9 -> C6/9. Every melody note belongs to the active
	# harmony or its diatonic extension, avoiding the sour interval collisions
	# that made the previous tune feel less settled.
	var chords := [
		[174.61, 220.00, 261.63, 329.63, 392.00],
		[146.83, 174.61, 220.00, 261.63, 329.63],
		[116.54, 146.83, 174.61, 220.00, 261.63],
		[130.81, 164.81, 196.00, 220.00, 293.66],
	]
	var phrases := [
		[440.00, 523.25, 392.00, 659.25, 523.25, 440.00, 392.00, 0.0],
		[349.23, 440.00, 329.63, 293.66, 349.23, 440.00, 523.25, 0.0],
		[293.66, 349.23, 523.25, 440.00, 349.23, 293.66, 261.63, 0.0],
		[329.63, 392.00, 587.33, 440.00, 392.00, 329.63, 293.66, 0.0],
	]
	var section_length := MUSIC_DURATION / 4.0
	var note_step := 0.75
	var delay_frames := maxi(1, int(float(MUSIC_RATE) * 0.23))
	var delay_l := PackedFloat32Array()
	var delay_r := PackedFloat32Array()
	delay_l.resize(delay_frames)
	delay_r.resize(delay_frames)

	for i in range(frames):
		if i > 0 and i % MUSIC_SYNTH_CHUNK_FRAMES == 0:
			if is_inside_tree():
				await get_tree().process_frame
		var t := float(i) / float(MUSIC_RATE)
		var section := mini(3, int(t / section_length))
		var local_t := fmod(t, section_length)
		var chord: Array = chords[section]
		var transition := 0.72
		var pad := _ambient_pad_sample(chord, t)
		# Crossfade only at the end of a section. At the next section's first
		# sample we are already on the destination chord, so there is no snap
		# back to the previous harmony.
		if local_t > section_length - transition:
			var next_chord: Array = chords[(section + 1) % chords.size()]
			var mix_out := _smoothstep01((local_t - (section_length - transition)) / transition)
			pad = lerpf(pad, _ambient_pad_sample(next_chord, t), mix_out)
		pad *= 0.94 + 0.06 * sin(TAU * t / 8.0 + 0.4)

		# Felt/glass lead: a simple memorable phrase with one full beat of silence
		# every four beats. Higher partials decay faster than the fundamental.
		var note_index := mini(7, int(local_t / note_step))
		var note_frequency := float(phrases[section][note_index])
		var note_phase := fmod(local_t, note_step)
		var note_edge := _smooth_edge(note_phase, note_step, 0.045)
		var lead := 0.0
		if note_frequency > 0.0:
			var body_env := exp(-note_phase * 4.3) * note_edge
			var high_env := exp(-note_phase * 8.5) * note_edge
			var melody_entry := _smoothstep01((t - 1.15) / 0.70)
			lead = sin(TAU * note_frequency * t) * 0.046 * body_env * melody_entry
			lead += sin(TAU * note_frequency * 1.997 * t + 0.18) * 0.0075 * body_env * melody_entry
			lead += sin(TAU * note_frequency * 2.72 * t + 0.49) * 0.0035 * high_env * melody_entry

		# Quiet chord-tone plucks add forward motion every two beats without drums.
		var arp_step := int(floor(local_t / 1.5)) % chord.size()
		var arp_frequency := float(chord[arp_step]) * 2.0
		var arp_phase := fmod(local_t, 1.5)
		var arp_env := exp(-arp_phase * 3.1) * _smooth_edge(arp_phase, 1.5, 0.055)
		var arpeggio := (
			sin(TAU * arp_frequency * t) * 0.009
			+ sin(TAU * arp_frequency * 2.01 * t + 0.27) * 0.0018
		) * arp_env

		# A tiny high, slowly moving texture keeps the bed alive on headphones.
		var air_frequency := 880.0 + 36.0 * sin(TAU * 0.07 * t)
		var air := sin(TAU * air_frequency * t + 0.4) * 0.0008

		var dry := pad + lead + arpeggio + air
		var dry_l := dry + sin(TAU * float(chord[1]) * 1.003 * t + 0.3) * 0.0016
		var dry_r := dry + sin(TAU * float(chord[2]) * 0.997 * t + 1.0) * 0.0016

		# One short cross-fed delay acts like a compact room reverb. It gives the
		# music the soft spatial tail heard in polished puzzle audio without a DSP
		# effect node or runtime allocation.
		var delay_index := i % delay_frames
		var echo_l := float(delay_l[delay_index])
		var echo_r := float(delay_r[delay_index])
		delay_l[delay_index] = dry_l + echo_r * 0.16
		delay_r[delay_index] = dry_r + echo_l * 0.16

		var loop_edge := _smooth_edge(t, MUSIC_DURATION, 0.16)
		var out_l := (dry_l + echo_l * 0.22) * 0.78 * loop_edge
		var out_r := (dry_r + echo_r * 0.22) * 0.78 * loop_edge
		_write_stereo(bytes, i, out_l, out_r)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_RATE
	stream.stereo = true
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func _ambient_pad_sample(chord: Array, t: float) -> float:
	var pad := 0.0
	for voice in range(chord.size()):
		var base := float(chord[voice])
		var phase := float(voice) * 0.47
		pad += sin(TAU * base * t + phase) * 0.020
		pad += sin(TAU * base * 1.004 * t + phase + 0.12) * 0.0070
		pad += sin(TAU * base * 2.0 * t + phase + 0.31) * 0.0030
	return pad

func _smoothstep01(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

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
