extends SceneTree

# Keyboard/screen-reader coverage for actual game navigation, not only source
# string inspection. Desktop and mobile still need human assistive-tech testing.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var shared := FigmaReferenceCanvas.premium_button("PLAY", 15, Color.WHITE, Color("#256c9c"), 12)
	if shared.focus_mode != Control.FOCUS_ALL or shared.accessibility_name != "PLAY":
		return _fail("Shared buttons must be focusable and have a screen reader label")
	if shared.get_theme_stylebox("focus") == null:
		return _fail("Shared buttons need a visible keyboard focus ring")
	shared.free()
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene missing")
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(6):
		await process_frame
	main.call("build_home")
	for _i in range(3):
		await process_frame
	for name in ["HomeGamesNavButton","HomeDailyNavButton","HomeCollectionNavButton","HomeSettingsNavButton"]:
		var control := main.find_child(name, true, false) as Button
		if not _assert_button(control, name):
			return
	main.call("build_daily_games")
	for _i in range(3):
		await process_frame
	for name in ["StdNavHit_HOME","StdNavHit_GAMES","StdNavHit_COLLECTION","StdNavHit_SETTINGS"]:
		var control := main.find_child(name, true, false) as Button
		if not _assert_button(control, name):
			return
	main.queue_free()
	await process_frame
	print("ACCESSIBLE_NAVIGATION_OK: focusable labels on shared buttons and both bottom bars.")
	quit(0)

func _assert_button(button: Button, name: String) -> bool:
	if button == null:
		return _fail("Missing navigation action " + name)
	if button.focus_mode != Control.FOCUS_ALL:
		return _fail("Nav action cannot be reached by keyboard: " + name)
	if button.accessibility_name.strip_edges().is_empty():
		return _fail("Nav action has no screen reader label: " + name)
	if button.get_theme_stylebox("focus") == null:
		return _fail("Nav action has no visible focus ring: " + name)
	return true

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
