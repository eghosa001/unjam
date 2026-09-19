extends "res://scripts/ui/monetization_hub.gd"

var _previous_world_accent := Unjam3DTheme.GREEN
var _previous_world_dark_mode := false
var _has_previous_world_style := false

func open_shop() -> void:
	if overlay == null or not is_instance_valid(overlay):
		super.open_shop()
		return
	var main := get_parent()
	var world: Unjam3DBackdrop = null
	if main != null:
		world = main.get_node_or_null("UnjamWorldBackdrop") as Unjam3DBackdrop
	if world != null:
		_previous_world_accent = world.accent
		_previous_world_dark_mode = world.dark_mode
		_has_previous_world_style = true
		if main.has_method("set_world_backdrop_style"):
			main.call("set_world_backdrop_style", Unjam3DTheme.ORANGE, world.dark_mode)
	super.open_shop()

func _close_shop() -> void:
	super._close_shop()
	if not _has_previous_world_style:
		return
	var main := get_parent()
	if main != null and main.has_method("set_world_backdrop_style"):
		main.call("set_world_backdrop_style", _previous_world_accent, _previous_world_dark_mode)
	_has_previous_world_style = false

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

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the shared world visible; Shop only adds a warm merchandising tint.
	shade.color = Color(0.20, 0.08, 0.02, 0.20)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var narrow := get_viewport().get_visible_rect().size.x < 650.0
	margin.add_theme_constant_override("margin_left", 22 if narrow else 44)
	margin.add_theme_constant_override("margin_right", 22 if narrow else 44)
	margin.add_theme_constant_override("margin_top", 28 if narrow else 42)
	margin.add_theme_constant_override("margin_bottom", 28 if narrow else 42)
	overlay.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 13)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 86)
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := Button.new()
	close.text = "←"
	close.custom_minimum_size = Vector2(84 if narrow else 92, 74 if narrow else 78)
	close.add_theme_font_size_override("font_size", 32)
	Unjam3DTheme.gloss_button(close, Unjam3DTheme.WATER_DARK, true, 24)
	close.pressed.connect(_close_shop)
	header.add_child(close)
	var title := Label.new()
	title.text = "UNJAM SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 31 if narrow else 38)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 5)
	header.add_child(title)
	balance_label = Label.new()
	balance_label.name = "ShopCoinBalance"
	balance_label.custom_minimum_size = Vector2(170 if narrow else 220, 74 if narrow else 78)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 22 if narrow else 24)
	Unjam3DTheme.label_3d(balance_label, Unjam3DTheme.GOLD, Unjam3DTheme.NAVY, 3)
	header.add_child(balance_label)

	var scroll := ScrollContainer.new()
	scroll.name = "ShopCatalogScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var products := VBoxContainer.new()
	products.name = "ShopCatalog"
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("separation", 12)
	scroll.add_child(products)

	_add_section_title(products, "REMOVE ADS", "Play without interstitial interruptions")
	_add_product(products, StoreManager.PRODUCT_REMOVE_ADS)
	_add_section_title(products, "STARTER PACK", "One-time launch boost")
	_add_product(products, StoreManager.PRODUCT_STARTER_PACK)
	_add_section_title(products, "COIN PACKS", "Use coins for hints, extra tubes and collection upgrades")
	_add_product(products, StoreManager.PRODUCT_COINS_SMALL)
	_add_product(products, StoreManager.PRODUCT_COINS_MEDIUM)
	_add_product(products, StoreManager.PRODUCT_COINS_LARGE)
	_add_section_title(products, "FREE COINS", "Optional rewarded ad • no purchase required")
	_add_reward_panel(products)

	var utility_row := HBoxContainer.new()
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 12)
	root.add_child(utility_row)
	var restore := Button.new()
	restore.text = "RESTORE PURCHASES"
	restore.custom_minimum_size = Vector2(0, 72 if narrow else 76)
	restore.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Unjam3DTheme.gloss_button(restore, Unjam3DTheme.WATER_DARK, false, 24)
	restore.pressed.connect(_restore_purchases)
	utility_row.add_child(restore)
	var privacy := Button.new()
	privacy.text = "PRIVACY OPTIONS"
	privacy.custom_minimum_size = Vector2(0, 72 if narrow else 76)
	privacy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Unjam3DTheme.gloss_button(privacy, Unjam3DTheme.WATER_DARK, false, 24)
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	utility_row.add_child(privacy)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 21 if narrow else 22)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Unjam3DTheme.label_3d(status_label, Color.WHITE, Unjam3DTheme.NAVY, 3)
	root.add_child(status_label)
	_refresh()

func _add_section_title(parent: VBoxContainer, title_text: String, subtitle_text: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 23)
	Unjam3DTheme.label_3d(title, Color.WHITE, Unjam3DTheme.NAVY, 4)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Unjam3DTheme.label_3d(subtitle, Color("d9efff"), Unjam3DTheme.NAVY, 2)
	box.add_child(subtitle)

func _add_reward_panel(parent: VBoxContainer) -> void:
	var reward_panel := PanelContainer.new()
	reward_panel.name = "ShopFreeCoinsPanel"
	reward_panel.custom_minimum_size = Vector2(0, 126)
	reward_panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("25c96b"), 32, Color("88f3aa"), 3, 11))
	parent.add_child(reward_panel)
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 18)
	reward_panel.add_child(reward_row)
	var reward_text := Label.new()
	reward_text.text = "WATCH & EARN\nGet 50 coins for an optional rewarded ad"
	reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_text.add_theme_font_size_override("font_size", 22)
	reward_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Unjam3DTheme.label_3d(reward_text, Color.WHITE, Color("08723a"), 3)
	reward_row.add_child(reward_text)
	var watch := Button.new()
	watch.name = "ShopRewardedCoinsButton"
	watch.text = "▶  +50 COINS"
	watch.custom_minimum_size = Vector2(270, 88)
	watch.add_theme_font_size_override("font_size", 20)
	Unjam3DTheme.gloss_button(watch, Unjam3DTheme.ORANGE, true, 27)
	watch.pressed.connect(_watch_rewarded.bind(watch))
	reward_row.add_child(watch)

func _is_owned_product(product_id: String, info: Dictionary) -> bool:
	if not bool(info.get("non_consumable", false)):
		return false
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	if product_id in purchased:
		return true
	if product_id == StoreManager.PRODUCT_REMOVE_ADS:
		return bool(SaveManager.data.get("remove_ads", false))
	if product_id == StoreManager.PRODUCT_STARTER_PACK:
		return bool(SaveManager.data.get("starter_pack_purchased", false))
	return false

func _add_product(parent: VBoxContainer, product_id: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	var panel := PanelContainer.new()
	panel.name = "ShopProduct_%s" % product_id
	panel.custom_minimum_size = Vector2(0, 112)
	panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(Color("f7fcff"), 28, Color("9cddff"), 2, 7))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var text := Label.new()
	text.text = "%s\n%s" % [String(info.get("title", product_id)), String(info.get("subtitle", ""))]
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Unjam3DTheme.label_3d(text, Unjam3DTheme.NAVY, Color.WHITE, 2)
	row.add_child(text)
	var buy := Button.new()
	buy.name = "Buy_%s" % product_id
	buy.custom_minimum_size = Vector2(250, 82)
	buy.add_theme_font_size_override("font_size", 18)
	if _is_owned_product(product_id, info):
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
