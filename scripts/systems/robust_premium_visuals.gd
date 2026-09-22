extends "res://scripts/systems/premium_visuals.gd"

const MATERIALS_SCRIPT = preload("res://scripts/ui/procedural_materials.gd")

var quality_scale := 1.0
var sample_time := 0.0
var low_fps_samples := 0
var medium_fps_samples := 0
var high_fps_samples := 0
var _materials = MATERIALS_SCRIPT.new()

func _ready() -> void:
	super._ready()
	quality_scale = float(SaveManager.data.get("visual_quality", 1.0))
	quality_scale = clampf(quality_scale, 0.45, 1.0)
	ambient_sparkles(_ambient_count())

func _reduced_motion() -> bool:
	# Override the legacy base hook so inherited effects and the adaptive layer
	# both use the canonical shared motion preference.
	return MotionSystem.reduced()

func _process(delta: float) -> void:
	# Keep the global sparkle field completely static when Reduce Motion is on.
	if not _reduced_motion():
		super._process(delta)
	sample_time += delta
	if sample_time < 2.0:
		return
	sample_time = 0.0
	var fps := Engine.get_frames_per_second()
	if fps > 0 and fps < 45:
		low_fps_samples += 1
		medium_fps_samples += 1
		high_fps_samples = 0
	elif fps > 0 and fps < 53:
		medium_fps_samples += 1
		low_fps_samples = maxi(0, low_fps_samples - 1)
		high_fps_samples = 0
	elif fps >= 58:
		high_fps_samples += 1
		low_fps_samples = 0
		medium_fps_samples = 0
	else:
		low_fps_samples = maxi(0, low_fps_samples - 1)
		medium_fps_samples = maxi(0, medium_fps_samples - 1)
		high_fps_samples = maxi(0, high_fps_samples - 1)

	# Step effects down before the device is visibly struggling. Gameplay logic,
	# board geometry and touch response never change—only decorative budgets.
	if low_fps_samples >= 2 and quality_scale > 0.50:
		_set_quality(0.50)
	elif medium_fps_samples >= 3 and quality_scale > 0.75:
		_set_quality(0.75)
	elif high_fps_samples >= 6 and quality_scale < 1.0:
		_set_quality(0.75 if quality_scale < 0.75 else 1.0)

func _set_quality(value: float) -> void:
	quality_scale = clampf(value, 0.45, 1.0)
	SaveManager.data["visual_quality"] = quality_scale
	SaveManager.save()
	ambient_sparkles(_ambient_count())
	low_fps_samples = 0
	medium_fps_samples = 0
	high_fps_samples = 0

func _ambient_count() -> int:
	return _materials.particle_budget(14, quality_scale, _reduced_motion())

func set_accent(color: Color) -> void:
	if accent.is_equal_approx(color) and not _ambient_nodes.is_empty():
		return
	accent = color
	ambient_sparkles(_ambient_count())

func _diamond(radius: float, color: Color) -> Polygon2D:
	# Polygon2D is a CanvasItem, not a Control, so assigning mouse_filter causes
	# a runtime error in Godot 4.7. The parent overlay already ignores input.
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.72, 0),
		Vector2(0, radius),
		Vector2(-radius * 0.72, 0)
	])
	p.color = color
	return p

func ambient_sparkles(count: int = 12) -> void:
	if not is_instance_valid(overlay):
		return
	clear_ambient()
	var scaled_count := mini(count, _ambient_count())
	if scaled_count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 44321
	for _i in range(scaled_count):
		var radius := rng.randf_range(1.7, 4.2)
		var dot := _diamond(radius, Color(accent.lightened(0.18), rng.randf_range(0.045, 0.14)))
		dot.position = Vector2(rng.randf_range(20.0, 1060.0), rng.randf_range(40.0, 1880.0))
		dot.rotation = rng.randf_range(0.0, TAU)
		dot.set_meta("ambient", true)
		dot.set_meta("speed", rng.randf_range(3.0, 9.0))
		overlay.add_child(dot)
		_ambient_nodes.append(dot)

func burst(global_pos: Vector2, color: Color = Color("2dd4b6"), count: int = 18) -> void:
	var scaled := _materials.particle_budget(count, quality_scale, _reduced_motion())
	if scaled <= 0:
		return
	super.burst(global_pos, color, maxi(2, scaled))
