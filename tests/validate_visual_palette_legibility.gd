extends SceneTree

# Focused visual measurement: no unrelated campaign tests or new animations.
# Contrast alone is not a visual-design score, but phone-readable typography
# and branded action colors are objectively testable.
func _initialize() -> void:
	var main_ui := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var home_ui := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var design := FileAccess.get_file_as_string("res://scripts/ui/figma_reference_canvas.gd")
	for marker in [
		"FigmaReferenceCanvas.accessible_text_color(resolved_text, resolved_fill, 4.5)",
		"var readable_size := maxi(12, font_size)",
		"_fit_single_line_control_text(button, maxf(24.0, rect.size.x - 18.0), readable_size, 12)",
		"FigmaReferenceCanvas.style_display_title(header_title, heading_color,",
		"var checkin_title_ink := FigmaReferenceCanvas.accessible_text_color(",
	]:
		if not main_ui.contains(marker):
			push_error("Secondary UI contrast or readable action typography drifted: " + marker)
			quit(1)
			return
	for marker in [
		"RefCanvas.accessible_text_color(text_color, fill, 4.5)",
		"var readable_size := maxi(font_size, 12)",
	]:
		if not home_ui.contains(marker):
			push_error("Home primary button or pill may have illegible labels: " + marker)
			quit(1)
			return
	if not design.contains('var dark_candidate := Color("#070e19")'):
		push_error("Accessible ink regressed to the 4.17:1 Block Puzzle purple navy")
		quit(1)
		return

	# Representative fills from Home, Daily, Friends, Shop and each game.
	for hex in [
		"#21c763", "#ff8d1f", "#19b9ff", "#c63cff", "#ffd83d",
		"#7a57e0", "#257e55", "#ee8a2d", "#22a9e8", "#7757cf",
		"#282a2e", "#d9cfaf", "#f5f2ec", "#d9d0f5", "#cbc4b8",
	]:
		var fill := Color(hex)
		var ink := FigmaReferenceCanvas.accessible_text_color(Color("#fffef8"), fill, 4.5)
		var measured := FigmaReferenceCanvas.contrast_ratio(ink, fill)
		if measured < 4.5:
			push_error("Unjam button %s has only %.2f:1 text contrast" % [hex, measured])
			quit(1)
			return
		# The same button must remain legible in its hovered and pressed
		# lacquer states, without changing geometry or using a shader.
		for state_fill in [fill.lightened(0.035), fill.darkened(0.055)]:
			var state_contrast := FigmaReferenceCanvas.contrast_ratio(ink, state_fill)
			if state_contrast < 4.3:
				push_error("Button %s loses readable text when interacted with: %.2f" % [hex, state_contrast])
				quit(1)
				return

	var purple_button := FigmaReferenceCanvas.premium_button(
		"BLOCK PUZZLE", 12, Color("#fffef8"), Color("#c63cff"), 14.0)
	var actual_ink := purple_button.get_theme_color("font_color")
	if FigmaReferenceCanvas.contrast_ratio(actual_ink, Color("#c63cff")) < 4.5:
		push_error("Block Puzzle's rendered button did not adopt the accessible ink")
		quit(1)
		return
	purple_button.free()

	if FigmaReferenceCanvas.contrast_ratio(Color("#26323d"), Color("#e9e5dd")) < 4.5:
		push_error("Light display header ink is insufficient against pale background")
		quit(1)
		return
	if FigmaReferenceCanvas.contrast_ratio(Color("#f5f7fa"), Color("#1c2027")) < 4.5:
		push_error("Dark display header ink is insufficient against charcoal background")
		quit(1)
		return
	print("VISUAL_PALETTE_LEGIBILITY_OK: 15 bright/pale palettes, action states, game purple and themed headers")
	quit(0)
