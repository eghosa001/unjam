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
	if not _check(no_price.tooltip_text.contains("region"), "Unavailable SKU has no helpful explanation"):return
	# The real Google Play async catalog signal must rebuild and enable only the
	# product with an actual localized price.
	store.set_localized_prices({id:"₦990.00"})
	for _i in range(6):await process_frame
	overlay = hub.get("overlay") as Control
	var priced := overlay.find_child("Buy_%s" % id,true,false) as Button
	if not _check(priced != null and not priced.disabled and priced.text == "₦990.00", "Catalog update failed to activate the priced product"):return
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
