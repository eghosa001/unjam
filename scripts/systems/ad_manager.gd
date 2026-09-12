extends Node

signal rewarded_completed(placement: String)
signal interstitial_closed

var ads_enabled := true
var completed_since_interstitial := 0
var interstitial_interval := 5

func show_rewarded(placement: String, on_reward: Callable = Callable()) -> void:
	# Replace this fallback with the chosen Android ad SDK adapter.
	# During development, rewards are granted immediately so gameplay remains testable.
	if on_reward.is_valid():
		on_reward.call()
	rewarded_completed.emit(placement)

func note_level_completed() -> void:
	completed_since_interstitial += 1

func should_show_interstitial() -> bool:
	return ads_enabled and completed_since_interstitial >= interstitial_interval

func show_interstitial() -> void:
	# SDK integration intentionally isolated here; never call ad APIs from game.gd.
	completed_since_interstitial = 0
	interstitial_closed.emit()

func set_ads_enabled(enabled: bool) -> void:
	ads_enabled = enabled
