extends "res://scripts/ui/monetization_hub.gd"

func _build_ui() -> void:
	if layer != null:
		return
	layer = CanvasLayer.new()
	layer.layer = 500
	add_child(layer)

	shop_button = Button.new()
	shop_button.text = "SHOP"
	shop_button.visible = false
	shop_button.pressed.connect(open_shop)
	layer.add_child(shop_button)

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	var backdrop := Unjam3DBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(Unjam3DTheme.ORANGE)
	overlay.add_child(backdrop)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.25, 0.42, 0.34)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 42)
	overlay.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 15)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 86)
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := Button.new()
	close.text = "←"
	close.custom_minimum_size = Vector2(92, 78)
	close.add_theme_font_size_override("font_size", 34)
	Unjam3DTheme.gloss_button(close, Unjam3DTheme.WATER_DARK, true, 24)
	close.pressed.connect(_close_shop)
	header.add_child(close)
	var title := Label.new()
	title.text = "UNJAM SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title)
	balance_label = Label.new()
	balance_label.custom_minimum_size = Vector2(220, 78)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 19)
	Unjam3DTheme.label_3d(balance_label, Unjam3DTheme.GOLD, Unjam3DTheme.NAVY, 3)
	header.add_child(balance_label)

	var reward_panel := PanelContainer.new()
	reward_panel.custom_minimum_size = Vector2(0, 132)
	reward_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("25c96b"), 32, Color("88f3aa"), 3, 11))
	root.add_child(reward_panel)
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 18)
	reward_panel.add_child(reward_row)
	var reward_text := Label.new()
	reward_text.text = "FREE COINS\nWatch an optional rewarded ad"
	reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_text.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.label_3d(reward_text, Color.WHITE, Color("08723a"), 3)
	reward_row.add_child(reward_text)
	var watch := Button.new()
	watch.text = "▶  +50 COINS"
	watch.custom_minimum_size = Vector2(330, 92)
	watch.add_theme_font_size_override("font_size", 21)
	Unjam3DTheme.gloss_button(watch, Unjam3DTheme.ORANGE, true, 27)
	watch.pressed.connect(_watch_rewarded.bind(watch))
	reward_row.add_child(watch)

	var products_title := Label.new()
	products_title.text = "POWER UP YOUR JOURNEY"
	products_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	products_title.add_theme_font_size_override("font_size", 25)
	Unjam3DTheme.label_3d(products_title, Color.WHITE, Unjam3DTheme.NAVY, 4)
	root.add_child(products_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var products := VBoxContainer.new()
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("separation", 13)
	scroll.add_child(products)
	for product_id in StoreManager.PRODUCTS.keys():
		_add_product(products, String(product_id))

	var utility_row := HBoxContainer.new()
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 12)
	root.add_child(utility_row)
	var restore := Button.new()
	restore.text = "RESTORE PURCHASES"
	restore.custom_minimum_size = Vector2(0, 76)
	restore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Unjam3DTheme.gloss_button(restore, Unjam3DTheme.WATER_DARK, false, 24)
	restore.pressed.connect(_restore_purchases)
	utility_row.add_child(restore)
	var privacy := Button.new()
	privacy.text = "PRIVACY OPTIONS"
	privacy.custom_minimum_size = Vector2(0, 76)
	privacy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Unjam3DTheme.gloss_button(privacy, Unjam3DTheme.WATER_DARK, false, 24)
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	utility_row.add_child(privacy)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	Unjam3DTheme.label_3d(status_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(status_label)
	_refresh()

func _add_product(parent: VBoxContainer, product_id: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 118)
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("f7fcff"), 28, Color("9cddff"), 2, 7))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var text := Label.new()
	text.text = "%s\n%s" % [String(info.get("title", product_id)), String(info.get("subtitle", ""))]
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.label_3d(text, Unjam3DTheme.NAVY, Color.WHITE, 2)
	row.add_child(text)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(280, 86)
	buy.add_theme_font_size_override("font_size", 19)
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	if bool(info.get("non_consumable", false)) and product_id in purchased:
		buy.text = "OWNED"
		buy.disabled = true
	elif StoreManager.is_purchase_pending(product_id):
		buy.text = "PENDING"
		buy.disabled = true
	else:
		buy.text = StoreManager.price_text(product_id)
		buy.pressed.connect(_purchase.bind(product_id, buy))
	Unjam3DTheme.gloss_button(buy, Unjam3DTheme.ORANGE, true, 25)
	row.add_child(buy)
