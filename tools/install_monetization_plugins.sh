#!/usr/bin/env bash
set -euo pipefail
mkdir -p .plugin-cache addons
curl -fL https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/download/3.3.0/godot-google-play-billing.zip -o .plugin-cache/billing.zip
unzip -oq .plugin-cache/billing.zip -d .plugin-cache/billing
if [ -d .plugin-cache/billing/addons/GodotGooglePlayBilling ]; then
  cp -R .plugin-cache/billing/addons/GodotGooglePlayBilling addons/
else
  BILLING_DIR=$(find .plugin-cache/billing -type d -path '*/addons/GodotGooglePlayBilling' | head -1)
  test -n "$BILLING_DIR"
  cp -R "$BILLING_DIR" addons/
fi
curl -fL https://github.com/poingstudios/godot-admob-plugin/releases/download/v5.1.0/poing-godot-admob-v5.1.0.zip -o .plugin-cache/admob.zip
unzip -oq .plugin-cache/admob.zip -d .plugin-cache/admob
ADMOB_ADDONS=$(find .plugin-cache/admob -type d -name addons | head -1)
test -n "$ADMOB_ADDONS"
cp -R "$ADMOB_ADDONS"/* addons/
cat > addons/unjam_admob_provider.gd <<'GDSCRIPT'
extends Node

var initialized := false
var rewarded_ad
var interstitial_ad

func _ready() -> void:
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status): initialized = true
	MobileAds.initialize(listener)

func request_consent(callback: Callable) -> void:
	var params := ConsentRequestParameters.new()
	ConsentInformation.request_consent_info_update(params, OnConsentInfoUpdateListener.new(
		func():
			if ConsentInformation.is_consent_form_available():
				ConsentForm.load_and_show_consent_form_if_required(OnConsentFormDismissedListener.new(func(_error): callback.call(_consent_status())))
			else:
				callback.call(_consent_status()),
		func(_error): callback.call("required")
	))

func show_privacy_options(callback: Callable) -> void:
	UserMessagingPlatform.show_privacy_options_form(func(_error): callback.call(_consent_status()))

func _consent_status() -> String:
	var status := int(ConsentInformation.get_consent_status())
	if status == 1:
		return "not_required"
	if status == 3:
		return "obtained"
	return "required"

func show_rewarded(_placement: String, completed: Callable, failed: Callable) -> bool:
	if not initialized:
		failed.call("AdMob is still initializing")
		return false
	var unit_id := String(ProjectSettings.get_setting("monetization/admob_rewarded_unit_id", ""))
	if unit_id.is_empty():
		failed.call("Rewarded ad unit is not configured")
		return false
	if rewarded_ad != null:
		rewarded_ad.destroy()
		rewarded_ad = null
	var load_callback := RewardedAdLoadCallback.new()
	load_callback.on_ad_failed_to_load = func(error): failed.call(String(error.message))
	load_callback.on_ad_loaded = func(ad):
		rewarded_ad = ad
		var full := FullScreenContentCallback.new()
		full.on_ad_failed_to_show_full_screen_content = func(error): failed.call(String(error.message))
		full.on_ad_dismissed_full_screen_content = func():
			if rewarded_ad != null:
				rewarded_ad.destroy()
				rewarded_ad = null
		rewarded_ad.full_screen_content_callback = full
		rewarded_ad.show(OnUserEarnedRewardListener.new(func(_reward): completed.call()))
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), load_callback)
	return true

func show_interstitial(closed: Callable, failed: Callable) -> bool:
	if not initialized:
		failed.call("AdMob is still initializing")
		return false
	var unit_id := String(ProjectSettings.get_setting("monetization/admob_interstitial_unit_id", ""))
	if unit_id.is_empty():
		failed.call("Interstitial ad unit is not configured")
		return false
	if interstitial_ad != null:
		interstitial_ad.destroy()
		interstitial_ad = null
	var load_callback := InterstitialAdLoadCallback.new()
	load_callback.on_ad_failed_to_load = func(error): failed.call(String(error.message))
	load_callback.on_ad_loaded = func(ad):
		interstitial_ad = ad
		var full := FullScreenContentCallback.new()
		full.on_ad_failed_to_show_full_screen_content = func(error): failed.call(String(error.message))
		full.on_ad_dismissed_full_screen_content = func():
			closed.call()
			if interstitial_ad != null:
				interstitial_ad.destroy()
				interstitial_ad = null
		interstitial_ad.full_screen_content_callback = full
		interstitial_ad.show()
	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), load_callback)
	return true
GDSCRIPT

echo "Installed GodotGooglePlayBilling 3.3.0, Poing AdMob 5.1.0, and the UNJAM provider adapter. Enable the AdMob and billing editor plugins, install their Android dependencies/template, then configure real production IDs."
