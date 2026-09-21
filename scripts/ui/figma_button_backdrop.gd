class_name FigmaButtonBackdrop
extends Control

var style_box: StyleBox
var pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var owner := get_parent() as BaseButton
	if owner != null:
		owner.button_down.connect(func() -> void:
			pressed = true
			queue_redraw()
		)
		owner.button_up.connect(func() -> void:
			pressed = false
			queue_redraw()
		)
		owner.mouse_exited.connect(func() -> void:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				pressed = false
			queue_redraw()
		)

func configure(value: StyleBox) -> void:
	style_box = value
	queue_redraw()

func _draw() -> void:
	if style_box == null:
		return
	# Premium toy-like controls visibly compress their lower sidewall on touch.
	# This material response works with MotionSystem.press() rather than replacing it.
	var y_offset := 2.0 if pressed else 0.0
	var height_loss := 2.0 if pressed else 0.0
	draw_style_box(style_box, Rect2(Vector2(0, y_offset), Vector2(size.x, maxf(1.0, size.y - height_loss))))
