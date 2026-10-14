extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var store := root.get_node_or_null("StoreManager")
	if not _check(store != null, "StoreManager missing"):return
	var previous_provider = store.provider
	var previous_prices: Dictionary = store.localized_prices.duplicate(true)
	var previous_mode = ProjectSettings.get_setting("monetization/test_mode", false)
	ProjectSettings.set_setting("monetization/test_mode", false)
	var phantom := Node.new()
	phantom.name = "PricingFixtureProvider"
	root.add_child(phantom)
	store.provider = phantom
	store.localized_prices = {}
	var id := String(store.PRODUCT_COINS_MEDIUM)
	if not _check(store.verifier_ready(), "Test project lacks purchase verification settings"):return
	if not _check(store.price_text(id) == "NO PRICE", "A connected provider with no price must fail closed"):return
	if not _check(store.price_text("not-in-catalog") == "UNAVAILABLE", "Unknown SKU is sellable"):return
	var main := (load("res://scenes/Main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	for _i in range(6):await process_frame
	var hub := main.get_node_or_null("MonetizationHub")
	if not _check(hub != null, "Shop hub missing"):return
	hub.call("open_shop")
	for _i in range(3):await process_frame
	var overlay := hub.get("overlay") as Control
	if not _check(overlay != null and overlay.visible, "Shop did not open"):return
	var no_price := overlay.find_child("Buy_%s" % id,true,false) as Button
	if not _check(no_price != null and no_price.disabled and no_price.text == "NO PRICE", "An unpriced SKU was shown as buyable"):return
	var scrim := overlay.find_child("ShopOverlayScrim",true,false) as ColorRect
	if not _check(scrim != null and scrim.color.a >= 0.80, "Shop modal still exposes distracting, tappable-looking Home content underneath"):return
	var starter_id := String(store.PRODUCT_STARTER_PACK)
	var starter_buy := overlay.find_child("Buy_%s" % starter_id,true,false) as Button
	var starter_state := overlay.find_child("ShopStatusStarterState",true,false) as Label
	if not _check(starter_buy != null and starter_state != null, "Starter purchase and status controls missing"):return
	if not _check(starter_buy.disabled and starter_state.text == "NO PRICE", "Starter chip must not advertise an unpriced item as AVAILABLE"):return
	if not _check(starter_buy.accessibility_name.contains("STARTER PACK"), "Product status lacks its name for assistive technology"):return
	if not _check(no_price.tooltip_text.contains("region"), "Unavailable SKU has no helpful explanation"):return
	# The real Google Play async catalog signal must rebuild and enable only the
	# product with an actual localized price.
	var previous_overlay := overlay
	var previous_button := no_price
	store.set_localized_prices({id:"₦990.00"})
	for _i in range(6):await process_frame
	overlay = hub.get("overlay") as Control
	if not _check(overlay == previous_overlay, "Catalog callback rebuilt the entire Shop overlay"):return
	var priced := overlay.find_child("Buy_%s" % id,true,false) as Button
	if not _check(priced != null and not priced.disabled and priced.text == "₦990.00", "Catalog update failed to activate the priced product"):return
	if not _check(priced == previous_button and priced.pressed.get_connections().size() == 1, "In-place price refresh duplicated the Buy callback or replaced its button"):return
	store.set_localized_prices({id:"₦1,090.00"})
	for _i in range(3):await process_frame
	if not _check(priced.text == "₦1,090.00" and priced.pressed.get_connections().size() == 1 and overlay == hub.get("overlay"), "Repeated catalog refresh caused a rebuild or duplicate callback"):return
	if not _check(starter_state.text == "NO PRICE" and starter_buy.disabled, "A priced coin pack incorrectly activated the unpriced Starter bundle"):return
	store.set_localized_prices({id:"₦1,090.00",starter_id:"₦2,490.00"})
	for _i in range(3):await process_frame
	if not _check(not starter_buy.disabled and starter_buy.text == "₦2,490.00" and starter_state.text == "AVAILABLE", "Starter availability chip failed to track live verified Google Play pricing"):return
	store.set_localized_prices({id:"₦1,090.00"})
	for _i in range(3):await process_frame
	if not _check(starter_buy.disabled and starter_state.text == "NO PRICE", "Starter availability did not revert when the verified price disappeared"):return
	var other := overlay.find_child("Buy_%s" % store.PRODUCT_COINS_LARGE,true,false) as Button
	if not _check(other != null and other.disabled and other.text == "NO PRICE", "Unpriced neighboring SKU became buyable"):return
	main.queue_free()
	await process_frame
	store.provider = previous_provider
	store.localized_prices = previous_prices
	ProjectSettings.set_setting("monetization/test_mode", previous_mode)
	phantom.queue_free()
	print("SHOP_VERIFIED_PRICING_OK: unpriced SKU disabled, catalog refresh enables only priced products")
	quit(0)

func _check(ok: bool, message: String) -> bool:
	if ok:return true
	push_error(message)
	quit(1)
	return false
