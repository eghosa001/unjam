extends "res://scripts/ui/water_tube_reference_motion.gd"
class_name WaterTube3DMotion

# Compatibility name retained for saved scenes/tests. The implementation is now
# fully CanvasItem-based so every bottle is fast 2D glass/liquid art.
var _arrival_impulse := 0.0
var _arrival_phase := 0.0
var _previous_progress := 0.0

func configure(values: Array, selected: bool, index: int) -> void:
	super.configure(values, selected, index)
	_previous_progress = 0.0
	queue_redraw()

func begin_pour_out(amount: int) -> void:
	set_process(true)
	_previous_progress = 0.0
	super.begin_pour_out(amount)

func begin_pour_in(color_index: int, amount: int) -> void:
	set_process(true)
	_arrival_impulse = 0.0
	_arrival_phase = 0.0
	_previous_progress = 0.0
	super.begin_pour_in(color_index, amount)

func set_pour_progress(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if pour_mode == 1 and pour_amount > 0 and not MotionSystem.reduced():
		var previous_units := floori(_previous_progress * float(pour_amount) + 0.0001)
		var current_units := floori(next * float(pour_amount) + 0.0001)
		if current_units > previous_units:
			_arrival_impulse = 1.0
			_arrival_phase = 0.0
			set_process(true)
	_previous_progress = next
	super.set_pour_progress(next)

func _process(delta: float) -> void:
	super._process(delta)
	if _arrival_impulse > 0.001:
		_arrival_phase += delta * 18.0
		_arrival_impulse = maxf(0.0, _arrival_impulse - delta * 4.8)
		queue_redraw()
	if pour_mode == 0 and slosh <= 0.001 and _arrival_impulse <= 0.001 and not is_selected and invalid_flash <= 0.001 and success_flash <= 0.001:
		set_process(false)

func _draw() -> void:
	super._draw()
	if _arrival_impulse <= 0.001:
		return
	# Tiny bubbles/ripples on landing add liquid life without particles or 3D.
	var mouth := visual_receive_rim_local()
	var a := clampf(_arrival_impulse, 0.0, 1.0)
	var radius := maxf(2.0, size.x * 0.035)
	for i in range(3):
		var x := (float(i) - 1.0) * size.x * 0.075
		var y := 16.0 + float(i % 2) * 7.0 + sin(_arrival_phase + i) * 2.0
		draw_circle(mouth + Vector2(x, y), radius * (1.0 - i * 0.12), Color(0.90, 0.99, 1.0, 0.34 * a))
	draw_arc(mouth + Vector2(0, 24), size.x * (0.12 + (1.0 - a) * 0.05), 0, TAU, 20, Color(0.78,0.96,1.0,0.36*a), maxf(1.2,size.x*0.018), true)
