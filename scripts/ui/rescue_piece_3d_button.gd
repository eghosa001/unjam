extends "res://scripts/ui/premium_piece_button.gd"
class_name RescuePiece3DButton

# Legacy class name retained so Rescue Rush gameplay and escape-animation code do
# not need to change. Active arrows use lightweight 2.5D CanvasItem geometry:
# deep sidewalls, directional cast shadow, lacquer highlights and a raised glyph.
# This keeps every puzzle tile cheap and perfectly aligned while reading much
# closer to a sculpted premium-game object than a flat button.

func _ready() -> void:
	super._ready()
	# The flat Rescue tile has no animated scene viewport to maintain. Keep the
	# inherited decorative pulse asleep while idle; press/release tweens still run
	# independently and the tile redraws whenever configure() changes its state.
	set_process(false)

func _set_hover(value: bool) -> void:
	# Desktop hover still gets immediate depth feedback without an always-running
	# process loop. Mobile gameplay is unaffected because touch uses press/release.
	hover_amount = 1.0 if value else 0.0
	var target := Vector2(1.035, 1.035) if value else Vector2.ONE
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, 0.10)
	queue_redraw()

func _press() -> void:
	super._press()
	queue_redraw()

func _release() -> void:
	super._release()
	queue_redraw()


func _draw_shell(rect: Rect2, center: Vector2, pulse: float) -> void:
	var radius := minf(rect.size.x, rect.size.y) * 0.22
	var depth := clampf(rect.size.y * 0.16, 6.0, 10.0)
	var front := Rect2(rect.position + Vector2(0, -1.0), Vector2(rect.size.x, maxf(12.0, rect.size.y - depth)))
	# A separated cast shadow gives the piece a real footprint instead of a dark
	# outline glued to the face.
	var cast := Rect2(front.position + Vector2(3.0, depth + 5.0), front.size)
	draw_style_box(_rounded(Color(0.01, 0.04, 0.10, 0.34), radius, Color.TRANSPARENT, 0), cast)
	# Draw the darker body behind the face so the lower/right edges read as
	# thickness even when neighboring tiles are packed tightly.
	var body := Rect2(front.position + Vector2(0, depth), front.size)
	draw_style_box(_rounded(accent.darkened(0.43), radius, accent.darkened(0.56), 2), body)
	var lower_lip := PackedVector2Array([
		Vector2(front.position.x + radius * 0.50, front.end.y - 1.0),
		Vector2(front.end.x - radius * 0.50, front.end.y - 1.0),
		Vector2(front.end.x - radius * 0.66, front.end.y + depth - 1.0),
		Vector2(front.position.x + radius * 0.66, front.end.y + depth - 1.0),
	])
	draw_colored_polygon(lower_lip, accent.darkened(0.31))
	# Front face: strong edge contrast plus a subtle inset face makes the bevel
	# read at phone size without introducing a per-piece viewport.
	draw_style_box(_rounded(accent, radius, glow.lightened(0.10), 3), front)
	var inset := Rect2(front.position + Vector2(4.0, 4.0), front.size - Vector2(8.0, 8.0))
	draw_style_box(_rounded(Color(accent.lightened(0.025), 0.94), radius * 0.78, Color(accent.lightened(0.26), 0.34), 1), inset)
	# Directional top/left bevels mimic a shared scene light.
	var top_bevel := PackedVector2Array([
		front.position + Vector2(radius * 0.45, 3.0),
		Vector2(front.end.x - radius * 0.45, front.position.y + 3.0),
		Vector2(front.end.x - radius * 0.64, front.position.y + 10.0),
		front.position + Vector2(radius * 0.64, 10.0),
	])
	draw_colored_polygon(top_bevel, Color(accent.lightened(0.40), 0.58))
	draw_line(front.position + Vector2(5.0, radius * 0.72), front.position + Vector2(5.0, front.size.y - radius * 0.62), Color(1, 1, 1, 0.18), 2.0, true)
	# Localized lacquer highlight; keep it asymmetric so the face does not look
	# like a flat gradient panel.
	var gloss_rect := Rect2(front.position + Vector2(9.0, 8.0), Vector2(front.size.x * 0.46, maxf(7.0, front.size.y * 0.13)))
	draw_style_box(_rounded(Color(1, 1, 1, 0.31), radius * 0.38, Color.TRANSPARENT, 0), gloss_rect)
	draw_circle(front.position + Vector2(front.size.x * 0.25, front.size.y * 0.27), maxf(2.0, front.size.x * 0.035), Color(1, 1, 1, 0.50))
	if hover_amount > 0.01:
		draw_arc(center - Vector2(0, depth * 0.30), front.size.x * 0.54, 0, TAU, 36, Color(glow, 0.20), 4.0, true)

func _draw_arrow(center: Vector2, dir: String, scale_value: float) -> void:
	var v := _dir_vec(dir)
	var n := Vector2(-v.y, v.x)
	var glyph_center := center - Vector2(0, 3.0)
	var tip := glyph_center + v * scale_value
	var tail := glyph_center - v * scale_value * 0.72
	var neck := glyph_center + v * scale_value * 0.13
	var half := scale_value * 0.23
	var wing := scale_value * 0.52
	var points := PackedVector2Array([
		tail + n * half,
		neck + n * half,
		neck + n * wing,
		tip,
		neck - n * wing,
		neck - n * half,
		tail - n * half,
	])
	# Extrude the arrow separately from the tile face so it reads like a raised
	# inlay rather than white paint.
	var cast := PackedVector2Array()
	var side := PackedVector2Array()
	var top := PackedVector2Array()
	for point in points:
		cast.append(point + Vector2(1.5, 6.0))
		side.append(point + Vector2(0, 3.5))
		top.append(point - Vector2(0, 1.0))
	draw_polygon(cast, PackedColorArray([Color(0.01, 0.09, 0.16, 0.30)]))
	draw_polygon(side, PackedColorArray([Color("b8d8e7")]))
	draw_polygon(top, PackedColorArray([Color("fffef8")]))
	draw_polyline(top + PackedVector2Array([top[0]]), Color("e3f5ff"), 2.0, true)
	# A small specular streak gives the glyph the same lacquer language as the tile.
	draw_line(glyph_center - v * scale_value * 0.38 - n * scale_value * 0.08, glyph_center + v * scale_value * 0.18 - n * scale_value * 0.08, Color(1, 1, 1, 0.62), 2.0, true)
