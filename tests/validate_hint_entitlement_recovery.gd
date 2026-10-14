extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _delivered() -> bool:
	return true

func _stale() -> bool:
	return false

func _run() -> void:
	var hints := root.get_node("HintManager")
	var save := root.get_node("SaveManager")
	var previous: Variant = save.data.get("hint_prepaid_credits",null)
	var balance := int(save.data.get("coins",0))
	save.data["hint_prepaid_credits"] = {}
	# Failed/deferred payouts must survive game destruction without being lost.
	hints.call("_grant","water_sort","rewarded_ad",Callable(self,"_stale"))
	var credits: Dictionary = save.data.get("hint_prepaid_credits",{})
	if int(credits.get("water_sort",0)) != 1:
		return _fail("Failed rewarded callback did not preserve hint")
	# A previously paid hint must take precedence over another 25-coin charge.
	if not bool(hints.call("request_hint","water_sort",Callable(self,"_delivered"))):
		return _fail("Prepaid hint was rejected")
	credits = save.data.get("hint_prepaid_credits",{})
	if int(credits.get("water_sort",0)) != 0 or int(save.data.get("coins",0)) != balance:
		return _fail("Prepaid hint double-charged or was not consumed")
	# A stale use of an existing voucher should restore exactly one voucher.
	hints.call("_grant","water_sort","rewarded_ad",Callable(self,"_stale"))
	hints.call("request_hint","water_sort",Callable(self,"_stale"))
	credits = save.data.get("hint_prepaid_credits",{})
	if int(credits.get("water_sort",0)) != 1:
		return _fail("Stale prepaid redemption lost or duplicated the voucher")
	# Players should not see a misleading 25-coin price when an ad earned
	# a valid prepaid hint which remains in their account.
	var packed := load("res://scenes/WaterSort.tscn") as PackedScene
	if packed == null:
		return _fail("Water game unavailable")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var hint_button := game.find_child("WaterHintAction",true,false) as Button
	if hint_button == null:
		return _fail("Water Hint action unavailable")
	hints.call("_refresh_hint_button",game,hint_button)
	if not hint_button.tooltip_text.contains("costs no coins") or not hint_button.accessibility_name.contains("costs no coins"):
		return _fail("Saved reward is not disclosed to the player or screen reader")
	game.queue_free()
	await process_frame
	if previous == null:
		save.data.erase("hint_prepaid_credits")
	else:
		save.data["hint_prepaid_credits"] = previous
	save.save()
	print("HINT_ENTITLEMENT_RECOVERY_OK: invalid paid/ad callbacks preserve voucher; reuse has no duplicate charge")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
