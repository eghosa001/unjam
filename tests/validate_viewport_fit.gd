extends SceneTree

const MAX_CAMPAIGN_LEVEL := 10000
const VIEWPORTS := [
	# Compact and tall phones. 432x936 is a compact modern portrait stress case
	# where the 390x844 reference surface still preserves a 48px exact-button
	# floor after scaling.
	Vector2i(432,936),
	Vector2i(540,960),
	Vector2i(720,1280),
	Vector2i(720,1600),
	Vector2i(1080,1920),
	Vector2i(1080,2160),
	Vector2i(1080,2340),
	Vector2i(1080,2400),
	# Portrait tablets and unfolded large screens.
	Vector2i(1200,1920),
	Vector2i(1536,2048),
	Vector2i(1600,2560),
	Vector2i(1812,2176),
	# Large-screen landscape / desktop-window shapes.
	Vector2i(2048,1536),
	Vector2i(2560,1600),
	Vector2i(2176,1812),
	# Near-square split-screen / freeform-window stress.
	Vector2i(1200,1200)
]
const STRESS_VIEWPORTS := [
	Vector2i(432,936),
	Vector2i(540,960),
	Vector2i(720,1280),
	Vector2i(1536,2048),
	Vector2i(2560,1600)
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _source_contracts():
		return
	for viewport_size in VIEWPORTS:
		if not await _validate_viewport(viewport_size):
			return
	for viewport_size in STRESS_VIEWPORTS:
		if not await _validate_late_game_viewport(viewport_size):
			return
	print("Viewport-fit validation passed: audited all production surfaces for canvas bounds, text clipping/overlap and scaled touch targets, plus level 10,000 gameplay across compact phones, tablets, foldables, landscape and square windows.")
	quit(0)

func _source_contracts() -> bool:
	var project_text := _read("res://project.godot")
	var ref_text := _read("res://scripts/ui/figma_reference_canvas.gd")
	var water_scene := _read("res://scenes/WaterSort.tscn")
	var water_10000 := _read("res://scripts/game/water_sort_10000.gd")
	var water_assisted := _read("res://scripts/game/water_sort_assisted.gd")
	var water_motion := _read("res://scripts/game/water_sort_reference_motion.gd")
	var water_casual := _read("res://scripts/game/water_sort_casual.gd")
	var water_tube_3d := _read("res://scripts/ui/water_tube_3d_motion.gd")
	var rescue_motion := _read("res://scripts/game/rescue_rush_polished.gd")
	var block_scene := _read("res://scenes/BlockPuzzle.tscn")
	var block_campaign := _read("res://scripts/game/block_puzzle_10000.gd")
	var block_polish := _read("res://scripts/game/block_puzzle_final_polish.gd")
	if not project_text.contains('window/stretch/aspect="expand"'):
		return _fail("Project stretch aspect must remain expand")
	if not ref_text.contains("REFERENCE_SIZE := Vector2(390.0, 844.0)") or not ref_text.contains("_fit_reference_canvas"):
		return _fail("Figma reference canvas contract is missing")
	if not water_scene.contains("water_sort_10000.gd") or not water_10000.contains('extends "res://scripts/game/water_sort_assisted.gd"') or not water_assisted.contains('extends "res://scripts/game/water_sort_casual.gd"'):
		return _fail("Water active scene no longer uses the 10K assisted Figma stack")
	if not water_casual.contains("FigmaWater390x844"):
		return _fail("Water gameplay no longer mounts the Figma canvas")
	if not water_motion.contains("visual_pour_rim_local") or not water_motion.contains("visual_receive_rim_local"):
		return _fail("Water pour motion no longer resolves visible bottle rims")
	if not water_motion.contains("pending_completion") or not water_motion.contains("_complete_if_visuals_settled"):
		return _fail("Water completion no longer waits for pour visuals")
	if not water_tube_3d.contains('extends "res://scripts/ui/water_tube_reference_motion.gd"') or not water_tube_3d.contains("func set_pour_progress"):
		return _fail("Water 2D bottle compatibility/motion contract is missing")
	if water_tube_3d.contains("SubViewport") or water_tube_3d.contains("Camera3D"):
		return _fail("Water bottle renderer reintroduced nested 3D viewport work")
	if not rescue_motion.contains("_offscreen_target") or not rescue_motion.contains("_wait_for_escape_visuals"):
		return _fail("Rescue completion no longer waits for escape visuals")
	if not block_scene.contains("block_puzzle_10000.gd") or not block_campaign.contains('extends "res://scripts/game/block_puzzle_final_polish.gd"'):
		return _fail("Block active scene no longer preserves final polish/campaign logic")
	for required in ["TENSION_THRESHOLD","PremiumVisuals.burst"]:
		if not block_polish.contains(required):
			return _fail("Block final-polish contract missing %s" % required)
	return true

func _validate_viewport(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(8)

	main.call("build_home")
	await _frames(5)
	var home := main.get_node_or_null("PremiumHome") as Control
	if home == null or not _assert_canvas(home,"FigmaHome390x844",viewport_size,"Home"):
		return false

	main.call("build_settings")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Settings"):
		return false

	main.call("build_collection")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Collection"):
		return false
	if viewport_size.x >= 1180 and float(viewport_size.x) / maxf(1.0, float(viewport_size.y)) >= 1.22:
		var wide_stage := (main.get("content") as Control).find_child("FigmaWideSurfaceStage", true, false) as Control
		var wide_art := (main.get("content") as Control).find_child("FigmaWideMetaArtwork", true, false) as TextureRect
		if wide_stage == null or not wide_stage.visible or wide_art == null:
			return _fail("Collection landscape tablet is missing authored wide artwork")
		if wide_art.size.x < float(viewport_size.x) * 0.40 or wide_art.size.y < float(viewport_size.y) * 0.60:
			return _fail("Collection landscape artwork is too small to use the tablet canvas")

	if viewport_size in STRESS_VIEWPORTS:
		if not await _validate_secondary_surfaces(main, viewport_size):
			return false

	main.call("build_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Rescue levels"):
		return false

	main.set("selected_game_id","water_sort")
	main.call("build_multi_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Water levels"):
		return false

	main.set("selected_game_id","block_puzzle")
	main.call("build_multi_level_select")
	await _frames(5)
	if not _assert_canvas(main.get("content") as Control,"FigmaSurface390x844",viewport_size,"Block levels"):
		return false

	main.call("start_level",1)
	await _frames(10)
	var shell := main.get_node_or_null("UXShell")
	if shell != null and shell.has_method("show_tutorial"):
		shell.call("show_tutorial","rescue_rush")
		await _frames(4)
		if not _assert_canvas(shell as Node,"FigmaTutorial390x844",viewport_size,"Tutorial"):
			return false
		shell.call("hide_tutorial")
		await _frames(2)
	if not _assert_game(main,"FigmaRescue390x844",viewport_size,"Rescue"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","water_sort",1,false)
	await _frames(10)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaWater390x844",viewport_size,"Water"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","block_puzzle",1,false)
	await _frames(10)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaBlock390x844",viewport_size,"Block"):
		return false

	main.queue_free()
	await process_frame
	return true

func _validate_secondary_surfaces(main: Control, viewport_size: Vector2i) -> bool:
	var content_owner := func() -> Control: return main.get("content") as Control
	var cases := [
		["build_daily_games", [], "Daily"],
		["build_collection_upgrades", [], "Collection Upgrades"],
		["build_goals", [], "Goals"],
		["build_profile", [], "Profile"],
		["build_friends", [false], "Friends"],
		["build_compete_leaderboard", [false], "Compete"],
		["show_playmate_sidekick", ["rescue_rush"], "Sidekick"],
	]
	for case_value in cases:
		var method := String(case_value[0])
		var args: Array = case_value[1]
		main.callv(method, args)
		await _frames(4)
		if not _assert_canvas(content_owner.call(), "FigmaSurface390x844", viewport_size, String(case_value[2])):
			return false

	main.call("_open_games_surface")
	await _frames(6)
	var live := main.get_node_or_null("PremiumLive") as Control
	if live == null or not _assert_canvas(live, "FigmaSelector390x844", viewport_size, "Choose Game"):
		return false

	var shop := main.get_node_or_null("MonetizationHub")
	if shop != null and shop.has_method("open_shop"):
		shop.call("open_shop")
		await _frames(5)
		if not _assert_canvas(shop, "FigmaShop390x844", viewport_size, "Shop"):
			return false
		if shop.has_method("_close_shop"):
			shop.call("_close_shop")
			await _frames(3)

	var coin_prompt := main.get_node_or_null("InsufficientCoinsPrompt")
	if coin_prompt != null and coin_prompt.has_method("show_for"):
		var balance := int(EconomyManager.balance())
		coin_prompt.call("show_for", "HINT", balance + 25)
		await _frames(4)
		if not _assert_canvas(coin_prompt, "FigmaInsufficientCoins390x844", viewport_size, "Insufficient Coins"):
			return false
		var overlay = coin_prompt.get("overlay")
		if overlay != null and is_instance_valid(overlay):
			overlay.visible = false
		await _frames(2)

	var result := PremiumResultOverlay.new()
	result.configure("LEVEL COMPLETE", "Production layout stress", "3 MOVES", 3, Color("#21c763"), "CONTINUE")
	result.configure_secondary("DOUBLE REWARD", true)
	main.add_child(result)
	result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(4)
	if not _assert_canvas(result, "FigmaResult390x844", viewport_size, "Result"):
		result.queue_free()
		return false
	result.queue_free()
	await _frames(2)
	return true

func _validate_late_game_viewport(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Could not load Main.tscn for level-10,000 stress test")
	var main := packed.instantiate() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _frames(7)

	main.call("start_level",MAX_CAMPAIGN_LEVEL)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaRescue390x844",viewport_size,"Rescue level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","water_sort",MAX_CAMPAIGN_LEVEL,false)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaWater390x844",viewport_size,"Water level 10,000"):
		return false

	main.call("build_home")
	await _frames(3)
	main.call("start_multi_level","block_puzzle",MAX_CAMPAIGN_LEVEL,false)
	await _frames(14)
	_hide_tutorial(main)
	if not _assert_game(main,"FigmaBlock390x844",viewport_size,"Block level 10,000"):
		return false

	main.queue_free()
	await process_frame
	return true

func _assert_game(main: Control, canvas_name: String, viewport_size: Vector2i, label: String) -> bool:
	var game = main.get("active_game")
	if game == null or not is_instance_valid(game):
		return _fail("%s active game missing" % label)
	var control := game as Control
	var logical_screen := _logical_screen(control)
	if not _rect_inside(control.get_global_rect(),logical_screen):
		return _fail("%s root spills outside logical viewport %s for window %s: %s" % [label,str(logical_screen.size),str(viewport_size),str(control.get_global_rect())])
	return _assert_canvas(game as Node,canvas_name,viewport_size,label)

func _assert_canvas(owner: Node, canvas_name: String, viewport_size: Vector2i, label: String) -> bool:
	if owner == null:
		return _fail("%s owner is missing" % label)
	var canvas := owner.find_child(canvas_name,true,false) as Control
	if canvas == null:
		return _fail("%s missing %s" % [label,canvas_name])
	if canvas.size.distance_to(Vector2(390,844)) > 1.0:
		return _fail("%s reference canvas local size changed: %s" % [label,str(canvas.size)])
	if absf(canvas.scale.x-canvas.scale.y) > 0.001 or canvas.scale.x <= 0.0:
		return _fail("%s reference canvas scale is not uniform" % label)
	var screen := _logical_screen(canvas)
	if not _rect_inside(canvas.get_global_rect(),screen):
		return _fail("%s reference canvas spills outside logical viewport %s for window %s: %s" % [label,str(screen.size),str(viewport_size),str(canvas.get_global_rect())])
	if not _assert_visible_text_geometry(canvas, viewport_size, label):
		return false
	return true

func _assert_visible_text_geometry(canvas: Control, viewport_size: Vector2i, context: String) -> bool:
	var canvas_rect := canvas.get_global_rect()
	var text_controls: Array[Control] = []
	for raw in canvas.find_children("*", "", true, false):
		if not raw is Control:
			continue
		var control := raw as Control
		if not control.is_visible_in_tree():
			continue
		if control is Label:
			var label := control as Label
			if label.text.strip_edges().is_empty():
				continue
			if not _rect_inside(label.get_global_rect(), canvas_rect):
				return _fail("%s text escapes its reference canvas at %s: %s %s" % [context,str(viewport_size),label.name,str(label.get_global_rect())])
			if label.get_visible_line_count() < label.get_line_count():
				return _fail("%s text is vertically clipped at %s: %s lines=%d visible=%d text=%s" % [context,str(viewport_size),label.name,label.get_line_count(),label.get_visible_line_count(),label.text])
			if label.autowrap_mode == TextServer.AUTOWRAP_OFF and not _single_line_text_fits(label, label.text):
				return _fail("%s label text clips horizontally at %s: %s text=%s rect=%s" % [context,str(viewport_size),label.name,label.text,str(label.size)])
			text_controls.append(label)
		elif control is LineEdit:
			var edit := control as LineEdit
			if not _rect_inside(edit.get_global_rect(), canvas_rect):
				return _fail("%s text field escapes its reference canvas at %s: %s %s" % [context,str(viewport_size),edit.name,str(edit.get_global_rect())])
			if edit.mouse_filter != Control.MOUSE_FILTER_IGNORE and edit.get_global_rect().size.y < 48.0:
				return _fail("%s text field touch target falls below 48px after scaling at %s: %s %s" % [context,str(viewport_size),edit.name,str(edit.get_global_rect().size)])
		elif control is Button:
			var button := control as Button
			if button.text.strip_edges().is_empty():
				continue
			if not _rect_inside(button.get_global_rect(), canvas_rect):
				return _fail("%s button escapes its reference canvas at %s: %s %s" % [context,str(viewport_size),button.name,str(button.get_global_rect())])
			if not _single_line_text_fits(button, button.text):
				return _fail("%s button text clips at %s: %s text=%s rect=%s" % [context,str(viewport_size),button.name,button.text,str(button.size)])
			if bool(button.get_meta("unjam_figma_exact_geometry", false)):
				var physical_size := button.get_global_rect().size
				if physical_size.x < 48.0 or physical_size.y < 48.0:
					return _fail("%s exact touch target falls below 48px after scaling at %s: %s %s" % [context,str(viewport_size),button.name,str(physical_size)])
			text_controls.append(button)

	for i in range(text_controls.size()):
		var a := text_controls[i]
		for j in range(i + 1, text_controls.size()):
			var b := text_controls[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var overlap := a.get_global_rect().intersection(b.get_global_rect())
			if overlap.size.x > 2.0 and overlap.size.y > 2.0:
				return _fail("%s visible text/control overlap at %s: %s %s intersects %s %s by %s" % [context,str(viewport_size),a.name,str(a.get_global_rect()),b.name,str(b.get_global_rect()),str(overlap)])
	return true

func _single_line_text_fits(control: Control, value: String) -> bool:
	var font := control.get_theme_font("font")
	if font == null:
		return true
	var font_size := control.get_theme_font_size("font_size")
	if font_size <= 0:
		return true
	var max_width := 0.0
	for raw_line in value.split("\n"):
		max_width = maxf(max_width, font.get_string_size(String(raw_line), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return max_width <= control.size.x + 2.0

func _logical_screen(node: Node) -> Rect2:
	var viewport := node.get_viewport() if node != null else root
	return viewport.get_visible_rect() if viewport != null else Rect2(Vector2.ZERO,root.size)

func _hide_tutorial(main: Control) -> void:
	var shell := main.get_node_or_null("UXShell")
	if shell != null and shell.has_method("hide_tutorial"):
		shell.call("hide_tutorial")

func _rect_inside(rect: Rect2, viewport: Rect2) -> bool:
	var epsilon := 2.0
	return rect.position.x >= viewport.position.x-epsilon and rect.position.y >= viewport.position.y-epsilon and rect.end.x <= viewport.end.x+epsilon and rect.end.y <= viewport.end.y+epsilon

func _read(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
