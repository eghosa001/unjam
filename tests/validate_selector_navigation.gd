extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene could not be loaded")
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(2)
	main.set("current_surface", "live")
	if main.has_signal("surface_changed"):
		main.emit_signal("surface_changed", "live")
	await _frames(3)

	var nav := _find(main, "SelectorBottomNav") as PanelContainer
	var active := _find(main, "SelectorNavActivePlate_GAMES") as PanelContainer
	if nav == null or active == null:
		return _fail("Games selector premium bottom navigation is incomplete")

	var multi_game := root.get_node_or_null("MultiGameManager")
	if multi_game == null:
		return _fail("MultiGameManager autoload is missing")
	for game_id in ["rescue_rush", "water_sort", "block_puzzle"]:
		var expected_level := maxi(1, int(multi_game.call("highest_level", game_id)))
		var level_label := _find(main, "SelectorLevelLabel_%s" % game_id) as Label
		if level_label == null or level_label.text != "LEVEL %d" % expected_level:
			return _fail("Selector shows stale/fake progress for %s" % game_id)
		var game_title := _find(main, "SelectorGameTitle_%s" % game_id) as Label
		if game_title == null:
			return _fail("Selector game title is missing for %s" % game_id)
		if game_title.get_theme_font_size("font_size") < 20:
			return _fail("Selector game title is too small for %s" % game_id)
		if game_title.get_theme_constant("outline_size") < 2:
			return _fail("Selector game title lost its high-contrast outline for %s" % game_id)
		if game_title.get_theme_color("font_color").get_luminance() < 0.80:
			return _fail("Selector game title lost its bright foreground for %s" % game_id)
		var game_subtitle := _find(main, "SelectorGameSubtitle_%s" % game_id) as Label
		if game_subtitle == null:
			return _fail("Selector game subtitle is missing for %s" % game_id)
		if game_subtitle.autowrap_mode == TextServer.AUTOWRAP_OFF or not game_subtitle.clip_text:
			return _fail("Selector subtitle must wrap and clip before the preview art for %s" % game_id)
		var preview_frame := _find(main, "SelectorGamePreviewFrame_%s" % game_id) as Control
		if preview_frame == null:
			return _fail("Selector preview frame is missing for subtitle containment: %s" % game_id)
		# Compare against the visible frame, not the stretching SubViewportContainer.
		# Both controls share the same scaled Figma canvas, so global geometry is safe.
		if game_subtitle.get_global_rect().end.x > preview_frame.get_global_rect().position.x + 1.0:
			return _fail("Selector subtitle overlaps preview frame for %s" % game_id)
		var preview := _find(main, "SelectorGameArt3D_%s" % game_id) as SubViewportContainer
		if preview == null or not bool(preview.get_meta("unjam_flat_3d_preview", false)):
			return _fail("Selector flat-3D gameplay emblem is missing for %s" % game_id)
		var preview_viewport := _find(preview, "GamePreviewViewport3D") as SubViewport
		if preview_viewport == null or preview_viewport.size.y <= 0:
			return _fail("Selector preview viewport is missing for %s" % game_id)
		var preview_aspect := float(preview_viewport.size.x) / float(preview_viewport.size.y)
		if absf(preview_aspect - (104.0 / 112.0)) > 0.03:
			return _fail("Selector preview aspect ratio regressed for %s" % game_id)
		var preview_camera := _find(preview, "Flat3DPreviewCamera") as Camera3D
		if preview_camera == null or preview_camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
			return _fail("Selector gameplay emblem must use orthographic flat-3D framing for %s" % game_id)

	for nav_name in ["HOME", "GAMES", "DAILY", "COLLECT", "SETTINGS"]:
		var glyph := _find(main, "SelectorNavGlyph_%s" % nav_name) as Label
		var label := _find(main, "SelectorNavLabel_%s" % nav_name) as Label
		var hit := _find(main, "SelectorNavHit_%s" % nav_name) as Button
		if glyph == null or glyph.text.is_empty() or label == null or label.text != nav_name:
			return _fail("Games selector navigation identity is incomplete for %s" % nav_name)
		if hit == null or hit.size.x < 70.0 or hit.size.y < 74.0:
			return _fail("Games selector navigation touch target is too small for %s" % nav_name)

	main.queue_free()
	await process_frame
	print("Selector navigation validated.")
	quit(0)

func _find(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := _find(child, wanted)
		if found != null:
			return found
	return null

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
