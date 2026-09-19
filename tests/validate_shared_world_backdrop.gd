extends SceneTree

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
	await _frames(8)

	main.call("build_home")
	await _frames(3)
	if not _assert_single_shared_backdrop(main, "home"):
		return

	main.call("build_settings")
	await _frames(3)
	if not _assert_single_shared_backdrop(main, "settings"):
		return

	main.call("build_collection")
	await _frames(3)
	if not _assert_single_shared_backdrop(main, "collection"):
		return

	main.call("build_home")
	await _frames(2)
	var hub := main.get_node_or_null("MonetizationHub")
	if hub == null or not hub.has_method("open_shop"):
		return _fail("Shop hub unavailable")
	hub.call("open_shop")
	await _frames(3)
	if not _assert_single_shared_backdrop(main, "shop"):
		return
	var overlay := hub.get("overlay") as Control
	if overlay == null or not overlay.visible:
		return _fail("Shop overlay is not visible")
	if _count_backdrops(overlay) != 0:
		return _fail("Shop still creates its own full-screen world backdrop")

	main.queue_free()
	await process_frame
	print("Shared world backdrop validated: Home, Settings, Collection and Shop reuse one persistent UNJAM world layer.")
	quit(0)

func _assert_single_shared_backdrop(main: Control, label: String) -> bool:
	var shared := main.get_node_or_null("UnjamWorldBackdrop") as Unjam3DBackdrop
	if shared == null:
		return _fail("%s has no persistent UnjamWorldBackdrop on Main" % label)
	if not shared.visible or not shared.is_visible_in_tree():
		return _fail("%s hides the persistent UnjamWorldBackdrop" % label)
	var count := _count_backdrops(main)
	if count != 1:
		return _fail("%s renders %d full-screen world backdrops instead of exactly one" % [label, count])
	var home := main.get_node_or_null("PremiumHome")
	if home != null and home.get_node_or_null("HomePremiumBackdrop") != null:
		return _fail("%s still gives Home a private full-screen backdrop" % label)
	var content := main.get("content") as Control
	if content != null and content.get_node_or_null("Unjam3DSurfaceBackdrop") != null:
		return _fail("%s still gives secondary surfaces a private full-screen backdrop" % label)
	return true

func _count_backdrops(node: Node) -> int:
	var count := 1 if node is Unjam3DBackdrop else 0
	for child in node.get_children():
		count += _count_backdrops(child)
	return count

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
