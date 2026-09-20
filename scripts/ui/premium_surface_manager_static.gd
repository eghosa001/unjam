extends "res://scripts/ui/premium_surface_manager.gd"

# App-wide bridge for the new bright 3D visual language. Legacy gameplay
# mechanics stay untouched while levels, settings and collection surfaces are
# reskinned through one lightweight pass.

func _configure_background(root: Node, game_id: String, dark: bool, accent: Color) -> void:
	if root is Control:
		var control := root as Control
		var bg := control.get_node_or_null("Unjam3DSurfaceBackdrop") as Unjam3DBackdrop
		if bg == null:
			bg = Unjam3DBackdrop.new()
			bg.name = "Unjam3DSurfaceBackdrop"
			bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg.z_index = -100
			control.add_child(bg)
			control.move_child(bg, 0)
		bg.configure(Unjam3DTheme.game_accent(game_id), dark)
	_hide_legacy_backdrops(root)
	PremiumVisuals.set_accent(accent)

func _hide_legacy_backdrops(node: Node) -> void:
	for child in node.get_children():
		var path := _script_path(child)
		if path.ends_with("premium_backdrop.gd"):
			if child is CanvasItem:
				(child as CanvasItem).visible = false
			continue
		_hide_legacy_backdrops(child)

func _polish_tree(node: Node, surface: String, dark: bool, accent: Color) -> void:
	if not is_instance_valid(node):
		return
	if node.has_meta("unjam_figma_reference_root"):
		return
	if node is Button and not _is_gameplay_widget(node):
		var button := node as Button
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 96.0)
		button.add_theme_font_size_override("font_size", maxi(28, button.get_theme_font_size("font_size")))
		var role := _role_for_surface_button(button, surface)
		var button_accent := _button_accent(role, accent)
		Unjam3DTheme.gloss_button(button, button_accent, role in ["primary", "reward", "success"], 24 if not _looks_like_level_button(button, surface) else 20, dark)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		var emphasis := _panel_emphasis(panel, surface)
		var fill := Unjam3DTheme.surface_fill(dark, emphasis)
		var edge := Color(accent, 0.72) if dark or emphasis else Color("9adfff")
		panel.add_theme_stylebox_override("panel", Unjam3DTheme.panel_3d(fill, 30 if emphasis else 25, edge, 3 if emphasis else 2, 11 if emphasis else 6))
	elif node is Label:
		var label := node as Label
		var base_font_size := label.get_theme_font_size("font_size")
		if label.has_meta("unjam_surface_base_font_size"):
			base_font_size = int(label.get_meta("unjam_surface_base_font_size"))
		elif base_font_size > 0:
			label.set_meta("unjam_surface_base_font_size", base_font_size)
		var font_size := base_font_size
		if base_font_size > 0:
			font_size = maxi(22, base_font_size + (6 if base_font_size >= 28 else 4))
			label.add_theme_font_size_override("font_size", font_size)
		var text := label.text.strip_edges().to_upper()
		var color := Unjam3DTheme.text_primary(dark)
		if "COIN" in text or "★" in text or "PRESTIGE" in text:
			color = Color("d88700")
		elif font_size >= 28 or text.begins_with("WORLD "):
			color = accent.lightened(0.28) if dark else Unjam3DTheme.game_dark(_game_id_from_accent(accent))
		var outline := Color("05182c") if dark else Color(1, 1, 1, 0.96)
		Unjam3DTheme.label_3d(label, color, outline, 2 if font_size < 28 else 3)
	elif node is ProgressBar:
		var progress := node as ProgressBar
		progress.add_theme_stylebox_override("background", Unjam3DTheme.panel_3d(Color("17304c") if dark else Color("d7efff"), 12, Color(accent, 0.55) if dark else Color("84d5ff"), 2, 2))
		progress.add_theme_stylebox_override("fill", Unjam3DTheme.panel_3d(accent, 12, accent.lightened(0.30), 2, 3))
	for child in node.get_children():
		if child.name == "Unjam3DSurfaceBackdrop":
			continue
		_polish_tree(child, surface, dark, accent)

