extends Node

var layer: CanvasLayer
var shop_button: Button
var overlay: Control
var balance_label: Label
var status_label: Label

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	StoreManager.catalog_changed.connect(_on_catalog_changed)
	StoreManager.purchase_pending.connect(_on_purchase_pending)
	StoreManager.purchase_succeeded.connect(_on_purchase_succeeded)
	StoreManager.purchase_failed.connect(_on_purchase_failed)
	AdManager.rewarded_completed.connect(_on_rewarded_completed)
	AdManager.rewarded_failed.connect(_on_rewarded_failed)
	call_deferred("_build_ui")

func _shop_button(text_value: String, role: String = "secondary", tint: Color = Color("62b6ff")) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 82)
	button.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_button(button, true, tint, role, 24)
	return button

func _build_ui() -> void:
	if layer != null:
		return
	layer = CanvasLayer.new()
	layer.layer = 500
	add_child(layer)
	shop_button = Button.new()
	shop_button.text = "SHOP"
	shop_button.visible = false
	shop_button.custom_minimum_size = Vector2(230, 82)
	shop_button.pressed.connect(open_shop)
	layer.add_child(shop_button)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.055, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var backdrop := PremiumBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Color("07111f"), Color("62b6ff"), 1)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 44)
	overlay.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := _shop_button("← BACK", "utility")
	close.custom_minimum_size.x = 190
	close.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(_close_shop)
	header.add_child(close)
	var title := Label.new()
	title.text = "UNJAM SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	PremiumDesignSystem.apply_label(title, true, "title", Color("62b6ff"))
	header.add_child(title)
	var balance_panel := PanelContainer.new()
	balance_panel.custom_minimum_size = Vector2(210, 72)
	balance_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.status_chip(PremiumDesignSystem.GOLD, true))
	header.add_child(balance_panel)
	balance_label = Label.new()
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 20)
	balance_label.add_theme_color_override("font_color", PremiumDesignSystem.GOLD)
	balance_panel.add_child(balance_label)

	var reward_panel := PanelContainer.new()
	reward_panel.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color("11294a"), 28, Color("49e1c0"), true, 9))
	root.add_child(reward_panel)
	var reward_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		reward_margin.add_theme_constant_override("margin_%s" % side, 18)
	reward_panel.add_child(reward_margin)
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 18)
	reward_margin.add_child(reward_row)
	var reward_text := Label.new()
	reward_text.text = "FREE COINS\nWatch an optional rewarded ad"
	reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_text.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_label(reward_text, true, "body", Color("49e1c0"))
	reward_row.add_child(reward_text)
	var watch := _shop_button("WATCH AD  •  +50 COINS", "reward", PremiumDesignSystem.GOLD)
	watch.custom_minimum_size.x = 360
	watch.pressed.connect(_watch_rewarded.bind(watch))
	reward_row.add_child(watch)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var products := VBoxContainer.new()
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("separation", 14)
	scroll.add_child(products)
	for product_id in StoreManager.PRODUCTS.keys():
		_add_product(products, String(product_id))

	var utility_row := HBoxContainer.new()
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 14)
	root.add_child(utility_row)
	var restore := _shop_button("RESTORE PURCHASES", "utility")
	restore.custom_minimum_size.x = 300
	restore.pressed.connect(_restore_purchases)
	utility_row.add_child(restore)
	var privacy := _shop_button("PRIVACY OPTIONS", "utility")
	privacy.custom_minimum_size.x = 300
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	utility_row.add_child(privacy)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", PremiumDesignSystem.muted(true))
	root.add_child(status_label)
	_refresh()

