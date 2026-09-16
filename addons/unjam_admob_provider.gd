extends Node

const AdMobConfigScript = preload("res://scripts/systems/admob_config.gd")

const ADMOB_ROOT := "res://addons/admob/gdscript/src"
const MOBILE_ADS_PATH := ADMOB_ROOT + "/api/MobileAds.gd"
const AD_REQUEST_PATH := ADMOB_ROOT + "/api/core/AdRequest.gd"
const REWARDED_LOADER_PATH := ADMOB_ROOT + "/api/RewardedAdLoader.gd"
const REWARDED_CALLBACK_PATH := ADMOB_ROOT + "/api/listeners/RewardedAdLoadCallback.gd"
const INTERSTITIAL_LOADER_PATH := ADMOB_ROOT + "/api/InterstitialAdLoader.gd"
const INTERSTITIAL_CALLBACK_PATH := ADMOB_ROOT + "/api/listeners/InterstitialAdLoadCallback.gd"
const FULLSCREEN_CALLBACK_PATH := ADMOB_ROOT + "/api/listeners/FullScreenContentCallback.gd"
const REWARD_LISTENER_PATH := ADMOB_ROOT + "/api/listeners/OnUserEarnedRewardListener.gd"
const CONSENT_INFO_PATH := ADMOB_ROOT + "/ump/api/ConsentInformation.gd"
const CONSENT_REQUEST_PATH := ADMOB_ROOT + "/ump/core/ConsentRequestParameters.gd"
const UMP_PATH := ADMOB_ROOT + "/ump/api/UserMessagingPlatform.gd"

const CONSENT_NOT_REQUIRED := 1
const CONSENT_REQUIRED := 2
const CONSENT_OBTAINED := 3

var _rewarded_ad: Object
var _interstitial_ad: Object
var _rewarded_completion := Callable()
var _rewarded_failure := Callable()
var _interstitial_closed := Callable()
var _interstitial_failure := Callable()
var _reward_earned := false
var _initialized := false
var _consent_information: Object

func _ready() -> void:
	if OS.get_name() != "Android":
		_initialize_mobile_ads()

func _privacy_manager() -> Node:
	return get_node_or_null("/root/PrivacyManager")

func _may_request_ads() -> bool:
	var privacy := _privacy_manager()
	return privacy != null and bool(privacy.call("may_request_ads"))

func plugin_available() -> bool:
	return (
		ResourceLoader.exists(MOBILE_ADS_PATH)
		and ResourceLoader.exists(AD_REQUEST_PATH)
		and ResourceLoader.exists(REWARDED_LOADER_PATH)
		and ResourceLoader.exists(REWARDED_CALLBACK_PATH)
		and ResourceLoader.exists(INTERSTITIAL_LOADER_PATH)
		and ResourceLoader.exists(INTERSTITIAL_CALLBACK_PATH)
		and ResourceLoader.exists(FULLSCREEN_CALLBACK_PATH)
		and ResourceLoader.exists(REWARD_LISTENER_PATH)
		and ResourceLoader.exists(CONSENT_INFO_PATH)
		and ResourceLoader.exists(CONSENT_REQUEST_PATH)
		and ResourceLoader.exists(UMP_PATH)
	)

func is_ready() -> bool:
	return plugin_available() and AdMobConfigScript.production_ready()

func _script(path: String) -> Script:
	return load(path) as Script if ResourceLoader.exists(path) else null

func _new(path: String) -> Object:
	var script := _script(path)
	return script.new() if script != null else null

func _initialize_mobile_ads() -> void:
	if _initialized or not plugin_available():
		return
	var mobile_ads := _new(MOBILE_ADS_PATH)
	if mobile_ads != null and mobile_ads.has_method("initialize"):
		mobile_ads.call("initialize")
	_initialized = true

func _preload_ads_if_allowed() -> void:
	if not plugin_available():
		return
	if OS.get_name() == "Android" and not _may_request_ads():
		return
	_initialize_mobile_ads()
	if _rewarded_ad == null:
		_load_rewarded(false)
	if _interstitial_ad == null:
		_load_interstitial(false)

func show_rewarded(_placement: String, completed: Callable, failed: Callable) -> bool:
	if not is_ready():
		if failed.is_valid():
			failed.call("AdMob provider is not ready")
		return false
	if not _may_request_ads():
		if failed.is_valid():
			failed.call("Advertising consent is not ready")
		return false
	_rewarded_completion = completed
	_rewarded_failure = failed
	_reward_earned = false
	if _rewarded_ad == null:
		return _load_rewarded(true)
	return _show_loaded_rewarded()

