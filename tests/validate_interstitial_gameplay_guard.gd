extends SceneTree

# Only natural Home/Choose Game breaks can show automatic fullscreen ads.
# This is a focused regression covering menu -> gameplay -> loading -> menu,
# an old in-flight request, source of native asynchronous load race, and
# voluntary rewarded ads remaining separate.
class FakeInterstitialProvider:
	extends Node
	var shows := 0
	var last_closed := Callable()
	var last_failed := Callable()
	func is_ready() -> bool:
		return true
	func show_interstitial(closed: Callable, failed: Callable) -> bool:
		shows += 1
		last_closed = closed
		last_failed = failed
		return true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := root.get_node_or_null("SaveManager")
	var ads := root.get_node_or_null("AdManager")
	if save == null or ads == null:
		return _fail("AdManager and SaveManager required")
	var saved_ads := ads.provider
	var saved_remove := bool(save.data.get("remove_ads",false))
	var saved_mode := ProjectSettings.get_setting("monetization/test_mode",true)
	var old_count := int(ads.completed_since_interstitial)
	var old_interval := int(ads.interstitial_interval)
	var old_in_progress := bool(ads.get("_interstitial_in_progress"))
	var old_ads_enabled := bool(ads.ads_enabled)
	save.data["remove_ads"] = false
	ProjectSettings.set_setting("monetization/test_mode",true)
	ads.ads_enabled = true
	ads.completed_since_interstitial = 7
	ads.interstitial_interval = 4
	var provider := FakeInterstitialProvider.new()
	root.add_child(provider)
	ads.register_provider(provider)

	var packed := load("res://scenes/Main.tscn") as PackedScene
	if packed == null:
		return _fail("Main scene unavailable")
	var main := packed.instantiate() as Control
	root.add_child(main)
	await _frames(6)
	main.call("build_home")
	await _frames(1)
	if not ads.can_present_interstitial_now() or not ads.should_show_interstitial():
		return _fail("Ad guard blocked a genuine Home break")
	main.set("current_surface","game_loading")
	if ads.can_present_interstitial_now() or ads.should_show_interstitial():
		return _fail("Fullscreen ad allowed during scene loading")
	if ads.show_interstitial() or provider.shows != 0:
		return _fail("Native provider called over level loading")
	main.set("current_surface","game")
	if ads.show_interstitial() or provider.shows != 0:
		return _fail("Fullscreen ad entered active gameplay")
	main.set("current_surface","live")
	var outgoing := Control.new()
	main.add_child(outgoing)
	main.set("active_game",outgoing)
	if ads.should_show_interstitial():
		return _fail("Interstitial opened while previous gameplay scene was still attached")
	main.set("active_game",null)
	outgoing.queue_free()
	await _frames(2)
	if not ads.should_show_interstitial():
		return _fail("Safe Choose Game menu did not restore eligible interstitial")
	if not ads.show_interstitial() or provider.shows != 1:
		return _fail("Ad could not show at the intentional settled menu break")
	main.set("current_surface","game")
	if ads.show_interstitial() or provider.shows != 1:
		return _fail("Ad manager allowed a second in-flight fullscreen request during gameplay")
	provider.last_closed.call()
	if bool(ads.get("_interstitial_in_progress")):
		return _fail("Fullscreen callbacks did not release the single-flight state")
	if ads.show_interstitial() or provider.shows != 1:
		return _fail("Closing native ad allowed immediate mid-game replay")

	# The actual AdMob SDK's load callback must only CACHE the creative.
	var native_source := FileAccess.get_file_as_string("res://addons/unjam_admob_provider.gd")
	var loader_start := native_source.find("func _load_interstitial(")
	var loader_end := native_source.find("func _attach_interstitial_fullscreen_callbacks()",loader_start)
	if loader_start < 0 or loader_end <= loader_start:
		return _fail("Native interstitial cache callback missing")
	var loader := native_source.substr(loader_start,loader_end-loader_start)
	if loader.contains("_show_loaded_interstitial()") or loader.contains("if show_when_loaded"):
		return _fail("AdMob loader can still launch a fullscreen ad on a stale asynchronous callback")
	if not native_source.contains("if not _interstitial_menu_allowed():"):
		return _fail("Native AdMob show path lacks a second gameplay guard")

	var game_source := FileAccess.get_file_as_string("res://scripts/game/game.gd")
	var result_callback := game_source.substr(game_source.find("result.continue_requested.connect("))
	if result_callback.contains("AdManager.show_interstitial()"):
		return _fail("Rescue victory still triggers an ad before gameplay returns to menu")
	var main_source := FileAccess.get_file_as_string("res://scripts/ui/robust_main.gd")
	if not main_source.contains("call_deferred(\"_maybe_show_interstitial_at_menu\")"):
		return _fail("Ad requests are not restricted to the completed gameplay exit")

	ads.provider = saved_ads
	ads.ads_enabled = old_ads_enabled
	ads.completed_since_interstitial = old_count
	ads.interstitial_interval = old_interval
	ads.set("_interstitial_in_progress",old_in_progress)
	ads.set_interstitial_surface("")
	ProjectSettings.set_setting("monetization/test_mode",saved_mode)
	save.data["remove_ads"] = saved_remove
	main.queue_free()
	provider.queue_free()
	await _frames(2)
	print("INTERSTITIAL_GAMEPLAY_GUARD_OK")
	quit(0)

func _frames(amount: int) -> void:
	for _i in range(amount):
		await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
