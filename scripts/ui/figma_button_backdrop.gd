class_name FigmaButtonBackdrop
extends Control

var style_box: StyleBox

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func configure(value: StyleBox) -> void:
	style_box = value
	queue_redraw()

func _draw() -> void:
	if style_box != null:
		draw_style_box(style_box, Rect2(Vector2.ZERO, size))
