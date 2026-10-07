extends "res://scripts/ui/premium_piece_button.gd"
class_name RescuePiece3DButton

const AUTHORED_TILE_OVERLAY: Texture2D = preload("res://assets/art/gameplay/rescue_tile_overlay.svg")

# Legacy class name retained so Rescue Rush gameplay and escape-animation code do
# not need to change. The tile itself keeps premium depth, but the directional
# arrow is intentionally flat and high-contrast. Direction must read instantly
# on a dense phone board without highlights, extrusion or visual fatigue.

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
	# One fast glossy 2D face. Pieces should be readable arrows, not miniature boxes.
	var radius := minf(rect.size.x, rect.size.y) * 0.22
	var face := rect.grow(-0.25)
	var cast := Rect2(face.position + Vector2(0, maxf(2.0, face.size.y * 0.08)), face.size)
	draw_style_box(_rounded(Color(0.01,0.04,0.10,0.26), radius, Color.TRANSPARENT, 0), cast)
	draw_style_box(_rounded(accent, radius, Color(accent.lightened(0.28),0.38), 1), face)
	draw_texture_rect(AUTHORED_TILE_OVERLAY, face.grow(1.0), false, Color.WHITE)
	var lower := Rect2(Vector2(face.position.x + face.size.x*0.09, face.end.y-face.size.y*0.15), Vector2(face.size.x*0.82,face.size.y*0.08))
	draw_style_box(_rounded(Color(accent.darkened(0.34),0.24),radius*0.45,Color.TRANSPARENT,0),lower)
	var gloss_rect := Rect2(face.position + Vector2(face.size.x*0.12, face.size.y*0.09), Vector2(face.size.x*0.58,maxf(4.0,face.size.y*0.13)))
	draw_style_box(_rounded(Color(1,1,1,0.27),radius*0.44,Color.TRANSPARENT,0),gloss_rect)
	if hover_amount > 0.01:
		draw_arc(center, face.size.x*0.53, 0, TAU, 32, Color(glow,0.18), 3.0, true)

func _draw_motion_trail(_center: Vector2, _pulse: float) -> void:
	# Direction is communicated by the printed glyph itself. Motion trails made
	# dense late-game boards visually noisy and competed with the arrow silhouette.
	return

func _draw_arrow(center: Vector2, dir: String, scale_value: float) -> void:
	var v := _dir_vec(dir)
	var n := Vector2(-v.y, v.x)
	var readable_scale := scale_value * 1.36
	var glyph_center := center - Vector2(0, 2.0)
	var tip := glyph_center + v * readable_scale
	var tail := glyph_center - v * readable_scale * 0.76
	var neck := glyph_center + v * readable_scale * 0.10
	var half := readable_scale * 0.24
	var wing := readable_scale * 0.54
	var points := PackedVector2Array([
		tail + n * half,
		neck + n * half,
		neck + n * wing,
		tip,
		neck - n * wing,
		neck - n * half,
		tail - n * half,
	])
	# One face, one keyline: no cast shadow, sidewall, bevel or glossy highlight.
	# Bright bricks receive a navy arrow; dark bricks receive warm white.
	var bright_tile := accent.get_luminance() >= 0.46
	var fill := Color("#0b2f52") if bright_tile else Color("#fffdf7")
	var keyline := Color(1, 1, 1, 0.78) if bright_tile else Color("#102f4a")
	draw_colored_polygon(points, fill)
	var closed := points + PackedVector2Array([points[0]])
	draw_polyline(closed, keyline, maxf(1.8, readable_scale * 0.075), true)
