extends Node

signal rewarded_completed(placement: String)
signal interstitial_closed

var ads_enabled := true
var completed_since_interstitial := 0
var interstitial_interval := 5

func _ready() -> void:
	ads_enabled = not bool(SaveManager.data.get("remove_ads", false))

func show_rewarded(placement: String, on_reward: Callable = Callable()) -> void:
	# Rewarded ads remain opt-in even for users who removed interstitial ads.
	# Replace this development fallback with the chosen Android ad SDK adapter.
	if on_reward.is_valid():
		on_reward.call()
	rewarded_completed.emit(placement)

func note_level_completed() -> void:
	completed_since_interstitial += 1

func should_show_interstitial() -> bool:
	return ads_enabled and not bool(SaveManager.data.get("remove_ads", false)) and completed_since_interstitial >= interstitial_interval

func show_interstitial() -> void:
	if not should_show_interstitial():
		interstitial_closed.emit()
		return
	completed_since_interstitial = 0
	# SDK integration intentionally isolated here; never call ad APIs from game.gd.
	interstitial_closed.emit()

func set_ads_enabled(enabled: bool) -> void:
	ads_enabled = enabled

func set_remove_ads_purchased(purchased: bool) -> void:
	SaveManager.data.remove_ads = purchased
	SaveManager.save()
	ads_enabled = not purchased
