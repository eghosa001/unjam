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
	shade.color = Color(0.01, 0.025, 0.07, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "InsufficientCoinsCard"
	var visible_size := get_viewport().get_visible_rect().size
	panel.custom_minimum_size = Vector2(minf(620.0, maxf(300.0, visible_size.x - 48.0)), minf(520.0, maxf(420.0, visible_size.y - 80.0)))
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("f8fbff"), 38, Color("ffd46a"), 4, 12))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24 if visible_size.x < 600.0 else 30)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14 if visible_size.y < 900.0 else 18)
	margin.add_child(box)

	var title := Label.new()
	title.text = "MORE COINS NEEDED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28 if visible_size.x < 600.0 else 34)
	Unjam3DTheme.label_3d(title, Unjam3DTheme.ORANGE, Unjam3DTheme.NAVY, 5)
	box.add_child(title)
	detail_label = Label.new()
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 18 if visible_size.x < 600.0 else 20)
	Unjam3DTheme.label_3d(detail_label, Unjam3DTheme.NAVY, Color.WHITE, 2)
	box.add_child(detail_label)

	var shop := Button.new()
	shop.name = "InsufficientCoinsShopButton"
	shop.text = "OPEN SHOP"
	shop.custom_minimum_size = Vector2(0, 82 if visible_size.y < 900.0 else 92)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.add_theme_font_size_override("font_size", 21 if visible_size.x < 600.0 else 23)
	Unjam3DTheme.gloss_button(shop, Unjam3DTheme.ORANGE, true, 30)
	shop.pressed.connect(_open_shop)
	box.add_child(shop)

	reward_button = Button.new()
	reward_button.name = "InsufficientCoinsRewardButton"
	reward_button.text = "▶  WATCH AD  •  +50 COINS"
	reward_button.custom_minimum_size = Vector2(0, 82 if visible_size.y < 900.0 else 92)
	reward_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_button.add_theme_font_size_override("font_size", 18 if visible_size.x < 600.0 else 21)
	Unjam3DTheme.gloss_button(reward_button, Color("24ba68"), true, 30)
	reward_button.pressed.connect(_watch_rewarded)
	box.add_child(reward_button)

	var close := Button.new()
	close.text = "NOT NOW"
	close.custom_minimum_size = Vector2(0, 66 if visible_size.y < 900.0 else 72)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Unjam3DTheme.gloss_button(close, Unjam3DTheme.WATER_DARK, false, 26)
	close.pressed.connect(_close)
	box.add_child(close)

func show_for(action_name: String, cost: int, retry: Callable = Callable()) -> void:
	if overlay == null or not is_instance_valid(overlay):
		_build()
	_action_name = action_name
	_cost = maxi(1, cost)
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
	var missing := maxi(0, _cost - balance)
	var text := "%s costs %d coins.\nYou have %d • Need %d more." % [_action_name, _cost, balance, missing]
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
	var accepted := AdManager.reward_coins("assist_coin_recovery", 50, Callable(self, "_on_reward_granted"), Callable(self, "_on_reward_failed"))
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