func _add_product(parent: VBoxContainer, product_id: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PremiumDesignSystem.raised_box(Color("101d38"), 24, Color("62b6ff55"), true, 6))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	var text := Label.new()
	text.text = "%s\n%s" % [String(info.get("title", product_id)), String(info.get("subtitle", ""))]
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 20)
	PremiumDesignSystem.apply_label(text, true, "body", Color("62b6ff"))
	row.add_child(text)
	var buy := _shop_button("", "primary", Color("62b6ff"))
	buy.custom_minimum_size.x = 280
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	if bool(info.get("non_consumable", false)) and product_id in purchased:
		buy.text = "OWNED"
		buy.disabled = true
		PremiumDesignSystem.apply_button(buy, true, PremiumDesignSystem.SUCCESS, "success", 24)
	elif StoreManager.is_purchase_pending(product_id):
		buy.text = "PENDING"
		buy.disabled = true
		PremiumDesignSystem.apply_button(buy, true, Color("62b6ff"), "disabled", 24)
	else:
		buy.text = StoreManager.price_text(product_id)
		buy.pressed.connect(_purchase.bind(product_id, buy))
	row.add_child(buy)

func open_shop() -> void:
	if overlay == null or not is_instance_valid(overlay):
		call_deferred("open_shop")
		return
	overlay.visible = true
	if not MotionSystem.reduced():
		overlay.modulate.a = 0.0
		var tween := overlay.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(overlay, "modulate:a", 1.0, 0.22)
	else:
		overlay.modulate.a = 1.0
	_refresh()
	AnalyticsManager.track("shop_opened", {})

func _close_shop() -> void:
	overlay.visible = false
	AnalyticsManager.track("shop_closed", {})

func _refresh() -> void:
	if balance_label != null:
		balance_label.text = "%d COINS" % int(SaveManager.data.get("coins", 0))

func _watch_rewarded(button: Button) -> void:
	button.disabled = true
	status_label.text = "Loading rewarded ad…"
	if not AdManager.reward_coins("shop_coins", 50):
		button.disabled = false
		status_label.text = "Rewarded ad is not available right now."

func _purchase(product_id: String, button: Button) -> void:
	button.disabled = true
	button.text = "PROCESSING…"
	status_label.text = "Opening Google Play…"
	if not StoreManager.purchase(product_id):
		button.disabled = false
		button.text = StoreManager.price_text(product_id)

func _on_catalog_changed() -> void:
	if layer != null and is_instance_valid(layer):
		call_deferred("_rebuild_shop")

func _on_purchase_pending(_product_id: String, reason: String) -> void:
	status_label.text = reason + ". You can keep playing while Google Play completes it."
	call_deferred("_rebuild_shop")

func _on_purchase_succeeded(_product_id: String) -> void:
	status_label.text = "Purchase confirmed. Thank you!"
	_refresh()
	call_deferred("_rebuild_shop")

func _on_purchase_failed(_product_id: String, reason: String) -> void:
	status_label.text = reason
	call_deferred("_rebuild_shop")

func _on_rewarded_completed(placement: String) -> void:
	if placement == "shop_coins":
		status_label.text = "+50 coins added"
		_refresh()
		call_deferred("_rebuild_shop")

func _on_rewarded_failed(placement: String, reason: String) -> void:
	if placement == "shop_coins":
		status_label.text = reason
		call_deferred("_rebuild_shop")

func _rebuild_shop() -> void:
	if overlay == null:
		return
	var was_open := overlay.visible
	layer.remove_child(overlay)
	overlay.queue_free()
	overlay = null
	balance_label = null
	status_label = null
	layer.remove_child(shop_button)
	shop_button.queue_free()
	shop_button = null
	remove_child(layer)
	layer.queue_free()
	layer = null
	_build_ui()
	if was_open:
		overlay.visible = true

func _on_node_added(node: Node) -> void:
	if node == null or not node.has_signal("finished"):
		return
	if not node.has_method("monetization_game_id"):
		return
	var game_id := String(node.call("monetization_game_id"))
	if game_id not in ["water_sort", "block_puzzle"]:
		return
	var callback := Callable(self, "_on_puzzle_finished").bind(game_id)
	if not node.is_connected("finished", callback):
		node.connect("finished", callback)

func _on_puzzle_finished(_level_number: int, game_id: String) -> void:
	AdManager.note_level_completed()
	AnalyticsManager.track("monetization_level_complete", {"game": game_id})
	if AdManager.should_show_interstitial():
		AdManager.show_interstitial()

func _restore_purchases() -> void:
	status_label.text = "Checking Google Play purchases…"
	if not StoreManager.restore_purchases():
		status_label.text = "Restore purchases is available on a Google Play build."
