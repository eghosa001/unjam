extends SceneTree

const MIN_VISIBLE_ALPHA := 0.84
const TEST_VIEWPORT := Vector2i(720, 1280)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = TEST_VIEWPORT
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(10)

	main.call("build_home")
	if not _assert_covered(main, "boot -> home immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "home", "boot -> home settled"):
		return

	var home := main.get_node_or_null("PremiumHome")
	if home == null or not home.has_method("_open_game_selector"):
		return _fail("PremiumHome game-selector navigation is unavailable")
	home.call("_open_game_selector")
	if not _assert_covered(main, "home -> selector immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "live", "home -> selector settled"):
		return

	main.call("open_game_campaign", "rescue_rush")
	if not _assert_covered(main, "selector -> Rescue Rush levels immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "levels", "selector -> Rescue Rush levels settled"):
		return

	main.call("start_level", 1)
	if not _assert_covered(main, "levels -> Rescue Rush game immediate"):
		return
	await _frames(6)
	if not _assert_surface(main, "game", "levels -> Rescue Rush game settled"):
		return

	main.call("force_back_from_game")
	if not _assert_covered(main, "Rescue Rush game -> levels immediate"):
		return
	await _frames(3)
	if not _assert_surface(main, "levels", "Rescue Rush game -> levels settled"):
		return

	main.call("build_home")
	if not _assert_covered(main, "levels -> home immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "home", "levels -> home settled"):
		return

	main.call("build_settings")
	if not _assert_covered(main, "home -> settings immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "settings", "home -> settings settled"):
		return
	main.call("build_home")
	if not _assert_covered(main, "settings -> home immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "home", "settings -> home settled"):
		return

	main.call("build_collection")
	if not _assert_covered(main, "home -> collection immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "collection", "home -> collection settled"):
		return
	main.call("build_home")
	if not _assert_covered(main, "collection -> home immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "home", "collection -> home settled"):
		return

	var hub := main.get_node_or_null("MonetizationHub")
	if hub == null or not hub.has_method("open_shop") or not hub.has_method("_close_shop"):
		return _fail("MonetizationHub shop navigation is unavailable")
	hub.call("open_shop")
	await _frames(2)
	if not _assert_shop_visible(main, hub, "home -> shop"):
		return
	hub.call("_close_shop")
	if not _assert_covered(main, "shop -> home immediate"):
		return
	await _frames(1)
	if not _assert_surface(main, "home", "shop -> home settled"):
		return

	home = main.get_node_or_null("PremiumHome")
	home.call("_open_game_selector")
	await _frames(2)
	main.call("open_game_campaign", "water_sort")
	if not _assert_covered(main, "selector -> Water Sort levels immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "levels", "selector -> Water Sort levels settled"):
		return
	main.call("start_multi_level", "water_sort", 1, false)
	if not _assert_covered(main, "Water Sort levels -> game immediate"):
		return
	await _frames(6)
	if not _assert_surface(main, "game", "Water Sort levels -> game settled"):
		return
	main.call("build_home")
	if not _assert_covered(main, "Water Sort game -> home immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "home", "Water Sort game -> home settled"):
		return

	home = main.get_node_or_null("PremiumHome")
	home.call("_open_game_selector")
	await _frames(2)
	main.call("open_game_campaign", "block_puzzle")
	if not _assert_covered(main, "selector -> Block Puzzle levels immediate"):
		return
	await _frames(2)
	if not _assert_surface(main, "levels", "selector -> Block Puzzle levels settled"):
		return
	main.call("start_multi_level", "block_puzzle", 1, false)
	if not _assert_covered(main, "Block Puzzle levels -> game immediate"):
		return
	await _frames(6)
	if not _assert_surface(main, "game", "Block Puzzle levels -> game settled"):
		return
	main.call("force_back_from_game")
	if not _assert_covered(main, "Block Puzzle game -> levels immediate"):
		return
	await _frames(3)
	if not _assert_surface(main, "levels", "Block Puzzle game -> levels settled"):
		return

	main.queue_free()
	await process_frame
	print("Navigation surface coverage passed: Home, selector, levels, games, settings, collection and shop transitions retain a visible surface with no blank-frame alpha dip.")
	quit(0)

func _assert_surface(main: Control, expected_surface: String, label: String) -> bool:
	var actual := String(main.get("current_surface"))
	if actual != expected_surface:
		return _fail("%s expected surface '%s', got '%s'" % [label, expected_surface, actual])
	return _assert_covered(main, label)

func _assert_shop_visible(main: Control, hub: Node, label: String) -> bool:
	var overlay = hub.get("overlay")
	if overlay == null or not is_instance_valid(overlay) or not overlay.visible:
		return _fail("%s did not expose a visible shop overlay" % label)
	if overlay is CanvasItem and (overlay as CanvasItem).modulate.a < MIN_VISIBLE_ALPHA:
		return _fail("%s shop overlay alpha dipped below safe coverage" % label)
	return _assert_covered(main, label, overlay as Control)

func _assert_covered(main: Control, label: String, extra: Control = null) -> bool:
	var candidates: Array[Control] = []
	for node_name in ["PremiumHome", "PremiumLive", "ActiveGame"]:
		var node := main.get_node_or_null(node_name) as Control
		if node != null and is_instance_valid(node):
			candidates.append(node)
	var content := main.get("content") as Control
	if content != null and is_instance_valid(content):
		candidates.append(content)
	if extra != null and is_instance_valid(extra):
		candidates.append(extra)

	var visible_count := 0
	for candidate in candidates:
		if not candidate.visible or not candidate.is_visible_in_tree():
			continue
		visible_count += 1
		if candidate.modulate.a < MIN_VISIBLE_ALPHA:
			return _fail("%s leaves visible surface %s at alpha %.3f" % [label, str(candidate.get_path()), candidate.modulate.a])
		var rect := candidate.get_global_rect()
		if rect.size.x < float(TEST_VIEWPORT.x) * 0.90 or rect.size.y < float(TEST_VIEWPORT.y) * 0.90:
			return _fail("%s visible surface %s does not cover the viewport: %s" % [label, str(candidate.get_path()), str(rect)])
	if visible_count <= 0:
		return _fail("%s exposes a blank frame: no primary surface is visible" % label)
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
