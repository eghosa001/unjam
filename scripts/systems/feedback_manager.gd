extends Node

# UNJAM audio palette.
# Gameplay feedback remains lightweight synthesized chimes. Background music is
# the user-selected human-composed Happy Lullaby track (CC0 source retained in
# assets/audio/UNJAM_HAPPY_LULLABY_LICENSE.txt).

const HAPPY_LULLABY_PATH := "res://assets/audio/unjam_happy_lullaby.ogg"
const SAMPLE_RATE := 32000
const SFX_POOL_SIZE := 8
const SFX_VOLUME_DB := 1.0
const SFX_GAIN_MULTIPLIER := 1.18
const MUSIC_VOLUME_DB := -7.0
const MUSIC_START_DB := -48.0
const MUSIC_FADE_IN_SECONDS := 0.90
const MUSIC_FADE_OUT_SECONDS := 0.18
const NAV_TAP_MIN_INTERVAL_MS := 35
# Each additional simultaneous chime is attenuated, reducing clipping risk
# when rapid touches, clears and celebration sounds coincide on phone speakers.
const ACTIVE_VOICE_DUCK_DB := 2.3
const MAX_VOICE_DUCK_DB := 9.0

var player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_stream: AudioStream
var last_music_enabled := false
var _sfx_cursor := 0
var _music_fade: Tween
var _last_nav_tap_ms := -1000
var _stream_cache: Dictionary = {}

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
	music_player.name = "HappyLullabyMusic"
	music_player.volume_db = MUSIC_START_DB
	add_child(music_player)
	music_stream = load(HAPPY_LULLABY_PATH) as AudioStream
	var selected_track := music_stream as AudioStreamOggVorbis
	if selected_track != null:
		selected_track.loop = true
	music_player.stream = music_stream
	last_music_enabled = bool(SaveManager.data.get("music", true))
	if last_music_enabled:
		_start_music_immediately()
	call_deferred("_prewarm_common_sfx")

func _exit_tree() -> void:
	shutdown_audio()

func shutdown_audio() -> void:
	set_process(false)
	_cancel_music_fade()
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
	last_music_enabled = bool(SaveManager.data.get("music", true))
	_sync_music()

func _cancel_music_fade() -> void:
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	_music_fade = null

func _start_music_immediately() -> void:
	if music_player == null or music_stream == null:
		return
	_cancel_music_fade()
	if music_player.stream != music_stream:
		music_player.stream = music_stream
	if not music_player.playing:
		music_player.volume_db = MUSIC_START_DB
		music_player.play()
	# Re-enabling music during fade-out must restore audible volume, not
	# leave an already-playing stream stuck near silent.
	var fade := create_tween()
	_music_fade = fade
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
		_cancel_music_fade()
		if not music_player.playing:
			music_player.volume_db = MUSIC_START_DB
			return
		# Stop at near-silence, never truncate an active Ogg at full amplitude.
		var fade := create_tween()
		_music_fade = fade
		fade.set_trans(Tween.TRANS_SINE)
		fade.set_ease(Tween.EASE_IN)
		fade.tween_property(music_player, "volume_db", MUSIC_START_DB, MUSIC_FADE_OUT_SECONDS)
		fade.tween_callback(func() -> void:
			if music_player != null and is_instance_valid(music_player) and not bool(SaveManager.data.get("music", true)):
				music_player.stop()
		)

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
	if not _accept_nav_tap(Time.get_ticks_msec()):
		return
	# Ordinary taps are SFX-only. Music state is synchronized only when an
	# actual setting changes, so UI feedback can never restart the BGM stream.
	# A tiny wooden tick: audible enough for confirmation, quiet enough for
	# repeated menu use.
	_play_chime([392.0], 0.080, 0.060, 0.20)

func _accept_nav_tap(now_ms: int) -> bool:
	# Double-fired UI signals and ultra-rapid taps should not pile synthesized
	# ticks on top of music. Gameplay clear/snap events bypass this limit.
	if now_ms - _last_nav_tap_ms < NAV_TAP_MIN_INTERVAL_MS:
		return false
	_last_nav_tap_ms = now_ms
	return true

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

func _prewarm_common_sfx() -> void:
	if sfx_players.is_empty() or DisplayServer.get_name() == "headless":
		return
	# Build common one-shots during startup, one per frame, so the first real
	# interaction never pays the waveform-generation cost.
	var common := [
		[[392.0], 0.080, 0.060, 0.20],
		[[392.0, 523.25], 0.105, 0.085, 0.42],
		[[440.0, 659.25], 0.130, 0.095, 0.52],
		[[392.0, 329.63], 0.145, 0.095, 0.30],
		[[493.88, 659.25], 0.090, 0.055, 0.28],
		[[349.23, 440.0], 0.135, 0.080, 0.26],
		[[440.0, 523.25, 659.25], 0.180, 0.092, 0.40],
	]
	for spec in common:
		_chime_stream(spec[0], float(spec[1]), float(spec[2]) * SFX_GAIN_MULTIPLIER, float(spec[3]))
		if is_inside_tree():
			await get_tree().process_frame

func _play_chime(notes: Array, duration: float, volume: float, brightness: float) -> void:
	if sfx_players.is_empty() or not bool(SaveManager.data.get("sound", true)):
		return
	var target := _next_available_sfx_player()
	if target == null:
		# Never replace a waveform mid-play. A dropped micro-effect under extreme
		# overlap is far less noticeable than the click caused by truncating an
		# active channel at a non-zero sample.
		return
	# The mixing bus sums simultaneous 16-bit chimes. Attenuate new voices
	# as concurrency grows; do not cut off voices already fading out.
	var active_voices := 0
	for voice in sfx_players:
		if voice != null and is_instance_valid(voice) and voice.playing:
			active_voices += 1
	target.volume_db = SFX_VOLUME_DB - _voice_headroom_db(active_voices)
	var stream := _chime_stream(notes, duration, volume * SFX_GAIN_MULTIPLIER, brightness)
	target.stream = stream
	target.play()

func _voice_headroom_db(active_voices: int) -> float:
	return minf(MAX_VOICE_DUCK_DB, maxf(0.0, float(active_voices)) * ACTIVE_VOICE_DUCK_DB)

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
# PCM helper used by synthesized gameplay feedback
# ---------------------------------------------------------------------------

func _write_stereo(bytes: PackedByteArray, frame: int, left: float, right: float) -> void:
	var l := int(clamp(left, -1.0, 1.0) * 32767.0)
	var r := int(clamp(right, -1.0, 1.0) * 32767.0)
	var o := frame * 4
	bytes[o] = l & 0xff
	bytes[o + 1] = (l >> 8) & 0xff
	bytes[o + 2] = r & 0xff
	bytes[o + 3] = (r >> 8) & 0xff
