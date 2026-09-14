extends Node

signal hint_granted(placement: String, source: String)
signal hint_unavailable(placement: String, reason: String)

const HINT_COST := 25

func _save() -> Node:
	return get_node_or_null("/root/SaveManager")

func _ads() -> Node:
	return get_node_or_null("/root/AdManager")

func _analytics() -> Node:
	return get_node_or_null("/root/AnalyticsManager")

func coin_balance() -> int:
	var save := _save()
	return maxi(0, int(save.data.get("coins", 0))) if save != null else 0

func can_afford_hint() -> bool:
	return coin_balance() >= HINT_COST

func request_hint(placement: String, reveal_hint: Callable, unavailable: Callable = Callable()) -> bool:
	if not reveal_hint.is_valid():
		return false
	var save := _save()
	if save == null:
		return false
	if bool(save.call("spend_coins", HINT_COST)):
		_grant(placement, "coins", reveal_hint)
		return true
	var ads := _ads()
	var reward_placement := "hint_%s" % placement
	var accepted := false
	if ads != null:
		accepted = bool(ads.call("show_rewarded", reward_placement, func() -> void:
			_grant(placement, "rewarded_ad", reveal_hint)
		))
	if accepted:
		_track("hint_rewarded_requested", {"placement": placement, "cost": HINT_COST})
		return true
	var reason := "Need %d coins. Rewarded ad is unavailable right now." % HINT_COST
	if unavailable.is_valid():
		unavailable.call(reason)
	hint_unavailable.emit(placement, reason)
	_track("hint_unavailable", {"placement": placement, "balance": coin_balance()})
	return false

func _grant(placement: String, source: String, reveal_hint: Callable) -> void:
	var save := _save()
	if save != null:
		save.call("record_hint")
	reveal_hint.call()
	hint_granted.emit(placement, source)
	_track("hint_granted", {"placement": placement, "source": source, "cost": HINT_COST if source == "coins" else 0})

func _track(event_name: String, properties: Dictionary) -> void:
	var analytics := _analytics()
	if analytics != null:
		analytics.call("track", event_name, properties)
