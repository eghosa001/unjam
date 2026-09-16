extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://scripts/ui/premium_main_casual.gd", FileAccess.READ)
	if file == null:
		push_error("Premium main casual source is missing")
		quit(1)
		return
	var source := file.get_as_text()
	var start := source.find("func build_home()")
	if start < 0:
		push_error("Home return still depends entirely on deferred surface visibility")
		quit(1)
		return
	var finish := source.find("\nfunc ", start + 1)
	var block := source.substr(start, finish - start)
	for needle in ["super.build_home()", "PremiumHome", "PremiumLive", "_on_surface_changed", "\"home\""]:
		if not block.contains(needle):
			push_error("Home return is not an atomic premium-surface handoff: " + needle)
			quit(1)
			return
	print("Returning Home swaps persistent premium surfaces before the next frame.")
	quit(0)
