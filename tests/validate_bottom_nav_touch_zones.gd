extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540, 960)
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene is missing")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(5)

	main.call("build_home")
	await _frames(3)
	if not _check_named(main, ["HomeNavButton","HomeGamesNavButton","HomeDailyNavButton","HomeCollectionNavButton","HomeSettingsNavButton"], "Home"):
		return
	if not _check_visual_and_action_parity(main, "HomeNav", ["HOME","GAMES","DAILY","COLLECT","SETTINGS"], true, "HOME"):
		return

	main.call("_open_games_surface")
	await _frames(3)
	if not _check_named(main, ["SelectorNavHit_HOME","SelectorNavHit_GAMES","SelectorNavHit_DAILY","SelectorNavHit_COLLECT","SelectorNavHit_SETTINGS"], "Games"):
		return
	if not _check_visual_and_action_parity(main, "SelectorNav", ["HOME","GAMES","DAILY","COLLECT","SETTINGS"], false, "GAMES"):
		return

	main.call("build_daily_games")
	await _frames(3)
	if not _check_named(main, ["StdNavHit_HOME","StdNavHit_GAMES","StdNavHit_DAILY","StdNavHit_COLLECTION","StdNavHit_SETTINGS"], "Shared"):
		return
	if not _check_visual_and_action_parity(main, "StdNav", ["home","games","daily","collection","settings"], false, "daily"):
		return
	# Settings, Collection and secondary screens share exactly the same nav
	# component. Confirm their active-state semantics and geometry never drift.
	for scene in [
		["build_settings", "settings", true],
		["build_collection", "collection", true],
		["build_goals", "", false],
		["build_profile", "", false],
		["build_friends", "", false],
		["build_compete_leaderboard", "", false],
	]:
		var method := String(scene[0])
		if method in ["build_friends","build_compete_leaderboard"]:
			main.call(method,false)
		else:
			main.call(method)
		await _frames(3)
		if not _check_visual_and_action_parity(main, "StdNav", ["home","games","daily","collection","settings"],false,String(scene[1])):
			return
	# Rendering both themes is essential to confirm the same labels, glyphs,
	# touch positions and selected-state contrast regardless of active palette.
	var shell := main.get_node_or_null("UXShell")
	if shell != null:
		var former := String(shell.get("theme_mode"))
		shell.set("theme_mode","dark" if former == "light" else "light")
		main.call("build_settings")
		await _frames(4)
		if not _check_visual_and_action_parity(main,"StdNav",["home","games","daily","collection","settings"],false,"settings"):
			return
		shell.set("theme_mode",former)

	main.queue_free()
	await process_frame
	print("Bottom navigation touch zones are non-overlapping.")
	quit(0)

