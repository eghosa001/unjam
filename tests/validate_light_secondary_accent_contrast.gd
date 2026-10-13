extends SceneTree

func _initialize() -> void:
	var surface: Node = load("res://scripts/ui/premium_main_casual.gd").new()
	var background := Color("#fffef8")
	for accent in [
		Color(1.0,0.84,0.24), Color(0.13,0.78,0.39),
		Color(0.14,0.68,1.0), Color(1.0,0.55,0.12),
		Color("20d86b"),Color("19b9ff"),Color("c63cff"),
	]:
		var ink: Color = surface.call("_light_accent_ink",accent)
		var l1 := maxf(ink.srgb_to_linear().get_luminance(),background.srgb_to_linear().get_luminance())
		var l2 := minf(ink.srgb_to_linear().get_luminance(),background.srgb_to_linear().get_luminance())
		var contrast := (l1 + 0.05) / (l2 + 0.05)
		if contrast < 4.5:
			surface.free()
			push_error("Light secondary accent contrast below 4.5:1, %.2f" % contrast)
			quit(1)
			return
	if not (surface.call("_light_accent_ink",Color.WHITE) as Color).is_equal_approx(Color.WHITE):
		surface.free()
		push_error("Preserving authored white-on-dark text is required")
		quit(1)
		return
	surface.free()
	print("LIGHT_SECONDARY_ACCENT_CONTRAST_OK")
	quit(0)
