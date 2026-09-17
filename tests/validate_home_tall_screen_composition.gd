extends SceneTree

const VIEWPORTS := [
	Vector2i(1080, 1920),
	Vector2i(1440, 3200)
]
const MAX_HERO_HEIGHT := 560.0
const MIN_HERO_WIDTH := 800.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	print("PASS home tall-screen composition")
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
	if home == null or not home.visible:
		return _fail("PremiumHome missing at %s" % str(viewport_size))
	var hero := home.find_child("HomeHero3D", true, false) as Control
	var play := home.find_child("HomePrimaryAction", true, false) as Control
	if hero == null:
		return _fail("HomeHero3D missing at %s" % str(viewport_size))
	if play == null:
		return _fail("HomePrimaryAction missing at %s" % str(viewport_size))
	if hero.size.x < MIN_HERO_WIDTH:
		return _fail("Home hero is too narrow at %s: %.1fpx wide (min %.1fpx), size=%s" % [str(viewport_size), hero.size.x, MIN_HERO_WIDTH, str(hero.size)])
	if hero.size.y > MAX_HERO_HEIGHT:
		return _fail("Home hero is too tall at %s: %.1fpx (max %.1fpx), size=%s" % [str(viewport_size), hero.size.y, MAX_HERO_HEIGHT, str(hero.size)])
	if hero.size.y < 500.0:
		return _fail("Home hero became too small at %s: %.1fpx, size=%s" % [str(viewport_size), hero.size.y, str(hero.size)])
	var hero_rect := hero.get_global_rect()
	var play_rect := play.get_global_rect()
	if hero_rect.intersects(play_rect):
		return _fail("Home hero overlaps PLAY at %s" % str(viewport_size))
	var hero_to_play_gap := play_rect.position.y - hero_rect.end.y
	if hero_to_play_gap > float(viewport_size.y) * 0.18:
		return _fail("Home hero-to-PLAY gap is excessive at %s: %.1fpx" % [str(viewport_size), hero_to_play_gap])
	print("HOME_COMPOSITION %s hero=%s gap=%.1f" % [str(viewport_size), str(hero.size), hero_to_play_gap])

	main.queue_free()
	await process_frame
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
