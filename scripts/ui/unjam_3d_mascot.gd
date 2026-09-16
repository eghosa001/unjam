class_name Unjam3DMascot
extends Control

var accent := Unjam3DTheme.GOLD

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10.0 or h < 10.0:
		return
	var center := Vector2(w * 0.52, h * 0.52)
	var r := minf(w, h) * 0.29
	# Ground shadow.
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(center.x, h * 0.83), r * 0.82, Color(0.02, 0.18, 0.30, 0.18))
	# Arms behind body.
	draw_line(center + Vector2(-r * 0.78, r * 0.08), center + Vector2(-r * 1.28, -r * 0.18), Color("f4b920"), r * 0.32, true)
	draw_line(center + Vector2(r * 0.78, r * 0.08), center + Vector2(r * 1.24, -r * 0.48), Color("f4b920"), r * 0.32, true)
	# Body depth and face.
	draw_circle(center + Vector2(0, r * 0.12), r * 1.03, Color("e29b09"))
	draw_circle(center, r, Color("ffd83d"))
	draw_circle(center - Vector2(r * 0.22, r * 0.16), r * 0.075, Color("17304a"))
	draw_circle(center + Vector2(r * 0.22, -r * 0.16), r * 0.075, Color("17304a"))
	draw_circle(center - Vector2(r * 0.25, r * 0.19), r * 0.025, Color.WHITE)
	draw_circle(center + Vector2(r * 0.19, -r * 0.19), r * 0.025, Color.WHITE)
	# Smile.
	draw_arc(center + Vector2(0, r * 0.05), r * 0.31, 0.22, PI - 0.22, 28, Color("7a321e"), r * 0.075, true)
	# Cheeks and highlight.
	draw_circle(center - Vector2(r * 0.48, -r * 0.06), r * 0.09, Color(1.0, 0.35, 0.32, 0.46))
	draw_circle(center + Vector2(r * 0.48, r * 0.06), r * 0.09, Color(1.0, 0.35, 0.32, 0.46))
	draw_circle(center - Vector2(r * 0.28, r * 0.38), r * 0.18, Color(1, 1, 1, 0.28))
