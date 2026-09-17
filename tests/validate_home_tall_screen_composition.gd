extends SceneTree

const VIEWPORTS := [
	Vector2i(1080, 1920),
	Vector2i(1440, 3200)
]
const MAX_HERO_HEIGHT_RATIO := 0.30
const MIN_HERO_HEIGHT_RATIO := 0.14
const MIN_HERO_WIDTH := 800.0
const MIN_ACTION_CENTER_RATIO := 0.42
const MAX_ACTION_CENTER_RATIO := 0.66

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
	var action_cluster := home.find_child("HomeActionCluster", true, false) as Control
	var play := home.find_child("HomePrimaryAction", true, false) as Control
	var strip := home.find_child("HomeGameStrip", true, false) as Control
	if hero == null:
		return _fail("HomeHero3D missing at %s" % str(viewport_size))
	if action_cluster == null:
		return _fail("HomeActionCluster missing at %s" % str(viewport_size))
	if play == null or strip == null:
		return _fail("Home center actions missing at %s" % str(viewport_size))
	if hero.size.x < MIN_HERO_WIDTH:
		return _fail("Home hero is too narrow at %s: %.1fpx wide (min %.1fpx), size=%s" % [str(viewport_size), hero.size.x, MIN_HERO_WIDTH, str(hero.size)])
	var hero_height_ratio := hero.size.y / maxf(1.0, float(viewport_size.y))
	if hero_height_ratio > MAX_HERO_HEIGHT_RATIO:
		return _fail("Home hero dominates the tall screen at %s: ratio %.3f (max %.3f), size=%s" % [str(viewport_size), hero_height_ratio, MAX_HERO_HEIGHT_RATIO, str(hero.size)])
	if hero_height_ratio < MIN_HERO_HEIGHT_RATIO:
		return _fail("Home hero became too small at %s: ratio %.3f (min %.3f), size=%s" % [str(viewport_size), hero_height_ratio, MIN_HERO_HEIGHT_RATIO, str(hero.size)])
	var hero_rect := hero.get_global_rect()
	var cluster_rect := action_cluster.get_global_rect()
	var play_rect := play.get_global_rect()
	var strip_rect := strip.get_global_rect()
	if hero_rect.intersects(cluster_rect):
		return _fail("Home hero overlaps the center action cluster at %s" % str(viewport_size))
	if not cluster_rect.encloses(play_rect) or not cluster_rect.encloses(strip_rect):
		return _fail("PLAY/game strip escaped HomeActionCluster at %s" % str(viewport_size))
	var screen_height := maxf(1.0, float(viewport_size.y))
	var cluster_center_ratio := (cluster_rect.position.y + cluster_rect.size.y * 0.5) / screen_height
	if cluster_center_ratio < MIN_ACTION_CENTER_RATIO or cluster_center_ratio > MAX_ACTION_CENTER_RATIO:
		return _fail("Home actions are not centrally placed at %s: center ratio %.3f" % [str(viewport_size), cluster_center_ratio])
	var hero_to_cluster_gap := cluster_rect.position.y - hero_rect.end.y
	if hero_to_cluster_gap > screen_height * 0.10:
		return _fail("Home hero-to-action gap is excessive at %s: %.1fpx" % [str(viewport_size), hero_to_cluster_gap])
	print("HOME_COMPOSITION %s hero=%s hero_ratio=%.3f action_center=%.3f gap=%.1f" % [str(viewport_size), str(hero.size), hero_height_ratio, cluster_center_ratio, hero_to_cluster_gap])

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
