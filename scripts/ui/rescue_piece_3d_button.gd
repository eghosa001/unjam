extends "res://scripts/ui/premium_piece_button.gd"
class_name RescuePiece3DButton

# Legacy class name retained so Rescue Rush gameplay and escape-animation code do
# not need to change. The active piece is intentionally a flat board tile now:
# PremiumPieceButton provides bevel, shadow, gloss and press depth entirely in
# CanvasItem drawing, with no perspective scene renderer behind each tile.
# This keeps puzzle geometry straight-on while preserving a chunky 3D effect.

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
