extends Node

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

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
	if not bool(SaveManager.data.get("sound", true)):
		return
	var rate := 22050
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var fade := 1.0 - float(i) / float(max(frames, 1))
		var sample := sin(TAU * frequency * float(i) / float(rate)) * volume * fade
		var value := int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = value & 0xff
		bytes[i * 2 + 1] = (value >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	player.stream = stream
	player.play()
