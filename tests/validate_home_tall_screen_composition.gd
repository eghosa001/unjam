extends SceneTree

const VIEWPORTS := [Vector2i(1080,1920), Vector2i(1440,3200)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	print("PASS Figma home tall-screen composition")
	quit(0)

func _validate_viewport(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(6)
	main.call("build_home")
	await _frames(8)

	var home := main.get_node_or_null("PremiumHome") as Control
	var canvas := home.find_child("FigmaHome390x844", true, false) as Control if home != null else null
	var hero := home.find_child("FigmaHomeHero", true, false) as Control if home != null else null
	var primary := home.find_child("HomePrimaryAction", true, false) as Control if home != null else null
	var nav := home.find_child("HomeBottomNav3D", true, false) as Control if home != null else null
	if home == null or canvas == null or hero == null or primary == null or nav == null:
		return _fail("Figma Home structure missing at %s" % str(viewport_size))
	if absf(canvas.scale.x - canvas.scale.y) > 0.001 or canvas.scale.x <= 0.0:
		return _fail("Reference canvas lost uniform scaling at %s" % str(viewport_size))
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for control in [hero,primary,nav]:
		var rect := (control as Control).get_global_rect()
		if not _inside(rect,screen):
			return _fail("%s spills outside %s: %s" % [control.name,str(viewport_size),str(rect)])
	if Rect2(hero.position,hero.size).size.distance_to(Vector2(346,224)) > 1.0:
		return _fail("Home hero local Figma geometry changed at %s" % str(viewport_size))
	if Rect2(primary.position,primary.size).size.distance_to(Vector2(178,48)) > 1.0:
		return _fail("Home primary action local Figma geometry changed at %s" % str(viewport_size))
	if Rect2(nav.position,nav.size).size.distance_to(Vector2(362,70)) > 1.0:
		return _fail("Home nav local Figma geometry changed at %s" % str(viewport_size))
	main.queue_free()
	await process_frame
	return true

func _inside(rect: Rect2, viewport: Rect2) -> bool:
	return rect.position.x >= -2.0 and rect.position.y >= -2.0 and rect.end.x <= viewport.end.x + 2.0 and rect.end.y <= viewport.end.y + 2.0

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
