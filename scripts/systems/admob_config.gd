extends RefCounted
class_name AdMobConfig

const PRODUCTION_APP_ID := "ca-app-pub-7517898921176341~1892369383"
const PRODUCTION_REWARDED_UNIT_ID := "ca-app-pub-7517898921176341/2926249456"
const PRODUCTION_INTERSTITIAL_UNIT_ID := "ca-app-pub-7517898921176341/9108514429"

const TEST_REWARDED_UNIT_ID_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_UNIT_ID_ANDROID := "ca-app-pub-3940256099942544/1033173712"

static func app_id() -> String:
	return String(ProjectSettings.get_setting("monetization/admob_android_app_id", PRODUCTION_APP_ID))

static func rewarded_unit_id(use_test: bool) -> String:
	return TEST_REWARDED_UNIT_ID_ANDROID if use_test else String(ProjectSettings.get_setting("monetization/admob_rewarded_unit_id", PRODUCTION_REWARDED_UNIT_ID))

static func interstitial_unit_id(use_test: bool) -> String:
	return TEST_INTERSTITIAL_UNIT_ID_ANDROID if use_test else String(ProjectSettings.get_setting("monetization/admob_interstitial_unit_id", PRODUCTION_INTERSTITIAL_UNIT_ID))

static func runtime_uses_test_ads() -> bool:
	return bool(ProjectSettings.get_setting("monetization/test_mode", false)) or OS.is_debug_build()

static func runtime_rewarded_unit_id() -> String:
	return rewarded_unit_id(runtime_uses_test_ads())

static func runtime_interstitial_unit_id() -> String:
	return interstitial_unit_id(runtime_uses_test_ads())

static func production_ready() -> bool:
	return (
		app_id() == PRODUCTION_APP_ID
		and String(ProjectSettings.get_setting("monetization/admob_rewarded_unit_id", "")) == PRODUCTION_REWARDED_UNIT_ID
		and String(ProjectSettings.get_setting("monetization/admob_interstitial_unit_id", "")) == PRODUCTION_INTERSTITIAL_UNIT_ID
	)
