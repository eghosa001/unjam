extends SceneTree

var failures: Array[String] = []

const EXPECTED_APP_ID := "ca-app-pub-7517898921176341~1892369383"
const EXPECTED_REWARDED := "ca-app-pub-7517898921176341/2926249456"
const EXPECTED_INTERSTITIAL := "ca-app-pub-7517898921176341/9108514429"
const TEST_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"

func _init() -> void:
	call_deferred("run")

func expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	await process_frame
	expect_true(String(ProjectSettings.get_setting("monetization/admob_android_app_id", "")) == EXPECTED_APP_ID, "production AdMob app ID missing")
	expect_true(String(ProjectSettings.get_setting("monetization/admob_rewarded_unit_id", "")) == EXPECTED_REWARDED, "production rewarded ad unit ID missing")
	expect_true(String(ProjectSettings.get_setting("monetization/admob_interstitial_unit_id", "")) == EXPECTED_INTERSTITIAL, "production interstitial ad unit ID missing")

	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	expect_true('permissions/internet=true' in export_source, "Android INTERNET permission missing from export preset")
	expect_true('permissions/access_network_state=true' in export_source, "Android ACCESS_NETWORK_STATE permission missing from export preset")
	expect_true('com.google.android.gms.permission.AD_ID' in export_source, "Android AD_ID permission missing from export preset")

	var config_script := load("res://scripts/systems/admob_config.gd")
	expect_true(config_script != null, "AdMob config helper missing")
	if config_script != null:
		expect_true(String(config_script.call("rewarded_unit_id", true)) == TEST_REWARDED, "debug rewarded ID must use Google's test unit")
		expect_true(String(config_script.call("interstitial_unit_id", true)) == TEST_INTERSTITIAL, "debug interstitial ID must use Google's test unit")
		expect_true(String(config_script.call("rewarded_unit_id", false)) == EXPECTED_REWARDED, "release rewarded ID must use production unit")
		expect_true(String(config_script.call("interstitial_unit_id", false)) == EXPECTED_INTERSTITIAL, "release interstitial ID must use production unit")

	expect_true(FileAccess.file_exists("res://tools/install_monetization_plugins.sh"), "monetization installer missing")
	if FileAccess.file_exists("res://tools/install_monetization_plugins.sh"):
		var installer := FileAccess.get_file_as_string("res://tools/install_monetization_plugins.sh")
		# Validate the pinned configuration and URL templates rather than requiring
		# shell-expanded literal URLs to appear in source. The installer composes
		# release filenames from these version variables at runtime.
		expect_true('ADMOB_VERSION="5.1.0"' in installer, "AdMob 5.1.0 version pin missing")
		expect_true('GODOT_ADMOB_TEMPLATE_VERSION="4.7.2"' in installer, "Godot 4.7.2 AdMob Android template version pin missing")
		expect_true("poingstudios/godot-admob-plugin/releases/download/v${ADMOB_VERSION}" in installer, "AdMob release source missing")
		expect_true("poing-godot-admob-v${ADMOB_VERSION}.zip" in installer, "AdMob package filename template missing")
		expect_true("android-template-v${GODOT_ADMOB_TEMPLATE_VERSION}.zip" in installer, "AdMob Android template filename template missing")
		expect_true("addons/admob/android/bin" in installer, "AdMob native Android dependency destination missing")
		expect_true("cat > addons/unjam_admob_provider.gd" not in installer, "installer must not overwrite the maintained provider adapter")

	expect_true(FileAccess.file_exists("res://app-ads.txt"), "root app-ads.txt missing")
	if FileAccess.file_exists("res://app-ads.txt"):
		var root_app_ads := FileAccess.get_file_as_string("res://app-ads.txt")
		expect_true("google.com, pub-7517898921176341, DIRECT, f08c47fec0942fa0" in root_app_ads, "root app-ads.txt publisher entry incorrect")
	expect_true(FileAccess.file_exists("res://docs/app-ads.txt"), "docs app-ads.txt mirror missing")
	if FileAccess.file_exists("res://docs/app-ads.txt"):
		var app_ads := FileAccess.get_file_as_string("res://docs/app-ads.txt")
		expect_true("google.com, pub-7517898921176341, DIRECT, f08c47fec0942fa0" in app_ads, "docs app-ads.txt publisher entry incorrect")

	expect_true(ResourceLoader.exists("res://addons/unjam_admob_provider.gd"), "UNJAM AdMob provider adapter missing")
	var provider_script := load("res://addons/unjam_admob_provider.gd")
	expect_true(provider_script != null, "UNJAM AdMob provider adapter does not parse")
	if provider_script != null:
		var provider_source := FileAccess.get_file_as_string("res://addons/unjam_admob_provider.gd")
		expect_true("res://addons/admob/gdscript/src" in provider_source, "provider does not target Poing v5 GDScript API")
		expect_true("ConsentRequestParameters.gd" in provider_source and "UserMessagingPlatform.gd" in provider_source, "UMP consent integration missing")
		expect_true("OnUserEarnedRewardListener.gd" in provider_source, "reward callback listener missing")
		expect_true('func _ready() -> void:\n\tif OS.get_name() != "Android"' in provider_source, "Android AdMob initialization must wait for consent flow")
		expect_true('if OS.get_name() == "Android" and not _may_request_ads()' in provider_source, "provider must gate Android ad requests on consent")

	var ad_manager := root.get_node_or_null("AdManager")
	expect_true(ad_manager != null, "AdManager autoload missing")
	if ad_manager != null:
		expect_true(int(ad_manager.INTERSTITIAL_COOLDOWN_SECONDS) >= 180, "interstitial cooldown is too aggressive")
		expect_true(int(ad_manager.interstitial_interval) >= 4, "interstitial level interval is too aggressive")
		expect_true(int(ad_manager.MAX_INTERSTITIALS_PER_SESSION) <= 6, "interstitial session cap is too aggressive")

	if failures.is_empty():
		print("ADMOB PRODUCTION CONFIG VALIDATION PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
