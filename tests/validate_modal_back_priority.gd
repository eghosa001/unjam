extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/ux_shell_premium.gd", FileAccess.READ)
	if file == null:
		return _fail("UX shell source is missing")
	var source := file.get_as_text()
	var start := source.find("func _handle_back()")
	var finish := source.find("\nfunc ", start + 1)
	if start < 0 or finish <= start:
		return _fail("Back handler is missing")
	var block := source.substr(start, finish - start)
	var coin := block.find("InsufficientCoinsPrompt")
	var shop := block.find("MonetizationHub")
	var rankings := block.find("PremiumLeaderboardPopup")
	var surface := block.find("var surface :=")
	var levels := block.find("surface == \"levels\"")
	if coin < 0 or shop < 0 or rankings < 0 or surface < 0:
		return _fail("Back handler must cover coin, shop and rankings overlays")
	if not (coin < shop and shop < rankings and rankings < surface):
		return _fail("Back handler must dismiss overlays before navigating")
	if levels < surface or not block.contains("main.call(\"_open_games_surface\")"):
		return _fail("Android Back from level browser must return to the Games selector")
	print("Modal Back priority validated.")
	quit(0)

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
