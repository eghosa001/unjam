extends SceneTree

# Focused native-ad callback regression: a late/doubled SDK event may never
# grant a second reward, consume a newer request or double-count an interstitial.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	var script := load("res://scripts/systems/ad_manager.gd")
	if save == null or script == null:
		_fail("SaveManager or ad script missing")
		return
	var ads: Node = script.new()
	root.add_child(ads)
	await process_frame
	var original_watched := int(save.data.get("rewarded_ads_watched", 0))
	var stats := {"grants":0, "failures":0, "closed":0}
	ads.rewarded_in_progress = true
	ads.set("_rewarded_request_serial", 41)
	ads.set("_pending_reward_placement", "qa_reward")
	ads.set("_pending_reward_callback", func() -> void:
		stats["grants"] = int(stats["grants"]) + 1
	)
	ads.set("_pending_reward_failed_callback", func(_reason: String) -> void:
		stats["failures"] = int(stats["failures"]) + 1
	)
	ads.call("_provider_rewarded_completed", 41)
	ads.call("_provider_rewarded_completed", 41)
	ads.call("_provider_rewarded_failed", "late failure", 41)
	if int(stats["grants"]) != 1 or int(stats["failures"]) != 0:
		_cleanup(ads, save, original_watched)
		_fail("Repeated rewarded SDK callbacks regranted or emitted a failure")
		return
	if int(save.data.get("rewarded_ads_watched", 0)) != original_watched + 1:
		_cleanup(ads, save, original_watched)
		_fail("Rewarded-watch counter did not increase exactly once")
		return

	ads.rewarded_in_progress = true
	ads.set("_rewarded_request_serial", 60)
	ads.set("_pending_reward_placement", "new_request")
	ads.call("_provider_rewarded_completed", 59)
	if not ads.rewarded_in_progress or ads.get("_pending_reward_placement") != "new_request":
		_cleanup(ads, save, original_watched)
		_fail("Stale rewarded callback consumed the next request")
		return
	ads.call("_provider_rewarded_failed", "expected cancellation", 60)

	ads.interstitial_closed.connect(func() -> void:
		stats["closed"] = int(stats["closed"]) + 1
	)
	ads.set("_interstitial_in_progress", true)
	ads.set("_interstitial_request_serial", 70)
	ads.call("_provider_interstitial_closed", 70)
	ads.call("_provider_interstitial_closed", 70)
	ads.call("_provider_interstitial_failed", "late", 70)
	if int(stats["closed"]) != 1 or int(ads.interstitials_this_session) != 1:
		_cleanup(ads, save, original_watched)
		_fail("Duplicate interstitial callbacks counted more than once")
		return
	ads.set("_interstitial_in_progress", true)
	ads.set("_interstitial_request_serial", 80)
	ads.call("_provider_interstitial_closed", 79)
	if not bool(ads.get("_interstitial_in_progress")):
		_cleanup(ads, save, original_watched)
		_fail("Stale interstitial callback consumed the next request")
		return
	ads.call("_provider_interstitial_failed", "expected cancellation", 80)
	_cleanup(ads, save, original_watched)
	print("AD_CALLBACK_EXACTLY_ONCE_OK")
	quit(0)

func _cleanup(ads: Node, save: Node, original_watched: int) -> void:
	save.data.rewarded_ads_watched = original_watched
	save.save()
	ads.queue_free()

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
