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
	overlay.name = "ShopOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02,0.12,0.22,0.20)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var canvas := FigmaReferenceCanvas.new()
	canvas.name = "FigmaShop390x844"
	overlay.add_child(canvas)

	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(
		Color(0.94,0.99,1.0),Color(0.9352,0.9208,0.9904),0
	))
	FigmaReferenceCanvas.set_rect(bg,0,0,390,844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	var back := FigmaReferenceCanvas.button("‹",27,Color(0.03,0.23,0.47),Color(0.987,0.996,1.0),18,Color(0.74,0.80,0.95,0.55),1)
	back.name = "ShopBackButton"
	FigmaReferenceCanvas.set_rect(back,18,20,52,52)
	back.pressed.connect(_close_shop)
	canvas.add_child(back)

	_add_text(canvas,"UNJAM SHOP",Rect2(84,22,205,28),23,Color(0.07,0.20,0.35))
	_add_text(canvas,"Useful upgrades • optional rewards",Rect2(84,52,210,15),12,Color(0.31,0.42,0.52))
	balance_label = _add_text(canvas,"",Rect2(298,38,60,15),12,Color(1,0.995,0.97))
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var wallet := PanelContainer.new()
	wallet.name = "ShopCoinPill"
	wallet.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(Color(1.0,0.63,0.20),Color(0.94,0.43,0.08),23,Color(1.0,0.78,0.38,0.55),1))
	FigmaReferenceCanvas.set_rect(wallet,286,22,84,46)
	wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(wallet)
	canvas.move_child(wallet,balance_label.get_index())

	_add_product_exact(canvas,StoreManager.PRODUCT_REMOVE_ADS,Rect2(18,92,354,70),"REMOVE ADS","No interstitial interruptions")
	_add_product_exact(canvas,StoreManager.PRODUCT_STARTER_PACK,Rect2(18,170,354,70),"STARTER PACK","One-time launch boost")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_SMALL,Rect2(18,248,354,60),"SMALL COINS","500 coins")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_MEDIUM,Rect2(18,316,354,60),"MEDIUM COINS","1,500 coins")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_LARGE,Rect2(18,384,354,60),"LARGE COINS","4,000 coins")

	var reward := PanelContainer.new()
	reward.name = "ShopFreeCoinsPanel"
	reward.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(Color(0.98,1.0,0.97),Color(0.91,0.98,0.93),16,Color(0.55,0.88,0.65,0.55),1))
	FigmaReferenceCanvas.set_rect(reward,18,458,354,78)
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(reward)
	_add_text(canvas,"WATCH & EARN",Rect2(34,474,150,18),15,Color(0.07,0.20,0.35))
	_add_text(canvas,"Optional • +50 coins",Rect2(34,501,160,15),12,Color(0.31,0.42,0.52))
	var watch := FigmaReferenceCanvas.button("▶ +50 COINS",12,Color.WHITE,Color(0.13,0.78,0.39),25,Color(0.50,0.91,0.65),1)
	watch.name = "ShopRewardedCoinsButton"
	FigmaReferenceCanvas.set_rect(watch,238,472,116,48)
	watch.pressed.connect(_watch_rewarded.bind(watch))
	canvas.add_child(watch)

	var restore := FigmaReferenceCanvas.button("RESTORE PURCHASES",12,Color.WHITE,Color(0.03,0.43,0.78),16,Color(0.45,0.72,0.91),1)
	restore.name = "ShopRestorePurchases"
	FigmaReferenceCanvas.set_rect(restore,18,558,170,46)
	restore.pressed.connect(_restore_purchases)
	canvas.add_child(restore)
	var privacy := FigmaReferenceCanvas.button("PRIVACY OPTIONS",12,Color.WHITE,Color(0.31,0.13,0.55),16,Color(0.70,0.54,0.88),1)
	privacy.name = "ShopPrivacyOptions"
	FigmaReferenceCanvas.set_rect(privacy,202,558,170,46)
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	canvas.add_child(privacy)

	status_label = _add_text(canvas,"",Rect2(24,618,342,52),12,Color(0.31,0.42,0.52))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh()

func _add_product_exact(canvas: Control, product_id: String, rect: Rect2, display_title: String, display_subtitle: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	var panel := PanelContainer.new()
	panel.name = "ShopProduct_%s" % product_id
	panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient(
		Color(0.995,0.998,1.0),Color(0.94,0.97,0.99),16,Color(0.70,0.85,0.95,0.52),1
	))
	FigmaReferenceCanvas.set_rect(panel,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	_add_text(canvas,display_title,Rect2(34,rect.position.y+14,180,17),14,Color(0.07,0.20,0.35))
	_add_text(canvas,display_subtitle,Rect2(34,rect.position.y+32,190,15),12,Color(0.31,0.42,0.52))

	var buy_text := StoreManager.price_text(product_id)
	var disabled := false
	if _is_owned_product(product_id,info):
		buy_text = "OWNED"
		disabled = true
	elif StoreManager.is_purchase_pending(product_id):
		buy_text = "PENDING"
		disabled = true
	var buy := FigmaReferenceCanvas.button(buy_text,12,Color.WHITE,Color(1.0,0.55,0.12),23,Color(1.0,0.75,0.36),1)
	buy.name = "Buy_%s" % product_id
	FigmaReferenceCanvas.set_rect(buy,276,rect.position.y+18,78,46)
	buy.disabled = disabled
	if not disabled:
		buy.pressed.connect(_purchase.bind(product_id,buy))
	canvas.add_child(buy)

func _is_owned_product(product_id: String, info: Dictionary) -> bool:
	if not bool(info.get("non_consumable",false)):
		return false
	var purchased: Array = SaveManager.data.get("purchased_products",[])
	if product_id in purchased:
		return true
	if product_id == StoreManager.PRODUCT_REMOVE_ADS:
		return bool(SaveManager.data.get("remove_ads",false))
	if product_id == StoreManager.PRODUCT_STARTER_PACK:
		return bool(SaveManager.data.get("starter_pack_purchased",false))
	return false

func _add_text(canvas: Control, text_value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := FigmaReferenceCanvas.label(text_value,font_size,color,true)
	FigmaReferenceCanvas.set_rect(label,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	canvas.add_child(label)
	return label

func _refresh() -> void:
	if balance_label != null:
		balance_label.text = "◈ %s" % _compact_coins(EconomyManager.balance())

func _compact_coins(value: int) -> String:
	if value < 1000:
		return str(value)
	if value < 1000000:
		var whole := int(value / 1000)
		var rem := int((value % 1000) / 100)
		return "%d.%dK" % [whole,rem] if rem > 0 else "%dK" % whole
	return "%.1fM" % (float(value)/1000000.0)
