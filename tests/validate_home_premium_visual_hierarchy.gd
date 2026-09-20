extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene could not be loaded")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_home")
	await _frames(6)

	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("Premium Home surface is missing")
	var canvas := home.find_child("FigmaHome390x844", true, false) as Control
	var hero := home.find_child("FigmaHomeHero", true, false) as Control
	var preview := home.find_child("FigmaHomeHeroPreview", true, false) as Control
	var primary := home.find_child("HomePrimaryAction", true, false) as Button
	var choose := home.find_child("HomeChooseGameButton", true, false) as Button
	var nav := home.find_child("HomeBottomNav3D", true, false) as Control
	if canvas == null or hero == null or preview == null or primary == null or choose == null or nav == null:
		return _fail("Figma Home hierarchy is incomplete")
	if not _rect_eq(Rect2(hero.position, hero.size), Rect2(22,122,346,224)):
		return _fail("Home hero drifted from Figma 346x224 reference")
	if not _rect_eq(Rect2(preview.position, preview.size), Rect2(220,145,125,136)):
		return _fail("Home preview drifted from Figma 125x136 reference")
	if not _rect_eq(Rect2(primary.position, primary.size), Rect2(42,286,178,48)):
		return _fail("Home primary action drifted from Figma reference")
	if not _rect_eq(Rect2(choose.position, choose.size), Rect2(22,366,166,52)):
		return _fail("Home Choose Game action drifted from Figma reference")
	if not _rect_eq(Rect2(nav.position, nav.size), Rect2(14,758,362,70)):
		return _fail("Home bottom nav drifted from Figma reference")
	if home.find_child("HomeMascot3D", true, false) != null:
		return _fail("Retired giant mascot returned to Figma Home")
	if home.find_child("HomeGameStrip", true, false) != null:
		return _fail("Retired oversized game strip returned to Figma Home")

	main.queue_free()
	await _frames(2)
	print("Home Figma visual hierarchy validated.")
	quit(0)

func _rect_eq(actual: Rect2, expected: Rect2) -> bool:
	return actual.position.distance_to(expected.position) <= 1.0 and actual.size.distance_to(expected.size) <= 1.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
