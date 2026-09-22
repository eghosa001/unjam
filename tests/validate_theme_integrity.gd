extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(8)

	var shell := main.get_node_or_null("UXShell")
	if shell == null:
		return _fail("UX shell is missing")
	shell.set("theme_mode", "dark")
	if shell.has_method("_apply_theme"):
		shell.call("_apply_theme")
	await _frames(5)

	main.call("build_home")
	await _frames(6)
	if not _assert_dark_color_rect(main, "FigmaHomeViewportBackground"):
		return

	if main.has_method("_open_games_surface"):
		main.call("_open_games_surface")
	else:
		main.set("current_surface", "live")
		if main.has_signal("surface_changed"):
			main.emit_signal("surface_changed", "live")
	await _frames(6)
	if not _assert_dark_color_rect(main, "FigmaSelectorViewportBackground"):
		return

	for method_name in ["build_collection", "build_daily_games", "build_settings"]:
		main.call(method_name)
		await _frames(6)
		if not _assert_dark_color_rect(main, "FigmaSurfaceViewportBackground"):
			return

	var shop := main.get_node_or_null("MonetizationHub")
	if shop == null or not shop.has_method("open_shop"):
		return _fail("Shop surface is missing")
	shop.call("open_shop")
	await _frames(4)
	if String(shop.get("_built_theme")) != "dark":
		return _fail("Shop did not rebuild for dark mode")
	if shop.has_method("_close_shop"):
		shop.call("_close_shop")

	var coin_prompt := main.get_node_or_null("InsufficientCoinsPrompt")
	if coin_prompt == null or not coin_prompt.has_method("show_for"):
		return _fail("Insufficient-coins prompt is missing")
	coin_prompt.call("show_for", "HINT", 999999)
	await _frames(4)
	if not bool(coin_prompt.get("_built_dark")):
		return _fail("Insufficient-coins prompt remained on the light theme")

	var tutorial_source := _read("res://scripts/ui/ux_shell_casual.gd")
	var result_source := _read("res://scripts/ui/premium_result_overlay.gd")
	for token in ["theme_mode == \"dark\"", "Color(\"#182a3b\")", "Color(\"#172238\")"]:
		if not tutorial_source.contains(token):
			return _fail("How To Play dark-theme contract is missing: %s" % token)
	for token in ["func _dark_theme()", "Color(\"#172238\") if dark", "Color(\"#eef7ff\") if dark"]:
		if not result_source.contains(token):
			return _fail("Result-overlay dark-theme contract is missing: %s" % token)

	shell.set("theme_mode", "light")
	if shell.has_method("_apply_theme"):
		shell.call("_apply_theme")
	main.call("build_home")
	await _frames(6)
	var light_bg := main.find_child("FigmaHomeViewportBackground", true, false) as ColorRect
	if light_bg == null:
		return _fail("Light Home background is missing")
	if light_bg.color.get_luminance() < 0.20 or light_bg.color.get_luminance() > 0.50:
		return _fail("Light theme is outside the premium primary-blue luminance range")
	if light_bg.color.b < light_bg.color.r + 0.12:
		return _fail("Light theme drifted away from the approved primary-blue family")
	if main.find_child("HomeLightGlassHorizon", true, false) == null:
		return _fail("Home light mode lost its layered glass horizon")
	var home_key := main.find_child("HomeKeyLight", true, false) as PanelContainer
	if home_key == null:
		return _fail("Home light-mode key light is missing")
	var backdrop_source := _read("res://scripts/ui/figma_reference_canvas.gd")
	if not backdrop_source.contains("0.24 if not dark else 0.09"):
		return _fail("Home light-mode key light became too flat")

	main.set("current_surface", "live")
	if main.has_signal("surface_changed"):
		main.emit_signal("surface_changed", "live")
	await _frames(5)
	if main.find_child("SelectorLightGlassHorizon", true, false) == null:
		return _fail("Choose Game light mode lost its layered glass horizon")
	var selector_title := main.find_child("SelectorTitle3D", true, false) as Label
	if selector_title == null or selector_title.get_theme_color("font_color").get_luminance() < 0.70:
		return _fail("Choose Game light-mode title lost readable light-on-blue contrast")
	var selector_game_title := main.find_child("SelectorGameTitle_rescue_rush", true, false) as Label
	if selector_game_title == null or selector_game_title.get_theme_color("font_color").get_luminance() < 0.70:
		return _fail("Choose Game card title lost readable contrast")

	main.call("build_settings")
	await _frames(5)
	if main.find_child("SurfaceLightGlassHorizon", true, false) == null:
		return _fail("Secondary light surfaces lost their layered glass horizon")
	var settings_bg := main.find_child("FigmaSurfaceBackground", true, false) as PanelContainer
	if settings_bg == null:
		return _fail("Light Settings surface background is missing")

	for path in [
		"res://scripts/ui/premium_main_casual.gd",
		"res://scripts/ui/premium_home_direct_levels.gd",
		"res://scripts/ui/premium_live_hub_3d.gd",
	]:
		var source := _read(path)
		for token in ["#4f76b8", "#3f67aa", "#315596"]:
			if not source.contains(token):
				return _fail("Premium light scene palette contract missing in %s: %s" % [path, token])

	var feedback := root.get_node_or_null("FeedbackManager")
	if feedback != null and feedback.has_method("shutdown_audio"):
		feedback.call("shutdown_audio")
	await _frames(2)
	print("THEME_INTEGRITY_OK")
	quit(0)

func _assert_dark_color_rect(parent: Node, node_name: String) -> bool:
	var bg := parent.find_child(node_name, true, false) as ColorRect
	if bg == null:
		return _fail("Missing theme background: %s" % node_name)
	if bg.color.get_luminance() > 0.38 or bg.color.get_luminance() < 0.10:
		return _fail("%s is outside the premium dark-neutral luminance range (%.3f)" % [node_name, bg.color.get_luminance()])
	return true

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
