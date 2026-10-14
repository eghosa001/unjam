extends SceneTree

# Change-scoped integration check: Collection -> interactive garden -> real
# persisted tiers -> existing upgrade screen; no fake progress or spending.
const IDS := ["tree","bench","fountain","lanterns","cottage","rainbow_bridge"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var save := root.get_node_or_null("SaveManager")
	if save == null:
		return _fail("SaveManager not installed")
	var saved: Dictionary = save.data.duplicate(true)
	save.data["collection_levels"] = {}
	save.data["decorations"] = []
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main unavailable")
	var app := packed.instantiate() as Control
	root.add_child(app)
	await _frames(6)
	app.call("build_collection")
	await _frames(2)
	var link := app.find_child("CollectionVisitGarden",true,false) as Button
	if link == null or link.disabled or link.size.y < 44.0:
		return _fail("Collection does not provide a safe Explore Garden entry")
	if not link.accessibility_name.contains("six"):
		return _fail("Garden entrance lacks the accessible reason to visit")
	link.emit_signal("pressed")
	await _frames(3)
	var sheet := app.get_node_or_null("RescueGardenWorldSheet")
	if sheet == null:
		return _fail("Visit Garden did not open the world")
	if not _check_world(sheet,"CLEARING",0):
		return _fail("Empty Garden must show six unbuilt structures and zero permanent levels")
	var bench := sheet.find_child("GardenLandmark_bench",true,false) as Button
	if bench == null or not bench.accessibility_name.contains("not yet built"):
		return _fail("Garden disguises locked property as owned")
	bench.emit_signal("pressed")
	await _frames(1)
	var selection := sheet.find_child("RescueGardenDetailHeading",true,false) as Label
	if selection == null or selection.text != "GARDEN BENCH":
		return _fail("Landmark taps do not open the correct property description")

	sheet.queue_free()
	await _frames(2)
	save.data["collection_levels"] = {
		"tree":5,"bench":5,"fountain":5,
		"lanterns":5,"cottage":5,"rainbow_bridge":5
	}
	app.call("build_collection")
	await _frames(2)
	link = app.find_child("CollectionVisitGarden",true,false) as Button
	link.emit_signal("pressed")
	await _frames(3)
	sheet = app.get_node_or_null("RescueGardenWorldSheet")
	if sheet == null or not _check_world(sheet,"COMPLETE",30):
		return _fail("Fully upgraded world does not visibly recognize all thirty owned tiers")
	var tree := sheet.find_child("GardenLandmark_tree",true,false) as Button
	if tree == null or not tree.accessibility_name.contains("level 5 of 5"):
		return _fail("World is not reading real persistent tree upgrade tiers")
	tree.emit_signal("pressed")
	await _frames(1)
	var next := sheet.find_child("RescueGardenDetailNext",true,false) as Label
	if next == null or not next.text.contains("permanent bonus"):
		return _fail("At max tier, Garden should not suggest another purchase")
	var world := sheet.find_child("RescueGardenWorld",true,false) as Control
	if world == null or not world.accessibility_name.contains("30 of 30"):
		return _fail("Landscape does not expose actual total Collection progression")
	var scroll := sheet.find_child("RescueGardenScroll",true,false) as Control
	if scroll == null:
		return _fail("Scrollable garden viewport not present")
	var vr := scroll.get_global_rect()
	var viewport_size := app.get_viewport().get_visible_rect().size
	if vr.position.x < -1 or vr.position.y < -1 or vr.end.x > viewport_size.x+1 or vr.end.y > viewport_size.y+1:
		return _fail("Garden is clipped on compact-phone authored viewport")
	var upgrade_btn := _button_named(sheet,"UPGRADE MY GARDEN")
	if upgrade_btn == null:
		return _fail("Garden lacks path to the existing upgrade economy")
	upgrade_btn.emit_signal("pressed")
	await _frames(3)
	if is_instance_valid(sheet) or app.find_child("CollectionUpgradeTitle*",true,false) == null:
		return _fail("Garden failed to return players to the genuine upgrades screen")
	app.queue_free()
	await _frames(1)
	save.data = saved
	save.save()
	print("INTERACTIVE_GARDEN_WORLD_OK")
	quit(0)

func _check_world(sheet: Node, stage: String, expected: int) -> bool:
	var label := sheet.find_child("RescueGardenStage",true,false) as Label
	if label == null or not label.text.contains(stage) or not label.text.contains("%d / 30" % expected):
		return false
	var world := sheet.find_child("RescueGardenWorld",true,false) as Control
	if world == null:
		return false
	for id in IDS:
		var btn := sheet.find_child("GardenLandmark_%s" % id,true,false) as Button
		var art := sheet.find_child("GardenLandmarkArt_%s" % id,true,false) as Control
		if btn == null or art == null or btn.size.x < 100 or btn.size.y < 120:
			return false
		if btn.position.x < 0 or btn.position.y < 0 or btn.position.x+btn.size.x > world.size.x or btn.position.y+btn.size.y > world.size.y:
			return false
	return true

func _button_named(node: Node, begins: String) -> Button:
	if node is Button and String((node as Button).text).begins_with(begins):
		return node as Button
	for child in node.get_children():
		var found := _button_named(child,begins)
		if found != null:
			return found
	return null

func _frames(number: int) -> void:
	for _i in range(number):
		await process_frame

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