func _load_rewarded(show_when_loaded: bool) -> bool:
	var loader := _new(REWARDED_LOADER_PATH)
	var request := _new(AD_REQUEST_PATH)
	var callback := _new(REWARDED_CALLBACK_PATH)
	if loader == null or request == null or callback == null:
		_fail_rewarded("Rewarded AdMob classes unavailable")
		return false
	callback.set("on_ad_loaded", func(ad: Object) -> void:
		_rewarded_ad = ad
		_attach_rewarded_fullscreen_callbacks()
		if show_when_loaded:
			_show_loaded_rewarded()
	)
	callback.set("on_ad_failed_to_load", func(error: Object) -> void:
		_fail_rewarded(_error_message(error, "Rewarded ad failed to load"))
	)
	loader.call("load", AdMobConfigScript.runtime_rewarded_unit_id(), request, callback)
	return true

func _attach_rewarded_fullscreen_callbacks() -> void:
	if _rewarded_ad == null:
		return
	var fullscreen := _new(FULLSCREEN_CALLBACK_PATH)
	if fullscreen == null:
		return
	fullscreen.set("on_ad_dismissed_full_screen_content", func() -> void:
		var earned := _reward_earned
		var failed := _rewarded_failure
		_cleanup_rewarded()
		if not earned and failed.is_valid():
			failed.call("Rewarded ad closed before the reward was earned")
		_preload_ads_if_allowed()
	)
	fullscreen.set("on_ad_failed_to_show_full_screen_content", func(error: Object) -> void:
		var reason := _error_message(error, "Rewarded ad failed to show")
		var failed := _rewarded_failure
		_cleanup_rewarded()
		if failed.is_valid():
			failed.call(reason)
		_preload_ads_if_allowed()
	)
	_rewarded_ad.set("full_screen_content_callback", fullscreen)

func _show_loaded_rewarded() -> bool:
	if _rewarded_ad == null:
		return false
	var listener := _new(REWARD_LISTENER_PATH)
	if listener == null:
		_fail_rewarded("Reward listener unavailable")
		return false
	listener.set("on_user_earned_reward", func(_reward: Object) -> void:
		if _reward_earned:
			return
		_reward_earned = true
		var completed := _rewarded_completion
		_rewarded_completion = Callable()
		if completed.is_valid():
			completed.call()
	)
	_rewarded_ad.call("show", listener)
	return true

func _cleanup_rewarded() -> void:
	if _rewarded_ad != null and _rewarded_ad.has_method("destroy"):
		_rewarded_ad.call("destroy")
	_rewarded_ad = null
	_rewarded_completion = Callable()
	_rewarded_failure = Callable()
	_reward_earned = false

func _fail_rewarded(reason: String) -> void:
	var failed := _rewarded_failure
	_cleanup_rewarded()
	if failed.is_valid():
		failed.call(reason)

func show_interstitial(closed: Callable, failed: Callable) -> bool:
	if not is_ready():
		if failed.is_valid():
			failed.call("AdMob provider is not ready")
		return false
	if not _may_request_ads():
		if failed.is_valid():
			failed.call("Advertising consent is not ready")
		return false
	_interstitial_closed = closed
	_interstitial_failure = failed
	if _interstitial_ad == null:
		return _load_interstitial(true)
	return _show_loaded_interstitial()

func _load_interstitial(show_when_loaded: bool) -> bool:
	var loader := _new(INTERSTITIAL_LOADER_PATH)
	var request := _new(AD_REQUEST_PATH)
	var callback := _new(INTERSTITIAL_CALLBACK_PATH)
	if loader == null or request == null or callback == null:
		_fail_interstitial("Interstitial AdMob classes unavailable")
		return false
	callback.set("on_ad_loaded", func(ad: Object) -> void:
		_interstitial_ad = ad
		_attach_interstitial_fullscreen_callbacks()
		if show_when_loaded:
			_show_loaded_interstitial()
	)
	callback.set("on_ad_failed_to_load", func(error: Object) -> void:
		_fail_interstitial(_error_message(error, "Interstitial failed to load"))
	)
	loader.call("load", AdMobConfigScript.runtime_interstitial_unit_id(), request, callback)
	return true

