extends SceneTree

# Eye comfort is a visual-intensity control, not a claim that software can
# remove physical reflections or control an Android device's brightness.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(540,960)
	var save := root.get_node_or_null("SaveManager")
	var premium := root.get_node_or_null("PremiumVisuals")
	if not _assert(save != null and premium != null, "Game settings/FX autoloads missing"): return
	var defaults := FileAccess.get_file_as_string("res://scripts/core/save_manager.gd")
	if not _assert(defaults.contains('"gentle_effects": true') and defaults.contains('"gentle_effects",'), "Gentle Effects must start enabled and survive a gameplay reset"): return
	var had_setting := save.data.has("gentle_effects")
	var old_setting := bool(save.data.get("gentle_effects",true))
	save.data["gentle_effects"] = true
	premium.call("refresh_effect_intensity")
	var overlay := premium.get("overlay") as Control
	if not _assert(overlay != null, "Premium FX overlay missing"): return
	var before_flash := overlay.get_child_count()
	premium.call("screen_flash", Color.WHITE, 1.0)
	if not _assert(overlay.get_child_count() == before_flash, "Gentle Effects still creates a bright center-screen flash"): return
	premium.call("burst", Vector2(250,400), Color.WHITE, 34)
	var spark_count := overlay.get_child_count() - before_flash
	if not _assert(spark_count >= 1 and spark_count <= 8, "Gentle Effects celebration has too many particles: %d" % spark_count): return

	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if not _assert(main_scene != null, "UNJAM Main scene missing"): return
	var main := main_scene.instantiate() as Control
	root.add_child(main)
	await _frames(8)
	main.call("build_settings")
	await _frames(3)
	var gentle := main.find_child("SettingToggle*Gentle_effects",true,false) as Button
	var fast := main.find_child("SettingToggle*Fast_animation",true,false) as Button
	var motion := main.find_child("SettingToggle*Reduce_motion",true,false) as Button
	var purchases := main.find_child("SettingsPurchases",true,false) as Button
	if not _assert(gentle != null and fast != null and motion != null and purchases != null, "All three Comfort controls and purchases must remain present"):return
	if not _assert(gentle.text == "ON" and gentle.size.y >= 44.0, "Default Gentle Effects toggle is not visible and comfortably tappable"):return
	if not _assert(gentle.position.y + gentle.size.y <= 450.0, "Comfort setting overlaps the Appearance card"):return
	if not _assert(purchases.position.y + purchases.size.y < 753.0, "Purchases overlap the persistent bottom navigation"):return
	if not _assert(gentle.accessibility_name.to_lower().contains("gentle effects"), "Gentle Effects lacks screen-reader name"):return
	gentle.pressed.emit()
	await _frames(3)
	if not _assert(not bool(save.data.get("gentle_effects",true)), "Gentle toggle does not actually persist an OFF preference"):return
	var gentle_off := main.find_child("SettingToggle*Gentle_effects",true,false) as Button
	if not _assert(gentle_off != null and gentle_off.text == "OFF", "Gentle setting does not visibly update on toggle"):return
	var count_before := overlay.get_child_count()
	premium.call("screen_flash",Color("ffbb22"),0.18)
	if not _assert(overlay.get_child_count() == count_before + 1, "Turning Gentle Effects off does not restore controlled celebration animation"):return
	# Restore existing state, including an older save without this key.
	if had_setting:
		save.data["gentle_effects"] = old_setting
	else:
		save.data.erase("gentle_effects")
	save.call("save")
	premium.call("refresh_effect_intensity")
	main.queue_free()
	await _frames(3)
	print("EYE_COMFORT_GENTLE_EFFECTS_OK")
	quit(0)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _assert(ok: bool, message: String) -> bool:
	if ok:
		return true
	push_error(message)
	quit(1)
	return false
