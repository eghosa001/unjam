extends Node

var layer: CanvasLayer
var overlay: Control
var ambient_time := 0.0
var accent := Color("2dd4b6")

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	set_process(true)

func _process(delta: float) -> void:
	ambient_time += delta
	for i in range(overlay.get_child_count()):
		var node := overlay.get_child(i)
		if node.has_meta("ambient"):
			var speed := float(node.get_meta("speed", 6.0))
			node.position.y -= speed * delta
			node.position.x += sin(ambient_time * 0.7 + float(i)) * 2.0 * delta
			if node.position.y < -40.0:
				node.position.y = 1960.0

func set_accent(color: Color) -> void:
	accent = color

func ambient_sparkles(count: int = 14) -> void:
	clear_ambient()
	var rng := RandomNumberGenerator.new()
	rng.seed = 44321
	for i in range(count):
		var dot := ColorRect.new()
		var size := rng.randf_range(3.0, 8.0)
		dot.size = Vector2(size, size)
		dot.position = Vector2(rng.randf_range(20.0, 1060.0), rng.randf_range(40.0, 1880.0))
		dot.color = Color(accent, rng.randf_range(0.08, 0.24))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("ambient", true)
		dot.set_meta("speed", rng.randf_range(4.0, 16.0))
		overlay.add_child(dot)

func clear_ambient() -> void:
	for child in overlay.get_children():
		if child.has_meta("ambient"):
			child.queue_free()

func burst(global_pos: Vector2, color: Color = accent, count: int = 18) -> void:
	var rng := RandomNumberGenerator.new()
	for i in range(count):
		var p := ColorRect.new()
		p.size = Vector2(rng.randf_range(6.0, 14.0), rng.randf_range(6.0, 14.0))
		p.position = global_pos
		p.color = Color(color, 0.95)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(p)
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(90.0, 260.0)
		var target := global_pos + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween().set_parallel(true)
		tween.tween_property(p, "position", target, rng.randf_range(0.35, 0.65)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(p.queue_free)

func screen_flash(color: Color = accent, strength: float = 0.18) -> void:
	var flash := ColorRect.new()
	flash.color = Color(color, strength)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.28)
	tween.tween_callback(flash.queue_free)

func entrance(node: Control, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.96, 0.96)
	node.pivot_offset = node.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, 0.28).set_delay(delay)
	tween.tween_property(node, "scale", Vector2.ONE, 0.34).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func premium_button(button: BaseButton) -> void:
	button.mouse_entered.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.10)
	)
	button.mouse_exited.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.10)
	)
	button.button_down.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.05)
	)
	button.button_up.connect(func():
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	)
