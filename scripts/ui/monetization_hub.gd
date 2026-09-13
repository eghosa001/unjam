extends Node

var layer: CanvasLayer
var shop_button: Button
var overlay: Control
var balance_label: Label
var status_label: Label

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	StoreManager.purchase_succeeded.connect(_on_purchase_succeeded)
	StoreManager.purchase_failed.connect(_on_purchase_failed)
	AdManager.rewarded_completed.connect(_on_rewarded_completed)
	AdManager.rewarded_failed.connect(_on_rewarded_failed)
	call_deferred("_build_ui")
	set_process(true)

func _process(_delta: float) -> void:
	if shop_button == null or not is_instance_valid(shop_button):
		return
	var host := get_parent()
	var surface := String(host.get("current_surface")) if host != null else ""
	shop_button.visible = surface == "home" and (overlay == null or not overlay.visible)

func _build_ui() -> void:
	if layer != null:
		return
	layer = CanvasLayer.new()
	layer.layer = 500
	add_child(layer)

	shop_button = Button.new()
	shop_button.text = "SHOP"
	shop_button.custom_minimum_size = Vector2(230, 82)
	shop_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	shop_button.position = Vector2(-270, -120)
	shop_button.add_theme_font_size_override("font_size", 22)
	shop_button.add_theme_stylebox_override("normal", _box(Color("7c5cff"), 24, Color("ffffff33"), 2))
	shop_button.add_theme_stylebox_override("hover", _box(Color("957cff"), 24, Color("ffffff66"), 2))
	shop_button.add_theme_stylebox_override("pressed", _box(Color("5c3fd6"), 24, Color.WHITE, 2))
	shop_button.pressed.connect(_open_shop)
	layer.add_child(shop_button)

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.055, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 70)
	overlay.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var close := Button.new()
	close.text = "← BACK"
	close.custom_minimum_size = Vector2(190, 72)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(_close_shop)
	header.add_child(close)
	var title := Label.new()
	title.text = "UNJAM SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("f8fbff"))
	header.add_child(title)
	balance_label = Label.new()
	balance_label.custom_minimum_size = Vector2(210, 72)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 20)
	balance_label.add_theme_color_override("font_color", Color("ffd166"))
	header.add_child(balance_label)

	var reward_panel := PanelContainer.new()
	reward_panel.add_theme_stylebox_override("panel", _box(Color("11294a"), 26, Color("49e1c0"), 2))
	root.add_child(reward_panel)
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 18)
	reward_panel.add_child(reward_row)
	var reward_text := Label.new()
	reward_text.text = "FREE COINS\nWatch an optional rewarded ad"
	reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_text.add_theme_font_size_override("font_size", 20)
	reward_row.add_child(reward_text)
	var watch := Button.new()
	watch.text = "WATCH AD  •  +50 COINS"
	watch.custom_minimum_size = Vector2(360, 88)
	watch.add_theme_font_size_override("font_size", 20)
	watch.pressed.connect(_watch_rewarded.bind(watch))
	reward_row.add_child(watch)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var products := VBoxContainer.new()
	products.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products.add_theme_constant_override("separation", 12)
	scroll.add_child(products)
	for product_id in StoreManager.PRODUCTS.keys():
		_add_product(products, String(product_id))
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color("9eb2cc"))
	root.add_child(status_label)
	_refresh()

func _add_product(parent: VBoxContainer, product_id: String) -> void:
	var info: Dictionary = StoreManager.PRODUCTS[product_id]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("101d38"), 22, Color("ffffff22"), 1))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var text := Label.new()
	text.text = "%s\n%s" % [String(info.get("title", product_id)), String(info.get("subtitle", ""))]
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 20)
	row.add_child(text)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(280, 82)
	buy.add_theme_font_size_override("font_size", 18)
	var purchased: Array = SaveManager.data.get("purchased_products", [])
	if bool(info.get("non_consumable", false)) and product_id in purchased:
		buy.text = "OWNED"
		buy.disabled = true
	else:
		buy.text = StoreManager.price_text(product_id)
		buy.pressed.connect(_purchase.bind(product_id, buy))
	row.add_child(buy)

func _open_shop() -> void:
	overlay.visible = true
	shop_button.visible = false
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
	# Recreate the whole monetization layer to refresh ownership/price state safely.
	layer.remove_child(shop_button)
	shop_button.queue_free()
	shop_button = null
	remove_child(layer)
	layer.queue_free()
	layer = null
	_build_ui()
	if was_open:
		overlay.visible = true
		shop_button.visible = false

func _on_node_added(node: Node) -> void:
	if node == null or not node.has_signal("finished"):
		return
	var script: Script = node.get_script() as Script
	if script == null:
		return
	var path := String(script.resource_path)
	var game_id := ""
	if path.ends_with("scripts/game/water_sort.gd"):
		game_id = "water_sort"
	elif path.ends_with("scripts/game/block_puzzle.gd"):
		game_id = "block_puzzle"
	if game_id.is_empty():
		return
	var callback := Callable(self, "_on_puzzle_finished").bind(game_id)
	if not node.is_connected("finished", callback):
		node.connect("finished", callback)

func _on_puzzle_finished(_level_number: int, game_id: String) -> void:
	AdManager.note_level_completed()
	AnalyticsManager.track("monetization_level_complete", {"game": game_id})
	if AdManager.should_show_interstitial():
		AdManager.show_interstitial()

func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border
	return style
