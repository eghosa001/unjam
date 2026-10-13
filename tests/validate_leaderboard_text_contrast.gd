extends SceneTree

func _initialize() -> void:
	var ui := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	for token in ['Color("#116080")','Color("#db80ff")','accent.darkened(0.55)']:
		if not ui.contains(token):
			push_error("Ranking labels lack a high-contrast alternative: %s" % token)
			quit(1)
			return
	var min_ratio := 4.5
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		var accent := Unjam3DTheme.game_accent(game_id)
		var light_card := Color("#fffaf2").lerp(Color(accent.r,accent.g,accent.b,1.0),0.035)
		var dark_card := Color("#282a2e").lerp(Color(accent.r,accent.g,accent.b,1.0),0.035)
		var light_text := accent.darkened(0.55)
		var dark_text := Color("#db80ff") if game_id == "block_puzzle" else accent
		if _contrast(light_text,light_card) < min_ratio:
			push_error("Light leaderboard %s contrast %.2f < 4.5" % [game_id,_contrast(light_text,light_card)])
			quit(1)
			return
		if _contrast(dark_text,dark_card) < min_ratio:
			push_error("Dark leaderboard %s contrast %.2f < 4.5" % [game_id,_contrast(dark_text,dark_card)])
			quit(1)
			return
	if _contrast(Color("#116080"),Color("#fffaf2")) < min_ratio:
		push_error("Light-mode own rank does not meet WCAG normal-text contrast")
		quit(1)
		return
	print("LEADERBOARD_TEXT_CONTRAST_OK: game accent and own-rank text >=4.5:1 against both card themes")
	quit(0)

func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

func _luminance(color: Color) -> float:
	return _linear_channel(color.r) * 0.2126 + _linear_channel(color.g) * 0.7152 + _linear_channel(color.b) * 0.0722

func _contrast(front: Color, back: Color) -> float:
	var a := _luminance(front)
	var b := _luminance(back)
	return (maxf(a,b) + 0.05) / (minf(a,b) + 0.05)
