extends Node

var overlay: Control
var detail_label: Label
var reward_button: Button
var _action_name := ""
var _cost := 0
var _retry := Callable()
var _reward_busy := false

func _ready() -> void:
	call_deferred("_build")

func _build() -> void:
	if overlay != null and is_instance_valid(overlay):
		return
	var layer := CanvasLayer.new()
	layer.name = "InsufficientCoinsLayer"
	layer.layer = 600
	add_child(layer)

	overlay = Control.new()
	overlay.name = "InsufficientCoinsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.name = "CoinModal/Dim"
	shade.color = Color(0.01,0.025,0.07,0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var canvas := FigmaReferenceCanvas.new()
	canvas.name = "FigmaInsufficientCoins390x844"
	overlay.add_child(canvas)

	var card := PanelContainer.new()
	card.name = "CoinModal/Card"
	card.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(
		Color(0.995,0.998,1.0),Color(0.94,0.97,0.99),26,Color("ffd46a"),2
	))
	FigmaReferenceCanvas.set_rect(card,26,194,338,410)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(card)

	var icon := PanelContainer.new()
	icon.name = "CoinModal/Icon"
	icon.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(Color("ffd95a"),Color("f3a820"),44,Color("fff1a8"),2))
	FigmaReferenceCanvas.set_rect(icon,151,220,88,88)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(icon)
	var icon_text := FigmaReferenceCanvas.label("◈",30,Color.WHITE,true)
	icon_text.name = "CoinModal/IconText"
	icon_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(icon_text,166,236,58,44)
	canvas.add_child(icon_text)

	var title := FigmaReferenceCanvas.label("MORE COINS NEEDED",23,Color(0.07,0.20,0.35),true)
	title.name = "CoinModal/Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.set_rect(title,52,326,286,30)
	canvas.add_child(title)

	detail_label = FigmaReferenceCanvas.label("",14,Color(0.31,0.42,0.52),false)
	detail_label.name = "CoinModal/Body"
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FigmaReferenceCanvas.set_rect(detail_label,54,368,282,48)
	canvas.add_child(detail_label)

	reward_button = FigmaReferenceCanvas.button("▶  WATCH AD  •  +50 COINS",14,Color.WHITE,Color(0.13,0.78,0.39),16,Color(0.49,0.89,0.63),1)
	reward_button.name = "CoinModal/Rewarded"
	FigmaReferenceCanvas.set_rect(reward_button,46,438,298,58)
	reward_button.pressed.connect(_watch_rewarded)
	canvas.add_child(reward_button)

	var shop := FigmaReferenceCanvas.button("OPEN SHOP",13,Color.WHITE,Color(1.0,0.55,0.12),16,Color(1.0,0.76,0.38),1)
	shop.name = "CoinModal/Shop"
	FigmaReferenceCanvas.set_rect(shop,46,506,142,52)
	shop.pressed.connect(_open_shop)
	canvas.add_child(shop)

	var later := FigmaReferenceCanvas.button("NOT NOW",13,Color(0.03,0.23,0.47),Color(0.96,0.985,1.0),16,Color(0.66,0.80,0.91),1)
	later.name = "CoinModal/Later"
	FigmaReferenceCanvas.set_rect(later,202,506,142,52)
	later.pressed.connect(_close)
	canvas.add_child(later)

func show_for(action_name: String, cost: int, retry: Callable = Callable()) -> void:
	if overlay == null or not is_instance_valid(overlay):
		_build()
	_action_name = action_name
	_cost = maxi(1,cost)
	_retry = retry
	_reward_busy = false
	if reward_button != null:
		reward_button.disabled = false
		reward_button.text = "▶  WATCH AD  •  +50 COINS"
	_refresh_detail()
	overlay.visible = true

func _refresh_detail(extra: String = "") -> void:
	if detail_label == null:
		return
	var balance := EconomyManager.balance()
	var missing := maxi(0,_cost-balance)
	var text := "%s costs %d coins\nYou have %d • Need %d more" % [_action_name,_cost,balance,missing]
	if not extra.is_empty():
		text += "\n" + extra
	detail_label.text = text

func _open_shop() -> void:
	_close()
	var main := get_parent()
	if main == null:
		return
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")

func _watch_rewarded() -> void:
	if _reward_busy:
		return
	_reward_busy = true
	reward_button.disabled = true
	reward_button.text = "LOADING…"
	var accepted := AdManager.reward_coins("assist_coin_recovery",50,Callable(self,"_on_reward_granted"),Callable(self,"_on_reward_failed"))
	if not accepted and _reward_busy:
		_on_reward_failed("Rewarded ad is unavailable right now")

func _on_reward_granted() -> void:
	_reward_busy = false
	if reward_button != null:
		reward_button.disabled = false
		reward_button.text = "▶  WATCH AD  •  +50 COINS"
	if EconomyManager.can_afford(_cost) and _retry.is_valid():
		var result = _retry.call()
		if not (result is bool) or bool(result):
			_close()
			return
	_refresh_detail("+50 coins added.")

func _on_reward_failed(reason: String = "Rewarded ad failed") -> void:
	_reward_busy = false
	if reward_button != null:
		reward_button.disabled = false
		reward_button.text = "▶  WATCH AD  •  +50 COINS"
	_refresh_detail("%s. Shop is still available." % reason)

func _close() -> void:
	if overlay != null:
		overlay.visible = false
	_reward_busy = false