func _attach_interstitial_fullscreen_callbacks() -> void:
	if _interstitial_ad == null:
		return
	var fullscreen := _new(FULLSCREEN_CALLBACK_PATH)
	if fullscreen == null:
		return
	fullscreen.set("on_ad_dismissed_full_screen_content", func() -> void:
		var closed := _interstitial_closed
		_cleanup_interstitial()
		if closed.is_valid():
			closed.call()
		_preload_ads_if_allowed()
	)
	fullscreen.set("on_ad_failed_to_show_full_screen_content", func(error: Object) -> void:
		var reason := _error_message(error, "Interstitial failed to show")
		var failed := _interstitial_failure
		_cleanup_interstitial()
		if failed.is_valid():
			failed.call(reason)
		_preload_ads_if_allowed()
	)
	_interstitial_ad.set("full_screen_content_callback", fullscreen)

func _show_loaded_interstitial() -> bool:
	if _interstitial_ad == null:
		return false
	_interstitial_ad.call("show")
	return true

func _cleanup_interstitial() -> void:
	if _interstitial_ad != null and _interstitial_ad.has_method("destroy"):
		_interstitial_ad.call("destroy")
	_interstitial_ad = null
	_interstitial_closed = Callable()
	_interstitial_failure = Callable()

func _fail_interstitial(reason: String) -> void:
	var failed := _interstitial_failure
	_cleanup_interstitial()
	if failed.is_valid():
		failed.call(reason)

func request_consent(callback: Callable) -> void:
	if OS.get_name() != "Android":
		if callback.is_valid():
			callback.call("not_required")
		return
	if not plugin_available():
		if callback.is_valid():
			callback.call("required")
		return

	_consent_information = _new(CONSENT_INFO_PATH)
	var params := _new(CONSENT_REQUEST_PATH)
	if _consent_information == null or params == null:
		if callback.is_valid():
			callback.call("required")
		return

	_consent_information.call(
		"update",
		params,
		func() -> void: _handle_consent_update(callback),
		func(_form_error: Object) -> void: _handle_consent_update_failure(callback)
	)

func _handle_consent_update(callback: Callable) -> void:
	var status := _consent_status()
	if status == CONSENT_NOT_REQUIRED:
		if callback.is_valid():
			callback.call("not_required")
		_preload_ads_if_allowed()
		return
	if status == CONSENT_OBTAINED:
		if callback.is_valid():
			callback.call("obtained")
		_preload_ads_if_allowed()
		return
	if status != CONSENT_REQUIRED:
		if callback.is_valid():
			callback.call("required")
		return

	var ump := _script(UMP_PATH)
	if ump == null:
		if callback.is_valid():
			callback.call("required")
		return
	ump.call(
		"load_consent_form",
		func(form: Object) -> void:
			if form == null or not form.has_method("show"):
				if callback.is_valid():
					callback.call("required")
				return
			form.call("show", func(_form_error: Object) -> void:
				_finish_consent(callback)
			),
		func(_form_error: Object) -> void:
			if callback.is_valid():
				callback.call("required")
	)

func _handle_consent_update_failure(callback: Callable) -> void:
	var status := _consent_status()
	if status == CONSENT_NOT_REQUIRED:
		if callback.is_valid():
			callback.call("not_required")
	elif status == CONSENT_OBTAINED:
		if callback.is_valid():
			callback.call("obtained")
	elif callback.is_valid():
		callback.call("required")

func _finish_consent(callback: Callable) -> void:
	var status := _consent_status()
	if status == CONSENT_NOT_REQUIRED:
		if callback.is_valid():
			callback.call("not_required")
		_preload_ads_if_allowed()
	elif status == CONSENT_OBTAINED:
		if callback.is_valid():
			callback.call("obtained")
		_preload_ads_if_allowed()
	elif callback.is_valid():
		callback.call("required")

func _consent_status() -> int:
	if _consent_information == null or not _consent_information.has_method("get_consent_status"):
		return 0
	return int(_consent_information.call("get_consent_status"))

func show_privacy_options(callback: Callable) -> void:
	if OS.get_name() != "Android" or not plugin_available():
		if callback.is_valid():
			callback.call("not_required" if OS.get_name() != "Android" else "required")
		return
	var ump := _script(UMP_PATH)
	if ump == null:
		if callback.is_valid():
			callback.call("required")
		return
	ump.call("show_privacy_options_form", func(_form_error: Object) -> void:
		_finish_consent(callback)
	)

func _error_message(error: Object, fallback: String) -> String:
	if error == null:
		return fallback
	var value = error.get("message")
	if value != null and not String(value).is_empty():
		return String(value)
	return fallback
