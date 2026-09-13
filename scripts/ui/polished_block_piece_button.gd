extends BlockPieceButton
class_name PolishedBlockPieceButton

var lift_tween: Tween

func _ready() -> void:
	super._ready()
	mouse_entered.connect(_animate_hover.bind(true))
	mouse_exited.connect(_animate_hover.bind(false))

func _animate_hover(active: bool) -> void:
	if lift_tween != null:
		lift_tween.kill()
	lift_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift_tween.set_parallel(true)
	lift_tween.tween_property(self, "position:y", position.y + (-7.0 if active else 7.0), 0.12)
	lift_tween.tween_property(self, "scale", Vector2(1.035, 1.035) if active else Vector2.ONE, 0.12)

func _make_drag_preview() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(240, 220)
	holder.size = Vector2(240, 220)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview := BlockPieceButton.new()
	preview.custom_minimum_size = Vector2(210, 132)
	preview.size = Vector2(210, 132)
	preview.position = Vector2(15, 8)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.configure(shape, true, accent)
	preview.modulate = Color(1, 1, 1, 0.98)
	preview.rotation = deg_to_rad(-2.0)
	preview.scale = Vector2(1.08, 1.08)
	holder.add_child(preview)
	# Put the visual well above the finger so the board target stays visible.
	holder.position = Vector2(-120, -205)
	var tween := holder.create_tween().set_loops()
	tween.tween_property(preview, "rotation", deg_to_rad(2.0), 0.24).set_trans(Tween.TRANS_SINE)
	tween.tween_property(preview, "rotation", deg_to_rad(-2.0), 0.24).set_trans(Tween.TRANS_SINE)
	return holder

func _gui_input(event: InputEvent) -> void:
	if used or shape.is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_drag_started = false
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.10)
		else:
			touch_drag_started = false
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "scale", Vector2.ONE, 0.14)
	elif event is InputEventScreenDrag and not touch_drag_started:
		touch_drag_started = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.42, 0.08)
		force_drag(_drag_payload(), _make_drag_preview())
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		scale = Vector2.ONE