func _check_visual_and_action_parity(owner: Node, prefix: String, keys: Array[String], home: bool, selected: String) -> bool:
	var controls: Array[Control] = []
	var nav_label_y := -1.0
	for key in keys:
		var k := String(key)
		var id := k.to_upper()
		var hit_name := ("HomeNavButton" if k == "HOME" else "Home%sNavButton" % k.capitalize()) if home else ("%sHit_%s" % [prefix, id])
		# Home historically calls the collection control HomeCollectionNavButton.
		if home and k == "COLLECT":
			hit_name = "HomeCollectionNavButton"
		var hit := owner.find_child(hit_name, true, false) as Button
		var label := owner.find_child("%sLabel_%s" % [prefix,k],true,false) as Label
		var glyph := owner.find_child("%sGlyph_%s" % [prefix,k],true,false) as Label
		if hit == null or label == null or glyph == null:
			return _fail("Navigation %s lacks hit/label/glyph for %s" % [prefix,k])
		if label.text != ("COLLECT" if k in ["COLLECT","collection"] else k.to_upper()):
			return _fail("%s has inconsistent tab label for %s" % [prefix,k])
		if hit.action_mode != BaseButton.ACTION_MODE_BUTTON_RELEASE:
			return _fail("%s triggers %s on touch-down (risk of accidental navigation on swipe)" % [prefix,k])
		var current := k.to_lower() == selected.to_lower()
		if current:
			if not hit.accessibility_name.to_lower().contains("current tab"):
				return _fail("%s does not narrate selected tab %s" % [prefix,k])
		else:
			if not hit.accessibility_name.to_lower().contains("open "):
				return _fail("%s lacks discoverable %s tab navigation" % [prefix,k])
			if hit.focus_mode != Control.FOCUS_ALL:
				return _fail("%s has no keyboard or accessibility focus on %s" % [prefix,k])
			if not hit.pressed.has_connections():
				return _fail("%s %s tab does not activate any page" % [prefix,k])
		if nav_label_y < 0.0:
			nav_label_y = label.position.y
		elif absf(label.position.y-nav_label_y) > 0.5:
			return _fail("%s bottom labels are not aligned" % prefix)
		if absf(label.position.y - 803.0) > 1.0:
			return _fail("%s tab %s is not at the canonical baseline" % [prefix,k])
		if label.get_theme_font_size("font_size") > 13:
			return _fail("%s tab %s uses a different text size" % [prefix,k])
		if k.to_lower() == "daily" and glyph.text != "★":
			return _fail("%s Daily tab has a different icon from other surfaces" % prefix)
		controls.append(hit)
	if not _check_controls(controls,prefix):
		return false
	if selected.is_empty():
		# Ancillary pages such as Goals/Friends/Compete must not pretend a
		# primary bottom tab is selected.
		return owner.find_child("%sActivePlate_*" % prefix,true,false) == null
	var hit_x := {"home":14.0,"games":86.0,"daily":158.0,"collection":230.0,"settings":302.0}
	var plate_name := "HomeNavActivePlate" if home else "%sActivePlate_%s" % [prefix,selected.to_upper() if prefix == "SelectorNav" else selected.to_lower()]
	var shine_name := "HomeNavActiveShine" if home else "%sActiveShine_%s" % [prefix,selected.to_upper() if prefix == "SelectorNav" else selected.to_lower()]
	var plate := owner.find_child(plate_name,true,false) as Control
	var shine := owner.find_child(shine_name,true,false) as Control
	if plate == null or shine == null:
		return _fail("%s lacks the common selected-state plate/quiet highlight for %s" % [prefix,selected])
	var expected_x := float(hit_x[selected.to_lower()])
	var pr := Rect2(plate.position,plate.size)
	var sr := Rect2(shine.position,shine.size)
	if pr.position.distance_to(Vector2(expected_x+7.0,761.0)) > 0.5 or pr.size.distance_to(Vector2(58.0,58.0)) > 0.5:
		return _fail("%s selected-state plate has inconsistent spacing or size" % prefix)
	if sr.position.distance_to(Vector2(expected_x+24.0,763.0)) > 0.5 or sr.size.distance_to(Vector2(24.0,2.0)) > 0.5:
		return _fail("%s selected-state marker differs from other screens" % prefix)
	return true

func _check_named(root_node: Node, names: Array[String], label: String) -> bool:
	var controls: Array[Control] = []
	for wanted in names:
		var node := root_node.find_child(wanted, true, false) as Control
		if node == null:
			return _fail("%s nav hit missing: %s" % [label, wanted])
		controls.append(node)
	return _check_controls(controls, label)

func _check_controls(controls: Array[Control], label: String) -> bool:
	if controls.size() != 5:
		return _fail("%s nav does not expose exactly five touch zones" % label)
	controls.sort_custom(func(a: Control, b: Control) -> bool: return a.global_position.x < b.global_position.x)
	for i in range(controls.size()):
		if controls[i].size.x < 70.0 or controls[i].size.y < 70.0:
			return _fail("%s nav touch zone is too small" % label)
		if i > 0 and controls[i - 1].get_global_rect().intersects(controls[i].get_global_rect()):
			return _fail("%s nav touch zones overlap" % label)
	return true

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
