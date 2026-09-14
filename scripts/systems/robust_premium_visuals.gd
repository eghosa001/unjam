extends "res://scripts/systems/premium_visuals.gd"

var quality_scale := 1.0
var sample_time := 0.0
var low_fps_samples := 0
var high_fps_samples := 0

func _ready() -> void:
	super._ready()
	quality_scale = float(SaveManager.data.get("visual_quality", 1.0))
	quality_scale = clampf(quality_scale, 0.45, 1.0)
	ambient_sparkles(_ambient_count())

func _process(delta: float) -> void:
	super._process(delta)
	sample_time += delta
	if sample_time < 2.0:
		return
	sample_time = 0.0
	var fps := Engine.get_frames_per_second()
	if fps > 0 and fps < 45:
		low_fps_samples += 1
		high_fps_samples = 0
	elif fps >= 57:
		high_fps_samples += 1
		low_fps_samples = 0
	else:
		low_fps_samples = maxi(0, low_fps_samples - 1)
		high_fps_samples = maxi(0, high_fps_samples - 1)
	if low_fps_samples >= 3 and quality_scale > 0.55:
		_set_quality(0.55)
	elif high_fps_samples >= 6 and quality_scale < 1.0:
		_set_quality(1.0)

func _set_quality(value: float) -> void:
	quality_scale = clampf(value, 0.45, 1.0)
	SaveManager.data["visual_quality"] = quality_scale
	SaveManager.save()
	ambient_sparkles(_ambient_count())
	low_fps_samples = 0
	high_fps_samples = 0

func _ambient_count() -> int:
	return 14 if quality_scale >= 0.9 else 7

func set_accent(color: Color) -> void:
	accent = color
	ambient_sparkles(_ambient_count())

func ambient_sparkles(count: int = 12) -> void:
	if not is_instance_valid(overlay):
		return
	var scaled_count := mini(count, _ambient_count())
	clear_ambient()
	var rng := RandomNumberGenerator.new()
	rng.seed = 44321
	for i in range(scaled_count):
		var radius := rng.randf_range(1.7, 4.2)
		var dot := _diamond(radius, Color(accent.lightened(0.18), rng.randf_range(0.045, 0.14)))
		dot.position = Vector2(rng.randf_range(20.0, 1060.0), rng.randf_range(40.0, 1880.0))
		dot.rotation = rng.randf_range(0.0, TAU)
		dot.set_meta("ambient", true)
		dot.set_meta("speed", rng.randf_range(3.0, 9.0))
		overlay.add_child(dot)

func burst(global_pos: Vector2, color: Color = Color("2dd4b6"), count: int = 18) -> void:
	var scaled := maxi(4, int(round(float(count) * quality_scale)))
	super.burst(global_pos, color, scaled)
