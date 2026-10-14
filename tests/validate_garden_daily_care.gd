extends SceneTree

# Scoped gameplay/economy regression: real Garden upkeep, 3 interactions,
# once-per-day idempotency, locked-item gating and crash-safe single-save
# wallet/debt marker. No broad puzzle or backend test suite.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var save := root.get_node_or_null("SaveManager")
	var economy := root.get_node_or_null("EconomyManager")
	if save == null or economy == null:
		return _fail("Garden owner services unavailable")
	var original: Dictionary = save.data.duplicate(true)
	save.data["collection_levels"] = {}
	save.data["decorations"] = []
	save.data["coins"] = 50
	save.data["purchase_coin_debt"] = 5
	save.data["garden_care_state"] = {"day":"2026-01-01","completed":[]}
	if bool(economy.care_for_garden_once("tree").get("credited",false)):
		return _fail("Unowned property must not earn Garden-care coins")
	if int(save.data.get("coins",0)) != 50 or int(save.data.get("purchase_coin_debt",0)) != 5:
		return _fail("Locked Garden care changed economy")
	save.data["collection_levels"] = {"tree":1,"bench":1}
	var first: Dictionary = economy.care_for_garden_once("tree")
	if not bool(first.get("credited",false)) or int(first.get("coins",-1)) != 3 or int(first.get("debt_settled",-1)) != 5:
		return _fail("Garden care must settle refund debt and award only net coins")
	if int(save.data.get("coins",0)) != 53 or int(save.data.get("purchase_coin_debt",-1)) != 0:
		return _fail("Refund debt settlement and Garden care wallet were not atomically saved")
	if bool(economy.care_for_garden_once("tree").get("credited",false)) or int(save.data.get("coins",0)) != 53:
		return _fail("Repeated Garden care must not duplicate coins")
	if not economy.garden_care_completed_today("tree") or int(economy.garden_care_remaining()) != 1:
		return _fail("Garden care progress does not reflect exactly the unfinished owned properties")
	var scene := load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		return _fail("Main scene unavailable")
	var app := scene.instantiate() as Control
	root.add_child(app)
	await _frames(5)
	app.call("build_collection")
	await _frames(2)
	var open := app.find_child("CollectionVisitGarden",true,false) as Button
	if open == null:
		return _fail("Cannot enter new Rescue Garden care experience")
	open.emit_signal("pressed")
	await _frames(3)
	var panel := app.get_node_or_null("RescueGardenWorldSheet")
	if panel == null:
		return _fail("Care world was not built")
	var care := panel.find_child("RescueGardenCareAction",true,false) as Button
	var note := panel.find_child("RescueGardenCareStatus",true,false) as Label
	if care == null or note == null or not care.disabled or care.text != "CARED FOR TODAY ✓":
		return _fail("Finished Garden maintenance must clearly show disabled daily status")
	var bench := panel.find_child("GardenLandmark_bench",true,false) as Button
	if bench == null:
		return _fail("Missing second landmark interaction")
	bench.emit_signal("pressed")
	await _frames(1)
	care = panel.find_child("RescueGardenCareAction",true,false) as Button
	if care == null or care.disabled or not care.text.contains("0/3"):
		return _fail("Fresh owned landmark must offer visible three-step care")
	for step in range(3):
		care.emit_signal("pressed")
		await _frames(1)
	if not care.disabled or not economy.garden_care_completed_today("bench"):
		return _fail("Completing care steps did not persist the once-per-day result")
	if int(save.data.get("coins",0)) != 61:
		return _fail("Three-step Garden care awarded incorrect amount or paid twice")
	if int(economy.garden_care_remaining()) != 0 or not care.text.contains("CARED FOR TODAY"):
		return _fail("All owned Garden structures were not marked cared for")
	var snapshot: Dictionary = save.data.get("garden_care_state",{})
	var done: Array = snapshot.get("completed",[])
	if done.size() != 2 or not ("tree" in done) or not ("bench" in done):
		return _fail("Garden care completion ledger must contain each location at most once")
	panel.queue_free()
	app.queue_free()
	await _frames(2)
	save.data = original
	save.save()
	print("GARDEN_DAILY_CARE_OK")
	quit(0)

func _frames(amount: int) -> void:
	for _i in range(amount):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