func _button_accent(role: String, accent: Color) -> Color:
	match role:
		"reward": return Unjam3DTheme.ORANGE
		"success": return Unjam3DTheme.GREEN
		"danger": return Unjam3DTheme.RED
		"primary": return accent
		_: return Unjam3DTheme.WATER_DARK

func _game_id_from_accent(accent: Color) -> String:
	if accent.is_equal_approx(PremiumDesignSystem.accent_for_game("water_sort")):
		return "water_sort"
	if accent.is_equal_approx(PremiumDesignSystem.accent_for_game("block_puzzle")):
		return "block_puzzle"
	return "rescue_rush"

func _add_surface_chrome(content: Control, surface: String, _game_id: String, dark: bool, _accent: Color) -> void:
	# Secondary screens already own their header/back navigation. Keep that single
	# ownership model, but make the shared wallet actionable inside the native
	# Collection/Levels header instead of drawing another overlay or badge.
	var existing := content.get_node_or_null("PremiumSurfaceChrome")
	if existing != null:
		content.remove_child(existing)
		existing.queue_free()
	_ensure_secondary_wallet(content, surface, dark)

func _ensure_secondary_wallet(content: Control, surface: String, dark: bool) -> void:
	if surface not in ["collection", "levels"]:
		return
	var header := _find_secondary_header(content)
	if header == null:
		return
	var wallet := header.get_node_or_null("SecondaryCoinShopButton") as Button
	if wallet == null:
		if surface == "collection":
			_remove_collection_coin_snapshot(header)
		wallet = Button.new()
		wallet.name = "SecondaryCoinShopButton"
		var viewport_width := get_viewport().get_visible_rect().size.x
		wallet.custom_minimum_size = Vector2(176 if viewport_width < 600.0 else 206, 94)
		wallet.add_theme_font_size_override("font_size", 25 if viewport_width < 600.0 else 27)
		wallet.tooltip_text = "Coins • Open Shop"
		Unjam3DTheme.gloss_button(wallet, Unjam3DTheme.ORANGE, true, 23, dark)
		wallet.pressed.connect(_open_shop)
		header.add_child(wallet)
	_set_secondary_wallet_balance(EconomyManager.balance())
	if not EconomyManager.balance_changed.is_connected(_on_economy_balance_changed):
		EconomyManager.balance_changed.connect(_on_economy_balance_changed)

func _find_secondary_header(node: Node) -> HBoxContainer:
	if node is HBoxContainer:
		var row := node as HBoxContainer
		for child in row.get_children():
			if child is Button:
				var text := (child as Button).text.strip_edges()
				if text in ["←", "‹", "← BACK"]:
					return row
	for child in node.get_children():
		var found := _find_secondary_header(child)
		if found != null:
			return found
	return null

func _remove_collection_coin_snapshot(header: HBoxContainer) -> void:
	for child in header.get_children():
		if child is Label and (child as Label).text.strip_edges().begins_with("◈"):
			header.remove_child(child)
			child.queue_free()
			return

func _set_secondary_wallet_balance(new_balance: int) -> void:
	var main := get_parent()
	if main == null:
		return
	var content = main.get("content")
	if content == null or not is_instance_valid(content):
		return
	var wallet := (content as Node).find_child("SecondaryCoinShopButton", true, false) as Button
	if wallet != null:
		wallet.text = "◈  %d  +" % new_balance

func _on_economy_balance_changed(new_balance: int, _delta: int, _reason: String) -> void:
	_set_secondary_wallet_balance(new_balance)

func _open_shop() -> void:
	var main := get_parent()
	if main == null:
		return
	var hub := main.get_node_or_null("MonetizationHub")
	if hub != null and hub.has_method("open_shop"):
		hub.call("open_shop")

func _animate_surface(content: Control) -> void:
	# MotionDirector owns navigation transitions. This manager owns only skinning,
	# background and chrome so two systems never fight over content.modulate.
	content.modulate.a = 1.0
