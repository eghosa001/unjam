extends Node

signal rewarded_completed(placement: String)
signal rewarded_failed(placement: String, reason: String)
signal interstitial_closed
signal interstitial_failed(reason: String)
signal provider_changed(ready: bool)

const DEFAULT_REWARDED_COINS := 50
const MIN_LEVELS_BEFORE_FIRST_INTERSTITIAL := 3
const INTERSTITIAL_COOLDOWN_SECONDS := 180
const MAX_INTERSTITIALS_PER_SESSION := 6

var ads_enabled := true
var completed_since_interstitial := 0
var interstitial_interval := 4
var interstitials_this_session := 0
var last_interstitial_unix := 0
var provider: Node
var _pending_reward_placement := ""
var _pending_reward_callback := Callable()
var _pending_reward_failed_callback := Callable()
var rewarded_in_progress := false

func _ready() -> void:
	ads_enabled = not bool(SaveManager.data.get("remove_ads", false))
	last_interstitial_unix = int(Time.get_unix_time_from_system()) - INTERSTITIAL_COOLDOWN_SECONDS

func register_provider(value: Node) -> void:
	provider = value
	provider_changed.emit(is_provider_ready())

func is_provider_ready() -> bool:
	if provider == null or not is_instance_valid(provider):
		return false
	if provider.has_method("is_ready"):
		return bool(provider.call("is_ready"))
	return true

func is_test_mode() -> bool:
	return bool(ProjectSettings.get_setting("monetization/test_mode", true))

func show_rewarded(placement: String, on_reward: Callable = Callable(), on_failed: Callable = Callable()) -> bool:
	if rewarded_in_progress:
		var reason := "A rewarded ad is already in progress"
		if on_failed.is_valid():
			on_failed.call(reason)
		rewarded_failed.emit(placement, reason)
		return false
	if OS.get_name() == "Android" and not PrivacyManager.may_request_ads():
		var reason := "Advertising consent is not ready"
		if on_failed.is_valid():
			on_failed.call(reason)
		rewarded_failed.emit(placement, reason)
		return false
	AnalyticsManager.track("rewarded_requested", {"placement": placement, "provider": is_provider_ready()})
	if is_provider_ready() and provider.has_method("show_rewarded"):
		rewarded_in_progress = true
		_pending_reward_placement = placement
		_pending_reward_callback = on_reward
		_pending_reward_failed_callback = on_failed
		var accepted = provider.call("show_rewarded", placement, Callable(self, "_provider_rewarded_completed"), Callable(self, "_provider_rewarded_failed"))
		if accepted == false and rewarded_in_progress:
			rewarded_in_progress = false
			_pending_reward_placement = ""
			_pending_reward_callback = Callable()
			_pending_reward_failed_callback = Callable()
			var reason := "Ad provider rejected rewarded request"
			if on_failed.is_valid():
				on_failed.call(reason)
			rewarded_failed.emit(placement, reason)
			AnalyticsManager.track("rewarded_failed", {"placement": placement, "reason": "provider_rejected"})
		return accepted != false
	if is_test_mode() and OS.get_name() != "Android":
		_grant_reward(placement, on_reward)
		return true
	var reason := "Ad provider unavailable"
	if on_failed.is_valid():
		on_failed.call(reason)
	rewarded_failed.emit(placement, reason)
	AnalyticsManager.track("rewarded_unavailable", {"placement": placement})
	return false

func _provider_rewarded_completed() -> void:
	rewarded_in_progress = false
	_grant_reward(_pending_reward_placement, _pending_reward_callback)
	_pending_reward_placement = ""
	_pending_reward_callback = Callable()
	_pending_reward_failed_callback = Callable()

func _provider_rewarded_failed(reason: String = "Rewarded ad failed") -> void:
	rewarded_in_progress = false
	var placement := _pending_reward_placement
	var failed_callback := _pending_reward_failed_callback
	_pending_reward_placement = ""
	_pending_reward_callback = Callable()
	_pending_reward_failed_callback = Callable()
	if failed_callback.is_valid():
		failed_callback.call(reason)
	rewarded_failed.emit(placement, reason)
	AnalyticsManager.track("rewarded_failed", {"placement": placement, "reason": reason})

func _grant_reward(placement: String, callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
	SaveManager.data.rewarded_ads_watched = int(SaveManager.data.get("rewarded_ads_watched", 0)) + 1
	SaveManager.save()
	rewarded_completed.emit(placement)
	AnalyticsManager.track("rewarded_completed", {"placement": placement})

func reward_coins(placement: String = "shop_coins", amount: int = DEFAULT_REWARDED_COINS, on_granted: Callable = Callable(), on_failed: Callable = Callable()) -> bool:
	if amount <= 0:
		return false
	return show_rewarded(placement, func() -> void:
		EconomyManager.grant(amount, "rewarded_ad", {"placement": placement})
		if on_granted.is_valid():
			on_granted.call()
	, on_failed)

func note_level_completed() -> void:
	completed_since_interstitial += 1

func should_show_interstitial() -> bool:
	if not ads_enabled or bool(SaveManager.data.get("remove_ads", false)):
		return false
	if OS.get_name() == "Android" and not PrivacyManager.may_request_ads():
		return false
	if is_test_mode() and OS.get_name() != "Android":
		return completed_since_interstitial >= interstitial_interval
	if int(SaveManager.data.get("total_levels_completed", 0)) < MIN_LEVELS_BEFORE_FIRST_INTERSTITIAL:
		return false
	if completed_since_interstitial < interstitial_interval:
		return false
	if interstitials_this_session >= MAX_INTERSTITIALS_PER_SESSION:
		return false
	return int(Time.get_unix_time_from_system()) - last_interstitial_unix >= INTERSTITIAL_COOLDOWN_SECONDS

func show_interstitial() -> bool:
	if not should_show_interstitial():
		interstitial_closed.emit()
		return false
	if is_provider_ready() and provider.has_method("show_interstitial"):
		var accepted = provider.call("show_interstitial", Callable(self, "_provider_interstitial_closed"), Callable(self, "_provider_interstitial_failed"))
		return accepted != false
	if is_test_mode() and OS.get_name() != "Android":
		_provider_interstitial_closed()
		return true
	interstitial_failed.emit("Ad provider unavailable")
	return false

func _provider_interstitial_closed() -> void:
	completed_since_interstitial = 0
	interstitials_this_session += 1
	last_interstitial_unix = int(Time.get_unix_time_from_system())
	interstitial_closed.emit()
	AnalyticsManager.track("interstitial_closed", {"session_count": interstitials_this_session})

func _provider_interstitial_failed(reason: String = "Interstitial failed") -> void:
	interstitial_failed.emit(reason)
	AnalyticsManager.track("interstitial_failed", {"reason": reason})

func set_ads_enabled(enabled: bool) -> void:
	ads_enabled = enabled

func set_remove_ads_purchased(purchased: bool) -> void:
	SaveManager.data.remove_ads = purchased
	SaveManager.save()
	ads_enabled = not purchased
