extends Node

signal hint_granted(placement: String, source: String)
signal hint_unavailable(placement: String, reason: String)

const HINT_COST := 25

var _attached_games := {}

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_existing")

func _save() -> Node:
	return get_node_or_null("/root/SaveManager")

func _economy() -> Node:
	return get_node_or_null("/root/EconomyManager")

func _ads() -> Node:
	return get_node_or_null("/root/AdManager")

func _analytics() -> Node:
	return get_node_or_null("/root/AnalyticsManager")

func coin_balance() -> int:
	var economy := _economy()
	if economy != null:
		return maxi(0, int(economy.call("balance")))
	var save := _save()
	return maxi(0, int(save.data.get("coins", 0))) if save != null else 0

func can_afford_hint() -> bool:
	var economy := _economy()
	if economy != null:
		return bool(economy.call("can_afford", HINT_COST))
	return coin_balance() >= HINT_COST

func request_hint(placement: String, reveal_hint: Callable, unavailable: Callable = Callable()) -> bool:
	if not reveal_hint.is_valid():
		return false
	var save := _save()
	if save == null:
		return false
	var economy := _economy()
	var paid := false
	if economy != null:
		paid = bool(economy.call("spend", HINT_COST, "hint_%s" % placement, {"placement": placement}))
	else:
		paid = bool(save.call("spend_coins", HINT_COST))
	if paid:
		_grant(placement, "coins", reveal_hint)
		return true

	# In the actual Main scene, show a player-controlled recovery choice instead
	# of silently forcing an ad. Headless/unit contexts without the prompt keep
	# the legacy optional rewarded fallback so existing monetization contracts and
	# non-Main test harnesses remain valid.
	if _show_recovery_prompt(placement, reveal_hint):
		_track("hint_recovery_prompt", {"placement": placement, "cost": HINT_COST, "balance": coin_balance()})
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

func request_hint_for_game(game: Node) -> bool:
	if game == null or not is_instance_valid(game) or not game.has_method("show_hint"):
		return false
	var placement := _game_id(game)
	var unavailable := Callable(self, "_show_unavailable_on_game").bind(game)
	if not _can_deliver_hint(game, placement):
		var reason := "No verified useful hint is available from this position. Undo or Retry first."
		unavailable.call(reason)
		hint_unavailable.emit(placement, reason)
		_track("hint_unavailable", {"placement": placement, "balance": coin_balance(), "reason": "no_verified_move"})
		return false
	return request_hint(placement, Callable(game, "show_hint"), unavailable)

func _can_deliver_hint(game: Node, placement: String) -> bool:
	if game.has_method("can_show_hint"):
		return bool(game.call("can_show_hint"))
	match placement:
		"water_sort":
			if bool(game.get("completed")) or bool(game.get("pending_completion")):
				return false
			var sources = game.get("active_source_tubes")
			var targets = game.get("active_target_tubes")
			return sources is Dictionary and targets is Dictionary and sources.is_empty() and targets.is_empty()
		"block_puzzle":
			if bool(game.get("completed")):
				return false
			if game.has_method("_best_hint_placement"):
				var best = game.call("_best_hint_placement")
				return best is Dictionary and not (best as Dictionary).is_empty()
			return true
		_:
			return not bool(game.get("board_locked")) and not bool(game.get("rescued"))

func _show_recovery_prompt(placement: String, reveal_hint: Callable) -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var prompt := scene.get_node_or_null("InsufficientCoinsPrompt")
	if prompt == null or not prompt.has_method("show_for"):
		return false
	var retry := Callable(self, "_retry_hint").bind(placement, reveal_hint)
	prompt.call("show_for", "%s HINT" % placement.replace("_", " ").to_upper(), HINT_COST, retry)
	return true

func _retry_hint(placement: String, reveal_hint: Callable) -> bool:
	return request_hint(placement, reveal_hint)

func _grant(placement: String, source: String, reveal_hint: Callable) -> void:
	reveal_hint.call()
	hint_granted.emit(placement, source)
	_track("hint_granted", {"placement": placement, "source": source, "cost": HINT_COST if source == "coins" else 0})

func _track(event_name: String, properties: Dictionary) -> void:
	var analytics := _analytics()
	if analytics != null:
		analytics.call("track", event_name, properties)

func _on_node_added(node: Node) -> void:
	# Game roots already expose their script methods when they enter the tree.
	# Filter here so scene construction does not schedule work for every label,
	# panel and cell button in a puzzle board.
	if node is Control and node.has_method("show_hint"):
		call_deferred("_attach_game", node)

func _scan_existing() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		_scan_node(scene)

func _scan_node(node: Node) -> void:
	_attach_game(node)
	for child in node.get_children():
		_scan_node(child)

func _attach_game(game: Node) -> void:
	if game == null or not is_instance_valid(game) or not game.has_method("show_hint"):
		return
	var id := game.get_instance_id()
	if _attached_games.has(id):
		return
	var button := _find_hint_button(game)
	if button == null:
		return
	for connection in button.pressed.get_connections():
		var callback: Callable = connection.get("callable", Callable())
		if callback.is_valid() and button.pressed.is_connected(callback):
			button.pressed.disconnect(callback)
	button.text = "✦  HINT • %d" % HINT_COST if "✦" in button.text else "HINT • %d" % HINT_COST
	button.tooltip_text = "Costs %d coins. Balance: %d. If you are short, Shop or an optional rewarded ad can help." % [HINT_COST, coin_balance()]
	button.pressed.connect(request_hint_for_game.bind(game))
	_attached_games[id] = true
	game.tree_exited.connect(func() -> void: _attached_games.erase(id), CONNECT_ONE_SHOT)

func _find_hint_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and "HINT" in child.text.to_upper():
			return child
		var nested := _find_hint_button(child)
		if nested != null:
			return nested
	return null

func _game_id(game: Node) -> String:
	var script := game.get_script() as Script
	var path := String(script.resource_path) if script != null else ""
	if "water_sort" in path:
		return "water_sort"
	if "block_puzzle" in path:
		return "block_puzzle"
	return "rescue_rush"

func _show_unavailable_on_game(reason: String, game: Node) -> void:
	if game == null or not is_instance_valid(game):
		return
	var label = game.get("hint_label")
	if label is Label:
		label.text = reason
