extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node("SaveManager")
	var original: Dictionary = save.data.duplicate(true)
	save.data["collection_levels"] = {}
	save.data["decorations"] = []
	save.data["garden_last_gift_date"] = ""
	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null: return _fail("Main scene unavailable")
	var app := packed.instantiate() as Control
	root.add_child(app)
	for _i in range(5): await process_frame
	app.call("build_collection")
	await process_frame
	var locked_tip := app.find_child("CollectionTipValue",true,false) as Label
	var locked_gift := app.find_child("CollectionGardenGift",true,false) as Button
	if locked_tip == null or locked_gift == null or not locked_gift.disabled:
		return _fail("Locked Garden UI is missing")
	if not locked_tip.text.contains("FIRST TREE: +5") or locked_gift.text != "GIFT LOCKED":
		return _fail("Collection fails to teach how the first permanent bonus unlocks")
	if not locked_gift.accessibility_name.contains("Unlock daily gifts"):
		return _fail("Locked Garden gift has no actionable explanation")
	save.data["collection_levels"] = {"tree": 1}
	app.call("build_collection")
	await process_frame
	var active_gift := app.find_child("CollectionGardenGift",true,false) as Button
	var active_tip := app.find_child("CollectionTipValue",true,false) as Label
	if active_gift == null or active_gift.disabled or active_tip == null:
		return _fail("Earned Garden gift remains locked")
	if not active_tip.text.contains("TREE: +5"):
		return _fail("Growing Garden should show the next permanent tree bonus")
	app.queue_free()
	await process_frame
	save.data = original
	save.save()
	print("COLLECTION_BONUS_DISCOVERY_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
