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
	bg.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(
		Color("#f0fcff"),Color("#fafcff"),Color("#eeebfd"),34,Color("#bad1e3"),1,0.48
	))
	FigmaReferenceCanvas.set_rect(bg,0,0,390,844)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	FigmaReferenceCanvas.add_shadow(canvas,Rect2(17,19,52,52),18,Color(0.02,0.15,0.30,0.16),4,Vector2(0,3))
	var back := FigmaReferenceCanvas.premium_button("‹",27,Color("#083b78"),Color("#fffef7"),18,Color(0.74,0.80,0.95,0.55),1.2)
	back.name = "ShopBackButton"
	FigmaReferenceCanvas.set_rect(back,17,19,52,52)
	back.pressed.connect(_close_shop)
	canvas.add_child(back)

	_add_text(canvas,"UNJAM SHOP",Rect2(83,21,205,28),23,Color("#123359"))
	_add_text(canvas,"Useful upgrades • optional rewards",Rect2(83,51,210,15),12,Color("#4f6b85"))
	balance_label = _add_text(canvas,"",Rect2(297,37,60,15),12,Color("#fffef7"))
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FigmaReferenceCanvas.add_shadow(canvas,Rect2(285,21,84,46),23,Color(0.02,0.15,0.30,0.16),3,Vector2(0,2))
	var wallet := PanelContainer.new()
	wallet.name = "ShopCoinPill"
	wallet.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(Color("#ffa550"),Color("#ff8c1f"),Color("#cc7018"),23,Color(1.0,0.78,0.38,0.55),1.2))
	FigmaReferenceCanvas.set_rect(wallet,285,21,84,46)
	wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(wallet)
	canvas.move_child(wallet,balance_label.get_index())

	_add_product_exact(canvas,StoreManager.PRODUCT_REMOVE_ADS,Rect2(17,91,354,70),"REMOVE ADS","No interstitial interruptions")
	_add_product_exact(canvas,StoreManager.PRODUCT_STARTER_PACK,Rect2(17,169,354,70),"STARTER PACK","One-time launch boost")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_SMALL,Rect2(17,247,354,60),"SMALL COINS","500 coins")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_MEDIUM,Rect2(17,315,354,60),"MEDIUM COINS","1,500 coins")
	_add_product_exact(canvas,StoreManager.PRODUCT_COINS_LARGE,Rect2(17,383,354,60),"LARGE COINS","4,000 coins")

	FigmaReferenceCanvas.add_shadow(canvas,Rect2(17,457,354,78),16,Color(0.03,0.11,0.20,0.16),5,Vector2(0,5))
	var reward := PanelContainer.new()
	reward.name = "ShopFreeCoinsPanel"
	reward.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(Color("#e9fdef"),Color("#e3f8e9"),Color("#ddf4e5"),16,Color(0.55,0.88,0.65,0.55),1.2))
	FigmaReferenceCanvas.set_rect(reward,17,457,354,78)
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(reward)
	_add_text(canvas,"WATCH & EARN",Rect2(33,473,150,18),15,Color("#088c3d"))
	_add_text(canvas,"Optional • +50 coins",Rect2(33,500,160,15),12,Color("#4f6b85"))
	FigmaReferenceCanvas.add_shadow(canvas,Rect2(237,471,116,48),25,Color(0.02,0.15,0.30,0.16),3,Vector2(0,2))
	var watch := FigmaReferenceCanvas.premium_button("▶ +50 COINS",12,Color.WHITE,Color("#ff8c1f"),25,Color("#ffbd64"),1.2)
	watch.name = "ShopRewardedCoinsButton"
	FigmaReferenceCanvas.set_rect(watch,237,471,116,48)
	watch.pressed.connect(_watch_rewarded.bind(watch))
	canvas.add_child(watch)

	FigmaReferenceCanvas.add_shadow(canvas,Rect2(17,557,170,46),16,Color(0.03,0.10,0.20,0.22),4,Vector2(0,4))
	var restore := FigmaReferenceCanvas.premium_button("RESTORE PURCHASES",12,Color.WHITE,Color("#086ec7"),16,Color("#70b9ef"),1.2)
	restore.name = "ShopRestorePurchases"
	FigmaReferenceCanvas.set_rect(restore,17,557,170,46)
	restore.pressed.connect(_restore_purchases)
	canvas.add_child(restore)
	FigmaReferenceCanvas.add_shadow(canvas,Rect2(201,557,170,46),16,Color(0.03,0.10,0.20,0.22),4,Vector2(0,4))
	var privacy := FigmaReferenceCanvas.premium_button("PRIVACY OPTIONS",12,Color.WHITE,Color("#086ec7"),16,Color("#70b9ef"),1.2)
	privacy.name = "ShopPrivacyOptions"
	FigmaReferenceCanvas.set_rect(privacy,201,557,170,46)
	privacy.pressed.connect(PrivacyManager.show_privacy_options)
	canvas.add_child(privacy)

	status_label = _add_text(canvas,"",Rect2(23,617,342,52),12,Color("#4f6b85"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var accent_rail := ColorRect.new()
	accent_rail.name = "ShopAccentRail"
	accent_rail.color = Color(0.46,0.34,0.92,0.88)
	accent_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FigmaReferenceCanvas.set_rect(accent_rail,17,103,5,58)
	canvas.add_child(accent_rail)

	_refresh()

func _add_product_exact(canvas: Control, product_id: String, rect: Rect2, display_title: String, display_subtitle: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	FigmaReferenceCanvas.add_shadow(canvas,rect,16,Color(0.03,0.11,0.20,0.16),5,Vector2(0,5))
	var panel := PanelContainer.new()
	panel.name = "ShopProduct_%s" % product_id
	panel.add_theme_stylebox_override("panel",FigmaReferenceCanvas.rounded_gradient3(
		Color("#fffef8"),Color("#fbfaf4"),Color("#f6f5ef"),16,Color(0.70,0.64,0.96,0.32),1.2,0.50
	))
	FigmaReferenceCanvas.set_rect(panel,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	_add_text(canvas,display_title,Rect2(33,rect.position.y+14,180,17),14,Color("#123359"))
	_add_text(canvas,display_subtitle,Rect2(33,rect.position.y+32,190,15),12,Color("#4f6b85"))

	var buy_text := StoreManager.price_text(product_id)
	var disabled := false
	if _is_owned_product(product_id,info):
		buy_text = "OWNED"
		disabled = true
	elif StoreManager.is_purchase_pending(product_id):
		buy_text = "PENDING"
		disabled = true
	FigmaReferenceCanvas.add_shadow(canvas,Rect2(275,rect.position.y+18,78,46),23,Color(0.02,0.15,0.30,0.16),3,Vector2(0,2))
	var buy := FigmaReferenceCanvas.premium_button(buy_text,12,Color.WHITE,Color("#ff8c1f"),23,Color("#ffbd64"),1.2)
	buy.name = "Buy_%s" % product_id
	FigmaReferenceCanvas.set_rect(buy,275,rect.position.y+18,78,46)
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
