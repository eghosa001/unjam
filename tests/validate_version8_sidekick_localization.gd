extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var project := FileAccess.get_file_as_string("res://project.godot")
	var home := FileAccess.get_file_as_string("res://scripts/ui/premium_home_direct_levels.gd")
	var main := FileAccess.get_file_as_string("res://scripts/ui/premium_main_casual.gd")
	var figma := FileAccess.get_file_as_string("res://scripts/ui/figma_reference_canvas.gd")
	var locale := FileAccess.get_file_as_string("res://scripts/systems/localization_manager.gd")
	var export_cfg := FileAccess.get_file_as_string("res://export_presets.cfg")

	_check('LocalizationManager="*res://scripts/systems/localization_manager.gd"' in project, "localization autoload missing", failures)
	_check("OS.get_locale_language()" in locale, "device-language detection missing", failures)
	_check('"es", "fr", "pt", "de", "it", "ha", "yo", "ig"' in locale, "expected Version 8 languages missing", failures)
	_check("localized_text(text_value)" in figma, "shared UI localization hook missing", failures)
	_check("SIDEKICK • β" in home and "_open_sidekick" in home, "home Sidekick entry missing", failures)
	_check("func show_playmate_sidekick" in main and "NEXT TIP" in main and "PLAY THIS GAME" in main, "Sidekick beta surface missing", failures)

	# Version 8 is additive: retain the Version 7 release-critical settings.
	_check('package/unique_name="com.eghosa.unjamgam"' in export_cfg, "package identity changed", failures)
	_check('package/signed=true' in export_cfg, "signed export disabled", failures)
	_check('gradle_build/target_sdk="36"' in export_cfg, "target SDK changed", failures)
	_check('architectures/arm64-v8a=true' in export_cfg, "arm64 disabled", failures)
	_check('user_data_backup/allow=true' in export_cfg, "Android backup disabled", failures)
	_check("com.google.android.gms.permission.AD_ID" in export_cfg, "AD_ID permission removed", failures)
	_check("test_mode=false" in project, "production billing mode changed", failures)
	_check("admob_test_mode=true" in project, "Version 7 closed-test ad mode changed", failures)
	_check("CloudSaveManager=" in project, "cloud save removed", failures)

	if failures.is_empty():
		print("VERSION8_SIDEKICK_LOCALIZATION_OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
