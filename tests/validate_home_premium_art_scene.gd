extends SceneTree

# Compact real-scene check for premium original Home art on phone and tablet.
# No screenshot-only score inflation: light/dark textures must be distinct,
# noninteractive, static, readable and behind the existing launcher controls.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("UNJAM_FAST_VISUAL_AUDIT","1")
	root.size = Vector2i(540,960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene unavailable")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(6)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null:
		return _fail("Premium Home root missing")
	var textures: Array[Texture2D] = []
	for mode in ["dark","light"]:
		# Home theme comes from UXShell, not from SaveManager directly.
		var shell := main.get_node_or_null("UXShell")
		if shell == null:
			return _fail("UXShell theme owner missing")
		shell.set("theme_mode",mode)
		main.call("build_home")
		await _frames(5)
		home = main.get_node("PremiumHome")
		var canvas := home.find_child("FigmaHome390x844",true,false) as Control
		var scenery := home.find_child("HomeWorldAtmosphere",true,false) as TextureRect
		var fallback := home.find_child("FigmaHomeBackground",true,false) as Control
		var hero := home.find_child("FigmaHomeHero",true,false) as Control
		var mark := home.find_child("HomeBrandEmblem",true,false) as TextureRect
		var choose := home.find_child("HomePrimaryAction",true,false) as Button
		if canvas == null or scenery == null or fallback == null or hero == null or mark == null or choose == null:
			return _fail("%s home art or launch controls missing" % mode)
		if scenery.mouse_filter != Control.MOUSE_FILTER_IGNORE or scenery.is_processing():
			return _fail("Home art must never intercept touch or process per frame")
		if scenery.size.distance_to(Vector2(390,844)) > 1.0:
			return _fail("Home art must fill reference stage without stretch errors")
		if scenery.get_parent() != canvas or scenery.get_index() <= fallback.get_index() or scenery.get_index() >= hero.get_index():
			return _fail("Illustration must paint behind opaque copy cards")
		if choose.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE or choose.size.y < 48:
			return _fail("Choose Game tap target degraded by illustration")
		if mark.texture == null or mark.texture.get_size().x < 200:
			return _fail("Three-game hero illustration missing")
		for game_id in ["rescue_rush","water_sort","block_puzzle"]:
			var shortcut := home.find_child("HomeShowcaseOpenLevels_%s" % game_id,true,false) as Button
			if shortcut == null or shortcut.pressed.get_connections().is_empty():
				return _fail("Illustrated scene disrupted a game-level shortcut")
		textures.append(scenery.texture)
	if textures.size() != 2 or textures[0] == textures[1]:
		return _fail("Home light and dark art are not independent")
	root.size = Vector2i(2560,1600)
	await _frames(8)
	home = main.get_node("PremiumHome")
	var wide := home.find_child("HomeWideAtmosphere",true,false) as TextureRect
	var wide_stage := home.find_child("HomeWideStage",true,false) as Control
	if wide == null or wide_stage == null or not wide_stage.visible or wide.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return _fail("Large-screen authored art is missing or intercepts the screen")
	if wide.is_processing():
		return _fail("Large-screen artwork consumes idle frame time")
	for game_id in ["rescue_rush","water_sort","block_puzzle"]:
		var hit := home.find_child("HomeWideOpenLevels_%s" % game_id,true,false) as Button
		if hit == null or hit.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
			return _fail("Wide illustrated background changed game navigation")
	main.queue_free()
	await _frames(2)
	print("HOME_PREMIUM_ART_SCENE_OK: static layered light/dark, tablet, original trio, safe actions")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
