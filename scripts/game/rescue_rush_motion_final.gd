extends "res://scripts/game/rescue_rush_premium.gd"

# Completion must never cover an escape that is still visibly travelling.
# The polished escape sequence lasts ~0.47 s; keep a small safety margin so
# the final arrow is fully off-screen before the rescue/result celebration.
var _escape_visual_deadline_msec := 0

func escape_piece(index: int, trigger_effect: bool) -> void:
	var was_active := index >= 0 and index < pieces.size() and bool(pieces[index].get("active", true))
	super.escape_piece(index, trigger_effect)
	if was_active and trigger_effect:
		_escape_visual_deadline_msec = maxi(_escape_visual_deadline_msec, Time.get_ticks_msec() + 520)

func resolve_rescue() -> void:
	if not rescue_has_exit():
		return
	# Re-render once after all cascade state has settled. This removes the
	# source buttons for escaped/inactive arrows while their flying ghosts finish.
	render_board()
	while Time.get_ticks_msec() < _escape_visual_deadline_msec:
		await get_tree().process_frame
	# A tiny breathing beat makes the final escape read before the rescue leaves.
	await get_tree().create_timer(0.035).timeout
	await super.resolve_rescue()
