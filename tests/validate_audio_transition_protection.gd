extends SceneTree

func _initialize() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/systems/feedback_manager.gd")
	for token in [
		"func _cancel_music_fade() -> void:",
		"fade.tween_property(music_player, \"volume_db\", MUSIC_START_DB, MUSIC_FADE_OUT_SECONDS)",
		"not bool(SaveManager.data.get(\"music\", true))",
		"var _music_fade: Tween",
		"const NAV_TAP_MIN_INTERVAL_MS := 35",
	]:
		if not _check(source.contains(token),"Music fade or double-tap protection absent: %s" % token):return

	var script := load("res://scripts/systems/feedback_manager.gd")
	if not _check(script != null,"Feedback manager script failed to load"):return
	var feedback: Node = script.new()
	if not _check(bool(feedback.call("_accept_nav_tap",1000)),"First nav tick was blocked"):return
	for ms in [1000,1001,1010,1034]:
		if not _check(not bool(feedback.call("_accept_nav_tap",ms)),"Rapid tap stacked too many ticks at %d" % ms):return
	if not _check(bool(feedback.call("_accept_nav_tap",1035)),"35ms response floor blocks legitimate taps"):return
	if not _check(not bool(feedback.call("_accept_nav_tap",1069)) and bool(feedback.call("_accept_nav_tap",1070)),
		"Nav tap throttle fails at boundary"):return
	feedback.free()
	print("AUDIO_TRANSITION_PROTECTION_OK: UI tick burst guard and click-free music toggles")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	push_error(message)
	quit(1)
	return false
